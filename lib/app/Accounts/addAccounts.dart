import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduationproject/app/Accounts/accounts.dart';
import 'package:graduationproject/connstants/linkApi.dart';
import 'package:graduationproject/controller/user_controller.dart';
import 'package:graduationproject/widgets/crud.dart';


class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

  @override
  _AddAccountState createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedGroup = 'Savings'; // Default group value
  String _selectedClassification = 'Assets'; // Default classification value

  Future<void> _addAccount() async {
    if (_formKey.currentState!.validate()) {
      String userId = userController.getUserId();

      try {
        var response = await crud.postRequest(linkAddAccount, {
          "user_id": userId,
          "group": _selectedGroup,
          "name": _nameController.text,
          "amount": _amountController.text,
          "description": _descriptionController.text,
          "classification": _selectedClassification, // إرسال التصنيف إلى الخادم
        });

        print("Raw Response: $response");

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Account added successfully");
          Get.offAll(const Accounts()); // Navigate to Accounts page after adding
        } else {
          Get.snackbar("Error", "Failed to add account");
        }
      } catch (e) {
        print("Error catch $e");
        Get.snackbar("Error", "An error occurred while adding the account");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Account"),
      ),
      body: Directionality(
        textDirection: TextDirection.ltr, // Set text direction to LTR
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown for Group
                DropdownButtonFormField<String>(
                  value: _selectedGroup,
                  decoration: InputDecoration(
                    labelText: 'Group',
                    labelStyle: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: <String>[
                    'Savings',
                    'Investments',
                    'Cash',
                    'Card',
                    'Debit Card',
                    'Overdrafts',
                    'Insurance',
                    'Loan',
                    'Others',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGroup = newValue!;
                      // تحديث التصنيف تلقائيًا بناءً على المجموعة
                      if (_selectedGroup == 'Cash' || _selectedGroup == 'Card' || _selectedGroup == 'Debit Card' || _selectedGroup == 'Savings' || _selectedGroup == 'Investments') {
                        _selectedClassification = 'Assets';
                      } else if (_selectedGroup == 'Overdrafts' || _selectedGroup == 'Insurance' || _selectedGroup == 'Loan') {
                        _selectedClassification = 'Liabilities';
                      } else {
                        _selectedClassification = 'Assets'; // Default value
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Dropdown for Classification
                DropdownButtonFormField<String>(
                  value: _selectedClassification,
                  decoration: InputDecoration(
                    labelText: 'Classification',
                    labelStyle: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: <String>['Assets', 'Liabilities']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedClassification = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Account Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Amount Field
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

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 4, // Make the description field larger
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Change button color to red
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
      ),
    );
  }
}