import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/app/Transaction/home.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/crud.dart';
import 'package:intl/intl.dart'; // استيراد مكتبة intl لتنسيق التاريخ

class UpdateTransaction extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const UpdateTransaction({super.key, required this.transaction});

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
          Get.offAll(const Home());
        } else {
          Get.snackbar("Error", "Failed to update transaction");
        }
      } catch (e) {
        Get.snackbar("Error", "An error occurred while updating the transaction");
      }
    }
  }

  Future<void> _deleteTransaction() async {
    bool confirmDelete = await Get.dialog(
      AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this transaction?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        String userId = userController.getUserId();
        var response = await crud.postRequest(linkDeleteTransaction, {
          "transaction_id": widget.transaction['id'],
          "user_id": userId,
        });

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Transaction deleted successfully");
          Get.offAll(const Home());
        } else {
          Get.snackbar("Error", "Failed to delete transaction");
        }
      } catch (e) {
        Get.snackbar("Error", "An error occurred while deleting the transaction");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Info"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete), // أيقونة الحذف
            onPressed: _deleteTransaction, // دالة الحذف
          ),
        ],
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
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: userAccounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'].toString(),
                    child: Text(account['name'], style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAccount = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: const TextStyle(fontSize: 16),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Transaction Type',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
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
              const SizedBox(height: 10),
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: const Icon(Icons.category),
                ),
                items: (_selectedType == 'income' ? incomeCategories : expenseCategories)
                    .map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name'], style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Transaction Date',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                style: const TextStyle(fontSize: 16),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Update", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}