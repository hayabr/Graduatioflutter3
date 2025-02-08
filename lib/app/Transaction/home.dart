import 'package:flutter/material.dart';
import 'package:managermoney/components/BottomNavBar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> transactions = [
    {"amount": "DH ١٠٠,٠٠٠", "category": "Salary 💰"},
    {"amount": "DH ٥٠,٠٠٠", "category": "Culture 🎮"},
    {"amount": "DH ٤٠,٠٠٠", "category": "Pets 🐶"},
    {"amount": "DH ٥٠,٠٠٠", "category": "Difference"},
    {"amount": "DH ٨٨٨,٠٠٠", "category": "Fees"},
    {"amount": "DH ٥٠٠,٠٠٠", "category": "Transfer"},
  ];

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
  elevation: 0,
  automaticallyImplyLeading: false,
  title: Align(
    alignment: Alignment.centerLeft, // محاذاة العنوان لليسار
    child: Text(
      "Money Manager",
      style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.search, color: Colors.black),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.star_border, color: Colors.black),
      onPressed: () {},
    ),
  ],
),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // SliverToBoxAdapter with full-width divider
            SliverToBoxAdapter(
              child: Divider(
                thickness: 1, 
                height: 1, 
                color: Colors.grey, 
                indent: 0, 
                endIndent: 0, 
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryBox("Income", "DH ١٠٠,٠٠٠", Colors.blue),
                          _summaryBox("Expenses", "DH ٥٠,٠٠٠", Colors.red[600]!),
                          _summaryBox("Total", "DH ٥٠,٠٠٠", Colors.black),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(thickness: 1, height: 1, color: Colors.grey),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Transaction History',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'See All',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  var transaction = transactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(
                        transaction["category"],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Text(
                        transaction["amount"],
                        style: TextStyle(
                          color: transaction["amount"].contains("DH ١٠٠,٠٠٠")
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
                childCount: transactions.length,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
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
}