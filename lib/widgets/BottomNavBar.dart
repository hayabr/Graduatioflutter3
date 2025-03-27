import 'package:flutter/material.dart';
import 'package:managermoney/app/Accounts/accounts.dart';
import 'package:managermoney/app/More/more.dart';
import 'package:managermoney/app/Statistics/statistics.dart';
import 'package:managermoney/app/Transaction/home.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt, size: 28),
          label: "Trans.",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart, size: 28),
          label: "Stats",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet, size: 28),
          label: "Accounts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz, size: 28),
          label: "More",
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey.shade600,
      onTap: (index) {
        // عندما يتم الضغط على الأيقونة
        onItemTapped(index);

        // إجراء التنقل حسب الأيقونة المحددة
        switch (index) {
          case 0:
            // عندما يتم الضغط على Trans.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
            break;
             case 1:
            // عندما يتم الضغط على Accounts
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Statistics()),
            );
            break;
          case 2:
            // عندما يتم الضغط على Accounts
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Accounts()),
            );
            break;
            case 3:
            // عندما يتم الضغط على Accounts
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => More()),
            );
            break;
          default:
            // لا حاجة للتنقل في الحالات الأخرى
            break;
        }
      },
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.orange,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
        color: Colors.grey,
      ),
      backgroundColor: Colors.white,
      elevation: 5, // الظل لجعل الشريط يبرز
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: const IconThemeData(
        color: Colors.red, // لون الأيقونة المحددة
        size: 30, // حجم الأيقونة المحددة
      ),
      unselectedIconTheme: const IconThemeData(
        color: Colors.grey, // لون الأيقونة غير المحددة
        size: 28, // حجم الأيقونة غير المحددة
      ),
    );
  }
}