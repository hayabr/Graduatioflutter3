// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulation_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SimulationStateAdapter extends TypeAdapter<SimulationState> {
  @override
  final int typeId = 1;

  @override
  SimulationState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SimulationState(
      isSimulating: fields[0] as bool,
      simulationStartTime: fields[1] as DateTime,
      userPricePoints: (fields[2] as List)
          .map((dynamic e) => (e as Map).cast<String, double>())
          .toList(),
      appPricePoints: (fields[3] as List)
          .map((dynamic e) => (e as Map).cast<String, double>())
          .toList(),
      currentStep: fields[4] as int,
      currentPrice: fields[5] as double,
      userResult: fields[6] as String,
      appResult: fields[7] as String,
      userProfitLoss: fields[8] as double,
      appProfitLoss: fields[9] as double,
      tradeClosed: fields[10] as bool,
      stockSymbol: fields[11] as String,
      entryPrice: fields[12] as double,
      stopLoss: fields[13] as double,
      takeProfit: fields[14] as double, isBuyTrade: null,
      
    );
  }

  @override
  void write(BinaryWriter writer, SimulationState obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.isSimulating)
      ..writeByte(1)
      ..write(obj.simulationStartTime)
      ..writeByte(2)
      ..write(obj.userPricePoints)
      ..writeByte(3)
      ..write(obj.appPricePoints)
      ..writeByte(4)
      ..write(obj.currentStep)
      ..writeByte(5)
      ..write(obj.currentPrice)
      ..writeByte(6)
      ..write(obj.userResult)
      ..writeByte(7)
      ..write(obj.appResult)
      ..writeByte(8)
      ..write(obj.userProfitLoss)
      ..writeByte(9)
      ..write(obj.appProfitLoss)
      ..writeByte(10)
      ..write(obj.tradeClosed)
      ..writeByte(11)
      ..write(obj.stockSymbol)
      ..writeByte(12)
      ..write(obj.entryPrice)
      ..writeByte(13)
      ..write(obj.stopLoss)
      ..writeByte(14)
      ..write(obj.takeProfit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimulationStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
