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
  int touchedIndex = -1;

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
      setState(() {
        incomeData = {};
        expenseData = {};
        totalIncome = 0;
        totalExpenses = 0;
      });
      var response = await crud.postRequest(link, {"user_id": userId});
      if (response != null && response['status'] == "success") {
        if (response['data'] is Map) {
          _processMapData(response['data']);
        } else {
          Get.snackbar("Error", "Invalid data format received",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12);
        }
      } else {
        Get.snackbar("Error", "Failed to load statistics",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12);
      }
    } catch (e) {
      print("Error fetching statistics: $e");
      Get.snackbar("Error", "Failed to load statistics: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    }
  }

  void _processMapData(Map<String, dynamic> dataMap) async {
    Map<String, double> incomeDataWithNames = {};
    Map<String, double> expenseDataWithNames = {};

    if (dataMap['income_percentages'] is Map) {
      for (var entry in (dataMap['income_percentages'] as Map<String, dynamic>).entries) {
        var categoryData = await _fetchCategoryData(entry.key);
        if (categoryData != null) {
          incomeDataWithNames["${categoryData['name']} ${categoryData['icon'] ?? ''}"] =
              (entry.value as num).toDouble();
        }
      }
    }

    if (dataMap['expense_percentages'] is Map) {
      for (var entry in (dataMap['expense_percentages'] as Map<String, dynamic>).entries) {
        var categoryData = await _fetchCategoryData(entry.key);
        if (categoryData != null) {
          expenseDataWithNames["${categoryData['name']} ${categoryData['icon'] ?? ''}"] =
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

  List<PieChartSectionData> _buildPieChartData(Map<String, double> data) {
    if (data.isEmpty) {
      return [];
    }

    final colors = showIncome
        ? [
            Colors.blue.shade300,
            Colors.blue.shade500,
            Colors.blue.shade700,
            Colors.blue.shade900,
            Colors.cyan.shade300,
          ]
        : [
            Colors.red.shade300,
            Colors.red.shade500,
            Colors.red.shade700,
            Colors.red.shade900,
            Colors.pink.shade300,
          ];

    int index = 0;
    return data.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 120.0 : 100.0;
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Text(
          entry.key.split(' ').first,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = showIncome ? incomeData : expenseData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Statistics",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false, // Changed to false to align title to the left
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Switch
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton(
                    label: "Income",
                    isSelected: showIncome,
                    color: Colors.blue,
                    onTap: () => setState(() => showIncome = true),
                  ),
                  _buildToggleButton(
                    label: "Expenses",
                    isSelected: !showIncome,
                    color: Colors.red,
                    onTap: () => setState(() => showIncome = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Total Amount
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showIncome ? "Total Income" : "Total Expenses",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "\$${showIncome ? totalIncome.toStringAsFixed(2) : totalExpenses.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: showIncome ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pie Chart
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: currentData.isNotEmpty
                    ? SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartData(currentData),
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "No Data Available",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Category List
            Text(
              "Categories",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            currentData.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      final entry = currentData.entries.elementAt(index);
                      final color = (showIncome
                              ? [
                                  Colors.blue.shade300,
                                  Colors.blue.shade500,
                                  Colors.blue.shade700,
                                  Colors.blue.shade900,
                                  Colors.cyan.shade300,
                                ]
                              : [
                                  Colors.red.shade300,
                                  Colors.red.shade500,
                                  Colors.red.shade700,
                                  Colors.red.shade900,
                                  Colors.pink.shade300,
                                ])[index % 5];

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Text(
                              entry.key.split(' ').last.isNotEmpty ? entry.key.split(' ').last : '📊',
                              style: TextStyle(color: color, fontSize: 16),
                            ),
                          ),
                          title: Text(
                            entry.key.split(' ').first,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            "${entry.value.toStringAsFixed(2)}%",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      "No categories to display",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
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

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}