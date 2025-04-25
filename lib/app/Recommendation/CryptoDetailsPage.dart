import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:graduationproject/app/Recommendation/CryptoRecommendation.dart';

class CryptoPricePoint {
  final DateTime date;
  final double price;

  CryptoPricePoint({required this.date, required this.price});
}

class CryptoMACDPoint {
  final int index;
  final double macdLine;
  final double signalLine;
  final double histogram;

  CryptoMACDPoint({
    required this.index,
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

class CryptoDetailsPage extends StatefulWidget {
  final CryptoRecommendation crypto;

  const CryptoDetailsPage({super.key, required this.crypto});

  @override
  _CryptoDetailsPageState createState() => _CryptoDetailsPageState();
}

class _CryptoDetailsPageState extends State<CryptoDetailsPage> {
  List<CryptoPricePoint> priceHistory = [];
  List<CryptoMACDPoint> macdHistory = [];
  bool isLoading = true;
  double fallbackSupport = 0;

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
      String symbol = widget.crypto.symbol;
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

        final List<CryptoPricePoint> points = [];
        final List<double> validCloses = [];
        final List<double> validLows = [];

        // Collect valid data
        for (int i = 0; i < timestamps.length; i++) {
          if (closes[i] != null && lows[i] != null) {
            points.add(CryptoPricePoint(
              date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
              price: closes[i].toDouble(),
            ));
            validCloses.add(closes[i].toDouble());
            validLows.add(lows[i].toDouble());
          }
        }

        // Ensure enough data for MACD
        if (validCloses.length < 26) {
          print('Not enough data for MACD: ${validCloses.length} points');
          setState(() {
            priceHistory = points;
            macdHistory = [];
            fallbackSupport = validLows.isNotEmpty
                ? validLows.reduce((a, b) => a < b ? a : b)
                : widget.crypto.support;
            isLoading = false;
          });
          return;
        }

        // Calculate MACD
        final macdData = _calculateMACD(validCloses);
        final macdPoints = <CryptoMACDPoint>[];
        final macdLine = macdData['macdLine']!;
        final signalLine = macdData['signalLine']!;
        for (int i = 0; i < macdLine.length && i < signalLine.length; i++) {
          macdPoints.add(CryptoMACDPoint(
            index: i,
            macdLine: macdLine[i],
            signalLine: signalLine[i],
            histogram: macdLine[i] - signalLine[i],
          ));
        }

        setState(() {
          priceHistory = points;
          macdHistory = macdPoints;
          fallbackSupport = validLows.isNotEmpty
              ? validLows.reduce((a, b) => a < b ? a : b)
              : widget.crypto.support;
          isLoading = false;
        });
      } else {
        print('Failed to fetch price history: ${response.statusCode}');
        throw Exception('Failed to load price history');
      }
    } catch (e) {
      print('Error loading price history: $e');
      setState(() {
        isLoading = false;
        priceHistory = [];
        macdHistory = [];
        fallbackSupport = widget.crypto.support;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
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
        title: Text(widget.crypto.title),
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
        const Icon(
          Icons.currency_bitcoin,
          size: 40,
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.crypto.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.crypto.subtitle,
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
    return Card(
      color: widget.crypto.recommendationColor.withOpacity(0.1),
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
              'التوصية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.crypto.recommendation,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.crypto.recommendationColor,
              ),
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
              'سجل الأسعار',
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
                      ? const Center(child: Text('لا توجد بيانات أسعار متاحة'))
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
                                      '\$${value.toStringAsFixed(2)}',
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
                                    .map((e) =>
                                        FlSpot(e.key.toDouble(), e.value.price))
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
                                      labelResolver: (line) =>
                                          'الدعم: \$${line.y.toStringAsFixed(2)}',
                                    ),
                                  ),
                                if (widget.crypto.resistance > 0)
                                  HorizontalLine(
                                    y: widget.crypto.resistance,
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
                                      labelResolver: (line) =>
                                          'المقاومة: \$${line.y.toStringAsFixed(2)}',
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
                                    .reduce((a, b) => a < b ? a : b) *
                                0.95
                                : 0,
                            maxY: priceHistory.isNotEmpty
                                ? ([priceHistory
                                            .map((p) => p.price)
                                            .reduce((a, b) => a > b ? a : b),
                                        widget.crypto.resistance > 0
                                            ? widget.crypto.resistance
                                            : double.negativeInfinity]
                                      ..removeWhere(
                                          (e) => e == double.negativeInfinity))
                                    .reduce((a, b) => a > b ? a : b) *
                                1.05
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
              'مؤشر MACD',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : macdHistory.isEmpty
                      ? const Center(
                          child: Text('فشل تحميل MACD: بيانات غير كافية'))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toStringAsFixed(2),
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
                                    .map((p) =>
                                        FlSpot(p.index.toDouble(), p.macdLine))
                                    .toList(),
                                isCurved: false,
                                color: Colors.blue,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: macdHistory
                                    .map((p) => FlSpot(
                                        p.index.toDouble(), p.signalLine))
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
                                  dashArray: [5, 5],
                                ),
                              ],
                            ),
                            minY: macdHistory.isNotEmpty
                                ? macdHistory
                                    .map((p) => [p.macdLine, p.signalLine]
                                        .reduce((a, b) => a < b ? a : b))
                                    .reduce((a, b) => a < b ? a : b) *
                                1.1
                                : -1,
                            maxY: macdHistory.isNotEmpty
                                ? macdHistory
                                    .map((p) => [p.macdLine, p.signalLine]
                                        .reduce((a, b) => a > b ? a : b))
                                    .reduce((a, b) => a > b ? a : b) *
                                1.1
                                : 1,
                          ),
                        ),
            ),
          ],
        ),
      ),
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
                  'السعر الحالي',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(widget.crypto.currentPrice)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التغير',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '${widget.crypto.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.crypto.changePercent >= 0
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
                  'المتوسط المتحرك (14 يوم)',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(widget.crypto.sma)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مؤشر القوة النسبية (RSI)',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  widget.crypto.rsi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getRsiColor(widget.crypto.rsi),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حجم التداول الأخير',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(widget.crypto.lastVolume.toDouble()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'متوسط الحجم',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _formatNumber(widget.crypto.avgVolume.toDouble()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الدعم',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(fallbackSupport > 0 ? fallbackSupport : widget.crypto.support)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المقاومة',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(widget.crypto.resistance)}',
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
              'الشروط المحققة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            ...widget.crypto.conditions.map((condition) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        condition.contains("شراء")
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: condition.contains("شراء")
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
                            color: condition.contains("شراء")
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
              'تحليل مفصل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            ...widget.crypto.analysis.map((item) => Padding(
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
                            color: item.contains("شراء")
                                ? Colors.green
                                : item.contains("بيع")
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
    if (widget.crypto.entryPrice == null ||
        widget.crypto.stopLoss == null ||
        widget.crypto.takeProfit == null) {
      return Container();
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
              'إستراتيجية التداول المقترحة',
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
                  'سعر الدخول',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(widget.crypto.entryPrice!)}',
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
                  'وقف الخسارة',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(widget.crypto.stopLoss!)}',
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
                  'جني الأرباح',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '\$${_formatNumber(widget.crypto.takeProfit!)}',
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

  String _formatNumber(double num) {
    String formatted = num.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return parts.length > 1 ? '$integerPart.${parts[1]}' : integerPart;
  }
}