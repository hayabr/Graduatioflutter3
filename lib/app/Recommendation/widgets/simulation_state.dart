

import 'package:hive/hive.dart';

part 'simulation_state.g.dart';

@HiveType(typeId: 1) // تأكد أن typeId فريد وغير مستخدم في كلاسات أخرى
class SimulationState extends HiveObject {
  @HiveField(0)
  bool isSimulating;

  @HiveField(1)
  DateTime simulationStartTime;

  @HiveField(2)
  List<Map<String, double>> userPricePoints; // تخزين كـ Map بدلاً من FlSpot

  @HiveField(3)
  List<Map<String, double>> appPricePoints; // تخزين كـ Map بدلاً من FlSpot

  @HiveField(4)
  int currentStep;

  @HiveField(5)
  double currentPrice;

  @HiveField(6)
  String userResult;

  @HiveField(7)
  String appResult;

  @HiveField(8)
  double userProfitLoss;

  @HiveField(9)
  double appProfitLoss;

  @HiveField(10)
  bool tradeClosed;

  @HiveField(11)
  String stockSymbol;

  @HiveField(12) // إضافة الحقول الجديدة
  double entryPrice;

  @HiveField(13)
  double stopLoss;

  @HiveField(14)
  double takeProfit;

    @HiveField(15)
 final bool? isBuyTrade;

  SimulationState({
    required this.isSimulating,
    required this.simulationStartTime,
    required this.userPricePoints,
    required this.appPricePoints,
    required this.currentStep,
    required this.currentPrice,
    required this.userResult,
    required this.appResult,
    required this.userProfitLoss,
    required this.appProfitLoss,
    required this.tradeClosed,
    required this.stockSymbol,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.isBuyTrade,
  });
}