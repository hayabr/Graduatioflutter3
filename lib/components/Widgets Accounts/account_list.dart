import 'package:flutter/material.dart';
import 'package:managermoney/components/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';

class AccountsList extends StatelessWidget {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  Future<dynamic> getAccounts() async {
    String userId = userController.getUserId();
    try {
      var response = await crud.postRequest(linkViewAccount, {
        "user_id": userId,
      });

      print("Raw Response: $response");

      if (response != null && response['status'] == "success") {
        return response;
      } else {
        print("Error retrieving accounts");
        return [];
      }
    } catch (e) {
      print("Error catch $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getAccounts(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No accounts found"));
        } else if (snapshot.hasData) {
          var data = snapshot.data['data'];
          if (data is List) {
            Map<String, List<Map<String, dynamic>>> groupedData = {};
            for (var item in data) {
              if (item is Map<String, dynamic>) {
                var group = item['group'] ?? "No Group";
                if (!groupedData.containsKey(group)) {
                  groupedData[group] = [];
                }
                groupedData[group]!.add(item);
              }
            }

            return ListView.builder(
              itemCount: groupedData.length,
              shrinkWrap: true,
              physics: ClampingScrollPhysics(), // تمكين التمرير
              itemBuilder: (context, index) {
                var group = groupedData.keys.elementAt(index);
                var accounts = groupedData[group]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 2.0), // تقليل padding
                      child: Text(
                        group,
                        style: TextStyle(
                          fontSize: 16, // تصغير حجم الخط
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      itemCount: accounts.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(), // تعطيل التمرير الداخلي
                      itemBuilder: (context, i) {
                        var account = accounts[i];
                        var name = account['name'] ?? "No Name";
                        var amount = account['amount'] ?? "0";
                        var classification = account['classification'] ?? "No Classification";

                        // تحديد اللون بناءً على classification
                        Color amountColor = Colors.black; // لون افتراضي
                        if (classification == "Assets") {
                          amountColor = Colors.blue;
                        } else if (classification == "Liabilities") {
                          amountColor = Colors.red;
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0), // تقليل padding الداخلي
                          dense: true, // جعل ListTile أكثر إحكاما
                          title: Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(fontSize: 16), // تصغير حجم الخط
                              ),
                              SizedBox(width: 4), // مسافة صغيرة بين الاسم والقيمة
                              Text(
                                amount,
                                style: TextStyle(
                                  color: amountColor, // تطبيق اللون المحدد
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // تصغير حجم الخط
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: 0.5, // تقليل ارتفاع الخط الفاصل
                      thickness: 0.5, // تقليل سماكة الخط الفاصل
                    ),
                  ],
                );
              },
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