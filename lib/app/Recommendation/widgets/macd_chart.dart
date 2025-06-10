import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MACDData {
  final double macdLine;
  final double signalLine;
  final double histogram;
  final int index;

  MACDData({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
    required this.index,
  });
}

class MACDChart extends StatelessWidget {
  final List<MACDData> macdHistory;
  final bool isLoading;
  final String title;
  final String? subtitle;
  final Function(double) formatNumber;

  const MACDChart({
    super.key,
    required this.macdHistory,
    required this.isLoading,
    this.title = 'MACD Indicator (6 Months)',
    this.subtitle,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    // Detect crossovers for buy and sell signals
    List<int> buySignals = [];
    List<int> sellSignals = [];
    List<String> signalAnalysis = [];

    // Start from 35 because we need 26 points for EMA26 and 9 for Signal Line
    for (int i = 35; i < macdHistory.length; i++) {
      final current = macdHistory[i];
      final previous = macdHistory[i - 1];

      // Strong Buy Signal: MACD crosses above Signal Line with positive histogram
      if (previous.macdLine <= previous.signalLine &&
          current.macdLine > current.signalLine &&
          current.histogram > 0) {
        buySignals.add(i);
        signalAnalysis.add(
          'Strong Buy Signal: MACD crossed above Signal Line with positive momentum',
        );
      }
      // Strong Sell Signal: MACD crosses below Signal Line with negative histogram
      else if (previous.macdLine >= previous.signalLine &&
          current.macdLine < current.signalLine &&
          current.histogram < 0) {
        sellSignals.add(i);
        signalAnalysis.add(
          'Strong Sell Signal: MACD crossed below Signal Line with negative momentum',
        );
      }
    }

    // Get the latest MACD analysis
    String latestAnalysis = '';
    if (macdHistory.isNotEmpty) {
      final latest = macdHistory.last;
      final previous =
          macdHistory.length > 1 ? macdHistory[macdHistory.length - 2] : latest;

      // Determine current position and trend
      bool isAboveSignalLine = latest.macdLine > latest.signalLine;
      bool isPositiveHistogram = latest.histogram > 0;
      bool isRecentCrossover = false;
      String crossoverType = '';

      // Check for recent crossover
      if (previous.macdLine <= previous.signalLine &&
          latest.macdLine > latest.signalLine) {
        isRecentCrossover = true;
        crossoverType = 'Buy';
      } else if (previous.macdLine >= previous.signalLine &&
          latest.macdLine < latest.signalLine) {
        isRecentCrossover = true;
        crossoverType = 'Sell';
      }

      // Generate analysis based on current position and recent crossover
      if (isRecentCrossover) {
        if (crossoverType == 'Buy' && isPositiveHistogram) {
          latestAnalysis =
              'Strong Buy Signal: MACD just crossed above Signal Line with positive momentum';
        } else if (crossoverType == 'Sell' && !isPositiveHistogram) {
          latestAnalysis =
              'Strong Sell Signal: MACD just crossed below Signal Line with negative momentum';
        } else if (crossoverType == 'Buy') {
          latestAnalysis = 'Buy Signal: MACD just crossed above Signal Line';
        } else {
          latestAnalysis = 'Sell Signal: MACD just crossed below Signal Line';
        }
      } else {
        // No recent crossover, analyze current position
        if (isAboveSignalLine) {
          if (isPositiveHistogram) {
            latestAnalysis =
                'Bullish: MACD above Signal Line with positive momentum';
          } else {
            latestAnalysis =
                'Bullish: MACD above Signal Line but momentum decreasing';
          }
        } else {
          if (!isPositiveHistogram) {
            latestAnalysis =
                'Bearish: MACD below Signal Line with negative momentum';
          } else {
            latestAnalysis =
                'Bearish: MACD below Signal Line but momentum decreasing';
          }
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 10),
            // MACD Line Chart
            SizedBox(
              height: 100,
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : macdHistory.isEmpty
                      ? const Center(
                        child: Text('Failed to load MACD: Insufficient data'),
                      )
                      : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      formatNumber(value),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
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
                              spots:
                                  macdHistory
                                      .map(
                                        (p) => FlSpot(
                                          p.index.toDouble(),
                                          p.macdLine,
                                        ),
                                      )
                                      .toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  if (buySignals.contains(index)) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.green,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  } else if (sellSignals.contains(index)) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.red,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  }
                                  return FlDotCirclePainter(radius: 0);
                                },
                              ),
                            ),
                            LineChartBarData(
                              spots:
                                  macdHistory
                                      .map(
                                        (p) => FlSpot(
                                          p.index.toDouble(),
                                          p.signalLine,
                                        ),
                                      )
                                      .toList(),
                              isCurved: true,
                              color: Colors.orange,
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
                          minY:
                              macdHistory.isNotEmpty
                                  ? macdHistory
                                          .map(
                                            (p) => [
                                              p.macdLine,
                                              p.signalLine,
                                            ].reduce((a, b) => a < b ? a : b),
                                          )
                                          .reduce((a, b) => a < b ? a : b) *
                                      1.1
                                  : -1,
                          maxY:
                              macdHistory.isNotEmpty
                                  ? macdHistory
                                          .map(
                                            (p) => [
                                              p.macdLine,
                                              p.signalLine,
                                            ].reduce((a, b) => a > b ? a : b),
                                          )
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.1
                                  : 1,
                        ),
                      ),
            ),
            const SizedBox(height: 10),
            // MACD Histogram
            SizedBox(
              height: 100,
              child:
                  macdHistory.isEmpty
                      ? const Center(child: Text('No histogram data available'))
                      : BarChart(
                        BarChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      formatNumber(value),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
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
                          barGroups:
                              macdHistory
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.histogram,
                                          color:
                                              e.value.histogram >= 0
                                                  // ignore: deprecated_member_use
                                                  ? Colors.green.withOpacity(
                                                    0.7,
                                                  )
                                                  // ignore: deprecated_member_use
                                                  : Colors.red.withOpacity(0.7),
                                          width: 4,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(2),
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                          minY:
                              macdHistory.isNotEmpty
                                  ? macdHistory
                                          .map((p) => p.histogram)
                                          .reduce((a, b) => a < b ? a : b) *
                                      1.1
                                  : -1,
                          maxY:
                              macdHistory.isNotEmpty
                                  ? macdHistory
                                          .map((p) => p.histogram)
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.1
                                  : 1,
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            // MACD Analysis
            if (latestAnalysis.isNotEmpty) ...[
              Text(
                'Current MACD Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                latestAnalysis,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      latestAnalysis.contains('Bullish')
                          ? Colors.green
                          : Colors.red,
                ),
              ),
            ],
            if (signalAnalysis.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent Signals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              ...signalAnalysis.reversed
                  .take(3)
                  .map(
                    (analysis) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            analysis.contains('Buy') ||
                                    analysis.contains('Bullish')
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color:
                                analysis.contains('Buy') ||
                                        analysis.contains('Bullish')
                                    ? Colors.green
                                    : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              analysis,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    analysis.contains('Buy') ||
                                            analysis.contains('Bullish')
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
