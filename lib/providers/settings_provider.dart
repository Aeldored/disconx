import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Settings state
  bool _isDarkMode = false;
  bool _locationEnabled = true;
  bool _autoBlockSuspicious = true;
  bool _notificationsEnabled = true;
  bool _backgroundScanEnabled = true;
  bool _vpnSuggestionsEnabled = true;
  String _language = 'en';
  int _networkHistoryDays = 30;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get locationEnabled => _locationEnabled;
  bool get autoBlockSuspicious => _autoBlockSuspicious;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get backgroundScanEnabled => _backgroundScanEnabled;
  bool get vpnSuggestionsEnabled => _vpnSuggestionsEnabled;
  String get language => _language;
  int get networkHistoryDays => _networkHistoryDays;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _locationEnabled = prefs.getBool('locationEnabled') ?? true;
    _autoBlockSuspicious = prefs.getBool('autoBlockSuspicious') ?? true;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _backgroundScanEnabled = prefs.getBool('backgroundScanEnabled') ?? true;
    _vpnSuggestionsEnabled = prefs.getBool('vpnSuggestionsEnabled') ?? true;
    _language = prefs.getString('language') ?? 'en';
    _networkHistoryDays = prefs.getInt('networkHistoryDays') ?? 30;
    
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('locationEnabled', _locationEnabled);
    await prefs.setBool('autoBlockSuspicious', _autoBlockSuspicious);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('backgroundScanEnabled', _backgroundScanEnabled);
    await prefs.setBool('vpnSuggestionsEnabled', _vpnSuggestionsEnabled);
    await prefs.setString('language', _language);
    await prefs.setInt('networkHistoryDays', _networkHistoryDays);
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  void toggleLocation() {
    _locationEnabled = !_locationEnabled;
    _saveSettings();
    notifyListeners();
  }

  void toggleAutoBlock() {
    _autoBlockSuspicious = !_autoBlockSuspicious;
    _saveSettings();
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _saveSettings();
    notifyListeners();
  }

  void toggleBackgroundScan() {
    _backgroundScanEnabled = !_backgroundScanEnabled;
    _saveSettings();
    notifyListeners();
  }

  void toggleVpnSuggestions() {
    _vpnSuggestionsEnabled = !_vpnSuggestionsEnabled;
    _saveSettings();
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    _saveSettings();
    notifyListeners();
  }

  void setNetworkHistoryDays(int days) {
    _networkHistoryDays = days;
    _saveSettings();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Reset to defaults
    _isDarkMode = false;
    _locationEnabled = true;
    _autoBlockSuspicious = true;
    _notificationsEnabled = true;
    _backgroundScanEnabled = true;
    _vpnSuggestionsEnabled = true;
    _language = 'en';
    _networkHistoryDays = 30;
    
    notifyListeners();
  }
}