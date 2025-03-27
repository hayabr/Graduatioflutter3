// lib/globals/notification_globals.dart
import 'package:get/get.dart';

class NotificationGlobals {
  static RxInt unreadNotificationsCount = 0.obs;
  
  static void updateUnreadCount(int count) {
    unreadNotificationsCount.value = count;
    print('✅ the number of unread notification is $count'); // طباعة في الكونسول
  }
  
  static int getUnreadCount() {
    print('🔢 جلب عدد الإشعارات الحالي: ${unreadNotificationsCount.value}');
    return unreadNotificationsCount.value;
  }
}