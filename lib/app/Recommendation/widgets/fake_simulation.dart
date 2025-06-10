import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:graduationproject/app/Recommendation/recommendations.dart';
import 'package:graduationproject/app/Recommendation/widgets/trade_record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:graduationproject/app/Recommendation/widgets/simulation_state.dart';

class SimulationManager {
  static final SimulationManager _instance = SimulationManager._internal();
  factory SimulationManager() => _instance;
  SimulationManager._internal();

  Timer? _priceTimer;
  Function? _timerCallback;

  void startTimer(Duration duration, Function callback) {
    stopTimer();
    _timerCallback = callback;
    _priceTimer = Timer.periodic(duration, (timer) {
      _timerCallback?.call();
    });
  }

  void stopTimer() {
    _priceTimer?.cancel();
    _priceTimer = null;
    _timerCallback = null;
  }

  bool isTimerActive() => _priceTimer != null && _priceTimer!.isActive;
}

class FakeSimulationPage extends StatefulWidget {
  final StockRecommendation stock;
  final String userId;

  const FakeSimulationPage({super.key, required this.stock, required this.userId});

  @override
  FakeSimulationPageState createState() => FakeSimulationPageState();
}

class FakeSimulationPageState extends State<FakeSimulationPage> with SingleTickerProviderStateMixin {
  List<FlSpot> userPricePoints = [];
  List<FlSpot> appPricePoints = [];
  bool isSimulating = false;
  String userResult = '';
  String appResult = '';
  double userProfitLoss = 0.0;
  double appProfitLoss = 0.0;
  int currentStep = 0;
  double currentPrice = 0.0;
  bool tradeClosed = false;
  DateTime simulationStartTime = DateTime.now();

  final TextEditingController entryPriceController = TextEditingController();
  final TextEditingController stopLossController = TextEditingController();
  final TextEditingController takeProfitController = TextEditingController();
  bool isBuyTrade = true;
  late Box<TradeRecord> tradeBox;
  late Box<SimulationState> simulationBox;

  final SimulationManager _simulationManager = SimulationManager();

  @override
  void initState() {
    super.initState();
    tradeBox = Hive.box<TradeRecord>('trades');
    simulationBox = Hive.box<SimulationState>('simulations');
    debugPrint('tradeBox opened: ${tradeBox.isOpen}');
    debugPrint('simulationBox opened: ${simulationBox.isOpen}');

    // استرجاع حالة المحاكاة لو موجودة
    _restoreSimulationState();
  }

  void _restoreSimulationState() {
    final existingSimulation = simulationBox.values.firstWhere(
      (sim) => sim.stockSymbol == widget.stock.symbol && !sim.tradeClosed,
      orElse: () => SimulationState(
        isSimulating: false,
        simulationStartTime: DateTime.now(),
        userPricePoints: [],
        appPricePoints: [],
        currentStep: 0,
        currentPrice: widget.stock.currentPrice,
        userResult: '',
        appResult: '',
        userProfitLoss: 0.0,
        appProfitLoss: 0.0,
        tradeClosed: false,
        stockSymbol: widget.stock.symbol,
        entryPrice: widget.stock.currentPrice,
        stopLoss: widget.stock.support,
        takeProfit: widget.stock.resistance,
        isBuyTrade: true, // Default value for new simulation
      ),
    );

    setState(() {
      isSimulating = existingSimulation.isSimulating;
      simulationStartTime = existingSimulation.simulationStartTime;
      currentStep = existingSimulation.currentStep;
      currentPrice = existingSimulation.currentPrice;
      userResult = existingSimulation.userResult;
      appResult = existingSimulation.appResult;
      userProfitLoss = existingSimulation.userProfitLoss;
      appProfitLoss = existingSimulation.appProfitLoss;
      tradeClosed = existingSimulation.tradeClosed;
      isBuyTrade = existingSimulation.isBuyTrade ?? true; // Restore isBuyTrade from saved state
      userPricePoints = existingSimulation.userPricePoints
          .map((point) => FlSpot(point['x'] ?? 0.0, point['y'] ?? 0.0))
          .toList();
      appPricePoints = existingSimulation.appPricePoints
          .map((point) => FlSpot(point['x'] ?? 0.0, point['y'] ?? 0.0))
          .toList();
      // استعادة قيم TextEditingController
      entryPriceController.text = _formatNumber(existingSimulation.entryPrice);
      stopLossController.text = _formatNumber(existingSimulation.stopLoss);
      takeProfitController.text = _formatNumber(existingSimulation.takeProfit);
    });

    if (isSimulating && !tradeClosed && !_simulationManager.isTimerActive()) {
      _startTimer();
    } else {
      fetchCurrentPrice();
    }
  }

  void _saveSimulationState() {
    final simulationState = SimulationState(
      isSimulating: isSimulating,
      simulationStartTime: simulationStartTime,
      userPricePoints: userPricePoints
          .map((point) => {'x': point.x, 'y': point.y})
          .toList(),
      appPricePoints: appPricePoints
          .map((point) => {'x': point.x, 'y': point.y})
          .toList(),
      currentStep: currentStep,
      currentPrice: currentPrice,
      userResult: userResult,
      appResult: appResult,
      userProfitLoss: userProfitLoss,
      appProfitLoss: appProfitLoss,
      tradeClosed: tradeClosed,
      stockSymbol: widget.stock.symbol,
      entryPrice: double.tryParse(entryPriceController.text) ?? widget.stock.currentPrice,
      stopLoss: double.tryParse(stopLossController.text) ?? widget.stock.support,
      takeProfit: double.tryParse(takeProfitController.text) ?? widget.stock.resistance,
      isBuyTrade: isBuyTrade, // Save isBuyTrade state
    );

    simulationBox.values
        .where((sim) => sim.stockSymbol == widget.stock.symbol)
        .toList()
        .forEach((sim) => sim.delete());

    simulationBox.add(simulationState);
  }

  Future<void> fetchCurrentPrice() async {
    try {
      final response = await http.get(
        Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/${widget.stock.symbol}?interval=1d&range=2mo'),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chartResult = data['chart']['result'][0];
        final closes = chartResult['indicators']['quote'][0]['close'] as List<dynamic>;

        final lastPrice = closes.lastWhere((price) => price != null, orElse: () => widget.stock.currentPrice).toDouble();
        setState(() {
          currentPrice = lastPrice;
        });
        _saveSimulationState();
      } else {
        throw Exception('Failed to fetch price: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        currentPrice = widget.stock.currentPrice;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching price: $e. Using fallback price.')),
        );
      });
      _saveSimulationState();
    }
  }

  void _startTimer() {
    double? userEntryPrice = double.tryParse(entryPriceController.text);
    double? userStopLoss = double.tryParse(stopLossController.text);
    double? userTakeProfit = double.tryParse(takeProfitController.text);

    if (userEntryPrice == null || userStopLoss == null || userTakeProfit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numerical values for all fields.')),
      );
      return;
    }

    setState(() {
      isSimulating = true;
      tradeClosed = false;
      if (userPricePoints.isEmpty) {
        userPricePoints = [FlSpot(0, currentPrice)];
      }
      if (appPricePoints.isEmpty) {
        appPricePoints = [FlSpot(0, widget.stock.entryPrice ?? currentPrice)];
      }
      _saveSimulationState();
    });

    double appEntryPrice = widget.stock.entryPrice ?? currentPrice;
    double appStopLoss = widget.stock.stopLoss ?? widget.stock.support;
    double appTakeProfit = widget.stock.takeProfit ?? widget.stock.resistance;
    bool isAppBuy = widget.stock.recommendation.contains('🟢');

    _simulationManager.startTimer(const Duration(seconds: 60), () async {
      if (tradeClosed || !mounted) {
        _simulationManager.stopTimer();
        if (mounted) {
          setState(() {
            isSimulating = false;
          });
        }
        return;
      }

      await fetchCurrentPrice();
      if (mounted) {
        setState(() {
          currentStep++;
          userPricePoints.add(FlSpot(currentStep.toDouble(), currentPrice));
          appPricePoints.add(FlSpot(currentStep.toDouble(), currentPrice));

          if (isBuyTrade && currentPrice <= userStopLoss) {
            userProfitLoss = currentPrice - userEntryPrice;
            userResult = 'Hit Stop-Loss: Loss of ${_formatNumber(userProfitLoss.abs())}.';
            tradeClosed = true;
          } else if (isBuyTrade && currentPrice >= userTakeProfit) {
            userProfitLoss = currentPrice - userEntryPrice;
            userResult = 'Hit Take-Profit: Profit of ${_formatNumber(userProfitLoss.abs())}!';
            tradeClosed = true;
          } else if (!isBuyTrade && currentPrice >= userStopLoss) {
            userProfitLoss = userEntryPrice - currentPrice;
            userResult = 'Hit Stop-Loss: Loss of ${_formatNumber(userProfitLoss.abs())}.';
            tradeClosed = true;
          } else if (!isBuyTrade && currentPrice <= userTakeProfit) {
            userProfitLoss = userEntryPrice - currentPrice;
            userResult = 'Hit Take-Profit: Profit of ${_formatNumber(userProfitLoss.abs())}!';
            tradeClosed = true;
          }

          if (isAppBuy && currentPrice <= appStopLoss) {
            appProfitLoss = currentPrice - appEntryPrice;
            appResult = 'App Recommendation Hit Stop-Loss: Loss of ${_formatNumber(appProfitLoss.abs())}.';
          } else if (isAppBuy && currentPrice >= appTakeProfit) {
            appProfitLoss = currentPrice - appEntryPrice;
            appResult = 'App Recommendation Hit Take-Profit: Profit of ${_formatNumber(appProfitLoss.abs())}!';
          } else if (!isAppBuy && currentPrice >= appStopLoss) {
            appProfitLoss = appEntryPrice - currentPrice;
            appResult = 'App Recommendation Hit Stop-Loss: Loss of ${_formatNumber(appProfitLoss.abs())}.';
          } else if (!isAppBuy && currentPrice <= appTakeProfit) {
            appProfitLoss = appEntryPrice - currentPrice;
            appResult = 'App Recommendation Hit Take-Profit: Profit of ${_formatNumber(appProfitLoss.abs())}!';
          }

          if (tradeClosed) {
            _simulationManager.stopTimer();
            if (mounted) {
              setState(() {
                isSimulating = false;
              });
            }
            saveTrade(userEntryPrice , userStopLoss , userTakeProfit );
          }
        });
      }
    });
  }

  void cancelSimulation() {
    _simulationManager.stopTimer();
    setState(() {
      isSimulating = false;
      tradeClosed = true;
      userResult = 'Simulation cancelled by user.';
      appResult = 'App recommendation simulation cancelled.';
      double? userEntryPrice = double.tryParse(entryPriceController.text);
      if (userEntryPrice != null) {
        userProfitLoss = isBuyTrade ? (currentPrice - userEntryPrice) : (userEntryPrice - currentPrice);
      }
    });
    _saveSimulationState();
    saveTrade(
      double.tryParse(entryPriceController.text) ?? 0.0,
      double.tryParse(stopLossController.text) ?? 0.0,
      double.tryParse(takeProfitController.text) ?? 0.0,
    );
  }

  void saveTrade(double entryPrice, double stopLoss, double takeProfit) {
    final trade = TradeRecord(
      userId: widget.userId,
      stockSymbol: widget.stock.symbol,
      stockTitle: widget.stock.title,
      isBuyTrade: isBuyTrade,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      profitLoss: userProfitLoss,
      result: userResult,
      timestamp: DateTime.now(),
    );
    tradeBox.add(trade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stock.title} Investment Simulation'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Your Trade',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Buy'),
                            leading: Radio<bool>(
                              value: true,
                              groupValue: isBuyTrade,
                              onChanged: (value) {
                                setState(() {
                                  isBuyTrade = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Sell'),
                            leading: Radio<bool>(
                              value: false,
                              groupValue: isBuyTrade,
                              onChanged: (value) {
                                setState(() {
                                  isBuyTrade = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: entryPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Entry Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stopLossController,
                      decoration: const InputDecoration(
                        labelText: 'Stop Loss',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: takeProfitController,
                      decoration: const InputDecoration(
                        labelText: 'Take Profit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isSimulating ? null : () => _startTimer(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    isSimulating ? 'Simulating...' : 'Start Simulation',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                if (isSimulating) const SizedBox(width: 10),
                if (isSimulating)
                  ElevatedButton(
                    onPressed: cancelSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel Simulation',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Current Price: ${_formatNumber(currentPrice)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Movement (Your Trade)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _formatNumber(value),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: userPricePoints,
                              isCurved: false,
                              color: Colors.blue,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: double.tryParse(entryPriceController.text) ?? 100.0,
                                color: Colors.blue,
                                strokeWidth: 2,
                                dashArray: [8, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                                  labelResolver: (line) => 'Entry: ${_formatNumber(line.y)}',
                                ),
                              ),
                              HorizontalLine(
                                y: double.tryParse(stopLossController.text) ?? 90.0,
                                color: Colors.red,
                                strokeWidth: 2,
                                dashArray: [8, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  labelResolver: (line) => 'Stop-Loss: ${_formatNumber(line.y)}',
                                ),
                              ),
                              HorizontalLine(
                                y: double.tryParse(takeProfitController.text) ?? 110.0,
                                color: Colors.green,
                                strokeWidth: 2,
                                dashArray: [8, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: const TextStyle(color: Colors.green, fontSize: 12),
                                  labelResolver: (line) => 'Take-Profit: ${_formatNumber(line.y)}',
                                ),
                              ),
                            ],
                          ),
                          minY: [
                            double.tryParse(entryPriceController.text) ?? 100.0,
                            double.tryParse(stopLossController.text) ?? 90.0,
                            double.tryParse(takeProfitController.text) ?? 110.0,
                            ...userPricePoints.map((spot) => spot.y),
                          ].reduce((a, b) => a < b ? a : b) * 0.95,
                          maxY: [
                            double.tryParse(entryPriceController.text) ?? 100.0,
                            double.tryParse(stopLossController.text) ?? 90.0,
                            double.tryParse(takeProfitController.text) ?? 110.0,
                            ...userPricePoints.map((spot) => spot.y),
                          ].reduce((a, b) => a > b ? a : b) * 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (userResult.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulation Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your Trade: $userResult',
                        style: TextStyle(
                          fontSize: 16,
                          color: userProfitLoss >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'App Recommendation: $appResult',
                        style: TextStyle(
                          fontSize: 16,
                          color: appProfitLoss >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userProfitLoss > appProfitLoss
                            ? 'Your trade performed better than the app\'s recommendation!'
                            : userProfitLoss < appProfitLoss
                                ? 'The app\'s recommendation outperformed your trade.'
                                : 'Your trade and the app\'s recommendation performed equally.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trade History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder(
                      valueListenable: tradeBox.listenable(),
                      builder: (context, Box<TradeRecord> box, _) {
                        final userTrades = box.values
                            .where((trade) => trade.userId == widget.userId)
                            .toList()
                            .reversed
                            .take(5)
                            .toList();
                        if (userTrades.isEmpty) {
                          return const Text('No trades yet.');
                        }
                        return Column(
                          children: userTrades.map((trade) {
                            return ListTile(
                              title: Text('${trade.stockTitle} (${trade.isBuyTrade ? "Buy" : "Sell"})'),
                              subtitle: Text(
                                  'Result: ${trade.result}\nTime: ${trade.timestamp.toString().substring(0, 19)}'),
                              trailing: Text(
                                _formatNumber(trade.profitLoss),
                                style: TextStyle(
                                  color: trade.profitLoss >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double num) {
    return num.toStringAsFixed(2);
  }

  @override
  void dispose() {
    if (tradeClosed || !isSimulating) {
      _simulationManager.stopTimer();
    }
    _saveSimulationState();
    entryPriceController.dispose();
    stopLossController.dispose();
    takeProfitController.dispose();
    super.dispose();
  }
}