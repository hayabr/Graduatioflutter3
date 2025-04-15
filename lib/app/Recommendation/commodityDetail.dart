import 'package:flutter/material.dart';
import 'package:graduationproject/app/Recommendation/CommoditiesRecommendation.dart';

class CommodityDetailsPage extends StatelessWidget {
  final CommodityRecommendation commodity;

  const CommodityDetailsPage({super.key, required this.commodity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(commodity.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and basic info
            Row(
              children: [
                Icon(
                  _getCommodityIcon(commodity.subtitle),
                  size: 40,
                  color: Colors.amber,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commodity.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      commodity.subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Recommendation chip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: commodity.recommendationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: commodity.recommendationColor,
                  width: 1,
                ),
              ),
              child: Text(
                commodity.recommendation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: commodity.recommendationColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Price information
            const Text(
              'معلومات السعر',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('السعر الحالي', '\$${commodity.currentPrice.toStringAsFixed(2)}'),
            _buildDetailRow('السعر الأول', '\$${commodity.firstPrice.toStringAsFixed(2)}'),
            _buildDetailRow('التغير', '${commodity.changePercent.toStringAsFixed(2)}%', 
                color: commodity.changePercent >= 0 ? Colors.green : Colors.red),
            _buildDetailRow('المتوسط المتحرك (14 يوم)', '\$${commodity.sma.toStringAsFixed(2)}'),
            _buildDetailRow('مؤشر القوة النسبية (RSI)', commodity.rsi.toStringAsFixed(1)),
            const SizedBox(height: 16),
            
            // Volume information
            const Text(
              'معلومات الحجم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('حجم التداول الأخير', commodity.lastVolume.toString()),
            _buildDetailRow('متوسط الحجم', commodity.avgVolume.toString()),
            const SizedBox(height: 16),
            
            // Support & Resistance
            const Text(
              'الدعم والمقاومة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('مستوى الدعم', '\$${commodity.support.toStringAsFixed(2)}'),
            _buildDetailRow('مستوى المقاومة', '\$${commodity.resistance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            
            // Trading signals if available
            if (commodity.entryPrice != null) ...[
              const Text(
                'إشارات التداول',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDetailRow('سعر الدخول المقترح', '\$${commodity.entryPrice!.toStringAsFixed(2)}'),
              _buildDetailRow('وقف الخسارة', '\$${commodity.stopLoss!.toStringAsFixed(2)}'),
              _buildDetailRow('جني الأرباح', '\$${commodity.takeProfit!.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
            ],
            
            // Conditions
            const Text(
              'الشروط المحققة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...commodity.conditions.map((condition) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      condition.contains("شراء") ? Icons.arrow_upward : Icons.arrow_downward,
                      color: condition.contains("شراء") ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        condition,
                        style: TextStyle(
                          fontSize: 16,
                          color: condition.contains("شراء") ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Analysis
            const Text(
              'التحليل الفني',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...commodity.analysis.map((item) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCommodityIcon(String category) {
    switch (category) {
      case "Metals":
        return Icons.diamond;
      case "Energy":
        return Icons.local_gas_station;
      case "Agriculture":
        return Icons.agriculture;
      case "Softs":
        return Icons.local_drink;
      default:
        return Icons.shopping_basket;
    }
  }
}