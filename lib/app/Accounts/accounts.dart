import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:managermoney/components/BottomNavBar.dart';
import 'package:managermoney/components/Widgets%20Accounts/accountsItem.dart';
import 'package:managermoney/components/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';

class Accounts extends StatefulWidget {
  @override
  _AccountsState createState() => _AccountsState();
}

class _AccountsState extends State<Accounts> {
  Crud crud = Crud();
  final UserController userController = Get.find<UserController>(); // احضار UserController

  // دالة لاسترجاع الحسابات باستخدام الـ id
  getAccounts() async {
  String userId = userController.getUserId();
  try {
    var response = await crud.postRequest(linkViewAccount, {
      "user_id": userId,
    });

    print("Raw Response: $response"); // طباعة الاستجابة الخام

    if (response != null && response['status'] == "success") {
      return response;
    } else {
      print("Error retrieving accounts");
      return [];
    }
  } catch (e) {
    print("Error catch $e"); // طباعة الخطأ بالتفصيل
    return [];
  }
}

  int _selectedIndex = 2;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox.shrink(),
        flexibleSpace: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 50, left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accounts',
                  style: TextStyle(fontSize: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: IconTheme(
                    data: IconThemeData(color: Colors.black.withOpacity(0.7)),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        print("تم اختيار: $value");
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(value: "Add", child: Text("Add", style: TextStyle(fontSize: 18))),
                        PopupMenuItem(value: "Delete", child: Text("Delete", style: TextStyle(fontSize: 18))),
                        PopupMenuItem(value: "Modify Account", child: Text("Modify Account", style: TextStyle(fontSize: 18))),
                      ],
                      icon: Icon(Icons.more_vert),
                      offset: Offset(0, 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Assets', '10,000', Colors.blue),
                _buildSummaryItem('Liabilities', '0,000', Colors.red),
                _buildSummaryItem('Total', '0,000', Colors.black),
              ],
            ),
          ),
          Divider(),
      Expanded(
  child: FutureBuilder(
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
          return ListView.builder(
            itemCount: data.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              var item = data[i];
              if (item is Map<String, dynamic>) {
                // تأكد من أن العنصر يحتوي على الحقل "name"
                var name = item['name'] ?? "No Name"; // استخدام قيمة افتراضية إذا كان الحقل غير موجود
                var amount = item['amount'] ?? "0";
                var group = item['group'] ?? "No Group";
                var classification = item['classification'] ?? "No Classification";

                return ListTile(
                  title: Text(name), // عرض الاسم هنا
                  subtitle: Text("Amount: $amount, Group: $group, Classification: $classification"),
                );
              }
              return Text("Invalid data format");
            },
          );
        } else {
          return Center(child: Text("Invalid data format"));
        }
      }
      return Container(); // Fallback return
    },
  ),
),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
