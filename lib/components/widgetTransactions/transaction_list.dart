import 'package:flutter/material.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:managermoney/widgets/crud.dart';

class TransactionCard extends StatelessWidget {
  final String userId;
  final Crud crud = Crud();

  TransactionCard({
    Key? key,
    required this.userId,
  }) : super(key: key);

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
          var dateA = DateTime.parse(a['transaction_date']);
          var dateB = DateTime.parse(b['transaction_date']);
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
      String date = transaction['transaction_date'];
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
  void _onTransactionTap(Map<String, dynamic> transaction) {
    // يمكنك استبدال هذا بالإجراء الذي تريده، مثل فتح صفحة التعديل أو الحذف
    print("Transaction tapped: ${transaction['id']}");
    // مثال: فتح صفحة التعديل
    // Get.to(() => EditTransactionPage(transaction: transaction));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getTransactions(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data.isEmpty) {
          return Center(child: Text("No transactions found"));
        } else if (snapshot.hasData) {
          var transactions = snapshot.data;

          // تجميع المعاملات بناءً على التاريخ
          var groupedTransactions = groupTransactionsByDate(transactions);

          return SingleChildScrollView(  // إضافة SingleChildScrollView للتأكد من التمرير
            child: ListView.builder(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),  // تحسين التمرير
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
                              onTap: () => _onTransactionTap(transaction), // تفعيل الضغط على المعاملة
                              borderRadius: BorderRadius.circular(12), // زوايا دائرية لتتناسب مع الـ Card
                              splashColor: Colors.blue.withOpacity(0.1), // لون الـ splash عند الضغط
                              highlightColor: Colors.blue.withOpacity(0.05), // لون الـ highlight عند الضغط
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    // الأيقونة
                                    Text(
                                      transaction['icon'],
                                      style: const TextStyle(fontSize: 24), // زيادة حجم الأيقونة
                                    ),
                                    const SizedBox(width: 12),
                                    // تفاصيل المعاملة
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction['category_name'],
                                            style: const TextStyle(
                                              fontSize: 16, // زيادة حجم الخط
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            transaction['name'],
                                            style: TextStyle(
                                              fontSize: 14, // زيادة حجم الخط
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // المبلغ
                                    Text(
                                      transaction['amount'],
                                      style: TextStyle(
                                        fontSize: 16, // زيادة حجم الخط
                                        fontWeight: FontWeight.bold,
                                        color: amountColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
