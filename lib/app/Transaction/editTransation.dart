import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:managermoney/app/Transaction/home.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:intl/intl.dart'; // استيراد مكتبة intl لتنسيق التاريخ

class UpdateTransaction extends StatefulWidget {
  final Map<String, dynamic> transaction;

  UpdateTransaction({required this.transaction});

  @override
  _UpdateTransactionState createState() => _UpdateTransactionState();
}

class _UpdateTransactionState extends State<UpdateTransaction> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // حقل التاريخ

  String _selectedAccount = '';
  String _selectedType = 'income'; // Default transaction type
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> userAccounts = [];
  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAccounts();
    _fetchCategories();
    _loadTransactionData();
  }

  void _loadTransactionData() {
    setState(() {
      _amountController.text = widget.transaction['amount']?.toString() ?? '0.00'; // قيمة افتراضية إذا كانت null
      _noteController.text = widget.transaction['note'] ?? ''; // قيمة افتراضية إذا كانت null
      _selectedType = widget.transaction['type'] ?? 'income'; // قيمة افتراضية إذا كانت null
      _selectedCategory = widget.transaction['category_id']?.toString() ?? ''; // قيمة افتراضية إذا كانت null
      _selectedAccount = widget.transaction['account_id']?.toString() ?? ''; // قيمة افتراضية إذا كانت null

      // تحقق من أن تاريخ المعاملة غير null
      if (widget.transaction['transaction_date'] != null) {
        _selectedDate = DateTime.parse(widget.transaction['transaction_date']);
      } else {
        _selectedDate = DateTime.now(); // قيمة افتراضية إذا كانت null
      }

      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
  }

  Future<void> _fetchUserAccounts() async {
    String userId = userController.getUserId();
    var response = await crud.postRequest(linkViewAccount, {"user_id": userId});
    if (response != null && response['status'] == "success") {
      setState(() {
        userAccounts = List<Map<String, dynamic>>.from(response['data']);
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
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate); // Update the date text
      });
    }
  }

  Future<void> _updateTransaction() async {
    if (_formKey.currentState!.validate()) {
      String userId = userController.getUserId();
      try {
        var response = await crud.postRequest(linkUpdateTransaction, {
          "transaction_id": widget.transaction['id'],
          "user_id": userId,
          "account_id": _selectedAccount,
          "category_id": _selectedCategory,
          "amount": _amountController.text,
          "type": _selectedType,
          "note": _noteController.text,
          "transaction_date": _selectedDate.toIso8601String(), // Send the selected date
        });

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Transaction updated successfully");
          Get.offAll(Home());
        } else {
          Get.snackbar("Error", "Failed to update transaction");
        }
      } catch (e) {
        Get.snackbar("Error", "An error occurred while updating the transaction");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction Info"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedAccount.isNotEmpty ? _selectedAccount : null,
                decoration: InputDecoration(
                  labelText: 'Account',
                  labelStyle: TextStyle(fontSize: 16), // زيادة حجم الخط
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: userAccounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'].toString(),
                    child: Text(account['name'], style: TextStyle(fontSize: 16)), // زيادة حجم الخط
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAccount = newValue!;
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(fontSize: 16), // زيادة حجم الخط
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: TextStyle(fontSize: 16), // زيادة حجم الخط
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
                  labelStyle: TextStyle(fontSize: 16), // زيادة حجم الخط
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  DropdownMenuItem(value: 'income', child: Text('Income', style: TextStyle(fontSize: 16))),
                  DropdownMenuItem(value: 'expenses', child: Text('Expense', style: TextStyle(fontSize: 16))),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                    _selectedCategory = ''; // Reset category when type changes
                  });
                },
              ),
              SizedBox(height: 10),
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontSize: 16), // زيادة حجم الخط
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: Icon(Icons.category),
                ),
                items: (_selectedType == 'income' ? incomeCategories : expenseCategories)
                    .map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name'], style: TextStyle(fontSize: 16)), // زيادة حجم الخط
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Transaction Date',
                  labelStyle: TextStyle(fontSize: 16), // زيادة حجم الخط
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                style: TextStyle(fontSize: 16), // زيادة حجم الخط
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  labelStyle: TextStyle(fontSize: 16), // زيادة حجم الخط
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: TextStyle(fontSize: 16), // زيادة حجم الخط
                maxLines: 3,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Update", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}