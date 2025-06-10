import 'package:hive/hive.dart';
part 'trade_record.g.dart';

@HiveType(typeId: 0)
class TradeRecord {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String stockSymbol;

  @HiveField(2)
  final String stockTitle;

  @HiveField(3)
  final bool isBuyTrade;

  @HiveField(4)
  final double entryPrice;

  @HiveField(5)
  final double stopLoss;

  @HiveField(6)
  final double takeProfit;

  @HiveField(7)
  final double profitLoss;

  @HiveField(8)
  final String result;

  @HiveField(9)
  final DateTime timestamp;

  TradeRecord({
    required this.userId,
    required this.stockSymbol,
    required this.stockTitle,
    required this.isBuyTrade,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.profitLoss,
    required this.result,
    required this.timestamp,
  });
}