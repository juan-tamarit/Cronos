import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class CronometrosApp extends StatelessWidget {
  const CronometrosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronómetros',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}