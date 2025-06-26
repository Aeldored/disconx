// Mock Firebase Service for local-only mode
// This file provides the same interface as Firebase but with local implementations

import '../models/network_model.dart';
import '../models/alert_model.dart';

class FirebaseService {
  bool _initialized = false;

  FirebaseService();

  // Initialize Firebase (mock implementation)
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 100));
      _initialized = true;
      print('Mock Firebase service initialized');
    } catch (e) {
      print('Firebase service initialization error: $e');
      _initialized = false;
    }
  }

  // Mock authentication methods
  Future<MockUser?> signInAnonymously() async {
    if (!_initialized) {
      print('Firebase not initialized - cannot sign in');
      return null;
    }
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockUser(
        uid: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        isAnonymous: true,
      );
    } catch (e) {
      print('Anonymous sign in error: $e');
      return null;
    }
  }

  Future<MockUser?> signInWithEmail(String email, String password) async {
    if (!_initialized) {
      print('Firebase not initialized - cannot sign in');
      return null;
    }
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (email.isNotEmpty && password.length >= 6) {
        return MockUser(
          uid: 'user_${email.hashCode}',
          email: email,
          displayName: email.split('@').first,
          isAnonymous: false,
        );
      }
      return null;
    } catch (e) {
      print('Email sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (_initialized) {
      print('Signed out from mock Firebase service');
    }
  }

  MockUser? get currentUser => null; // Mock - no persistent user state
  Stream<MockUser?> get authStateChanges => Stream.value(null);

  // Mock Firestore methods
  Future<List<NetworkModel>> getVerifiedNetworks() async {
    try {
      // Return mock verified networks
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        NetworkModel(
          id: 'verified_1',
          name: 'DICT-CALABARZON-OFFICIAL',
          macAddress: '00:11:22:33:44:55',
          signalStrength: -45,
          frequency: 2437,
          securityType: 'WPA2',
          isVerified: true,
          latitude: 14.2334,
          longitude: 121.1644,
          lastSeen: DateTime.now(),
        ),
        NetworkModel(
          id: 'verified_2',
          name: 'GOV-PH-SECURE',
          macAddress: '00:11:22:33:44:66',
          signalStrength: -52,
          frequency: 5180,
          securityType: 'WPA3',
          isVerified: true,
          latitude: 14.2340,
          longitude: 121.1650,
          lastSeen: DateTime.now(),
        ),
      ];
    } catch (e) {
      print('Mock Firestore error: $e');
      return [];
    }
  }

  Future<List<String>> getWhitelist() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return [
        '00:11:22:33:44:55', // DICT-CALABARZON-OFFICIAL
        '00:11:22:33:44:66', // GOV-PH-SECURE
        '00:11:22:33:44:77', // LOCAL-GOV-WIFI
      ];
    } catch (e) {
      print('Whitelist fetch error: $e');
      return [];
    }
  }

  Future<void> reportSuspiciousNetwork(NetworkModel network, String reason) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      print('Mock report submitted: ${network.name} - $reason');
      // In a real implementation, this would save to Firestore
    } catch (e) {
      print('Report submission error: $e');
      rethrow;
    }
  }

  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      print('Mock preferences saved: $preferences');
      // In a real implementation, this would save to Firestore
    } catch (e) {
      print('Save preferences error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      // Return mock preferences
      return {
        'notifications': true,
        'autoScan': true,
        'scanInterval': 30,
        'theme': 'system',
      };
    } catch (e) {
      print('Get preferences error: $e');
      return null;
    }
  }

  // Mock real-time listeners
  Stream<List<AlertModel>> getAlertsStream() {
    return Stream.periodic(const Duration(seconds: 30), (count) {
      // Generate mock alerts periodically
      final alerts = <AlertModel>[];
      
      if (count % 3 == 0) {
        alerts.add(AlertModel(
          id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.evilTwin,
          title: 'Evil Twin Detected',
          message: 'Suspicious network "FREE_WIFI_${count}" detected nearby.',
          severity: AlertSeverity.high,
          timestamp: DateTime.now(),
          location: 'Lipa City, Batangas',
          isRead: false,
        ));
      }
      
      return alerts;
    });
  }

  Stream<List<NetworkModel>> getNearbyNetworksStream(double latitude, double longitude, double radiusKm) {
    return Stream.periodic(const Duration(seconds: 5), (count) {
      // Generate mock nearby networks
      return [
        NetworkModel(
          id: 'nearby_1',
          name: 'PLDT_FIBR_${count % 100}',
          macAddress: '00:11:22:33:44:${(count % 256).toString().padLeft(2, '0')}',
          signalStrength: -45 + (count % 20),
          frequency: 2437,
          securityType: 'WPA2',
          isVerified: false,
          latitude: latitude + (count % 10) * 0.001,
          longitude: longitude + (count % 10) * 0.001,
          lastSeen: DateTime.now(),
        ),
        NetworkModel(
          id: 'nearby_2',
          name: 'Globe_At_Home_${count % 50}',
          macAddress: '00:22:33:44:55:${(count % 256).toString().padLeft(2, '0')}',
          signalStrength: -60 + (count % 15),
          frequency: 5180,
          securityType: 'WPA3',
          isVerified: false,
          latitude: latitude + (count % 8) * 0.0008,
          longitude: longitude + (count % 8) * 0.0008,
          lastSeen: DateTime.now(),
        ),
      ];
    });
  }

  // Mock push notification methods
  Future<void> subscribeToTopic(String topic) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('Mock subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('Mock unsubscribed from topic: $topic');
  }
}

// Mock user class
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  
  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}