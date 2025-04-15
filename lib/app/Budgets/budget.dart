import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/app/Budgets/UpdateBudget.dart';
import 'package:graduationproject/app/Budgets/insertBudget.dart';
import 'package:graduationproject/app/Transaction/home.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/crud.dart';


class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();
  List<dynamic> budgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  Future<void> _fetchBudgets() async {
    try {
      String userId = userController.getUserId();
      var response = await crud.postRequest(linkReadBudget, {
        "user_id": userId,
      });

      print("API Response: $response"); // Debug print

      if (response != null && response['status'] == "success") {
        setState(() {
          budgets = response['budgets'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching budgets: $e"); // Debug print
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Get.offAll(() => const Home()); // الرجوع إلى الصفحة الرئيسية
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Get.to(() => AddBudget())?.then((_) => _fetchBudgets());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can check out the budget status in Trans. tab > Total page.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : budgets.isEmpty
                      ? const Center(
                          child: Text(
                            'No budgets found.',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchBudgets,
                          child: ListView.builder(
                            itemCount: budgets.length,
                            itemBuilder: (context, index) {
                              var budget = budgets[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.only(bottom: 10), // Corrected margin placement
                                child: ListTile(
                                  leading: const Icon(Icons.edit, color: Colors.black54),
                                  title: Text(
                                    '\$${budget['amount'] ?? 'N/A'} - ${budget['category_name'] ?? 'No Category'}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Get.to(() => UpdateBudget(budgetData: budget))?.then((_) => _fetchBudgets());
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          // Implement navigation logic here
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz), label: 'More'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Trans.'),
        ],
      ),
    );
  }
}
