import 'package:flutter/material.dart';
import 'package:graduationproject/app/Recommendation/CommoditiesRecommendation.dart';
import 'package:graduationproject/app/Recommendation/CryptoRecommendation.dart';
import 'package:graduationproject/app/Recommendation/commodityDetail.dart';
import 'package:graduationproject/app/Recommendation/forex_recommendation.dart';
import 'package:graduationproject/app/Recommendation/stock_detail_page.dart';
import 'package:graduationproject/widgets/BottomNavBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StockRecommendation {
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

  StockRecommendation({
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

class Recommendations extends StatefulWidget {
  const Recommendations({super.key});

  @override
  _RecommendationsState createState() => _RecommendationsState();
}

class _RecommendationsState extends State<Recommendations> with RouteAware {
  int _selectedIndex = 3;
  int _selectedMarket = 0;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  bool _loadingStocks = false;
  List<StockRecommendation> stockRecommendations = [];

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
    _fetchStockData();
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
      _selectedMarket = 0;
    });
  }

  Future<void> _fetchStockData() async {
    setState(() {
      _loadingStocks = true;
    });

    final stocks = ["AAPL", "TSLA", "MSFT", "GOOGL", "MSTR", "AMZN", "NVDA", "META", "NFLX"];
    List<StockRecommendation> tempRecommendations = [];

    for (String symbol in stocks) {
      try {
        final data = await _fetchStockDataForSymbol(symbol);
        if (data != null) {
          final recommendation = _generateStockRecommendation(symbol, data);
          tempRecommendations.add(recommendation);
        } else {
          print('No data returned for $symbol');
        }
      } catch (e) {
        print('Error fetching data for $symbol: $e');
      }
    }

    setState(() {
      stockRecommendations = tempRecommendations;
      _loadingStocks = false;
    });
  }

  Future<Map<String, dynamic>?> _fetchStockDataForSymbol(String symbol) async {
    final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=2mo');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to fetch data for $symbol: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data for $symbol: $e');
    }
    return null;
  }

  List<double> _extractList(dynamic list) {
    return List<double>.from(list.where((e) => e != null).map((e) => (e as num).toDouble()));
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

  Map<String, List<double>> _calculateMACD(List<double> prices) {
    List<double> calculateEMA(List<double> prices, int period) {
      List<double> ema = [];
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

  double _calculateATR(List<double> highs, List<double> lows, List<double

> closes) {
    List<double> tr = [];
    for (int i = 1; i < highs.length; i++) {
      double highLow = (highs[i] - lows[i]).abs();
      double highClose = (highs[i] - closes[i - 1]).abs();
      double lowClose = (lows[i] - closes[i - 1]).abs();
      tr.add([highLow, highClose, lowClose].reduce((a, b) => a > b ? a : b));
    }
    return tr.isEmpty ? 0 : tr.reduce((a, b) => a + b) / tr.length;
  }

  StockRecommendation _generateStockRecommendation(String symbol, Map<String, dynamic> data) {
    final result = data['chart']['result'][0];
    final meta = result['meta'];
    final quote = result['indicators']['quote'][0];

    final closes = _extractList(quote['close']);
    final volumes = _extractList(quote['volume']);
    final highs = _extractList(quote['high']);
    final lows = _extractList(quote['low']);

    if (closes.length < 15 || volumes.length < 15 || highs.length < 15 || lows.length < 15) {
      return StockRecommendation(
        symbol: symbol,
        title: symbol,
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
        recommendation: "⚠️ لا توجد بيانات كافية",
        recommendationColor: Colors.grey,
        analysis: ["⚠️ لا توجد بيانات كافية لتحليل السهم"],
        conditions: [],
        buySignals: 0,
        sellSignals: 0,
      );
    }

    final lastClose = closes.last;
    final firstClose = closes.first;
    final lastVolume = volumes.last;
    final avgVolume = volumes.reduce((a, b) => a + b) / volumes.length;
    final sma = _calculateSMA(closes, 14);
    final lastSMA = sma.isNotEmpty ? sma.last : lastClose;
    final rsi = _calculateRSI(closes, 14);
    final percentChange = ((lastClose - firstClose) / firstClose) * 100;

    // تحسين الدعم والمقاومة
    List<double> supports = lows.where((low) => lows.where((l) => l <= low * 1.01 && l >= low * 0.99).length >= 3).toList();
    List<double> resistances = highs.where((high) => highs.where((h) => h <= high * 1.01 && h >= high * 0.99).length >= 3).toList();
    final support = supports.isNotEmpty ? supports.reduce((a, b) => a < b ? a : b) : lows.reduce((a, b) => a < b ? a : b);
    final resistance = resistances.isNotEmpty ? resistances.reduce((a, b) => a > b ? a : b) : highs.reduce((a, b) => a > b ? a : b);

    // حساب ATR لتخصيص العتبات
    final atr = _calculateATR(highs, lows, closes);
    final smaThreshold = atr > 0 ? 0.05 * (atr / lastClose) : 0.05;
    final percentChangeThreshold = atr > 0 ? 0.05 * (atr / lastClose) * 100 : 5.0;

    // حساب MACD مع الهيستوغرام
    final macdData = _calculateMACD(closes);
    final macdLine = macdData['macdLine']!;
    final signalLine = macdData['signalLine']!;
    final histogram = macdLine.isNotEmpty && signalLine.isNotEmpty ? macdLine.last - signalLine.last : 0;
    bool isMacdBuy = macdLine.isNotEmpty &&
        signalLine.isNotEmpty &&
        macdLine.length >= 2 &&
        signalLine.length >= 2 &&
        macdLine.last > signalLine.last &&
        macdLine[macdLine.length - 2] <= signalLine[signalLine.length - 2] &&
        histogram > 0;
    bool isMacdSell = macdLine.isNotEmpty &&
        signalLine.isNotEmpty &&
        macdLine.length >= 2 &&
        signalLine.length >= 2 &&
        macdLine.last < signalLine.last &&
        macdLine[macdLine.length - 2] >= signalLine[signalLine.length - 2] &&
        histogram < 0;

    // تعريف الشروط الستة مع إزالة الحالة المحايدة
    final conditions = [
      // 1. المتوسط المتحرك
      lastClose < lastSMA * (1 - smaThreshold)
          ? "شراء قوي - السعر أقل من المتوسط المتحرك بنسبة ${((smaThreshold * 100).toStringAsFixed(2))}٪"
          : lastClose < lastSMA
              ? "شراء ضعيف - السعر أقل من المتوسط المتحرك قليلاً"
              : lastClose > lastSMA * (1 + smaThreshold)
                  ? "بيع قوي - السعر أعلى من المتوسط المتحرك بنسبة ${((smaThreshold * 100).toStringAsFixed(2))}٪"
                  : "بيع ضعيف - السعر أعلى من المتوسط المتحرك قليلاً",

      // 2. RSI
      rsi < 30
          ? "شراء قوي - RSI في ذروة البيع (<30)"
          : rsi < 50
              ? "شراء ضعيف - RSI يشير إلى ميل للشراء"
              : rsi > 70
                  ? "بيع قوي - RSI في ذروة الشراء (>70)"
                  : "بيع ضعيف - RSI يشير إلى ميل للبيع",

      // 3. حجم التداول
      lastVolume > avgVolume * 1.3 && lastClose > lastSMA
          ? "شراء قوي - حجم تداول مرتفع مع صعود"
          : lastVolume > avgVolume && lastClose > lastSMA
              ? "شراء ضعيف - حجم تداول مرتفع قليلاً مع صعود"
              : lastVolume > avgVolume * 1.3 && lastClose < lastSMA
                  ? "بيع قوي - حجم تداول مرتفع مع هبوط"
                  : lastVolume > avgVolume && lastClose < lastSMA
                      ? "بيع ضعيف - حجم تداول مرتفع قليلاً مع هبوط"
                      : lastClose > lastSMA
                          ? "شراء ضعيف - السعر صاعد بدون حجم قوي"
                          : "بيع ضعيف - السعر هابط بدون حجم قوي",

      // 4. التغير السعري
      percentChange < -percentChangeThreshold
          ? "شراء قوي - انخفاض قوي (>${percentChangeThreshold.toStringAsFixed(2)}%)"
          : percentChange < 0
              ? "شراء ضعيف - انخفاض طفيف"
              : percentChange > percentChangeThreshold
                  ? "بيع قوي - ارتفاع قوي (>${percentChangeThreshold.toStringAsFixed(2)}%)"
                  : "بيع ضعيف - ارتفاع طفيف",

      // 5. الدعم والمقاومة
      lastClose <= support * 1.02
          ? "شراء قوي - السعر قريب من مستوى الدعم"
          : lastClose < (support + resistance) / 2
              ? "شراء ضعيف - السعر أقرب إلى الدعم"
              : lastClose >= resistance * 0.98
                  ? "بيع قوي - السعر قريب من مستوى المقاومة"
                  : "بيع ضعيف - السعر أقرب إلى المقاومة",

      // 6. MACD
      isMacdBuy
          ? "شراء قوي - تقاطع MACD صعودي مع هيستوغرام إيجابي"
          : macdLine.isNotEmpty && signalLine.isNotEmpty && macdLine.last > signalLine.last
              ? "شراء ضعيف - MACD يشير إلى ميل صعودي"
              : isMacdSell
                  ? "بيع قوي - تقاطع MACD هبوطي مع هيستوغرام سلبي"
                  : "بيع ضعيف - MACD يشير إلى ميل هبوطي",
    ];

    final buySignals = conditions.where((c) => c.contains("شراء قوي")).length;
    final sellSignals = conditions.where((c) => c.contains("بيع قوي")).length;

    String recommendation;
    Color recommendationColor;

    // نظام التوصية
    if (buySignals >= 4 && sellSignals == 0) {
      recommendation = "🟢 شراء قوي (إشارات: $buySignals)";
      recommendationColor = Colors.green;
    } else if (sellSignals >= 4 && buySignals == 0) {
      recommendation = "🔴 بيع قوي (إشارات: $sellSignals)";
      recommendationColor = Colors.red;
    } else if (buySignals >= 2 && sellSignals == 0) {
      recommendation = "🟢 شراء معتدل (إشارات: $buySignals شراء)";
      recommendationColor = Colors.lightGreen;
    } else if (sellSignals >= 2 && buySignals == 0) {
      recommendation = "🔴 بيع معتدل (إشارات: $sellSignals بيع)";
      recommendationColor = Colors.red[300]!;
    } else if (buySignals > sellSignals) {
      recommendation = "🟢 شراء معتدل (إشارات: $buySignals شراء، $sellSignals بيع)";
      recommendationColor = Colors.lightGreen;
    } else {
      recommendation = "🔴 بيع معتدل (إشارات: $sellSignals بيع، $buySignals شراء)";
      recommendationColor = Colors.red[300]!;
    }

    double? entryPrice, stopLoss, takeProfit;

    if (recommendation.contains("شراء")) {
      entryPrice = lastClose;
      stopLoss = support * 0.98;
      takeProfit = lastClose * 1.05;
    } else if (recommendation.contains("بيع")) {
      entryPrice = lastClose;
      stopLoss = resistance * 1.02;
      takeProfit = lastClose * 0.95;
    }

    final analysis = [
      if (lastClose > lastSMA * (1 + smaThreshold))
        "• السعر أعلى من المتوسط المتحرك بـ${((smaThreshold * 100).toStringAsFixed(2))}% (إشارة بيع قوية)"
      else if (lastClose > lastSMA)
        "• السعر أعلى من المتوسط المتحرك قليلاً (إشارة بيع ضعيفة)"
      else if (lastClose < lastSMA * (1 - smaThreshold))
        "• السعر أقل من المتوسط المتحرك بـ${((smaThreshold * 100).toStringAsFixed(2))}% (إشارة شراء قوية)"
      else
        "• السعر أقل من المتوسط المتحرك قليلاً (إشارة شراء ضعيفة)",
      if (rsi > 70)
        "• RSI في منطقة ذروة الشراء (مفرط في الشراء)"
      else if (rsi > 50)
        "• RSI يشير إلى ميل للبيع"
      else if (rsi < 30)
        "• RSI في منطقة ذروة البيع (مفرط في البيع)"
      else
        "• RSI يشير إلى ميل للشراء",
      if (percentChange > percentChangeThreshold)
        "• اتجاه صعودي قوي (↑ ${percentChange.toStringAsFixed(2)}%)"
      else if (percentChange > 0)
        "• اتجاه صعودي طفيف (↑ ${percentChange.toStringAsFixed(2)}%)"
      else if (percentChange < -percentChangeThreshold)
        "• اتجاه هبوطي قوي (↓ ${percentChange.abs().toStringAsFixed(2)}%)"
      else
        "• اتجاه هبوطي طفيف (↓ ${percentChange.abs().toStringAsFixed(2)}%)",
      if (lastVolume > avgVolume * 1.3)
        "• حجم التداول أعلى من المتوسط بـ30% (نشاط ملحوظ)"
      else if (lastVolume < avgVolume * 0.7)
        "• حجم التداول أقل من المتوسط بـ30% (نشاط ضعيف)"
      else
        "• حجم التداول قريب من المتوسط",
      if (lastClose <= support * 1.02)
        "• السعر قريب من مستوى الدعم (إشارة شراء قوية)"
      else if (lastClose < (support + resistance) / 2)
        "• السعر أقرب إلى الدعم (إشارة شراء ضعيفة)"
      else if (lastClose >= resistance * 0.98)
        "• السعر قريب من مستوى المقاومة (إشارة بيع قوية)"
      else
        "• السعر أقرب إلى المقاومة (إشارة بيع ضعيفة)",
      if (isMacdBuy)
        "• تقاطع MACD صعودي مع هيستوغرام إيجابي (إشارة شراء قوية)"
      else if (macdLine.isNotEmpty && signalLine.isNotEmpty && macdLine.last > signalLine.last)
        "• MACD يشير إلى ميل صعودي (إشارة شراء ضعيفة)"
      else if (isMacdSell)
        "• تقاطع MACD هبوطي مع هيستوغرام سلبي (إشارة بيع قوية)"
      else
        "• MACD يشير إلى ميل هبوطي (إشارة بيع ضعيفة)",
      "• مستوى الدعم الحالي: ${support.toStringAsFixed(2)} دولار",
      "• مستوى المقاومة الحالي: ${resistance.toStringAsFixed(2)} دولار",
      "• متوسط النطاق الحقيقي (ATR): ${atr.toStringAsFixed(2)} دولار",
    ];

    return StockRecommendation(
      symbol: symbol,
      title: meta['symbol'] ?? symbol,
      subtitle: meta['exchangeName'] ?? 'N/A',
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

    if (index != 0) {
      final route = MaterialPageRoute(
        builder: (context) {
          switch (index) {
            case 1:
              return const CommoditiesRecommendation();
            case 2:
              return const ForexRecommendationPage();
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
          'Market Recommendations',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _fetchStockData,
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
            child: _loadingStocks
                ? const Center(child: CircularProgressIndicator())
                : stockRecommendations.isEmpty
                    ? const Center(child: Text('فشل جلب البيانات. تحقق من الاتصال وحاول مجددًا.'))
                    : ListView.builder(
                        itemCount: stockRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = stockRecommendations[index];
                          return _buildRecommendationCard(
                            stock: recommendation,
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
    required StockRecommendation stock,
  }) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailsPage(stock: stock),
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
                    stock.recommendation.contains('شراء')
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: stock.recommendationColor,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          stock.subtitle,
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
                      stock.recommendation.split('(')[0].trim(),
                      style: TextStyle(color: stock.recommendationColor),
                    ),
                    backgroundColor: stock.recommendationColor.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السعر: \$${stock.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'التغير: ${stock.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: stock.changePercent >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المتوسط: \$${stock.sma.toStringAsFixed(2)}'),
                  Text('RSI: ${stock.rsi.toStringAsFixed(1)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSignalChip('إشارات شراء', stock.buySignals, Colors.green),
                  _buildSignalChip('إشارات بيع', stock.sellSignals, Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'الشروط المحققة:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Column(
                children: stock.conditions.map((condition) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        condition.contains("شراء")
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: condition.contains("قوي")
                            ? (condition.contains("شراء") ? Colors.green : Colors.red)
                            : (condition.contains("شراء") ? Colors.green[300] : Colors.red[300]),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          condition,
                          style: TextStyle(
                            color: condition.contains("قوي")
                                ? (condition.contains("شراء") ? Colors.green : Colors.red)
                                : (condition.contains("شراء") ? Colors.green[300] : Colors.red[300]),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalChip(String label, int count, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        '$label: $count',
        style: TextStyle(color: color),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}