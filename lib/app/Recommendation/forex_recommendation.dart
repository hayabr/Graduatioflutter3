import 'package:flutter/material.dart';
import 'package:graduationproject/app/Recommendation/commodities_recommendation.dart';
import 'package:graduationproject/app/Recommendation/crypto_recommendation.dart';
import 'package:graduationproject/app/Recommendation/forex_detail_page.dart';
import 'package:graduationproject/app/Recommendation/recommendations.dart';
import 'package:graduationproject/widgets/bottom_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Adding a class to store MACD points (similar to ForexDetailsPage)
class ForexMACDPoint {
  final int index;
  final double macdLine;
  final double signalLine;
  final double histogram;

  ForexMACDPoint({
    required this.index,
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

class ForexRecommendation {
  final String symbol;
  final String title;
  final String subtitle;
  final double currentPrice;
  final double firstPrice;
  final double sma;
  final double rsi;
  final int lastVolume;
  final int avgVolume;
  final double support;
  final double resistance;
  final double changePercent;
  final double? entryPrice;
  final double? stopLoss;
  final double? takeProfit;
  final String recommendation;
  final Color recommendationColor;
  final List<String> analysis;
  final List<String> conditions;
  final int buySignals;
  final int sellSignals;

  ForexRecommendation({
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.currentPrice,
    required this.firstPrice,
    required this.sma,
    required this.rsi,
    required this.lastVolume,
    required this.avgVolume,
    required this.support,
    required this.resistance,
    required this.changePercent,
    this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    required this.recommendation,
    required this.recommendationColor,
    required this.analysis,
    required this.conditions,
    required this.buySignals,
    required this.sellSignals,
  });
}

class MarketCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  MarketCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class ForexRecommendationPage extends StatefulWidget {
  const ForexRecommendationPage({super.key});

  @override
  ForexRecommendationPageState createState() => ForexRecommendationPageState();
}

class ForexRecommendationPageState extends State<ForexRecommendationPage> with RouteAware {
  int _selectedIndex = 3;
  int _selectedMarket = 2;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  bool _loadingForex = false;
  List<ForexRecommendation> forexRecommendations = [];

  final List<MarketCategory> marketCategories = [
    MarketCategory(
      name: 'Stocks',
      icon: Icons.bar_chart,
      color: Colors.blue,
      description: 'Tech, Finance, Healthcare sectors',
    ),
    MarketCategory(
      name: 'Commodities',
      icon: Icons.shopping_basket,
      color: Colors.amber,
      description: 'Gold, Oil, Silver, Agricultural',
    ),
    MarketCategory(
      name: 'Forex',
      icon: Icons.currency_exchange,
      color: Colors.green,
      description: 'Currency pairs and exchange rates',
    ),
    MarketCategory(
      name: 'Crypto',
      icon: Icons.currency_bitcoin,
      color: Colors.orange,
      description: 'Bitcoin, Ethereum, Altcoins',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchForexData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _selectedMarket = 2;
    });
  }

  Future<void> _fetchForexData() async {
    setState(() {
      _loadingForex = true;
    });

    final pairs = [
      {"symbol": "EURUSD=X", "name": "EUR/USD"},
      {"symbol": "GBPUSD=X", "name": "GBP/USD"},
      {"symbol": "USDJPY=X", "name": "USD/JPY"},
      {"symbol": "AUDUSD=X", "name": "AUD/USD"},
      {"symbol": "USDCAD=X", "name": "USD/CAD"},
      {"symbol": "USDCHF=X", "name": "USD/CHF"},
      {"symbol": "NZDUSD=X", "name": "NZD/USD"},
    ];
    List<ForexRecommendation> tempRecommendations = [];

    for (var pair in pairs) {
      try {
        final data = await _fetchForexDataForPair(pair["symbol"]!);
        if (data != null) {
          final recommendation = _generateForexRecommendation(
            pair["symbol"]!,
            pair["name"]!,
            data,
          );
          tempRecommendations.add(recommendation);
        }
      } catch (e) {
        debugPrint('Error fetching data for ${pair["symbol"]}: $e');
      }
      await Future.delayed(Duration(milliseconds: 500)); // Avoid rate limiting
    }

    setState(() {
      forexRecommendations = tempRecommendations;
      _loadingForex = false;
    });
  }

  Future<Map<String, dynamic>?> _fetchForexDataForPair(String pair) async {
    final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$pair?interval=1d&range=2mo');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['chart']['result'] != null) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error fetching data for $pair: $e');
    }
    return null;
  }

  List<double> _extractList(dynamic list) {
    return List<double>.from(
        list.where((e) => e != null).map((e) => (e as num).toDouble()));
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

  double _calculateRSI(List<double> prices, int period) {
    List<double> gains = [], losses = [];
    for (int i = 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    double avgGain = gains.sublist(0, period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.sublist(0, period).reduce((a, b) => a + b) / period;
    double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
    double rsi = 100 - (100 / (1 + rs));

    for (int i = period; i < gains.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i]) / period;
      rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      rsi = 100 - (100 / (1 + rs));
    }

    return rsi;
  }

  // Modified MACD calculation to include full history for charting
  List<ForexMACDPoint> _calculateMACDHistory(List<double> prices) {
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

    List<ForexMACDPoint> macdPoints = [];
    for (int i = 0; i < macdLine.length && i < signalLine.length; i++) {
      macdPoints.add(ForexMACDPoint(
        index: i,
        macdLine: macdLine[i],
        signalLine: signalLine[i],
        histogram: macdLine[i] - signalLine[i],
      ));
    }

    return macdPoints;
  }

  double _calculateATR(List<double> highs, List<double> lows, List<double> closes) {
    List<double> tr = [];
    for (int i = 1; i < highs.length; i++) {
      double highLow = (highs[i] - lows[i]).abs();
      double highClose = (highs[i] - closes[i - 1]).abs();
      double lowClose = (lows[i] - closes[i - 1]).abs();
      tr.add([highLow, highClose, lowClose].reduce((a, b) => a > b ? a : b));
    }
    return tr.isEmpty ? 0 : tr.reduce((a, b) => a + b) / tr.length;
  }

  ForexRecommendation _generateForexRecommendation(
      String symbol, String name, Map<String, dynamic> data) {
    final result = data['chart']['result'][0];
    final meta = result['meta'];
    final quote = result['indicators']['quote'][0];

    final closes = _extractList(quote['close']);
    final volumes = _extractList(quote['volume']);
    final highs = _extractList(quote['high']);
    final lows = _extractList(quote['low']);

    if (closes.length < 26 || highs.length < 15 || lows.length < 15) {
      return ForexRecommendation(
        symbol: symbol,
        title: name,
        subtitle: 'No data available',
        currentPrice: 0,
        firstPrice: 0,
        sma: 0,
        rsi: 0,
        lastVolume: 0,
        avgVolume: 0,
        support: 0,
        resistance: 0,
        changePercent: 0,
        recommendation: "⚠️ Insufficient data",
        recommendationColor: Colors.grey,
        analysis: ["⚠️ Insufficient data to analyze the pair"],
        conditions: [],
        buySignals: 0,
        sellSignals: 0,
      );
    }

    final lastClose = closes.last;
    final firstClose = closes.first;
    final lastVolume = volumes.isNotEmpty ? volumes.last : 0;
    final avgVolume = volumes.isNotEmpty
        ? volumes.reduce((a, b) => a + b) / volumes.length
        : 0;
    final sma = _calculateSMA(closes, 14);
    final lastSMA = sma.isNotEmpty ? sma.last : lastClose;
    final rsi = _calculateRSI(closes, 14);
    final percentChange = ((lastClose - firstClose) / firstClose) * 100;

    // Improved support and resistance calculation
    List<double> supports = lows
        .where((low) => lows.where((l) => l <= low * 1.01 && l >= low * 0.99).length >= 3)
        .toList();
    List<double> resistances = highs
        .where((high) => highs.where((h) => h <= high * 1.01 && h >= high * 0.99).length >= 3)
        .toList();
    final support = supports.isNotEmpty
        ? supports.reduce((a, b) => a < b ? a : b)
        : lows.reduce((a, b) => a < b ? a : b);
    final resistance = resistances.isNotEmpty
        ? resistances.reduce((a, b) => a > b ? a : b)
        : highs.reduce((a, b) => a > b ? a : b);

    // Calculate ATR for threshold customization
    final atr = _calculateATR(highs, lows, closes);
    final smaThreshold = atr > 0 ? 0.05 * (atr / lastClose) : 0.005;
    final percentChangeThreshold = atr > 0 ? 0.05 * (atr / lastClose) * 100 : 0.5;

    // Calculate MACD using full history
    final macdHistory = _calculateMACDHistory(closes);
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

    // Detailed MACD analysis (similar to ForexDetailsPage)
    List<String> macdAnalysis = [];
    String macdCondition = "Weak Sell - MACD indicates bearish tendency"; // Default value
    if (isCrossOver) {
      if (isBullish) {
        macdAnalysis.add("Strong bullish crossover: MACD line crossed above signal line with positive histogram (strong buy signal).");
        macdCondition = "Strong Buy - Bullish MACD crossover with positive histogram";
      } else {
        macdAnalysis.add("Strong bearish crossover: MACD line crossed below signal line with negative histogram (strong sell signal).");
        macdCondition = "Strong Sell - Bearish MACD crossover with negative histogram";
      }
    } else if (latestMACD != null && latestMACD.macdLine > latestMACD.signalLine) {
      macdAnalysis.add("Bullish trend: MACD line is above signal line, indicating bullish momentum (weak buy signal).");
      macdCondition = "Weak Buy - MACD indicates bullish tendency";
    } else if (latestMACD != null && latestMACD.macdLine < latestMACD.signalLine) {
      macdAnalysis.add("Bearish trend: MACD line is below signal line, indicating bearish momentum (weak sell signal).");
      macdCondition = "Weak Sell - MACD indicates bearish tendency";
    }

    if (isTrendingUp) {
      macdAnalysis.add("Sustained bullish momentum: MACD line has been rising for the last three periods.");
    } else if (isTrendingDown) {
      macdAnalysis.add("Sustained bearish momentum: MACD line has been declining for the last three periods.");
    }

    if (latestMACD != null && latestMACD.histogram.abs() > 0.5) {
      macdAnalysis.add("Strong momentum: Histogram shows a large value (${latestMACD.histogram.toStringAsFixed(4)}), indicating a strong trend.");
    } else if (latestMACD != null) {
      macdAnalysis.add("Moderate momentum: Histogram shows a small value (${latestMACD.histogram.toStringAsFixed(4)}), indicating a non-strong trend.");
    }

    // Define the six conditions with updated MACD condition
    final conditions = [
      // 1. Moving Average
      lastClose < lastSMA * (1 - smaThreshold)
          ? "Strong Buy - Price is below moving average by ${((smaThreshold * 100).toStringAsFixed(2))}%"
          : lastClose < lastSMA
              ? "Weak Buy - Price is slightly below moving average"
              : lastClose > lastSMA * (1 + smaThreshold)
                  ? "Strong Sell - Price is above moving average by ${((smaThreshold * 100).toStringAsFixed(2))}%"
                  : "Weak Sell - Price is slightly above moving average",

      // 2. RSI
      rsi < 30
          ? "Strong Buy - RSI in oversold territory (<30)"
          : rsi < 50
              ? "Weak Buy - RSI indicates buying tendency"
              : rsi > 70
                  ? "Strong Sell - RSI in overbought territory (>70)"
                  : "Weak Sell - RSI indicates selling tendency",

      // 3. Trading Volume
      lastVolume > avgVolume * 1.3 && lastClose > lastSMA
          ? "Strong Buy - High trading volume with upward movement"
          : lastVolume > avgVolume && lastClose > lastSMA
              ? "Weak Buy - Slightly high trading volume with upward movement"
              : lastVolume > avgVolume * 1.3 && lastClose < lastSMA
                  ? "Strong Sell - High trading volume with downward movement"
                  : lastVolume > avgVolume && lastClose < lastSMA
                      ? "Weak Sell - Slightly high trading volume with downward movement"
                      : lastClose > lastSMA
                          ? "Weak Buy - Price rising without strong volume"
                          : "Weak Sell - Price falling without strong volume",

      // 4. Price Change
      percentChange < -percentChangeThreshold
          ? "Strong Buy - Strong decline (>${percentChangeThreshold.toStringAsFixed(2)}%)"
          : percentChange < 0
              ? "Weak Buy - Slight decline"
              : percentChange > percentChangeThreshold
                  ? "Strong Sell - Strong rise (>${percentChangeThreshold.toStringAsFixed(2)}%)"
                  : "Weak Sell - Slight rise",

      // 5. Support and Resistance
      lastClose <= support * 1.002
          ? "Strong Buy - Price is near support level"
          : lastClose < (support + resistance) / 2
              ? "Weak Buy - Price is closer to support"
              : lastClose >= resistance * 0.998
                  ? "Strong Sell - Price is near resistance level"
                  : "Weak Sell - Price is closer to resistance",

      // 6. MACD (updated based on detailed analysis)
      macdCondition,
    ];

    final buySignals = conditions.where((c) => c.contains("Buy")).length;
    final sellSignals = conditions.where((c) => c.contains("Sell")).length;
    final strongBuySignals = conditions.where((c) => c.contains("Strong Buy")).length;
    final strongSellSignals = conditions.where((c) => c.contains("Strong Sell")).length;

    String recommendation;
    Color recommendationColor;
    double? entryPrice, stopLoss, takeProfit;

    // Modified recommendation system
    if (buySignals > sellSignals) {
      recommendation = "🟢 Buy";
      recommendationColor = Colors.green;
      // Entry price for buy: midpoint between current price and support
      entryPrice = (lastClose + support) / 2;
      if (entryPrice >= lastClose) {
        entryPrice = lastClose * 0.995; // Ensure entry price is below current price
      }
      stopLoss = entryPrice * 0.995; // Stop loss 0.5% below
      takeProfit = entryPrice * 1.015; // Take profit 1.5% above
    } else if (sellSignals > buySignals) {
      recommendation = "🔴 Sell";
      recommendationColor = Colors.red;
      // Entry price for sell: midpoint between current price and resistance
      entryPrice = (lastClose + resistance) / 2;
      if (entryPrice <= lastClose) {
        entryPrice = lastClose * 1.005; // Ensure entry price is above current price
      }
      stopLoss = entryPrice * 1.005; // Stop loss 0.5% above
      takeProfit = entryPrice * 0.985; // Take profit 1.5% below
    } else {
      // If general signals are equal, compare strong signals
      if (strongBuySignals > strongSellSignals) {
        recommendation = "🟢 Buy";
        recommendationColor = Colors.green;
        // Entry price for buy: midpoint between current price and support
        entryPrice = (lastClose + support) / 2;
        if (entryPrice >= lastClose) {
          entryPrice = lastClose * 0.995; // Ensure entry price is below current price
        }
        stopLoss = entryPrice * 0.995; // Stop loss 0.5% below
        takeProfit = entryPrice * 1.015; // Take profit 1.5% above
      } else if (strongSellSignals > strongBuySignals) {
        recommendation = "🔴 Sell";
        recommendationColor = Colors.red;
        // Entry price for sell: midpoint between current price and resistance
        entryPrice = (lastClose + resistance) / 2;
        if (entryPrice <= lastClose) {
          entryPrice = lastClose * 1.005; // Ensure entry price is above current price
        }
        stopLoss = entryPrice * 1.005; // Stop loss 0.5% above
        takeProfit = entryPrice * 0.985; // Take profit 1.5% below
      } else {
        // If strong signals are equal, choose based on general signals
        recommendation = buySignals >= sellSignals ? "🟢 Buy" : "🔴 Sell";
        recommendationColor = buySignals >= sellSignals ? Colors.green : Colors.red;
        if (buySignals >= sellSignals) {
          entryPrice = (lastClose + support) / 2;
          if (entryPrice >= lastClose) {
            entryPrice = lastClose * 0.995;
          }
          stopLoss = entryPrice * 0.995;
          takeProfit = entryPrice * 1.015;
        } else {
          entryPrice = (lastClose + resistance) / 2;
          if (entryPrice <= lastClose) {
            entryPrice = lastClose * 1.005;
          }
          stopLoss = entryPrice * 1.005;
          takeProfit = entryPrice * 0.985;
        }
      }
    }

    final analysis = [
      if (lastClose > lastSMA * (1 + smaThreshold))
        "• Price is above moving average by ${((smaThreshold * 100).toStringAsFixed(2))}% (strong sell signal)"
      else if (lastClose > lastSMA)
        "• Price is slightly above moving average (weak sell signal)"
      else if (lastClose < lastSMA * (1 - smaThreshold))
        "• Price is below moving average by ${((smaThreshold * 100).toStringAsFixed(2))}% (strong buy signal)"
      else
        "• Price is slightly below moving average (weak buy signal)",
      if (rsi > 70)
        "• RSI in overbought territory (overbought)"
      else if (rsi > 50)
        "• RSI indicates selling tendency"
      else if (rsi < 30)
        "• RSI in oversold territory (oversold)"
      else
        "• RSI indicates buying tendency",
      if (percentChange > percentChangeThreshold)
        "• Strong bullish trend (↑ ${percentChange.toStringAsFixed(2)}%)"
      else if (percentChange > 0)
        "• Slight bullish trend (↑ ${percentChange.toStringAsFixed(2)}%)"
      else if (percentChange < -percentChangeThreshold)
        "• Strong bearish trend (↓ ${percentChange.abs().toStringAsFixed(2)}%)"
      else
        "• Slight bearish trend (↓ ${percentChange.abs().toStringAsFixed(2)}%)",
      if (lastVolume > avgVolume * 1.3)
        "• Trading volume 30% above average (significant activity)"
      else if (lastVolume < avgVolume * 0.7)
        "• Trading volume 30% below average (weak activity)"
      else
        "• Trading volume close to average",
      if (lastClose <= support * 1.002)
        "• Price is near support level (strong buy signal)"
      else if (lastClose < (support + resistance) / 2)
        "• Price is closer to support (weak buy signal)"
      else if (lastClose >= resistance * 0.998)
        "• Price is near resistance level (strong sell signal)"
      else
        "• Price is closer to resistance (weak sell signal)",
      // Adding detailed MACD analysis
      ...macdAnalysis,
      "• Current support level: ${support.toStringAsFixed(4)}",
      "• Current resistance level: ${resistance.toStringAsFixed(4)}",
      "• Average True Range (ATR): ${atr.toStringAsFixed(4)}",
    ];

    return ForexRecommendation(
      symbol: symbol,
      title: name,
      subtitle: meta['exchangeName'] ?? 'Forex',
      currentPrice: lastClose,
      firstPrice: firstClose,
      sma: lastSMA,
      rsi: rsi,
      lastVolume: lastVolume.toInt(),
      avgVolume: avgVolume.toInt(),
      support: support,
      resistance: resistance,
      changePercent: percentChange,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      recommendation: recommendation,
      recommendationColor: recommendationColor,
      analysis: analysis,
      conditions: conditions,
      buySignals: buySignals,
      sellSignals: sellSignals,
    );
  }

  void _navigateToMarketPage(int index) {
    setState(() {
      _selectedMarket = index;
    });

    if (index != 2) {
      final route = MaterialPageRoute(
        builder: (context) {
          switch (index) {
            case 0:
              return const StockRecommendationPage();
            case 1:
              return const CommoditiesRecommendation();
            case 3:
              return const CryptoRecommendationPage();
            default:
              return Container();
          }
        },
      );
      routeObserver.subscribe(this, route);
      Navigator.push(context, route);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Forex Recommendations',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _fetchForexData,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: marketCategories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _navigateToMarketPage(index),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: _selectedMarket == index
                          // ignore: deprecated_member_use
                          ? marketCategories[index].color.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedMarket == index
                            ? marketCategories[index].color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          marketCategories[index].icon,
                          color: marketCategories[index].color,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          marketCategories[index].name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: marketCategories[index].color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          marketCategories[index].description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _loadingForex
                ? const Center(child: CircularProgressIndicator())
                : forexRecommendations.isEmpty
                    ? const Center(
                        child: Text('Failed to fetch data. Check connection and try again.'))
                    : ListView.builder(
                        itemCount: forexRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = forexRecommendations[index];
                          return _buildRecommendationCard(
                            forex: recommendation,
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildRecommendationCard({
    required ForexRecommendation forex,
  }) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForexDetailsPage(forex: forex),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    forex.recommendation.contains('Buy')
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: forex.recommendationColor,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forex.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          forex.subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      forex.recommendation,
                      style: TextStyle(color: forex.recommendationColor),
                    ),
                    // ignore: deprecated_member_use
                    backgroundColor: forex.recommendationColor.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price: ${forex.currentPrice.toStringAsFixed(4)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Change: ${forex.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: forex.changePercent >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Average: ${forex.sma.toStringAsFixed(4)}'),
                  Text('RSI: ${forex.rsi.toStringAsFixed(1)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSignalChip('Buy Signals', forex.buySignals, Colors.green),
                  _buildSignalChip('Sell Signals', forex.sellSignals, Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Met Conditions:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Column(
                children: forex.conditions
                    .map((condition) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                condition.contains("Buy")
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: condition.contains("Strong")
                                    ? (condition.contains("Buy") ? Colors.green : Colors.red)
                                    : (condition.contains("Buy") ? Colors.green[300] : Colors.red[300]),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  condition,
                                  style: TextStyle(
                                    color: condition.contains("Strong")
                                        ? (condition.contains("Buy") ? Colors.green : Colors.red)
                                        : (condition.contains("Buy") ? Colors.green[300] : Colors.red[300]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalChip(String label, int count, Color color) {
    return Chip(
      // ignore: deprecated_member_use
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        '$label: $count',
        style: TextStyle(color: color),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        // ignore: deprecated_member_use
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}