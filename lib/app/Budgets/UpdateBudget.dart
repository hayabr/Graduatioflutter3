import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/app/Budgets/budget.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/crud.dart';


class UpdateBudget extends StatefulWidget {
  final Map<String, dynamic> budgetData;

  const UpdateBudget({super.key, required this.budgetData});

  @override
  _UpdateBudgetState createState() => _UpdateBudgetState();
}

class _UpdateBudgetState extends State<UpdateBudget> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late String _selectedCategory;

  final List<String> _categories = [
    'Food', 'Pets', 'Transport', 'Culture', 'Social Life',
    'Health', 'Education', 'Household', 'Beauty',
    'Apparel', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.budgetData['amount']);
    
    // Normalize category name from backend (e.g., "food" -> "Food")
    final initialCategory = widget.budgetData['category_name']?.toString() ?? 'Food';
    
    // Ensure the category selected is valid
    _selectedCategory = _categories.firstWhere(
      (category) => category.toLowerCase() == initialCategory.toLowerCase(),
      orElse: () => 'Food'
    );
  }

  Future<void> _updateBudget() async {
    if (_formKey.currentState!.validate()) {
      try {
        var response = await crud.postRequest(linkEditBudget, {
          "budget_id": widget.budgetData['id'],
          "user_id": userController.getUserId(),
          "category_id": _getCategoryId(_selectedCategory).toString(),
          "amount": _amountController.text,
          "start_date": widget.budgetData['start_date'] ?? '',
          "end_date": widget.budgetData['end_date'] ?? ''
        });

        print("Update Response: $response"); // Debugging

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Budget updated successfully");
          Get.offAll(() => const BudgetPage());
        } else {
          Get.snackbar("Error", response?['message'] ?? "Failed to update budget");
        }
      } catch (e) {
        print("Update Error: $e"); // Debugging
        Get.snackbar("Error", "An error occurred while updating the budget");
      }
    }
  }

  Future<void> _deleteBudget() async {
  bool confirmDelete = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Budget"),
      content: const Text("Are you sure you want to delete this budget?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmDelete == true) {
    try {
      var response = await crud.postRequest(linkDeleteBudget, {
        "budget_id": widget.budgetData['id'], // تأكد من إرسال الـ budget_id الصحيح
        "user_id": userController.getUserId(),
      });

      print("Delete Response: $response"); // طباعة الاستجابة لفحصها

      if (response != null && response['status'] == "success") {
        Get.snackbar("Success", "Budget deleted successfully");
        Get.offAll(() => const BudgetPage());
      } else {
        Get.snackbar("Error", response?['message'] ?? "Failed to delete budget");
      }
    } catch (e) {
      print("Delete Error: $e"); // طباعة الأخطاء
      Get.snackbar("Error", "An error occurred while deleting the budget");
    }
  }
}


  int _getCategoryId(String category) {
    switch (category) {
      case 'Pets': return 1;
      case 'Social Life': return 2;
      case 'Food': return 3;
      case 'Household': return 4;
      case 'Culture': return 5;
      case 'Transport': return 6;
      case 'Health': return 7;
      case 'Beauty': return 8;
      case 'Apparel': return 9;
      case 'Gift': return 10;
      case 'Education': return 11;
      case 'Other': return 12;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Details"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.grey[800]),
            onPressed: _deleteBudget,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _categories.map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter amount';
                  if (double.tryParse(value) == null) return 'Enter valid number';
                  if (double.parse(value) <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Update Budget"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
