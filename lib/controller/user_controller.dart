import 'package:get/get.dart';

class UserController extends GetxController {
  // تعريف متغير لتخزين الـ id
  var userId = ''.obs;

  // دالة لتعيين الـ id
  void setUserId(String id) {
    userId.value = id;
  }

  // دالة لاسترجاع الـ id
  String getUserId() {
    return userId.value;
  }
}
