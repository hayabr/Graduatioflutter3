import 'package:get/get.dart';

class HomeController extends GetxController {
  var notifications = <String>[].obs;

  void addNotification(String message) {
    notifications.add(message);
    update(); // تحديث الواجهة تلقائيًا
  }
}
