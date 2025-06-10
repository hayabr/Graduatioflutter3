import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:graduationproject/app/Recommendation/recommendations.dart';
import 'package:graduationproject/app/Recommendation/widgets/fake_simulation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StockPricePoint {
  final DateTime date;
  final double price;

  StockPricePoint({required this.date, required this.price});
}

class StockMACDPoint {
  final int index;
  final double macdLine;
  final double signalLine;
  final double histogram;

  StockMACDPoint({
    required this.index,
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

class StockDetailsPage extends StatefulWidget {
  final StockRecommendation stock;

  const StockDetailsPage({super.key, required this.stock});

  @override
  // ignore: library_private_types_in_public_api
  _StockDetailsPageState createState() => _StockDetailsPageState();
}

class _StockDetailsPageState extends State<StockDetailsPage> {
  List<StockPricePoint> priceHistory = [];
  List<StockMACDPoint> macdHistory = [];
  bool isLoading = true;
  double fallbackSupport = 0;
  double fallbackResistance = 0;

  @override
  void initState() {
    super.initState();
    fetchPriceHistory();
  }

  Future<void> fetchPriceHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      String symbol = widget.stock.symbol;
      final response = await http.get(
        Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=3mo&interval=1d',
        ),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List<dynamic>;
        final closes = result['indicators']['quote'][0]['close'] as List<dynamic>;
        final lows = result['indicators']['quote'][0]['low'] as List<dynamic>;
        final highs = result['indicators']['quote'][0]['high'] as List<dynamic>;

        final List<StockPricePoint> points = [];
        final List<double> validCloses = [];
        final List<double> validLows = [];
        final List<double> validHighs = [];

        for (int i = 0; i < timestamps.length; i++) {
          if (closes[i] != null && lows[i] != null && highs[i] != null) {
            points.add(StockPricePoint(
              date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
              price: closes[i].toDouble(),
            ));
            validCloses.add(closes[i].toDouble());
            validLows.add(lows[i].toDouble());
            validHighs.add(highs[i].toDouble());
          }
        }

        if (validCloses.length < 26) {
          debugPrint('Not enough data for MACD: ${validCloses.length} points');
          List<double> supports = validLows
              .where((low) => validLows.where((l) => l <= low * 1.01 && l >= low * 0.99).length >= 3)
              .toList();
          fallbackSupport = supports.isNotEmpty
              ? supports.reduce((a, b) => a < b ? a : b)
              : validLows.isNotEmpty
                  ? validLows.reduce((a, b) => a < b ? a : b)
                  : widget.stock.support;

          List<double> resistances = validHighs
              .where((high) => validHighs.where((h) => h <= high * 1.01 && h >= high * 0.99).length >= 3)
              .toList();
          fallbackResistance = resistances.isNotEmpty
              ? resistances.reduce((a, b) => a > b ? a : b)
              : validHighs.isNotEmpty
                  ? validHighs.reduce((a, b) => a > b ? a : b)
                  : widget.stock.resistance;

          if (mounted) {
            setState(() {
              priceHistory = points;
              macdHistory = [];
              isLoading = false;
            });
          }
          return;
        }

        final macdData = _calculateMACD(validCloses);
        final macdPoints = <StockMACDPoint>[];
        final macdLine = macdData['macdLine']!;
        final signalLine = macdData['signalLine']!;
        for (int i = 0; i < macdLine.length && i < signalLine.length; i++) {
          macdPoints.add(StockMACDPoint(
            index: i,
            macdLine: macdLine[i],
            signalLine: signalLine[i],
            histogram: macdLine[i] - signalLine[i],
          ));
        }

        List<double> supports = validLows
            .where((low) => validLows.where((l) => l <= low * 1.01 && l >= low * 0.99).length >= 3)
            .toList();
        fallbackSupport = supports.isNotEmpty
            ? supports.reduce((a, b) => a < b ? a : b)
            : validLows.reduce((a, b) => a < b ? a : b);

        List<double> resistances = validHighs
            .where((high) => validHighs.where((h) => h <= high * 1.01 && h >= high * 0.99).length >= 3)
            .toList();
        fallbackResistance = resistances.isNotEmpty
            ? resistances.reduce((a, b) => a > b ? a : b)
            : validHighs.reduce((a, b) => a > b ? a : b);

        if (mounted) {
          setState(() {
            priceHistory = points;
            macdHistory = macdPoints;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load price history');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          priceHistory = [];
          macdHistory = [];
          fallbackSupport = widget.stock.support;
          fallbackResistance = widget.stock.resistance;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<double> _calculateSMA(List<double> prices, int period) {
    List<double> sma = [];
    for (int i = period - 1; i < prices.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += prices[i - j];
      }
      sma.add(sum / period);
    }
    return sma;
  }

  Map<String, List<double>> _calculateMACD(List<double> prices) {
    List<double> calculateEMA(List<double> prices, int period) {
      List<double> ema = [];
      if (prices.length < period) return ema;
      double multiplier = 2 / (period + 1);
      ema.add(prices.sublist(0, period).reduce((a, b) => a + b) / period);

      for (int i = period; i < prices.length; i++) {
        double value = (prices[i] * multiplier) + (ema.last * (1 - multiplier));
        ema.add(value);
      }
      return ema;
    }

    List<double> ema12 = calculateEMA(prices, 12);
    List<double> ema26 = calculateEMA(prices, 26);

    List<double> macdLine = [];
    for (int i = 0; i < ema12.length && i < ema26.length; i++) {
      macdLine.add(ema12[i] - ema26[i]);
    }

    List<double> signalLine = calculateEMA(macdLine, 9);

    return {
      'macdLine': macdLine,
      'signalLine': signalLine,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stock.title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildRecommendationCard(),
            const SizedBox(height: 20),
            _buildPriceChart(),
            const SizedBox(height: 20),
            _buildMACDChart(),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildConditionsSection(),
            const SizedBox(height: 20),
            _buildAnalysisSection(),
            const SizedBox(height: 20),
            _buildTradingStrategySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.bar_chart,
          size: 40,
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stock.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.stock.subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    Color cardColor;
    if (widget.stock.recommendation.contains('🟢')) {
      // ignore: deprecated_member_use
      cardColor = Colors.green.withOpacity(0.1);
    } else if (widget.stock.recommendation.contains('🔴')) {
      // ignore: deprecated_member_use
      cardColor = Colors.red.withOpacity(0.1);
    } else {
      // ignore: deprecated_member_use
      cardColor = Colors.blue.withOpacity(0.1);
    }

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.stock.recommendation,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getRecommendationColor(widget.stock.recommendation),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FakeSimulationPage(
                          stock: widget.stock,
                          userId: '12',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Simulation',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : priceHistory.isEmpty
                      ? const Center(child: Text('No price data available'))
                      : LineChart(
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
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: priceHistory
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value.price))
                                    .toList(),
                                isCurved: false,
                                color: Colors.blue,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: _calculateSMA(
                                  priceHistory.map((p) => p.price).toList(),
                                  14,
                                )
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          (e.key + 14 - 1).toDouble(),
                                          e.value,
                                        ))
                                    .toList(),
                                isCurved: false,
                                color: Colors.orange,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                if (fallbackSupport > 0)
                                  HorizontalLine(
                                    y: fallbackSupport,
                                    color: Colors.green,
                                    strokeWidth: 2,
                                    dashArray: [8, 4],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                      labelResolver: (line) => 'Support: ${_formatNumber(line.y)}',
                                    ),
                                  ),
                                if (fallbackResistance > 0)
                                  HorizontalLine(
                                    y: fallbackResistance,
                                    color: Colors.red,
                                    strokeWidth: 2,
                                    dashArray: [8, 4],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                      labelResolver: (line) => 'Resistance: ${_formatNumber(line.y)}',
                                    ),
                                  ),
                              ],
                            ),
                            minY: priceHistory.isNotEmpty
                                ? ([priceHistory
                                            .map((p) => p.price)
                                            .reduce((a, b) => a < b ? a : b),
                                        fallbackSupport > 0
                                            ? fallbackSupport
                                            : double.infinity]
                                      ..removeWhere((e) => e == double.infinity))
                                    .reduce((a, b) => a < b ? a : b) * 0.95
                                : 0,
                            maxY: priceHistory.isNotEmpty
                                ? ([priceHistory
                                            .map((p) => p.price)
                                            .reduce((a, b) => a > b ? a : b),
                                        fallbackResistance > 0
                                            ? fallbackResistance
                                            : double.negativeInfinity]
                                      ..removeWhere((e) => e == double.negativeInfinity))
                                    .reduce((a, b) => a > b ? a : b) * 1.05
                                : 0,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMACDChart() {
    final latestMACD = macdHistory.isNotEmpty ? macdHistory.last : null;
    final isBullish = latestMACD != null && latestMACD.histogram > 0;
    final isBearish = latestMACD != null && latestMACD.histogram < 0;
    final isCrossOver = macdHistory.length >= 2 &&
        ((macdHistory[macdHistory.length - 2].histogram <= 0 && isBullish) ||
            (macdHistory[macdHistory.length - 2].histogram >= 0 && isBearish));
    final isTrendingUp = macdHistory.length >= 3 &&
        macdHistory[macdHistory.length - 3].macdLine <
            macdHistory[macdHistory.length - 2].macdLine &&
        macdHistory[macdHistory.length - 2].macdLine <
            macdHistory[macdHistory.length - 1].macdLine;
    final isTrendingDown = macdHistory.length >= 3 &&
        macdHistory[macdHistory.length - 3].macdLine >
            macdHistory[macdHistory.length - 2].macdLine &&
        macdHistory[macdHistory.length - 2].macdLine >
            macdHistory[macdHistory.length - 1].macdLine;

    List<String> macdAnalysis = [];
    if (isCrossOver) {
      if (isBullish) {
        macdAnalysis.add("Strong bullish crossover: MACD line crossed above signal line with positive histogram (strong buy signal).");
      } else {
        macdAnalysis.add("Strong bearish crossover: MACD line crossed below signal line with negative histogram (strong sell signal).");
      }
    } else if (latestMACD != null && latestMACD.macdLine > latestMACD.signalLine) {
      macdAnalysis.add("Bullish trend: MACD line is above signal line, indicating bullish momentum (weak buy signal).");
    } else if (latestMACD != null && latestMACD.macdLine < latestMACD.signalLine) {
      macdAnalysis.add("Bearish trend: MACD line is below signal line, indicating bearish momentum (weak sell signal).");
    }

    if (isTrendingUp) {
      macdAnalysis.add("Sustained bullish momentum: MACD line has been rising for the last three periods.");
    } else if (isTrendingDown) {
      macdAnalysis.add("Sustained bearish momentum: MACD line has been declining for the last three periods.");
    }

    if (latestMACD != null && latestMACD.histogram.abs() > 0.5) {
      macdAnalysis.add("Strong momentum: Histogram shows a large value (${_formatNumber(latestMACD.histogram)}), indicating a strong trend.");
    } else if (latestMACD != null) {
      macdAnalysis.add("Moderate momentum: Histogram shows a small value (${_formatNumber(latestMACD.histogram)}), indicating a non-strong trend.");
    }

    final minY = macdHistory.isNotEmpty
        ? [
            macdHistory.map((p) => p.macdLine).reduce((a, b) => a < b ? a : b),
            macdHistory.map((p) => p.signalLine).reduce((a, b) => a < b ? a : b),
            macdHistory.map((p) => p.histogram).reduce((a, b) => a < b ? a : b),
            0.0
          ].reduce((a, b) => a < b ? a : b) * 1.1
        : -1.0;
    final maxY = macdHistory.isNotEmpty
        ? [
            macdHistory.map((p) => p.macdLine).reduce((a, b) => a > b ? a : b),
            macdHistory.map((p) => p.signalLine).reduce((a, b) => a > b ? a : b),
            macdHistory.map((p) => p.histogram).reduce((a, b) => a > b ? a : b),
            0.0
          ].reduce((a, b) => a > b ? a : b) * 1.1
        : 1.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MACD Indicator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : macdHistory.isEmpty
                      ? const Center(child: Text('Failed to load MACD: Insufficient data'))
                      : Stack(
                          children: [
                            BarChart(
                              BarChartData(
                                barGroups: macdHistory.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final point = entry.value;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: point.histogram,
                                        fromY: 0,
                                        color: point.histogram > 0
                                            // ignore: deprecated_member_use
                                            ? Colors.green.withOpacity(0.5)
                                            // ignore: deprecated_member_use
                                            : Colors.red.withOpacity(0.5),
                                        width: 1.0,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ],
                                  );
                                }).toList(),
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                alignment: BarChartAlignment.spaceBetween,
                                barTouchData: BarTouchData(enabled: false),
                                minY: minY,
                                maxY: maxY,
                              ),
                            ),
                            LineChart(
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
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: macdHistory
                                        .map((p) => FlSpot(p.index.toDouble(), p.macdLine))
                                        .toList(),
                                    isCurved: false,
                                    color: Colors.blue,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: macdHistory
                                        .map((p) => FlSpot(p.index.toDouble(), p.signalLine))
                                        .toList(),
                                    isCurved: false,
                                    color: Colors.yellow,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: 0,
                                      color: Colors.grey,
                                      strokeWidth: 1,
                                      dashArray: const [5, 5],
                                    ),
                                  ],
                                ),
                                minY: minY,
                                maxY: maxY,
                              ),
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("MACD Line", Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem("Signal Line", Colors.yellow),
                const SizedBox(width: 16),
                _buildLegendItem("Histogram", Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Detailed MACD Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            if (macdAnalysis.isEmpty)
              const Text(
                'Insufficient data for MACD analysis.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              )
            else
              ...macdAnalysis.map((analysis) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            analysis,
                            style: TextStyle(
                              fontSize: 14,
                              color: analysis.contains("Buy")
                                  ? Colors.green
                                  : analysis.contains("Sell")
                                      ? Colors.red
                                      : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            if (latestMACD != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildIndicatorValue("MACD Line", latestMACD.macdLine, Colors.blue),
                  _buildIndicatorValue("Signal Line", latestMACD.signalLine, Colors.yellow),
                  _buildIndicatorValue(
                    "Histogram",
                    latestMACD.histogram,
                    latestMACD.histogram > 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIndicatorValue(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          _formatNumber(value),
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Price',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(widget.stock.currentPrice),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '${widget.stock.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.stock.changePercent >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Moving Average (14-day)',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(widget.stock.sma),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relative Strength Index (RSI)',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  widget.stock.rsi.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getRsiColor(widget.stock.rsi),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Support',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(
                      fallbackSupport > 0 ? fallbackSupport : widget.stock.support),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resistance',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(
                      fallbackResistance > 0 ? fallbackResistance : widget.stock.resistance),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsSection() {
    final conditions = widget.stock.conditions;
    if (conditions.isEmpty) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Met Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            ...conditions.map((condition) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        condition.contains("Buy")
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: condition.contains("Buy")
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          condition,
                          style: TextStyle(
                            fontSize: 16,
                            color: condition.contains("Buy")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            ...widget.stock.analysis.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                            color: item.contains("Buy")
                                ? Colors.green
                                : item.contains("Sell")
                                    ? Colors.red
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingStrategySection() {
    if (widget.stock.entryPrice == null ||
        widget.stock.stopLoss == null ||
        widget.stock.takeProfit == null) {
      return Container();
    }

    // تحديد نوع الصفقة بناءً على التوصية
    bool isBuySignal = widget.stock.recommendation.contains('🟢');
    bool isSellSignal = widget.stock.recommendation.contains('🔴');

    // التحقق من الأسعار
    double entryPrice = widget.stock.entryPrice!;
    double currentPrice = widget.stock.currentPrice;
    double stopLoss = widget.stock.stopLoss!;
    double takeProfit = widget.stock.takeProfit!;

    // تعديل الأسعار بناءً على نوع الصفقة
    if (isBuySignal) {
      // صفقة شراء: وقف الخسارة أقل من سعر الدخول والسعر الحالي
      // جني الأرباح أعلى من سعر الدخول والسعر الحالي
      stopLoss = (entryPrice < currentPrice ? entryPrice : currentPrice) * 0.98; // 2% أقل من الأدنى
      takeProfit = (entryPrice > currentPrice ? entryPrice : currentPrice) * 1.03; // 3% أعلى من الأعلى
    } else if (isSellSignal) {
      // صفقة بيع: وقف الخسارة أعلى من سعر الدخول والسعر الحالي
      // جني الأرباح أقل من سعر الدخول والسعر الحالي
      stopLoss = (entryPrice > currentPrice ? entryPrice : currentPrice) * 1.02; // 2% أعلى من الأعلى
      takeProfit = (entryPrice < currentPrice ? entryPrice : currentPrice) * 0.97; // 3% أقل من الأدنى
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested Trading Strategy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entry Price',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(entryPrice),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stop Loss',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(stopLoss),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Take Profit',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(takeProfit),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRsiColor(double rsi) {
    if (rsi > 70) return Colors.red;
    if (rsi < 30) return Colors.green;
    return Colors.black;
  }

  Color _getRecommendationColor(String recommendation) {
    if (recommendation.contains('🟢')) return Colors.green;
    if (recommendation.contains('🔴')) return Colors.red;
    return Colors.blue;
  }

  String _formatNumber(double num) {
    return num.toStringAsFixed(2); // Stock prices typically use 2 decimal places
  }
}