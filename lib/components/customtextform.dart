import 'package:flutter/material.dart';

class CustomtextFormSign extends StatelessWidget {
  final String hint;
  final TextEditingController mycontroller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? valid; // Optional validator

  const CustomtextFormSign({
    super.key, 
    required this.hint, 
    required this.mycontroller,
    this.isPassword = false, // Default: not a password field
    this.keyboardType = TextInputType.text, // Default keyboard type
    required this.valid, // Optional validation
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        validator: valid, // Validation support
        controller: mycontroller,
        obscureText: isPassword, // Hide text if it's a password
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 20), // Fixed fontWeight here
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          hintText: hint,
          alignLabelWithHint: true, // Align hint with field
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        textAlignVertical: TextAlignVertical.center, // Align text vertically
      ),
    );
  }
}
