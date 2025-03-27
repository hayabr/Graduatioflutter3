import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:managermoney/app/Notification/globalVariable.dart';
import 'package:managermoney/app/Transaction/home.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:intl/intl.dart';

class AddTransaction extends StatefulWidget {
  @override
  _AddTransactionState createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedAccount;
  String _selectedType = 'income';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> userAccounts = [];
  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAccounts();
    _fetchCategories();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  Future<void> _fetchUserAccounts() async {
    String userId = userController.getUserId();
    var response = await crud.postRequest(linkViewAccount, {"user_id": userId});
    if (response != null && response['status'] == "success") {
      setState(() {
        userAccounts = List<Map<String, dynamic>>.from(response['data']);
        if (userAccounts.isNotEmpty) {
          _selectedAccount = userAccounts.first['id'].toString();
        }
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      var responseIncome = await crud.postRequest(linkViewCategory, {"type": "income"});
      var responseExpenses = await crud.postRequest(linkViewCategory, {"type": "expenses"});

      if (responseIncome != null && responseIncome['status'] == "success") {
        setState(() {
          incomeCategories = List<Map<String, dynamic>>.from(responseIncome['data']);
        });
      }

      if (responseExpenses != null && responseExpenses['status'] == "success") {
        setState(() {
          expenseCategories = List<Map<String, dynamic>>.from(responseExpenses['data']);
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch categories");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _insertNotification(String message) async {
    try {
      String userId = userController.getUserId();
      var response = await crud.postRequest(linkinsertNotification, {
        "user_id": userId,
        "message": message,
      });

      if (response != null && response['status'] == "success") {
        NotificationGlobals.updateUnreadCount(
          NotificationGlobals.unreadNotificationsCount.value + 1);
      }
    } catch (e) {
      print("Error inserting notification: $e");
    }
  }

  Future<void> _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      String userId = userController.getUserId();
      try {
        var response = await crud.postRequest(linkAddTransaction, {
          "user_id": userId,
          "account_id": _selectedAccount ?? "",
          "category_id": _selectedCategory ?? "",
          "amount": _amountController.text,
          "type": _selectedType,
          "note": _noteController.text,
          "transaction_date": _selectedDate.toIso8601String(),
        });

        if (response != null && response['status'] == "success") {
          // Always insert success notification
          await _insertNotification("Transaction added: ${_amountController.text} ${_selectedType}");

          if (response.containsKey('message')) {
            // Insert budget exceeded notification
            await _insertNotification("Budget Alert: ${response['message']}");

            // Display the budget exceeded notification with an "OK" button at the top of the screen
            Get.snackbar(
              "Budget Exceeded",
              response['message'],
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () {
                  // Close the snackbar when the button is pressed
                  Get.back();
                },
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            );

            // No need to show "Success" notification here
          } else {
            // Show the success notification only if there is no budget issue
            Get.snackbar("Success", "Transaction added successfully");
          }
          Get.offAll(Home());
        } else {
          Get.snackbar("Error", "Failed to add transaction");
        }
      } catch (e) {
        Get.snackbar("Error", "An error occurred while adding the transaction");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Transaction"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedAccount,
                decoration: InputDecoration(
                  labelText: 'Account',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: userAccounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'].toString(),
                    child: Text(account['name'], style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAccount = newValue;
                  });
                },
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: TextStyle(fontSize: 16),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Transaction Type',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  DropdownMenuItem(value: 'income', child: Text('Income', style: TextStyle(fontSize: 16))),
                  DropdownMenuItem(value: 'expenses', child: Text('Expense', style: TextStyle(fontSize: 16))),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                    _selectedCategory = null;
                  });
                },
              ),
              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: Icon(Icons.category),
                ),
                items: (_selectedType == 'income' ? incomeCategories : expenseCategories)
                    .map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name'], style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Transaction Date',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                style: TextStyle(fontSize: 16),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: TextStyle(fontSize: 16),
                maxLines: 3,
              ),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
