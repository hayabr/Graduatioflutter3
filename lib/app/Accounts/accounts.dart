import 'package:flutter/material.dart';
import 'package:managermoney/app/Accounts/addAccounts.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';
import 'package:managermoney/widgets/BottomNavBar.dart';
import 'package:managermoney/widgets/Widgets%20Accounts/accountSummary.dart';
import 'package:managermoney/widgets/Widgets%20Accounts/account_list.dart';

class Accounts extends StatefulWidget {
  const Accounts({super.key});

  @override
  _AccountsState createState() => _AccountsState();
}

class _AccountsState extends State<Accounts> {
  int _selectedIndex = 2;

  // تغيير الاختيار في شريط التنقل السفلي
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: SizedBox.shrink(),
        flexibleSpace: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 30, left: 10),
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
                        if (value == "Add") {
                          // الانتقال إلى صفحة إضافة حساب
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAccount(),
                            ),
                          );
                        } else if (value == "Delete") {
                          print("Delete selected");
                        } else if (value == "Modify Account") {
                          print("Modify Account selected");
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(value: "Add", child: Text("Add", style: TextStyle(fontSize: 18))),
                      //  PopupMenuItem(value: "Delete", child: Text("Delete", style: TextStyle(fontSize: 18))),
                      //  PopupMenuItem(value: "Modify Account", child: Text("Modify Account", style: TextStyle(fontSize: 18))),
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AccountSummary()  // استدعاء حسابات المستخدم
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: AccountsList(), // عرض قائمة الحسابات
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // دالة لإظهار تفاصيل الحسابات (مثال)
  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, color: color),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
