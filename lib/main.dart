
import 'package:field_visit_app/splashScreen/Splash_screen.dart';
import 'package:flutter/material.dart';
import 'Login Page/login.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'MyApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0755D9),
        ),
        useMaterial3: true,
      ),
      home:SplashScreen(),
    );
  }
}
