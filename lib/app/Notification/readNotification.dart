import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:managermoney/app/Notification/globalVariable.dart';
import 'dart:convert';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/BottomNavBar.dart';
// استيراد المتغيرات العامة

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

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
        Uri.parse('$linkViewNotification'),
        body: {"user_id": userId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data["status"] == "success") {
          final List<dynamic> rawNotifications = data["notifications"] ?? [];
          
          // حساب الإشعارات غير المقروءة
          int unreadCount = rawNotifications.where((n) => 
            (n["is_read"]?.toString() ?? "0") == "0").length;
          
          // تحديث المتغير العام
          NotificationGlobals.updateUnreadCount(unreadCount);
          
          setState(() {
            notifications = rawNotifications.map((e) => Map<String, dynamic>.from(e)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.white,
      ),
      body: notifications.isEmpty
          ? Center(child: CircularProgressIndicator())
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