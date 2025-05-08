import 'package:flutter/material.dart';
import 'package:graduationproject/app/Accounts/accounts.dart';
import 'package:graduationproject/app/More/more.dart';
import 'package:graduationproject/app/Recommendation/recommendations.dart';
import 'package:graduationproject/app/Statistics/statistics.dart';
import 'package:graduationproject/app/Transaction/home.dart';

 // Add this import

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

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
          icon: Icon(Icons.account_balance_wallet, size: 28), // New recommendation icon
          label: "Accounts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up, size: 28),
          label: "Markets",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, size: 28),
          label: "profile",
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey.shade600,
      onTap: (index) {
        onItemTapped(index);

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Statistics()),
            );
            break;
          case 2: 
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Accounts()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StockRecommendationPage()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const More()),
            );
            break;
          default:
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
      elevation: 5,
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: const IconThemeData(
        color: Colors.red,
        size: 30,
      ),
      unselectedIconTheme: const IconThemeData(
        color: Colors.grey,
        size: 28,
      ),
    );
  }
}