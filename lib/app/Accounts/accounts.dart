import 'package:flutter/material.dart';
import 'package:managermoney/components/BottomNavBar.dart';
import 'package:managermoney/components/Widgets%20Accounts/accountSummary.dart';
import 'package:managermoney/components/Widgets%20Accounts/account_list.dart';
import 'package:managermoney/components/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:get/get.dart';
 // استيراد الودجت الجديدة

class Accounts extends StatefulWidget {
  @override
  _AccountsState createState() => _AccountsState();
}

class _AccountsState extends State<Accounts> {
  int _selectedIndex = 2;

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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AccountSummary()
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: AccountsList(), // استدعاء الودجت الجديدة هنا
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

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