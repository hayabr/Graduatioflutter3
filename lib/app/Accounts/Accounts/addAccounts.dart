import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:managermoney/app/Accounts/accounts.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';

class AddAccount extends StatefulWidget {
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
        });

        print("Raw Response: $response");

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Account added successfully");
          Get.offAll(Accounts()); // Navigate to Accounts page after adding
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
        title: Text("Add Account"),
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
                DropdownButtonFormField<String>(
                  value: _selectedGroup,
                  decoration: InputDecoration(
                    labelText: 'Group',
                    labelStyle: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
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
                    });
                  },
                ),
                SizedBox(height: 10),
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
                SizedBox(height: 10),
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
                SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 4, // Make the description field larger
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Change button color to red
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
      ),
    );
  }
}


