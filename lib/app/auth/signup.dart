import 'package:flutter/material.dart';

import 'package:managermoney/connstants/linkApi.dart';
import 'package:managermoney/widgets/crud.dart';
import 'package:managermoney/widgets/customtextform.dart';
import 'package:managermoney/widgets/valid.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignUpState();
}

class _SignUpState extends State<Signup> {
  GlobalKey <FormState> formstate= GlobalKey();
  
  Crud _crud = Crud();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController username = TextEditingController();

 Signup () async {
  if (formstate.currentState!.validate()){
    var response = await _crud.postRequest(linkSignUp, {
    "username": username.text,
    "email": email.text,
    "password": password.text,
  });

  print("Response: $response"); // ✅ طباعة الاستجابة للتحقق

  if (response != null && response['status'] == "success") {
    Navigator.of(context).pushNamedAndRemoveUntil("success", (route) => false);
  } else {
    print("Sign up failed! Response: $response");
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
                
                key: formstate,// ✅ Added Form widget
                child: Column(
                  
                  children: [
                    
                    const SizedBox(height: 40),
                    Image.asset(
                      "lib/assets/272889.png",
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                     CustomtextFormSign(
                      valid: (val){
                        return validInput(val!, 3,20);
                      },
                      key: UniqueKey(),
                      hint: "username",
                      mycontroller: username,
                    ),
                     const SizedBox(height: 1),
                    CustomtextFormSign(
                       valid: (val){
                        return validInput(val!, 5,40);
                      },
                      key: UniqueKey(),
                      hint: "Email",
                      mycontroller: email,
                    ),
                    const SizedBox(height: 1),
                    CustomtextFormSign(
                       valid: (val){
                        return validInput(val!, 3,10);
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
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                      shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  
                ),
                      onPressed: () async {
                        await Signup() ;
                       
                      },
                      child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                      
                    ),
                    const SizedBox(height: 10),
   
                    InkWell(
                      child: const Text("Login", style: TextStyle(color: Color.fromARGB(255, 100, 93, 12), fontSize: 18)),
                      onTap: () {
                        Navigator.of(context).pushNamed("login");
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
