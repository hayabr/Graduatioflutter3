import 'package:flutter/material.dart';
import 'package:managermoney/app/Notification/globalVariable.dart';
import 'package:managermoney/app/Transaction/addTransaction.dart';
import 'package:managermoney/widgets/BottomNavBar.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:managermoney/widgets/widgetTransactions/summaryBox.dart';
import 'package:managermoney/widgets/widgetTransactions/transaction_list.dart';
import 'package:managermoney/app/Notification/readNotification.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  int _selectedIndex = 0;
  final UserController userController = Get.find<UserController>();
  bool showNotificationBadge = true; // متغير للتحكم في ظهور العداد

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToNotificationsScreen(BuildContext context) async {
    setState(() {
      showNotificationBadge = false; // إخفاء العداد
    });

    // تحديث حالة القراءة في الخلفية
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
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Money Manager",
            style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Obx(() => Stack(
              children: [
                Transform.scale(
                  scale: 1.3, // تكبير الأيقونة
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
                // عند الضغط على الأيقونة، إخفاء العداد وتحديثه ليصبح صفرًا
                NotificationGlobals.updateUnreadCount(0); 
                showNotificationBadge = false; // إخفاء العداد
              });

              // الانتقال إلى صفحة الإشعارات
              _navigateToNotificationsScreen(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Divider(
                      thickness: 1,
                      height: 1,
                      color: Colors.grey,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SummaryRow(),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Divider(thickness: 1, height: 1, color: Colors.grey),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Transaction History',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'See All',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: TransactionCard(userId: userId),
                  ),
                ],
              ),
            ),
            Container(
              height: 20,
              color: Colors.white,
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
            MaterialPageRoute(builder: (context) =>  AddTransaction()),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
