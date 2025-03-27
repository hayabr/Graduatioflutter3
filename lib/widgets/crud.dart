import 'package:http/http.dart' as http; // to Request we need to pub
import 'dart:convert'; // to convert JSON to Dart 

class Crud {
  Future<dynamic> getRequest(String url) async {
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        print("Error ${response.statusCode}");
        return null; // ✅ تجنب الأخطاء عند الاستدعاء
      }
    } catch (e) {
      print("Error catch $e");
      return null; // ✅ في حال حدوث استثناء، تُرجع الدالة قيمة افتراضية
    }
  }

  Future<dynamic> postRequest(String url, Map<String, String> data) async {
    try {
      var response = await http.post(Uri.parse(url), body: data);

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        print("Error ${response.statusCode}");
        return null; // ✅ معالجة الأخطاء وإرجاع قيمة افتراضية
      }
    } catch (e) {
      print("Error catch $e");
      return null; // ✅ منع الأعطال عند حدوث استثناء
    }
  }
}
