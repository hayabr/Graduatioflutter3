import 'package:flutter/material.dart';
import 'package:managermoney/components/BottomNavBar.dart';

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
      appBar: AppBar(
        leading: SizedBox.shrink(),
        // تغيير العنوان ليظهر في أقصى اليسار باستخدام flexibleSpace
        flexibleSpace: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 30, left: 20),
            child: Text(
              'Accounts',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10), // المسافة بين الأيقونة وحافة الشاشة
            child: IconTheme(
              data: IconThemeData(color: Colors.black.withOpacity(0.7)), // جعل الأيقونة أغمق
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  print("تم اختيار: $value");
               //   Navigator.of(context).pushNamedAndRemoveUntil("home", (route)=>false);
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(value: "Add ", child: Text("Add ",style: TextStyle(fontSize: 18),)),
                 // PopupMenuItem(value: "Show/Hide", child: Text("Show/Hide",style: TextStyle(fontSize: 18),)),
                  PopupMenuItem(value: "Delete", child: Text("Delete",style: TextStyle(fontSize: 18),)),
                  PopupMenuItem(value: "Modify Account", child: Text("Modify Account",style: TextStyle(fontSize: 18),)),
                ],
                icon: Icon(Icons.more_vert),
                offset: Offset(0, 40), // المسافة بين الأيقونة والقائمة
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(), // الـ Divider الأول بعد الـ AppBar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Assets', '10,000', Colors.blue),
                _buildSummaryItem('Liabilities', '0,000', Colors.red),
                _buildSummaryItem('Total', '0,000', Colors.black),
              ],
            ),
          ),
          Divider(), // الـ Divider الثاني بين المحتويات
          Expanded(
            child: ListView(
              children: [
                _buildAccountItem('Cash', 'DH 10,000', Colors.blue),
                _buildAccountItem('Cash from Ahmed', 'DH 10,000', Colors.blue),
                _buildAccountItem('Loan', 'DH 5,000', Colors.red),
                _buildAccountItem('Family Loan', 'DH 5,000', Colors.red),
              ],
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

  Widget _buildAccountItem(String name, String amount, Color color) {
    return ListTile(
      title: Text(name, style: TextStyle(fontSize: 16)),
      leading: Text(
        amount,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Accounts(),
  ));
}
