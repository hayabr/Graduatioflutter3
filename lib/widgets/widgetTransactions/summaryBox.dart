import 'package:flutter/material.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/crud.dart';
import 'package:get/get.dart';


class SummaryRow extends StatelessWidget {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  SummaryRow({super.key});

  Future<dynamic> getSummaryData() async {
    String userId = userController.getUserId();
    try {
      var response = await crud.postRequest(linkViewTransactionSummary, {
        "user_id": userId,
      });

      print("Raw Response: $response");

      if (response != null && response['status'] == "success") {
        return response;
      } else {
        print("Error retrieving summary data");
        return [];
      }
    } catch (e) {
      print("Error catch $e");
      return [];
    }
  }

  Widget _summaryBox(String title, String amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getSummaryData(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } 
        // إذا لم توجد بيانات أو كانت النتيجة فارغة، يتم عرض التصميم مع القيم الافتراضية "0"
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox("Income", "0", Colors.green),
              _summaryBox("Expenses", "0", Colors.red[600]!),
              _summaryBox("Total", "0", Colors.black),
            ],
          );
        } 
        // في حال وجود بيانات
        else if (snapshot.hasData) {
          var data = snapshot.data['data'];
          var income = data['income'] ?? "0";
          var expenses = data['expenses'] ?? "0";
          var total = data['total'] ?? "0";

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox("Income", income, Colors.green),
              _summaryBox("Expenses", expenses, Colors.red[600]!),
              _summaryBox("Total", total, Colors.black),
            ],
          );
        }
        return Container();
      },
    );
  }
}