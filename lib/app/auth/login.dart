import 'package:flutter/material.dart';
import 'package:managermoney/connstants/linkApi.dart';
import 'package:awesome_dialog/awesome_dialog.dart'; //pub
import 'package:get/get.dart'; // استيراد GetX
import 'package:managermoney/controller/user_controller.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/widgets/customtextform.dart';
import 'package:managermoney/widgets/valid.dart';
 // استيراد UserController

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  GlobalKey<FormState> formstate = GlobalKey();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  Crud crud = Crud(); // ✅ Removed unnecessary `new` keyword
  final UserController userController = Get.put(UserController()); // استخدام GetX Controller

  login() async {
    if (formstate.currentState!.validate()) {
      var response = await crud.postRequest(linkLogin, {
        "email": email.text,
        "password": password.text
      });

      if (response['status'] == "success") {
        // تخزين الـ id باستخدام GetX
        userController.setUserId(response['data']['id'].toString());
        print('User ID saved in GetX: ${userController.userId.value}');
        
        Navigator.of(context).pushNamed("home");
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: "Login Failed",
          desc: "Invalid email or password!",
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Center(
              child: Form(
                key: formstate, // ✅ Added Form widget
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Image.asset(
                      "lib/assets/272889.png",
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 30),
                    CustomtextFormSign(
                      valid: (val) {
                        return validInput(val!, 3, 20);
                      },
                      key: UniqueKey(),
                      hint: "Email",
                      mycontroller: email,
                    ),
                    const SizedBox(height: 1),
                    CustomtextFormSign(
                      valid: (val) {
                        return validInput(val!, 3, 20);
                      },
                      key: UniqueKey(),
                      hint: "Password",
                      mycontroller: password,
                      isPassword: true,
                    ),
                    const SizedBox(height: 15),
                    MaterialButton(
                      color: const Color.fromARGB(255, 211, 74, 74),
                      textColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onPressed: () async {
                        await login(); // ✅ Fixed function call
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color.fromARGB(255, 100, 93, 12),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                         
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed("signup");
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
