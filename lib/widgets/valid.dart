import 'package:managermoney/connstants/message.dart';


String? validInput(String val, int min, int max) {
  if (val.isEmpty) {
    return "$messageInputEmpty"; // 🟢 التحقق أولًا من أن الحقل ليس فارغًا
  }
  if (val.length < min) {
    return "$messageInputMin $min"; // 🟢 التحقق من الحد الأدنى
  }
  if (val.length > max) {
    return "$messageInputMax $max"; // 🟢 التحقق من الحد الأقصى
  }
  return null; // 🟢 الإدخال صحيح، لا توجد رسالة خطأ
}

