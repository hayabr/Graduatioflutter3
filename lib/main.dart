import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ✅ تأكدي من استيراد GetX
import 'package:managermoney/app/Accounts/accounts.dart';
import 'package:managermoney/app/auth/login.dart';
import 'package:managermoney/app/auth/signup.dart';
import 'package:managermoney/app/auth/success.dart';
import 'package:managermoney/app/Transaction/home.dart';
import 'package:managermoney/controller/user_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(UserController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // ✅ استخدمي GetMaterialApp بدلاً من MaterialApp
      debugShowCheckedModeBanner: false,
      title: 'PHP Material App',
      initialRoute: "/login", 
      getPages: [
        GetPage(name: "/login", page: () => const Login()),
        GetPage(name: "/signup", page: () => const Signup()),
        GetPage(name: "/home", page: () => const Home()),
        GetPage(name: "/success", page: () => const Success()),
        GetPage(name: '/accounts', page: () => Accounts()),
      ],
    );
  }
}

