import 'package:flutter/material.dart';
import 'package:graduationproject/app/Budgets/budget.dart';
import 'package:graduationproject/app/Notification/globalVariable.dart';
import 'package:graduationproject/app/Notification/readNotification.dart';
import 'package:graduationproject/app/Transaction/addTransaction.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/BottomNavBar.dart';
import 'package:graduationproject/widgets/widgetTransactions/summaryBox.dart';
import 'package:graduationproject/widgets/widgetTransactions/transaction_list.dart';
import 'package:get/get.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  int _selectedIndex = 0;
  final UserController userController = Get.find<UserController>();
  bool showNotificationBadge = true;
  final int _selectedTabIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToNotificationsScreen(BuildContext context) async {
    setState(() {
      showNotificationBadge = false;
    });

    NotificationGlobals.updateUnreadCount(0);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );

    setState(() {
      showNotificationBadge = NotificationGlobals.unreadNotificationsCount.value > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userId = userController.getUserId();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Money Manager",
          style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // استبدال أيقونة البحث بأيقونة "Set Budget"
          IconButton(
            icon: const Icon(Icons.pie_chart, color: Colors.black), // أيقونة "Set Budget"
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetPage()),
              );
            },
          ),
          IconButton(
            icon: Obx(() => Stack(
              children: [
                Transform.scale(
                  scale: 1.3,
                  child: const Icon(Icons.notifications_none, color: Colors.black),
                ),
                if (showNotificationBadge && NotificationGlobals.unreadNotificationsCount.value > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${NotificationGlobals.unreadNotificationsCount.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            )),
            onPressed: () {
              setState(() {
                NotificationGlobals.updateUnreadCount(0);
                showNotificationBadge = false;
              });
              _navigateToNotificationsScreen(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(thickness: 1, height: 1, color: Colors.grey),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Column(
                children: [
                  SummaryRow(),
                ],
              ),
            ),
            const Divider(thickness: 1, height: 1, color: Colors.grey),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: TransactionCard(userId: userId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransaction()),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
