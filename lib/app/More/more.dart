import 'package:flutter/material.dart';
import 'package:managermoney/components/BottomNavBar.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _MoreState();
}

class _MoreState extends State<More> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // تغيير اللون هنا إذا أردت
        automaticallyImplyLeading: false, // إزالة السهم الخلفي
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // محاذاة العنوان لليسار
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16), // تحكم في المسافة من اليسار
              child: Text(
                "More",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200], // تدرج لوني ناعم
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20), // حواف مستديرة بشكل أفضل
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // ظل خفيف
              spreadRadius: 3,
              blurRadius: 6,
              offset: Offset(0, 4), // تحريك الظل
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed("login");
              },
              icon: Icon(Icons.exit_to_app, color: Colors.white), // إضافة أيقونة
              label: Text(
                "Log Out",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                iconColor: Colors.blue, // لون الزر
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5, // إضافة تأثير الظل للزر
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped, // استدعاء الوظيفة عند الضغط على الأيقونات
      ),
    );
  }
}
