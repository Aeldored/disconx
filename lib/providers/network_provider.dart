import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/network_model.dart';
import '../data/services/firebase_service.dart';
import '../data/services/wifi_scanning_service.dart';
import '../data/repositories/whitelist_repository.dart';
import 'alert_provider.dart';

class NetworkProvider extends ChangeNotifier {
  List<NetworkModel> _networks = [];
  List<NetworkModel> _filteredNetworks = [];
  NetworkModel? _currentNetwork;
  bool _isLoading = false;
  String _searchQuery = '';
  final Set<String> _blockedNetworkIds = {};
  AlertProvider? _alertProvider;
  
  // Firebase integration
  FirebaseService? _firebaseService;
  WhitelistRepository? _whitelistRepository;
  WhitelistData? _currentWhitelist;
  bool _firebaseEnabled = false;
  
  // Wi-Fi scanning integration
  final WiFiScanningService _wifiScanner = WiFiScanningService();
  bool _wifiScanningEnabled = false;

  List<NetworkModel> get networks => _networks;
  List<NetworkModel> get filteredNetworks => _filteredNetworks;
  NetworkModel? get currentNetwork => _currentNetwork;
  bool get isLoading => _isLoading;
  bool get firebaseEnabled => _firebaseEnabled;
  bool get wifiScanningEnabled => _wifiScanningEnabled;
  WhitelistData? get currentWhitelist => _currentWhitelist;

  NetworkProvider() {
    _initializeMockData();
    _initializeWiFiScanning();
  }

  /// Initialize Wi-Fi scanning service
  Future<void> _initializeWiFiScanning() async {
    try {
      _wifiScanningEnabled = await _wifiScanner.initialize();
      if (_wifiScanningEnabled) {
        print('Wi-Fi scanning enabled successfully');
      } else {
        print('Wi-Fi scanning not available, using mock data');
      }
    } catch (e) {
      print('Wi-Fi scanning initialization failed: $e');
      _wifiScanningEnabled = false;
    }
  }

  void setAlertProvider(AlertProvider alertProvider) {
    _alertProvider = alertProvider;
  }

  // Initialize Firebase integration
  Future<void> initializeFirebase(SharedPreferences prefs) async {
    try {
      _firebaseService = FirebaseService();
      _whitelistRepository = WhitelistRepository(
        firebaseService: _firebaseService!,
        prefs: prefs,
      );
      
      _firebaseEnabled = true;
      
      // Load whitelist
      await refreshWhitelist();
      
      // Listen for whitelist updates
      _whitelistRepository!.whitelistUpdates().listen((metadata) {
        print('Whitelist updated: v${metadata.version}');
        refreshWhitelist();
      });
      
      print('Firebase integration initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      _firebaseEnabled = false;
    }
  }

  // Refresh whitelist from Firebase
  Future<void> refreshWhitelist() async {
    if (!_firebaseEnabled || _whitelistRepository == null) return;
    
    try {
      final data = await _whitelistRepository!.getWhitelist();
      if (data != null) {
        _currentWhitelist = data;
        print('Whitelist loaded: ${data.accessPoints.length} access points');
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing whitelist: $e');
    }
  }

  // Check if network is whitelisted
  bool isNetworkWhitelisted(String macAddress) {
    if (!_firebaseEnabled || _whitelistRepository == null) return false;
    return _whitelistRepository!.isNetworkWhitelisted(macAddress, _currentWhitelist);
  }

  // Report suspicious network to Firebase
  Future<void> reportSuspiciousNetwork(NetworkModel network) async {
    if (!_firebaseEnabled || _firebaseService == null) return;
    
    try {
      await _firebaseService!.submitThreatReport(
        network: network,
        latitude: network.latitude ?? 14.2117, // Fallback to Calamba coordinates
        longitude: network.longitude ?? 121.1644,
        deviceId: 'device_${DateTime.now().millisecondsSinceEpoch}', // Generate unique device ID
        additionalInfo: 'Reported as suspicious from mobile app',
      );
      print('Threat report submitted for network: ${network.name}');
    } catch (e) {
      print('Error reporting network: $e');
    }
  }

  // Log scan event to Firebase Analytics
  Future<void> logScanEvent() async {
    if (!_firebaseEnabled || _firebaseService == null) return;
    
    try {
      final threatsDetected = _networks.where((n) => n.status == NetworkStatus.suspicious).length;
      await _firebaseService!.logScan(
        networksFound: _networks.length,
        threatsDetected: threatsDetected,
        scanType: 'manual_scan',
      );
    } catch (e) {
      print('Error logging scan event: $e');
    }
  }

  void _initializeMockData() {
    // Mock data - replace with Firebase integration later
    _networks = [
      NetworkModel(
        id: '1',
        name: 'CalambaFreeWiFi',
        description: 'DICT Public Access Point',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa2,
        signalStrength: 85,
        macAddress: '00:1A:2B:3C:4D:5E',
        latitude: 14.2117,
        longitude: 121.1644,
        lastSeen: DateTime.now(),
        isConnected: true,
      ),
      NetworkModel(
        id: '2',
        name: 'ShopMall_FREE',
        description: 'SM Calamba',
        status: NetworkStatus.unknown,
        securityType: SecurityType.open,
        signalStrength: 60,
        macAddress: 'A1:B2:C3:D4:E5:F6',
        latitude: 14.2050,
        longitude: 121.1580,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NetworkModel(
        id: '3',
        name: 'FREE_WiFi_CalambaCity',
        description: 'Unknown location',
        status: NetworkStatus.suspicious,
        securityType: SecurityType.open,
        signalStrength: 75,
        macAddress: 'FF:FF:FF:FF:FF:FF',
        latitude: 14.2100,
        longitude: 121.1650,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      NetworkModel(
        id: '4',
        name: 'PLDT_HomeWiFi_5G',
        description: 'Private Network',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa3,
        signalStrength: 90,
        macAddress: '11:22:33:44:55:66',
        lastSeen: DateTime.now(),
      ),
    ];

    _currentNetwork = _networks.firstWhere((n) => n.isConnected);
    _filteredNetworks = List.from(_networks);
  }

  Future<void> loadNearbyNetworks() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_wifiScanningEnabled) {
        // Use real Wi-Fi scanning
        await _performRealWiFiScan();
      } else if (_firebaseEnabled && _currentWhitelist != null) {
        // Use Firebase-enhanced mock data
        await _performFirebaseEnhancedScan();
      } else {
        // Fallback to mock data
        await _performRealisticScan();
      }

      // Log scan event to Firebase Analytics
      await logScanEvent();
    } catch (e) {
      print('Error loading networks: $e');
      // Fallback to mock data on error
      await _performRealisticScan();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performRealWiFiScan() async {
    print('Performing real Wi-Fi scan...');
    
    // Clear existing networks
    _networks.clear();
    notifyListeners();
    
    try {
      // Perform Wi-Fi scan
      final scannedNetworks = await _wifiScanner.performScan();
      
      // Process and validate scanned networks
      _networks = scannedNetworks;
      
      // Perform evil twin detection on real scan results
      _performEvilTwinDetection();
      
      // Cross-reference with whitelist if available
      if (_firebaseEnabled && _currentWhitelist != null) {
        _crossReferenceWithWhitelist();
      }
      
      // Generate alerts for suspicious networks
      _generateAlertsForSuspiciousNetworks();
      
      // Auto-report suspicious networks to Firebase
      if (_firebaseEnabled) {
        for (final network in _networks.where((n) => n.status == NetworkStatus.suspicious)) {
          await reportSuspiciousNetwork(network);
        }
      }
      
      // Set current network (check if we're connected to any of the scanned networks)
      await _identifyCurrentNetwork();
      
      print('Real Wi-Fi scan completed: ${_networks.length} networks found');
      
    } catch (e) {
      print('Real Wi-Fi scan failed: $e');
      // Fall back to mock data
      await _performRealisticScan();
    }
    
    _filteredNetworks = List.from(_networks);
  }

  /// Cross-reference scanned networks with Firebase whitelist
  void _crossReferenceWithWhitelist() {
    for (int i = 0; i < _networks.length; i++) {
      final network = _networks[i];
      if (isNetworkWhitelisted(network.macAddress)) {
        _networks[i] = network.copyWith(
          status: NetworkStatus.verified,
          description: '${network.description} (Verified via DICT whitelist)',
        );
      }
    }
  }

  /// Identify current connected network from scan results
  Future<void> _identifyCurrentNetwork() async {
    // Try to identify which network we're currently connected to
    // This is a simplified implementation - in practice, you'd use 
    // connectivity APIs to get the current SSID and match it
    
    // For now, we'll mark the strongest signal as potentially connected
    if (_networks.isNotEmpty) {
      final strongestNetwork = _networks.reduce((a, b) => 
        a.signalStrength > b.signalStrength ? a : b);
      
      // Only mark as connected if it's a verified/trusted network with very strong signal
      if ((strongestNetwork.status == NetworkStatus.verified || 
           strongestNetwork.status == NetworkStatus.trusted) &&
          strongestNetwork.signalStrength > 80) {
        
        final index = _networks.indexWhere((n) => n.id == strongestNetwork.id);
        if (index != -1) {
          _networks[index] = strongestNetwork.copyWith(isConnected: true);
          _currentNetwork = _networks[index];
        }
      }
    }
  }

  Future<void> _performFirebaseEnhancedScan() async {
    // Clear existing networks
    _networks.clear();
    
    // Simulate scanning delay with progressive discovery
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Add verified networks from Firebase whitelist (simulated as nearby)
    if (_currentWhitelist != null) {
      final nearbyWhitelistedAPs = _currentWhitelist!.accessPoints
          .where((ap) => ap.status == 'active')
          .take(3) // Simulate only some being nearby
          .toList();
      
      for (final ap in nearbyWhitelistedAPs) {
        _networks.add(NetworkModel(
          id: 'whitelist_${ap.id}',
          name: ap.ssid,
          description: 'DICT Verified Access Point - ${ap.city}, ${ap.province}',
          status: NetworkStatus.verified,
          securityType: SecurityType.wpa2,
          signalStrength: 75 + (ap.ssid.hashCode % 20), // Simulate signal strength
          macAddress: ap.macAddress,
          latitude: ap.latitude,
          longitude: ap.longitude,
          lastSeen: DateTime.now(),
          isConnected: ap.ssid == 'DICT-CALABARZON-OFFICIAL', // Simulate connection to main network
        ));
      }
    }
    
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Add some commercial networks (mix of verified and unknown)
    _networks.addAll([
      NetworkModel(
        id: 'commercial_1',
        name: 'SM_WiFi',
        description: 'SM Calamba',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa2,
        signalStrength: 60,
        macAddress: 'A1:B2:C3:D4:E5:F6',
        latitude: 14.2050,
        longitude: 121.1580,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NetworkModel(
        id: 'commercial_2',
        name: 'PLDT_HomeWiFi_5G',
        description: 'Private Network',
        status: NetworkStatus.unknown,
        securityType: SecurityType.wpa3,
        signalStrength: 90,
        macAddress: '11:22:33:44:55:66',
        latitude: 14.2080,
        longitude: 121.1600,
        lastSeen: DateTime.now(),
      ),
    ]);
    
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Add potentially suspicious networks (evil twins) - enhanced with Firebase verification
    final suspiciousNetworks = _generateEvilTwinNetworks();
    _networks.addAll(suspiciousNetworks);
    
    // Verify networks against whitelist
    for (int i = 0; i < _networks.length; i++) {
      final network = _networks[i];
      if (network.status == NetworkStatus.unknown) {
        // Check if MAC address is in whitelist
        if (isNetworkWhitelisted(network.macAddress)) {
          _networks[i] = NetworkModel(
            id: network.id,
            name: network.name,
            description: '${network.description} (Verified via whitelist)',
            status: NetworkStatus.verified,
            securityType: network.securityType,
            signalStrength: network.signalStrength,
            macAddress: network.macAddress,
            latitude: network.latitude,
            longitude: network.longitude,
            lastSeen: network.lastSeen,
            isConnected: network.isConnected,
          );
        }
      }
    }
    
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Add some unknown networks
    _networks.addAll([
      NetworkModel(
        id: 'unknown_1',
        name: 'Coffee_Shop_WiFi',
        description: 'Unknown location',
        status: NetworkStatus.unknown,
        securityType: SecurityType.open,
        signalStrength: 45,
        macAddress: 'B1:C2:D3:E4:F5:A6',
        latitude: 14.2090,
        longitude: 121.1610,
        lastSeen: DateTime.now(),
      ),
      NetworkModel(
        id: 'unknown_2',
        name: 'Guest_Network',
        description: 'Unknown network',
        status: NetworkStatus.unknown,
        securityType: SecurityType.wep,
        signalStrength: 55,
        macAddress: 'C1:D2:E3:F4:A5:B6',
        latitude: 14.2070,
        longitude: 121.1590,
        lastSeen: DateTime.now(),
      ),
    ]);
    
    // Perform evil twin detection
    _performEvilTwinDetection();
    
    // Generate alerts for suspicious networks and report them
    _generateAlertsForSuspiciousNetworks();
    
    // Auto-report suspicious networks to Firebase
    for (final network in _networks.where((n) => n.status == NetworkStatus.suspicious)) {
      await reportSuspiciousNetwork(network);
    }
    
    // Set current network if not already set
    if (_currentNetwork == null) {
      final connectedNetwork = _networks.firstWhere(
        (n) => n.isConnected, 
        orElse: () => _networks.isNotEmpty ? _networks.first : NetworkModel(
          id: 'none',
          name: 'No Connection',
          description: 'Not connected to any network',
          status: NetworkStatus.unknown,
          securityType: SecurityType.open,
          signalStrength: 0,
          macAddress: '00:00:00:00:00:00',
          lastSeen: DateTime.now(),
        ),
      );
      _currentNetwork = connectedNetwork;
    }
    
    _filteredNetworks = List.from(_networks);
  }

  Future<void> _performRealisticScan() async {
    // Clear existing networks
    _networks.clear();
    
    // Simulate scanning delay with progressive discovery
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Add verified government networks
    _networks.addAll([
      NetworkModel(
        id: 'gov_1',
        name: 'DICT-CALABARZON-OFFICIAL',
        description: 'DICT Public Access Point',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa2,
        signalStrength: 85,
        macAddress: '00:1A:2B:3C:4D:5E',
        latitude: 14.2117,
        longitude: 121.1644,
        lastSeen: DateTime.now(),
        isConnected: true,
      ),
      NetworkModel(
        id: 'gov_2',
        name: 'GOV-PH-SECURE',
        description: 'Government Network',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa3,
        signalStrength: 78,
        macAddress: '00:1A:2B:3C:4D:5F',
        latitude: 14.2120,
        longitude: 121.1650,
        lastSeen: DateTime.now(),
      ),
    ]);
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Add legitimate commercial networks
    _networks.addAll([
      NetworkModel(
        id: 'commercial_1',
        name: 'SM_WiFi',
        description: 'SM Calamba',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa2,
        signalStrength: 60,
        macAddress: 'A1:B2:C3:D4:E5:F6',
        latitude: 14.2050,
        longitude: 121.1580,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NetworkModel(
        id: 'commercial_2',
        name: 'PLDT_HomeWiFi_5G',
        description: 'Private Network',
        status: NetworkStatus.verified,
        securityType: SecurityType.wpa3,
        signalStrength: 90,
        macAddress: '11:22:33:44:55:66',
        latitude: 14.2080,
        longitude: 121.1600,
        lastSeen: DateTime.now(),
      ),
    ]);
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Add potentially suspicious networks (evil twins)
    final suspiciousNetworks = _generateEvilTwinNetworks();
    _networks.addAll(suspiciousNetworks);
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Add some unknown networks
    _networks.addAll([
      NetworkModel(
        id: 'unknown_1',
        name: 'Coffee_Shop_WiFi',
        description: 'Unknown location',
        status: NetworkStatus.unknown,
        securityType: SecurityType.open,
        signalStrength: 45,
        macAddress: 'B1:C2:D3:E4:F5:A6',
        latitude: 14.2090,
        longitude: 121.1610,
        lastSeen: DateTime.now(),
      ),
      NetworkModel(
        id: 'unknown_2',
        name: 'Guest_Network',
        description: 'Unknown network',
        status: NetworkStatus.unknown,
        securityType: SecurityType.wep,
        signalStrength: 55,
        macAddress: 'C1:D2:E3:F4:A5:B6',
        latitude: 14.2070,
        longitude: 121.1590,
        lastSeen: DateTime.now(),
      ),
    ]);
    
    // Perform evil twin detection
    _performEvilTwinDetection();
    
    // Generate alerts for suspicious networks
    _generateAlertsForSuspiciousNetworks();
    
    // Set current network if not already set
    if (_currentNetwork == null) {
      _currentNetwork = _networks.firstWhere(
        (n) => n.isConnected, 
        orElse: () => _networks.first
      );
    }
    
    _filteredNetworks = List.from(_networks);
  }

  List<NetworkModel> _generateEvilTwinNetworks() {
    final DateTime now = DateTime.now();
    return [
      // Evil twin of DICT network
      NetworkModel(
        id: 'evil_1',
        name: 'DICT-CALABARZON-FREE', // Suspicious variant
        description: 'Suspicious network mimicking government WiFi',
        status: NetworkStatus.suspicious,
        securityType: SecurityType.open, // Red flag: open when original is secured
        signalStrength: 95, // Suspiciously strong signal
        macAddress: 'FF:FF:FF:FF:FF:FF', // Suspicious MAC
        latitude: 14.2115, // Very close to legitimate network
        longitude: 121.1642,
        lastSeen: now.subtract(const Duration(minutes: 1)),
      ),
      // Evil twin of commercial network
      NetworkModel(
        id: 'evil_2',
        name: 'SM_Free_WiFi', // Variant of SM_WiFi
        description: 'Potentially malicious network',
        status: NetworkStatus.suspicious,
        securityType: SecurityType.open,
        signalStrength: 85,
        macAddress: 'AA:BB:CC:DD:EE:FF',
        latitude: 14.2048,
        longitude: 121.1578,
        lastSeen: now.subtract(const Duration(minutes: 3)),
      ),
      // Generic evil twin
      NetworkModel(
        id: 'evil_3',
        name: 'FREE_WiFi_CalambaCity',
        description: 'Suspicious open network',
        status: NetworkStatus.suspicious,
        securityType: SecurityType.open,
        signalStrength: 75,
        macAddress: 'DE:AD:BE:EF:CA:FE',
        latitude: 14.2100,
        longitude: 121.1650,
        lastSeen: now.subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  void _performEvilTwinDetection() {
    final Map<String, List<NetworkModel>> networkGroups = {};
    
    // Group networks by similar names
    for (var network in _networks) {
      final normalizedName = _normalizeNetworkName(network.name);
      networkGroups.putIfAbsent(normalizedName, () => []).add(network);
    }
    
    // Detect potential evil twins
    for (var entry in networkGroups.entries) {
      if (entry.value.length > 1) {
        final networks = entry.value;
        
        // Find the most legitimate network (secured, known MAC, etc.)
        final legitimate = networks.firstWhere(
          (n) => n.status == NetworkStatus.verified || 
                 n.securityType != SecurityType.open,
          orElse: () => networks.first,
        );
        
        // Mark others as suspicious if they don't match the legitimate one
        for (var network in networks) {
          if (network.id != legitimate.id) {
            final index = _networks.indexWhere((n) => n.id == network.id);
            if (index != -1) {
              _networks[index] = NetworkModel(
                id: network.id,
                name: network.name,
                description: 'Potential evil twin of ${legitimate.name}',
                status: NetworkStatus.suspicious,
                securityType: network.securityType,
                signalStrength: network.signalStrength,
                macAddress: network.macAddress,
                latitude: network.latitude,
                longitude: network.longitude,
                lastSeen: network.lastSeen,
                isConnected: network.isConnected,
              );
            }
          }
        }
      }
    }
  }

  String _normalizeNetworkName(String name) {
    // Remove common variations and normalize for comparison
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-\s]'), '')
        .replaceAll('free', '')
        .replaceAll('wifi', '')
        .replaceAll('public', '')
        .replaceAll('guest', '');
  }

  void filterNetworks(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredNetworks = List.from(_networks);
    } else {
      _filteredNetworks = _networks.where((network) {
        return network.name.toLowerCase().contains(_searchQuery) ||
            (network.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void _generateAlertsForSuspiciousNetworks() {
    if (_alertProvider == null) return;
    
    for (var network in _networks) {
      if (network.status == NetworkStatus.suspicious) {
        _alertProvider!.generateAlertForNetwork(network);
      }
    }
  }

  void blockNetwork(String networkId) {
    final network = _networks.firstWhere((n) => n.id == networkId);
    
    _blockedNetworkIds.add(networkId);
    _networks.removeWhere((n) => n.id == networkId);
    _filteredNetworks.removeWhere((n) => n.id == networkId);
    
    // Generate alert for blocked network
    if (_alertProvider != null) {
      _alertProvider!.generateBlockedNetworkAlert(network);
    }
    
    notifyListeners();
  }

  Future<void> connectToNetwork(String networkId) async {
    // Disconnect from current network
    if (_currentNetwork != null) {
      final index = _networks.indexWhere((n) => n.id == _currentNetwork!.id);
      if (index != -1) {
        _networks[index] = NetworkModel(
          id: _currentNetwork!.id,
          name: _currentNetwork!.name,
          description: _currentNetwork!.description,
          status: _currentNetwork!.status,
          securityType: _currentNetwork!.securityType,
          signalStrength: _currentNetwork!.signalStrength,
          macAddress: _currentNetwork!.macAddress,
          latitude: _currentNetwork!.latitude,
          longitude: _currentNetwork!.longitude,
          lastSeen: _currentNetwork!.lastSeen,
          isConnected: false,
        );
      }
    }

    // Connect to new network
    final networkIndex = _networks.indexWhere((n) => n.id == networkId);
    if (networkIndex != -1) {
      final network = _networks[networkIndex];
      _networks[networkIndex] = NetworkModel(
        id: network.id,
        name: network.name,
        description: network.description,
        status: network.status,
        securityType: network.securityType,
        signalStrength: network.signalStrength,
        macAddress: network.macAddress,
        latitude: network.latitude,
        longitude: network.longitude,
        lastSeen: network.lastSeen,
        isConnected: true,
      );
      _currentNetwork = _networks[networkIndex];
    }

    // Refresh filtered list
    filterNetworks(_searchQuery);
    notifyListeners();
  }

  List<NetworkModel> getNetworksForMap() {
    return _networks.where((n) => n.latitude != null && n.longitude != null).toList();
  }

  /// Refresh the networks list to reflect any status changes
  Future<void> refreshNetworks() async {
    await loadNearbyNetworks();
  }

  /// Check if Wi-Fi scanning permissions are granted
  Future<bool> hasWiFiScanningPermissions() async {
    return await _wifiScanner.hasRequiredPermissions();
  }

  /// Request Wi-Fi scanning permissions
  Future<bool> requestWiFiScanningPermissions() async {
    if (!_wifiScanningEnabled) {
      _wifiScanningEnabled = await _wifiScanner.initialize();
      if (_wifiScanningEnabled) {
        notifyListeners();
      }
    }
    return _wifiScanningEnabled;
  }

  /// Start continuous Wi-Fi scanning (for real-time updates)
  Stream<List<NetworkModel>>? startContinuousScanning() {
    if (_wifiScanningEnabled) {
      return _wifiScanner.startContinuousScanning();
    }
    return null;
  }

  /// Stop continuous Wi-Fi scanning
  void stopContinuousScanning() {
    _wifiScanner.stopContinuousScanning();
  }
}