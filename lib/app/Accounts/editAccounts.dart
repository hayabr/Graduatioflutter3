import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:managermoney/app/Accounts/accounts.dart';
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/connstants/linkApi.dart';

class UpdateAccount extends StatefulWidget {
  final Map<String, dynamic> accountData;

  UpdateAccount({required this.accountData});

  @override
  _UpdateAccountState createState() => _UpdateAccountState();
}

class _UpdateAccountState extends State<UpdateAccount> {
  final Crud crud = Crud();
  final UserController userController = Get.find<UserController>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedGroup;
  late String _selectedClassification;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accountData['name']);
    _amountController = TextEditingController(text: widget.accountData['amount']);
    _descriptionController = TextEditingController(text: widget.accountData['description']);
    _selectedGroup = widget.accountData['group'];
    _selectedClassification = widget.accountData['classification']; // استخراج التصنيف الحالي
  }

  Future<void> _updateAccount() async {
    if (_formKey.currentState!.validate()) {
      String userId = userController.getUserId();
      try {
        var response = await crud.postRequest(linkUpdateAccount, {
          "id": widget.accountData['id'],
          "user_id": userId,
          "group": _selectedGroup,
          "name": _nameController.text,
          "amount": _amountController.text,
          "description": _descriptionController.text,
          "classification": _selectedClassification, // إرسال التصنيف إلى الخادم
        });

        print("Raw Response: $response");

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Account updated successfully");
          Get.offAll(Accounts()); // Navigate to Accounts page after updating
        } else {
          Get.snackbar("Error", "Failed to update account");
        }
      } catch (e) {
        print("Error catch $e");
        Get.snackbar("Error", "An error occurred while updating the account");
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Show a confirmation dialog before deleting
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete this account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      String userId = userController.getUserId();
      try {
        var response = await crud.postRequest(linkDeleteAccount, {
          "id": widget.accountData['id'],
          "user_id": userId,
        });

        print("Raw Response: $response");

        if (response != null && response['status'] == "success") {
          Get.snackbar("Success", "Account deleted successfully");
          Get.offAll(Accounts()); // Navigate to Accounts page after deleting
        } else {
          Get.snackbar("Error", "Failed to delete account");
        }
      } catch (e) {
        print("Error catch $e");
        Get.snackbar("Error", "An error occurred while deleting the account");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Account Info"),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 13.0),
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.grey[800]),
              iconSize: 30,
              onPressed: _deleteAccount,
            ),
          ),
        ],
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
                SizedBox(height: 10),

                // Dropdown for Classification
                DropdownButtonFormField<String>(
                  value: _selectedClassification,
                  decoration: InputDecoration(
                    labelText: 'Classification',
                    labelStyle: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
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
                SizedBox(height: 10),

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
                SizedBox(height: 10),

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
                SizedBox(height: 10),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 4, // Make the description field larger
                ),
                SizedBox(height: 20),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Change button color to red
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
      ),
    );
  }
}