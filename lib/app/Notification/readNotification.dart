import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/app/Notification/globalVariable.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/BottomNavBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final UserController userController = Get.find();
      final String userId = userController.userId.value;

      final response = await http.post(
        Uri.parse(linkViewNotification),
        body: {"user_id": userId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data["status"] == "success") {
          final List<dynamic> rawNotifications = data["notifications"] ?? [];

          int unreadCount = rawNotifications
              .where((n) => (n["is_read"]?.toString() ?? "0") == "0")
              .length;

          NotificationGlobals.updateUnreadCount(unreadCount);

          // تحقق من وجود إشعار واحد فقط عند تجاوز الميزانية
          bool budgetExceededNotified = false;

          for (var notification in rawNotifications) {
            // إذا كانت الإشعار من نوع "budget_exceeded" ولم يتم تنبيه المستخدم بعد
            if (notification["type"] == "budget_exceeded" && !budgetExceededNotified) {
              // حدد تنبيه واحد فقط عند تجاوز الميزانية
              Future.delayed(Duration.zero, () {
                showBudgetExceededDialog(context, notification["message"] ?? "تم تجاوز الميزانية!");
              });
              budgetExceededNotified = true; // تأكد من أن الإشعار يظهر مرة واحدة فقط
            }
          }

          setState(() {
            notifications =
                rawNotifications.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      print('❌ خطأ في جلب الإشعارات: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // دالة عرض الـ Dialog عند تجاوز الميزانية
  void showBudgetExceededDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // المستخدم يجب أن يغلقه يدويًا
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, size: 50, color: Colors.red),
                const SizedBox(height: 10),
                const Text(
                  "تحذير: تجاوزت الميزانية!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إغلاق"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
      ),
      body: notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  title: Text(notification["message"] ?? "No Message"),
                  subtitle: Text(notification["created_at"] ?? "Unknown Date"),
                  leading: Icon(
                    (notification["is_read"]?.toString() ?? "0") == "1"
                        ? Icons.notifications_active
                        : Icons.notifications,
                    color: (notification["is_read"]?.toString() ?? "0") == "1"
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
