import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MiniCloudApp());
}

class MiniCloudApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Cloud',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
