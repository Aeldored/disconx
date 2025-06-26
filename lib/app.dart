import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';

class DiSConXApp extends StatelessWidget {
  const DiSConXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiSCon-X | DICT Secure Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}