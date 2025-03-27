import 'package:flutter/material.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:managermoney/widgets/crud.dart';

class AccountSummary extends StatelessWidget {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  Future<dynamic> getAccountSummary() async {
    String userId = userController.getUserId();
    try {
      var response = await crud.postRequest(linkViewAccountSummary, {
        "user_id": userId,
      });

      print("Raw Response: $response");

      if (response != null && response['status'] == "success") {
        return response;
      } else {
        print("Error retrieving account summary");
        return [];
      }
    } catch (e) {
      print("Error catch $e");
      return [];
    }
  }

  Widget _buildSummaryItem(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black, // العنوان دائماً أسود
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor, // القيمة تأخذ اللون المحدد
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getAccountSummary(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } 
        // إذا لم توجد بيانات أو كانت النتيجة فارغة، يتم عرض التصميم مع القيم الافتراضية "0"
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(right: 17.0, left: 17.0),
            child: Row(
              children: [
                SizedBox(height: 2),
                _buildSummaryItem('Assets', "0", Colors.blue),
                SizedBox(width: 90),
                _buildSummaryItem('Liabilities', "0", Colors.red),
                SizedBox(width: 90),
                _buildSummaryItem('Total', "0", Colors.black),
              ],
            ),
          );
        } 
        // في حال وجود بيانات
        else if (snapshot.hasData) {
          var data = snapshot.data['data'];
          if (data is List && data.isNotEmpty) {
            var summary = data[0]; // نأخذ العنصر الأول من القائمة
            var assets = summary['assets'] ?? "0";
            var liabilities = summary['liabilities'] ?? "0";
            var total = summary['total'] ?? "0";

            return Padding(
              padding: const EdgeInsets.only(right: 17.0, left: 17.0),
              child: Row(
                children: [
                  SizedBox(height: 2),
                  _buildSummaryItem('Assets', assets, Colors.blue),
                  SizedBox(width: 90),
                  _buildSummaryItem('Liabilities', liabilities, Colors.red),
                  SizedBox(width: 90),
                  _buildSummaryItem('Total', total, Colors.black),
                ],
              ),
            );
          } else {
            return Center(child: Text("Invalid data format"));
          }
        }
        return Container();
      },
    );
  }
}
