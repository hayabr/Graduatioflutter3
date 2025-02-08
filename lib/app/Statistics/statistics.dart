import 'package:flutter/material.dart';
import 'package:managermoney/components/BottomNavBar.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  int _selectedIndex = 1; 

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });}

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Text("Statistics"),
       leading: SizedBox.shrink(), //لاخفاء arrowback
    ),
    body: (Column(
     
    )),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,  // استدعاء الوظيفة عند الضغط على الأيقونات
      ),
    );
    
  }

}