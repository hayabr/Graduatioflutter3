import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:graduationproject/app/Accounts/accounts.dart';
import 'package:graduationproject/app/More/more.dart';
import 'package:graduationproject/app/Transaction/home.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/BottomNavBar.dart';
import 'package:graduationproject/widgets/crud.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();
  Map<String, double> incomeData = {};
  Map<String, double> expenseData = {};
  double totalIncome = 0;
  double totalExpenses = 0;
  String selectedPeriod = "Monthly";
  bool showIncome = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    String userId = userController.getUserId();
    String link;

    switch (selectedPeriod) {
      case "Daily":
        link = linkViewStaticDaily;
        break;
      case "Weekly":
        link = linkViewStaticWeekly;
        break;
      case "Monthly":
        link = linkViewStaticMonthly;
        break;
      case "Yearly":
        link = linkViewStaticYearly;
        break;
      default:
        link = linkViewStaticMonthly;
    }

    try {
      var response = await crud.postRequest(link, {"user_id": userId});
      if (response != null && response['status'] == "success") {
        if (response['data'] is Map) {
          _processMapData(response['data']);
        }
      }
    } catch (e) {
      print("Error fetching statistics: $e");
    }
  }

  void _processMapData(Map<String, dynamic> dataMap) async {
    Map<String, double> incomeDataWithNames = {};
    Map<String, double> expenseDataWithNames = {};

    if (dataMap['income_percentages'] is Map) {
      for (var entry in (dataMap['income_percentages'] as Map<String, dynamic>).entries) {
        var categoryData = await _fetchCategoryData(entry.key);
        if (categoryData != null) {
          incomeDataWithNames["${categoryData['name']} ${categoryData['icon']}"] =
              (entry.value as num).toDouble();
        }
      }
    }

    if (dataMap['expense_percentages'] is Map) {
      for (var entry in (dataMap['expense_percentages'] as Map<String, dynamic>).entries) {
        var categoryData = await _fetchCategoryData(entry.key);
        if (categoryData != null) {
          expenseDataWithNames["${categoryData['name']} ${categoryData['icon']}"] =
              (entry.value as num).toDouble();
        }
      }
    }

    setState(() {
      totalIncome = (dataMap['total_income'] as num?)?.toDouble() ?? 0.0;
      totalExpenses = (dataMap['total_expenses'] as num?)?.toDouble() ?? 0.0;
      incomeData = incomeDataWithNames;
      expenseData = expenseDataWithNames;
    });
  }

  Future<Map<String, dynamic>?> _fetchCategoryData(String categoryId) async {
    try {
      var response = await crud.postRequest(linkGetCategory, {"category_id": categoryId});
      if (response != null && response['status'] == "success") {
        return response['data'];
      }
    } catch (e) {
      print("Error fetching category data: $e");
    }
    return null;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Accounts()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const More()));
        break;
    }
  }

  List<BarChartGroupData> _buildBarChartData(List<String> keys, Map<String, double> data) {
    return data.entries.toList().asMap().entries.map((entry) {
      int index = entry.key;
      double percentage = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: percentage,
            width: 22,
            borderRadius: BorderRadius.circular(6),
            color: showIncome ? Colors.blue : Colors.red,
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = showIncome ? incomeData : expenseData;
    final dataKeys = currentData.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: selectedPeriod,
              items: const [
                DropdownMenuItem(value: "Daily", child: Text("Daily")),
                DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                DropdownMenuItem(value: "Yearly", child: Text("Yearly")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPeriod = value!;
                  _fetchStatistics();
                });
              },
              underline: Container(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => setState(() => showIncome = true),
                  child: Text(
                    "Income",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: showIncome ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => showIncome = false),
                  child: Text(
                    "Expenses",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: !showIncome ? Colors.red : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            currentData.isNotEmpty
                ? SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        barGroups: _buildBarChartData(dataKeys, currentData),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < dataKeys.length) {
                                  return Text(
                                    dataKeys[value.toInt()].split(' ').first,
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 42,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return Text("${value.toInt()}%");
                              },
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
                  )
                : const Center(child: Text("There is no Data")),
            const SizedBox(height: 20),
            Expanded(
              child: currentData.isNotEmpty
                  ? ListView(
                      children: currentData.entries
                          .map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontSize: 16)),
                                    Text("${entry.value.toStringAsFixed(2)}%",
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ))
                          .toList(),
                    )
                  : const Center(child: Text("There is no Data")),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
