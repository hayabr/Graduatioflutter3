import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/app/Budgets/budget.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/crud.dart';


class AddBudget extends StatefulWidget {
  const AddBudget({super.key});

  @override
  _AddBudgetState createState() => _AddBudgetState();
}

class _AddBudgetState extends State<AddBudget> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String _selectedCategory = 'Food'; // Default category value
  final String _selectedPeriod = 'Monthly'; // Default period value

  Future<void> _addBudget() async {
    if (_formKey.currentState!.validate()) {
      String userId = userController.getUserId();

      // الحصول على category_id بناءً على الفئة المختارة
      int categoryId = getCategoryId(_selectedCategory);

      try {
        var response = await crud.postRequest(linkaddBudget, {
          "user_id": userId,
          "category_id": categoryId.toString(), // إضافة category_id
          "amount": _amountController.text,
          "description": _descriptionController.text,
          "start_date": _startDateController.text, // إضافة start_date
          "end_date": _endDateController.text, // إضافة end_date
          "period": _selectedPeriod, // Period (Monthly, Weekly, etc.)
        });

        print("Response from server: $response");

        if (response != null && response['status'] == "success") {
          // عرض التنبيه بنجاح العملية
          Get.snackbar(
            "Success", 
            "Budget added successfully", 
           snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white
          );

          // العودة إلى صفحة الميزانية بعد النجاح
          Future.delayed(const Duration(seconds: 1), () {
            Get.back();
            Get.to(const BudgetPage());   // الرجوع إلى الصفحة السابقة (الميزانية)
          });
        } else {
          // عرض التنبيه بفشل العملية
          Get.snackbar(
            "Error", 
            "Failed to add budget", 
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white
          );
        }
      } catch (e) {
        print("Error caught: $e");
        Get.snackbar(
          "Error", 
          "An error occurred while adding the budget", 
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
      }
    } else {
      // عرض التنبيه عند فشل التحقق من النموذج
      Get.snackbar(
        "Validation Error", 
        "Please fill all the required fields", 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white
      );
    }
  }

  int getCategoryId(String category) {
    switch (category) {
      case 'Pets':
        return 1;
      case 'Social Life':
        return 2;
      case 'Food':
        return 3;
      case 'Houshold':
        return 4;
      case 'Culture':
        return 5;
      case 'Transport':
        return 6;
      case 'Health':
        return 7;
      case 'Beauty':
        return 8;
      case 'Apparel':
        return 9;
      case 'Gift':
        return 10;
      case 'Education':
        return 11;
      case 'Other':
        return 12;
      default:
        return 0; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Budget"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: <String>[
                  'Food', 'Pets', 'Transport', 'Culture', 'Social Life', 'Entertainment', 'Health',
                  'Education', 'Houshold', 'Beauty', 'Apparel', 'Gift', 'Other',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
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
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
