import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/services/permission_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final PermissionService _permissionService = PermissionService();
  
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

  SettingsProvider(this._prefs) {
    _loadSettings();
    _syncPermissionStatus();
  }

  void _loadSettings() {
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _locationEnabled = _prefs.getBool('locationEnabled') ?? true;
    _autoBlockSuspicious = _prefs.getBool('autoBlockSuspicious') ?? true;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    _backgroundScanEnabled = _prefs.getBool('backgroundScanEnabled') ?? true;
    _vpnSuggestionsEnabled = _prefs.getBool('vpnSuggestionsEnabled') ?? true;
    _language = _prefs.getString('language') ?? 'en';
    _networkHistoryDays = _prefs.getInt('networkHistoryDays') ?? 30;
    
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('isDarkMode', _isDarkMode);
    await _prefs.setBool('locationEnabled', _locationEnabled);
    await _prefs.setBool('autoBlockSuspicious', _autoBlockSuspicious);
    await _prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await _prefs.setBool('backgroundScanEnabled', _backgroundScanEnabled);
    await _prefs.setBool('vpnSuggestionsEnabled', _vpnSuggestionsEnabled);
    await _prefs.setString('language', _language);
    await _prefs.setInt('networkHistoryDays', _networkHistoryDays);
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  Future<void> toggleLocation() async {
    if (!_locationEnabled) {
      // If currently disabled, try to enable by requesting permission
      final permissionGranted = await _permissionService.requestLocationPermission();
      if (permissionGranted == PermissionStatus.granted) {
        _locationEnabled = true;
      } else {
        // Permission denied, keep location disabled
        _locationEnabled = false;
      }
    } else {
      // If currently enabled, just disable (we can't revoke permissions programmatically)
      _locationEnabled = false;
    }
    
    await _saveSettings();
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

  /// Sync settings with actual system permissions
  Future<void> _syncPermissionStatus() async {
    try {
      final locationStatus = await _permissionService.checkLocationPermission();
      final hasLocationPermission = locationStatus == PermissionStatus.granted;
      
      if (_locationEnabled && !hasLocationPermission) {
        // Setting is enabled but permission is denied - update setting
        _locationEnabled = false;
        await _saveSettings();
        notifyListeners();
      }
    } catch (e) {
      // Ignore permission check errors during initialization
    }
  }

  /// Get current permission status for location
  Future<PermissionStatus> getLocationPermissionStatus() async {
    return await _permissionService.checkLocationPermission();
  }

  /// Check if location services are actually available
  Future<bool> isLocationActuallyEnabled() async {
    final status = await getLocationPermissionStatus();
    return status == PermissionStatus.granted && _locationEnabled;
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    
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