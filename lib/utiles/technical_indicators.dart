class TechnicalIndicators {
  static Map<String, List<double>> calculateMACD(List<double> prices) {
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
}