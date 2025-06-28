import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_navigation.dart';
import 'home/home_screen.dart';
import 'scan/scan_screen.dart';
import 'alerts/alerts_screen.dart';
import 'education/education_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScanScreen(),
    const AlertsScreen(),
    const EducationScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'DisConX',
    'Network Scan',
    'Security Alerts',
    'Cybersecurity Education',
    'App Settings',
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNotificationTap() {
    // Navigate to alerts page
    _onTabSelected(2);
  }

  void _onSettingsTap() {
    // Navigate to settings page
    _onTabSelected(4);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: _titles[_currentIndex],
            showNotificationIcon: _currentIndex != 2, // Hide on alerts page
            showSettingsIcon: _currentIndex != 4, // Hide on settings page
            onNotificationTap: _onNotificationTap,
            onSettingsTap: _onSettingsTap,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}