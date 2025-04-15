import 'package:flutter/material.dart';
import 'package:graduationproject/app/Recommendation/CommoditiesRecommendation.dart';
import 'package:graduationproject/app/Recommendation/CryptoRecommendation.dart';
import 'package:graduationproject/app/Recommendation/forex_detail_page.dart';
import 'package:graduationproject/app/Recommendation/recommendations.dart';
import 'package:graduationproject/widgets/BottomNavBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForexRecommendation {
  final String symbol;
  final String title;
  final String subtitle;
  final double currentPrice;
  final double firstPrice;
  final double sma;
  final double rsi;
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
  _ForexRecommendationPageState createState() => _ForexRecommendationPageState();
}

class _ForexRecommendationPageState extends State<ForexRecommendationPage>
    with RouteAware {
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
      "EURUSD=X",
      "GBPUSD=X",
      "USDJPY=X",
      "AUDUSD=X",
      "USDCAD=X",
      "USDCHF=X",
      "NZDUSD=X"
    ];
    List<ForexRecommendation> tempRecommendations = [];

    for (String pair in pairs) {
      try {
        final data = await _fetchForexDataForPair(pair);
        if (data != null) {
          final recommendation = _generateForexRecommendation(pair, data);
          tempRecommendations.add(recommendation);
        }
      } catch (e) {
        print('Error fetching data for $pair: $e');
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
        'https://query1.finance.yahoo.com/v8/finance/chart/$pair?interval=1d&range=1mo');

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
      print('Error fetching data for $pair: $e');
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

    return rsi;
  }

  ForexRecommendation _generateForexRecommendation(
      String symbol, Map<String, dynamic> data) {
    final result = data['chart']['result'][0];
    final meta = result['meta'];
    final quote = result['indicators']['quote'][0];

    final closes = _extractList(quote['close']);
    final highs = _extractList(quote['high']);
    final lows = _extractList(quote['low']);

    if (closes.length < 15 || highs.length < 15 || lows.length < 15) {
      return ForexRecommendation(
        symbol: symbol,
        title: symbol.replaceAll('=X', ''),
        subtitle: 'No data available',
        currentPrice: 0,
        firstPrice: 0,
        sma: 0,
        rsi: 0,
        support: 0,
        resistance: 0,
        changePercent: 0,
        recommendation: "⚠️ لا توجد بيانات كافية",
        recommendationColor: Colors.grey,
        analysis: ["⚠️ لا توجد بيانات كافية لتحليل الزوج"],
        conditions: [],
        buySignals: 0,
        sellSignals: 0,
      );
    }

    final lastClose = closes.last;
    final firstClose = closes.first;
    final sma = _calculateSMA(closes, 14);
    final lastSMA = sma.isNotEmpty ? sma.last : lastClose;
    final rsi = _calculateRSI(closes, 14);
    final percentChange = ((lastClose - firstClose) / firstClose) * 100;
    final support = lows.reduce((a, b) => a < b ? a : b);
    final resistance = highs.reduce((a, b) => a > b ? a : b);

    final conditions = [
      lastClose < lastSMA * 0.95 ? "شراء - السعر تحت المتوسط" : null,
      rsi < 30 ? "شراء - RSI منخفض" : null,
      percentChange < -5 ? "شراء - انخفاض قوي" : null,
      lastClose > lastSMA * 1.05 ? "بيع - السعر فوق المتوسط" : null,
      rsi > 70 ? "بيع - RSI مرتفع" : null,
      percentChange > 5 ? "بيع - ارتفاع قوي" : null,
    ].where((c) => c != null).toList().cast<String>();

    final buySignals = conditions.where((c) => c.contains("شراء")).length;
    final sellSignals = conditions.where((c) => c.contains("بيع")).length;

    String recommendation;
    Color recommendationColor;
    double? entryPrice, stopLoss, takeProfit;

    if (buySignals >= 2 && sellSignals == 0) {
      recommendation = "🟢 شراء قوي (إشارات: $buySignals)";
      recommendationColor = Colors.green;
      entryPrice = lastClose;
      stopLoss = support * 0.98;
      takeProfit = lastClose * 1.05;
    } else if (sellSignals >= 2 && buySignals == 0) {
      recommendation = "🔴 بيع قوي (إشارات: $sellSignals)";
      recommendationColor = Colors.red;
      entryPrice = lastClose;
      stopLoss = resistance * 1.02;
      takeProfit = lastClose * 0.95;
    } else if (buySignals > sellSignals) {
      recommendation =
          "🟢 شراء (إشارات: $buySignals شراء، $sellSignals بيع)";
      recommendationColor = Colors.lightGreen;
      entryPrice = lastClose;
      stopLoss = support * 0.98;
      takeProfit = lastClose * 1.05;
    } else if (sellSignals > buySignals) {
      recommendation =
          "🔴 بيع (إشارات: $sellSignals بيع، $buySignals شراء)";
      recommendationColor = Colors.red[300]!;
      entryPrice = lastClose;
      stopLoss = resistance * 1.02;
      takeProfit = lastClose * 0.95;
    } else {
      recommendation = "🟡 حيادي (إشارات متوازنة)";
      recommendationColor = Colors.amber;
      entryPrice = null;
      stopLoss = null;
      takeProfit = null;
    }

    final analysis = [
      if (lastClose > lastSMA * 1.05)
        "• السعر أعلى من المتوسط المتحرك بـ 5% (إشارة بيع)"
      else if (lastClose < lastSMA * 0.95)
        "• السعر أقل من المتوسط المتحرك بـ 5% (إشارة شراء)"
      else
        "• السعر قريب من المتوسط المتحرك (حياد)",
      if (rsi > 70) "• RSI في منطقة ذروة الشراء (بيع)"
      else if (rsi < 30) "• RSI في منطقة ذروة البيع (شراء)"
      else
        "• RSI في المنطقة المحايدة",
      if (percentChange > 5)
        "• اتجاه صعودي قوي (↑ ${percentChange.toStringAsFixed(2)}%)"
      else if (percentChange < -5)
        "• اتجاه هبوطي قوي (↓ ${percentChange.abs().toStringAsFixed(2)}%)"
      else
        "• تغير سعري طفيف (↔ ${percentChange.toStringAsFixed(2)}%)",
      "• الدعم: ${support.toStringAsFixed(4)}",
      "• المقاومة: ${resistance.toStringAsFixed(4)}",
    ];

    return ForexRecommendation(
      symbol: symbol,
      title: symbol.replaceAll('=X', '').replaceAll('', '/'),
      subtitle: meta['exchangeName'] ?? 'Forex',
      currentPrice: lastClose,
      firstPrice: firstClose,
      sma: lastSMA,
      rsi: rsi,
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
              return const Recommendations();
            case 1:
              return const CommoditiesRecommendation();
            case 3:
               return const CryptoRecommendationPage();
              break;
          }
          return Container();
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
            icon: const Icon(Icons.refresh, color: Colors.blue),
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
                    forex.recommendation.contains('شراء')
                        ? Icons.trending_up
                        : forex.recommendation.contains('بيع')
                            ? Icons.trending_down
                            : Icons.trending_flat,
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
                      forex.recommendation.split('(')[0].trim(),
                      style: TextStyle(color: forex.recommendationColor),
                    ),
                    backgroundColor: forex.recommendationColor.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السعر: ${forex.currentPrice.toStringAsFixed(4)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'التغير: ${forex.changePercent.toStringAsFixed(2)}%',
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
                  Text('المتوسط: ${forex.sma.toStringAsFixed(4)}'),
                  Text('RSI: ${forex.rsi.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSignalChip('إشارات شراء', forex.buySignals, Colors.green),
                  _buildSignalChip('إشارات بيع', forex.sellSignals, Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'الشروط المحققة:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Column(
                children: forex.conditions.map((condition) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            condition.contains("شراء")
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: condition.contains("شراء") ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              condition,
                              style: TextStyle(
                                color: condition.contains("شراء")
                                    ? Colors.green
                                    : Colors.red,
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