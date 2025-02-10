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
  String _selectedGroup = 'Savings';
  String _selectedClassification = 'Assets';

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
          "classification": _selectedClassification,
        });

        print("Raw Response: $response");

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Account added successfully");
          Get.offAll(Accounts()); // الانتقال إلى صفحة AccountsList بعد الإضافة
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Account Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: InputDecoration(labelText: 'Group'),
                items: <String>['Savings', 'Investments', 'Expenses']
                    .map<DropdownMenuItem<String>>((String value) {
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
              DropdownButtonFormField<String>(
                value: _selectedClassification,
                decoration: InputDecoration(labelText: 'Classification'),
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addAccount,
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}