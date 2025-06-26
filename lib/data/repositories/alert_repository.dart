import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/alert_model.dart';
import '../models/network_model.dart';
import '../services/firebase_service.dart';

class AlertRepository {
  final Dio _dio;
  final FirebaseService _firebaseService;
  final SharedPreferences _prefs;

  AlertRepository({
    required Dio dio,
    required FirebaseService firebaseService,
    required SharedPreferences prefs,
  })  : _dio = dio,
        _firebaseService = firebaseService,
        _prefs = prefs;

  // Fetch alerts from API
  Future<List<AlertModel>> fetchAlerts() async {
    try {
      final response = await _dio.get(
        AppConstants.alertsEndpoint,
        options: Options(
          receiveTimeout: AppConstants.networkTimeout.inMilliseconds,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['alerts'];
        final alerts = data.map((json) => AlertModel.fromJson(json)).toList();
        
        // Cache the alerts
        await _cacheAlerts(alerts);
        
        return alerts;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch alerts',
        );
      }
    } on DioException catch (e) {
      // If network error, try to load from cache
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown) {
        return await _getCachedAlerts();
      }
      rethrow;
    }
  }

  // Create new alert locally
  Future<void> createAlert(AlertModel alert) async {
    final alerts = await getLocalAlerts();
    alerts.insert(0, alert);
    
    // Limit alert history
    if (alerts.length > AppConstants.maxAlertHistory) {
      alerts.removeRange(AppConstants.maxAlertHistory, alerts.length);
    }
    
    await _saveLocalAlerts(alerts);
  }

  // Get local alerts
  Future<List<AlertModel>> getLocalAlerts() async {
    final jsonString = _prefs.getString('local_alerts');
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => AlertModel.fromJson(json)).toList();
  }

  // Mark alert as read
  Future<void> markAsRead(String alertId) async {
    final alerts = await getLocalAlerts();
    final index = alerts.indexWhere((a) => a.id == alertId);
    
    if (index != -1) {
      alerts[index].isRead = true;
      await _saveLocalAlerts(alerts);
    }
  }

  // Archive alert
  Future<void> archiveAlert(String alertId) async {
    final alerts = await getLocalAlerts();
    final index = alerts.indexWhere((a) => a.id == alertId);
    
    if (index != -1) {
      alerts[index].isArchived = true;
      await _saveLocalAlerts(alerts);
    }
  }

  // Delete alert
  Future<void> deleteAlert(String alertId) async {
    final alerts = await getLocalAlerts();
    alerts.removeWhere((a) => a.id == alertId);
    await _saveLocalAlerts(alerts);
  }

  // Get unread alert count
  Future<int> getUnreadCount() async {
    final alerts = await getLocalAlerts();
    return alerts.where((a) => !a.isRead && !a.isArchived).length;
  }

  // Get alerts by type
  Future<List<AlertModel>> getAlertsByType(AlertType type) async {
    final alerts = await getLocalAlerts();
    return alerts.where((a) => a.type == type).toList();
  }

  // Clear all alerts
  Future<void> clearAllAlerts() async {
    await _prefs.remove('local_alerts');
    await _prefs.remove('cached_alerts');
  }

  // Private methods
  Future<void> _saveLocalAlerts(List<AlertModel> alerts) async {
    final jsonList = alerts.map((a) => a.toJson()).toList();
    await _prefs.setString('local_alerts', jsonEncode(jsonList));
  }

  Future<void> _cacheAlerts(List<AlertModel> alerts) async {
    final jsonList = alerts.map((a) => a.toJson()).toList();
    await _prefs.setString('cached_alerts', jsonEncode(jsonList));
    await _prefs.setString('alerts_cache_timestamp', DateTime.now().toIso8601String());
  }

  Future<List<AlertModel>> _getCachedAlerts() async {
    final jsonString = _prefs.getString('cached_alerts');
    if (jsonString == null) return [];
    
    // Check cache expiration
    final cacheTimestamp = _prefs.getString('alerts_cache_timestamp');
    if (cacheTimestamp != null) {
      final cachedTime = DateTime.parse(cacheTimestamp);
      if (DateTime.now().difference(cachedTime) > AppConstants.cacheExpiration) {
        return []; // Cache expired
      }
    }
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => AlertModel.fromJson(json)).toList();
  }

  // Generate alert based on network detection
  AlertModel generateNetworkAlert({
    required String networkName,
    required String macAddress,
    required NetworkStatus status,
    String? location,
    String? securityType,
  }) {
    AlertType type;
    String title;
    String message;

    switch (status) {
      case NetworkStatus.suspicious:
        type = AlertType.critical;
        title = 'Evil Twin Attack Detected';
        message = 'A suspicious network "$networkName" was detected that may be attempting to mimic an official network.';
        break;
      case NetworkStatus.unknown:
        type = AlertType.warning;
        title = 'Unknown Network Detected';
        message = 'The network "$networkName" is not on DICT\'s verified list of public Wi-Fi hotspots. Exercise caution when connecting.';
        break;
      case NetworkStatus.verified:
        type = AlertType.info;
        title = 'Verified Network Found';
        message = '"$networkName" is a verified DICT public access point. Safe to connect.';
        break;
    }

    return AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      networkName: networkName,
      macAddress: macAddress,
      location: location,
      securityType: securityType,
      timestamp: DateTime.now(),
      isRead: false,
      isArchived: false,
    );
  }
}