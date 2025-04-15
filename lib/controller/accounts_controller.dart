import 'package:get/get.dart';

class AccountsController extends GetxController {
  // متغيرات قابلة للملاحظة (Observable)
  var isLoading = false.obs;
  var accountsList = [].obs;

  // دالة لجلب البيانات (مثال)
  void fetchAccounts() async {
    isLoading(true); // بدء التحميل
    await Future.delayed(const Duration(seconds: 2)); // محاكاة طلب شبكة
    accountsList.addAll(['Account 1', 'Account 2', 'Account 3']); // إضافة بيانات وهمية
    isLoading(false); // إيقاف التحميل
  }

  @override
  void onInit() {
    fetchAccounts(); // جلب البيانات عند تهيئة الـ Controller
    super.onInit();
  }
}     