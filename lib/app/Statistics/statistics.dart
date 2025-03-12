import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:managermoney/app/Accounts/accounts.dart';
import 'package:managermoney/app/More/more.dart';
import 'package:managermoney/app/Transaction/home.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:managermoney/widgets/BottomNavBar.dart'; // تأكد من استيراد BottomNavBar
import 'package:managermoney/app/Transaction/addTransaction.dart'; // إذا كنت تريد إضافة FloatingActionButton

class Statistics extends StatefulWidget {
  @override
  _StatisticsState createState() => _StatisticsState();
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
  int _selectedIndex = 1; // أيقونة الإحصائيات لها index = 1

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
      print("Response: $response"); // طباعة الاستجابة للتأكد من البيانات

      if (response != null && response['status'] == "success") {
        if (response['data'] is List) {
          // إذا كانت البيانات قائمة
          List<dynamic> dataList = response['data'];
          _processListData(dataList);
        } else if (response['data'] is Map) {
          // إذا كانت البيانات خريطة
          Map<String, dynamic> dataMap = response['data'];
          _processMapData(dataMap);
        } else {
          print("Unknown data structure");
        }
      } else {
        print("No data found or status is not success");
      }
    } catch (e) {
      print("Error fetching statistics: $e");
    }
  }

  void _processListData(List<dynamic> dataList) async {
    Map<String, double> incomeDataWithNames = {};
    Map<String, double> expenseDataWithNames = {};

    for (var item in dataList) {
      if (item['type'] == 'income') {
        var categoryData = await _fetchCategoryData(item['category_id']);
        if (categoryData != null) {
          incomeDataWithNames["${categoryData['name']} ${categoryData['icon']}"] = (item['amount'] as num).toDouble();
        }
      } else if (item['type'] == 'expense') {
        var categoryData = await _fetchCategoryData(item['category_id']);
        if (categoryData != null) {
          expenseDataWithNames["${categoryData['name']} ${categoryData['icon']}"] = (item['amount'] as num).toDouble();
        }
      }
    }

    setState(() {
      totalIncome = incomeDataWithNames.values.fold(0, (prev, amount) => prev + amount);
      totalExpenses = expenseDataWithNames.values.fold(0, (prev, amount) => prev + amount);
      incomeData = incomeDataWithNames;
      expenseData = expenseDataWithNames;
    });

    print("Income Data: $incomeDataWithNames"); // طباعة بيانات الدخل
    print("Expense Data: $expenseDataWithNames"); // طباعة بيانات المصروفات
  }

  void _processMapData(Map<String, dynamic> dataMap) async {
    Map<String, double> incomeDataWithNames = {};
    Map<String, double> expenseDataWithNames = {};

    // جلب أسماء الفئات والأيقونات لبيانات الدخل
    if (dataMap['income_percentages'] is Map) {
      for (var entry in (dataMap['income_percentages'] as Map<String, dynamic>).entries) {
        var categoryData = await _fetchCategoryData(entry.key);
        if (categoryData != null) {
          incomeDataWithNames["${categoryData['name']} ${categoryData['icon']}"] = (entry.value as num).toDouble();
        }
      }
    }

    // جلب أسماء الفئات والأيقونات لبيانات المصروفات
    if (dataMap['expense_percentages'] is Map) {
      for (var entry in (dataMap['expense_percentages'] as Map<String, dynamic>).entries) {
        var categoryData = await _fetchCategoryData(entry.key);
        if (categoryData != null) {
          expenseDataWithNames["${categoryData['name']} ${categoryData['icon']}"] = (entry.value as num).toDouble();
        }
      }
    }

    setState(() {
      totalIncome = (dataMap['total_income'] as num?)?.toDouble() ?? 0.0;
      totalExpenses = (dataMap['total_expenses'] as num?)?.toDouble() ?? 0.0;
      incomeData = incomeDataWithNames;
      expenseData = expenseDataWithNames;
    });

    print("Income Data: $incomeDataWithNames"); // طباعة بيانات الدخل
    print("Expense Data: $expenseDataWithNames"); // طباعة بيانات المصروفات
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

    // التنقل بين الصفحات
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
        break;
      case 1:
        // الصفحة الحالية (الإحصائيات)
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Accounts()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => More()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Statistics"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
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
                ),
                Text("Statistics", style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showIncome = true;
                    });
                  },
                  child: Text(
                    "Income",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: showIncome ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showIncome = false;
                    });
                  },
                  child: Text(
                    "Expenses",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: !showIncome ? Colors.red : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            PieChart(
              dataMap: showIncome
                  ? (incomeData.isNotEmpty ? incomeData : {"No Data": 1})
                  : (expenseData.isNotEmpty ? expenseData : {"No Data": 1}),
              animationDuration: Duration(milliseconds: 800),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 2.5,
              chartType: ChartType.ring,
              legendOptions: LegendOptions(
                showLegends: true,
                legendPosition: LegendPosition.right,
              ),
              chartValuesOptions: ChartValuesOptions(
                showChartValues: true,
                showChartValuesInPercentage: true,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: (showIncome ? incomeData : expenseData).isNotEmpty
                  ? ListView(
                      children: (showIncome ? incomeData : expenseData)
                          .entries
                          .map((entry) => _buildExpenseItem(entry.key, entry.value))
                          .toList(),
                    )
                  : Center(child: Text("There is no Data")),
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

  Widget _buildExpenseItem(String category, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(
                  text: "${amount.toStringAsFixed(2)}%",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "   "), // زيادة المسافة بين النسبة واسم الفئة
                TextSpan(text: category),
              ],
            ),
          ),
        ],
      ),
    );
  }
}