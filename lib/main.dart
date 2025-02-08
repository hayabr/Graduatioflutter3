import 'package:flutter/material.dart';

import 'package:managermoney/app/auth/login.dart';
import 'package:managermoney/app/auth/signup.dart';
import 'package:managermoney/app/auth/success.dart';
import 'package:managermoney/app/Transaction/home.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PHP Material App',
      initialRoute: "login", // ✅ Ensure correct case
      routes: {
        "login": (context) => const Login(),
        "signup": (context) => const Signup(),
        "home": (context) => const Home(),
        "success": (context) => const Success(),
      
        
      },
    );
  }
}

