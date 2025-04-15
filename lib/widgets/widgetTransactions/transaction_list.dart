import 'package:flutter/material.dart';
import 'package:graduationproject/app/Transaction/editTransation.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/widgets/crud.dart';
import 'package:get/get.dart';


class TransactionCard extends StatelessWidget {
  final String userId;
  final Crud crud = Crud();

  TransactionCard({
    super.key,
    required this.userId,
  });

  Future<dynamic> getTransactions() async {
    try {
      var response = await crud.postRequest(linkViewTransaction, {
        "user_id": userId,
      });

      print("Raw Response: $response");

      if (response != null && response['status'] == "success") {
        var transactions = response['data'];

        // فرز المعاملات بناءً على التاريخ (الأحدث أولاً)
        transactions.sort((a, b) {
          var dateA = DateTime.parse(a['transaction_date'] ?? '1970-01-01');
          var dateB = DateTime.parse(b['transaction_date'] ?? '1970-01-01');
          return dateB.compareTo(dateA); // ترتيب تنازلي (الأحدث أولاً)
        });

        return transactions;
      } else {
        print("Error retrieving transactions");
        return [];
      }
    } catch (e) {
      print("Error catch $e");
      return [];
    }
  }

  // دالة لتجميع المعاملات بناءً على التاريخ
  Map<String, List<dynamic>> groupTransactionsByDate(List<dynamic> transactions) {
    Map<String, List<dynamic>> groupedTransactions = {};

    for (var transaction in transactions) {
      String date = transaction['transaction_date'] ?? 'Unknown Date'; // استخدام قيمة افتراضية إذا كانت null
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // فرز التواريخ من الأحدث إلى الأقدم
    var sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    Map<String, List<dynamic>> sortedGroupedTransactions = {};
    for (var key in sortedKeys) {
      sortedGroupedTransactions[key] = groupedTransactions[key]!;
    }

    return sortedGroupedTransactions;
  }

  // دالة عند الضغط على المعاملة
  void _onTransactionTap(BuildContext context, Map<String, dynamic> transaction) {
    // استخدام Navigator.push للانتقال إلى صفحة التعديل
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateTransaction(transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getTransactions(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data.isEmpty) {
          return const Center(child: Text("No transactions found"));
        } else if (snapshot.hasData) {
          var transactions = snapshot.data;

          // تجميع المعاملات بناءً على التاريخ
          var groupedTransactions = groupTransactionsByDate(transactions);

          return SingleChildScrollView(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: groupedTransactions.length,
              itemBuilder: (context, index) {
                var date = groupedTransactions.keys.elementAt(index);
                var transactionsForDate = groupedTransactions[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عرض التاريخ خارج الـ Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    // عرض المعاملات داخل الـ Card
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Column(
                        children: [
                          ...transactionsForDate.map((transaction) {
                            Color amountColor = transaction['type'] == "income" ? Colors.green : Colors.red;
                            return InkWell(
                              onTap: () => _onTransactionTap(context, transaction),
                              borderRadius: BorderRadius.circular(12),
                              splashColor: Colors.blue.withOpacity(0.1),
                              highlightColor: Colors.blue.withOpacity(0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    // الأيقونة
                                    Text(
                                      transaction['icon'] ?? '📄', // استخدام قيمة افتراضية إذا كانت null
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    // تفاصيل المعاملة
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction['category_name'] ?? 'Unknown Category', // استخدام قيمة افتراضية إذا كانت null
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            transaction['name'] ?? 'Unknown Name', // استخدام قيمة افتراضية إذا كانت null
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // المبلغ
                                    Text(
                                      transaction['amount']?.toString() ?? '0.00', // استخدام قيمة افتراضية إذا كانت null
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: amountColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
        return Container();
      },
    );
  }
}