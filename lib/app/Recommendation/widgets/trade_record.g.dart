// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeRecordAdapter extends TypeAdapter<TradeRecord> {
  @override
  final int typeId = 0;

  @override
  TradeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradeRecord(
      userId: fields[0] as String,
      stockSymbol: fields[1] as String,
      stockTitle: fields[2] as String,
      isBuyTrade: fields[3] as bool,
      entryPrice: fields[4] as double,
      stopLoss: fields[5] as double,
      takeProfit: fields[6] as double,
      profitLoss: fields[7] as double,
      result: fields[8] as String,
      timestamp: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TradeRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.stockSymbol)
      ..writeByte(2)
      ..write(obj.stockTitle)
      ..writeByte(3)
      ..write(obj.isBuyTrade)
      ..writeByte(4)
      ..write(obj.entryPrice)
      ..writeByte(5)
      ..write(obj.stopLoss)
      ..writeByte(6)
      ..write(obj.takeProfit)
      ..writeByte(7)
      ..write(obj.profitLoss)
      ..writeByte(8)
      ..write(obj.result)
      ..writeByte(9)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
