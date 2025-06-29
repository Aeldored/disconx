import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/network_model.dart';
import '../data/services/firebase_service.dart';
import '../data/services/wifi_scanning_service.dart';
import '../data/services/access_point_service.dart';
import '../data/repositories/whitelist_repository.dart';
import 'alert_provider.dart';

class NetworkProvider extends ChangeNotifier {
  List<NetworkModel> _networks = [];
  List<NetworkModel> _filteredNetworks = [];
  NetworkModel? _currentNetwork;
  bool _isLoading = false;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  DateTime? _lastScanTime;
  String _searchQuery = '';
  final Set<String> _blockedNetworkIds = {};
  final Set<String> _trustedNetworkIds = {};
  final Set<String> _flaggedNetworkIds = {};
  final Map<String, NetworkStatus> _originalStatuses = {}; // Track original statuses before user modifications
  AlertProvider? _alertProvider;
  bool _hasPerformedScan = false;
  int _scanSessionId = 0;
  final Set<String> _alertedNetworksThisSession = <String>{};
  bool _isManualScan = false;
  
  // Scan statistics
  int _totalNetworksFound = 0;
  int _verifiedNetworksFound = 0;
  int _suspiciousNetworksFound = 0;
  int _threatsDetected = 0;
  
  // Firebase integration
  FirebaseService? _firebaseService;
  WhitelistRepository? _whitelistRepository;
  WhitelistData? _currentWhitelist;
  bool _firebaseEnabled = false;
  
  // Wi-Fi scanning integration
  final WiFiScanningService _wifiScanner = WiFiScanningService();
  bool _wifiScanningEnabled = false;
  
  // Access Point Service integration
  final AccessPointService _accessPointService = AccessPointService();

  List<NetworkModel> get networks => _networks;
  List<NetworkModel> get filteredNetworks => _filteredNetworks;
  NetworkModel? get currentNetwork => _currentNetwork;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  DateTime? get lastScanTime => _lastScanTime;
  bool get firebaseEnabled => _firebaseEnabled;
  bool get wifiScanningEnabled => _wifiScanningEnabled;
  WhitelistData? get currentWhitelist => _currentWhitelist;
  bool get hasPerformedScan => _hasPerformedScan;
  Set<String> get trustedNetworks => Set.from(_trustedNetworkIds);
  Set<String> get blockedNetworks => Set.from(_blockedNetworkIds);
  Set<String> get flaggedNetworks => Set.from(_flaggedNetworkIds);
  int get currentScanSessionId => _scanSessionId;
  
  // Scan statistics getters
  int get totalNetworksFound => _totalNetworksFound;
  int get verifiedNetworksFound => _verifiedNetworksFound;
  int get suspiciousNetworksFound => _suspiciousNetworksFound;
  int get threatsDetected => _threatsDetected;

  NetworkProvider() {
    _initializeMockData();
    _initializeWiFiScanning();
    _initializeAccessPointService();
    loadUserPreferences();
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

  /// Initialize Access Point Service
  Future<void> _initializeAccessPointService() async {
    try {
      await _accessPointService.initialize();
      print('Access Point Service initialized successfully');
    } catch (e) {
      print('Access Point Service initialization failed: $e');
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

    _currentNetwork = _networks.firstWhere((n) => n.isConnected, orElse: () => NetworkModel(
      id: 'mock_connected',
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
    ));
    // Update filtered networks with current search query
    _updateFilteredNetworks();
  }

  /// Start a new network scan with progress tracking
  Future<void> startNetworkScan({bool forceRescan = false, bool isManualScan = false}) async {
    if (_isScanning && !forceRescan) return;
    
    _isScanning = true;
    _isLoading = true;
    _scanProgress = 0.0;
    _scanSessionId++;
    _lastScanTime = DateTime.now();
    _isManualScan = isManualScan;
    
    // Reset statistics
    _totalNetworksFound = 0;
    _verifiedNetworksFound = 0;
    _suspiciousNetworksFound = 0;
    _threatsDetected = 0;
    
    notifyListeners();

    try {
      if (_wifiScanningEnabled) {
        await _performRealWiFiScanWithProgress();
      } else if (_firebaseEnabled && _currentWhitelist != null) {
        await _performFirebaseEnhancedScanWithProgress();
      } else {
        await _performRealisticScanWithProgress();
      }

      // Apply user-defined statuses
      _applyUserDefinedStatuses();
      
      // Calculate final statistics
      _calculateScanStatistics();
      
      // Mark that we've performed a scan
      _hasPerformedScan = true;

      // Generate real-time threat alerts
      await _generateScanBasedAlerts();

      // Log scan event to Firebase Analytics
      await logScanEvent();
    } catch (e) {
      print('Error during network scan: $e');
      await _performRealisticScanWithProgress();
      _applyUserDefinedStatuses();
      _calculateScanStatistics();
      _hasPerformedScan = true;
    }

    _isScanning = false;
    _isLoading = false;
    _scanProgress = 1.0;
    
    // Ensure filtered networks are properly updated with current search query
    _updateFilteredNetworks();
    
    // Final notification to ensure all tabs are updated
    notifyListeners();
    
    // Log scan completion for debugging
    print('Scan completed: $_totalNetworksFound networks found, $_threatsDetected threats detected');
  }
  
  /// Stop ongoing scan
  void stopNetworkScan() {
    _isScanning = false;
    _scanProgress = 1.0;
    notifyListeners();
  }
  
  /// Legacy method for backward compatibility
  Future<void> loadNearbyNetworks() async {
    await startNetworkScan();
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
    
    // Update filtered networks with current search query
    _updateFilteredNetworks();
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
        orElse: () => _networks.isNotEmpty && _networks.any((n) => n.status == NetworkStatus.verified) 
            ? _networks.firstWhere((n) => n.status == NetworkStatus.verified).copyWith(isConnected: true)
            : _networks.isNotEmpty 
                ? _networks.first.copyWith(isConnected: true) 
                : NetworkModel(
                    id: 'mock_connected',
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
      );
      _currentNetwork = connectedNetwork;
      
      // Update the network in the list to show it as connected
      if (_networks.isNotEmpty) {
        final index = _networks.indexWhere((n) => n.id == _currentNetwork!.id);
        if (index != -1) {
          _networks[index] = _currentNetwork!;
        }
      }
    }
    
    // Update filtered networks with current search query
    _updateFilteredNetworks();
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
      final connectedNetwork = _networks.firstWhere(
        (n) => n.isConnected, 
        orElse: () => _networks.isNotEmpty && _networks.any((n) => n.status == NetworkStatus.verified) 
            ? _networks.firstWhere((n) => n.status == NetworkStatus.verified).copyWith(isConnected: true)
            : _networks.isNotEmpty 
                ? _networks.first.copyWith(isConnected: true) 
                : NetworkModel(
                    id: 'mock_connected',
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
      );
      _currentNetwork = connectedNetwork;
      
      // Update the network in the list to show it as connected
      if (_networks.isNotEmpty) {
        final index = _networks.indexWhere((n) => n.id == _currentNetwork!.id);
        if (index != -1) {
          _networks[index] = _currentNetwork!;
        }
      }
    }
    
    // Update filtered networks with current search query
    _updateFilteredNetworks();
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
    _updateFilteredNetworks();
    notifyListeners();
  }
  
  void _updateFilteredNetworks() {
    if (_searchQuery.isEmpty) {
      _filteredNetworks = List.from(_networks);
    } else {
      _filteredNetworks = _networks.where((network) {
        return network.name.toLowerCase().contains(_searchQuery) ||
            (network.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }
  
  /// Get network by ID with current status
  NetworkModel? getNetworkById(String networkId) {
    try {
      return _networks.firstWhere((n) => n.id == networkId);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if network is currently trusted
  bool isNetworkTrusted(String networkId) {
    return _trustedNetworkIds.contains(networkId);
  }
  
  /// Check if network is currently blocked
  bool isNetworkBlocked(String networkId) {
    return _blockedNetworkIds.contains(networkId);
  }
  
  /// Check if network is currently flagged
  bool isNetworkFlagged(String networkId) {
    return _flaggedNetworkIds.contains(networkId);
  }
  
  /// Get all networks with current user-applied statuses
  List<NetworkModel> getNetworksWithStatus(NetworkStatus status) {
    return _networks.where((n) => n.status == status).toList();
  }
  
  /// Force refresh UI for all tabs
  void forceUIRefresh() {
    // Ensure filtered networks are up to date
    _updateFilteredNetworks();
    notifyListeners();
  }
  
  /// Get the AccessPointService instance for external access
  AccessPointService get accessPointService => _accessPointService;
  
  /// Check if the last scan detected any new threats
  bool get hasNewThreatsFromLastScan => _threatsDetected > 0 && _hasPerformedScan;
  
  /// Get a summary of the last scan results
  String getLastScanSummary() {
    if (!_hasPerformedScan) return 'No scan performed yet';
    
    final String threatText = _threatsDetected > 0 
        ? '$_threatsDetected threat${_threatsDetected == 1 ? '' : 's'} detected'
        : 'No threats detected';
    
    return 'Found $_totalNetworksFound network${_totalNetworksFound == 1 ? '' : 's'}, $threatText';
  }
  
  /// Debug method to check network sync status
  void debugNetworkSync() {
    print('=== NetworkProvider Debug ===');
    print('_networks.length: ${_networks.length}');
    print('_filteredNetworks.length: ${_filteredNetworks.length}');
    print('_searchQuery: "$_searchQuery"');
    print('_hasPerformedScan: $_hasPerformedScan');
    print('_isScanning: $_isScanning');
    print('_isLoading: $_isLoading');
    print('Trusted Networks: $_trustedNetworkIds');
    print('Blocked Networks: $_blockedNetworkIds');
    print('Flagged Networks: $_flaggedNetworkIds');
    print('Networks: ${_networks.map((n) => n.name).join(', ')}');
    print('Filtered: ${_filteredNetworks.map((n) => n.name).join(', ')}');
    print('=============================');
  }
  
  /// Debug method to verify AccessPointService synchronization
  Future<void> debugAccessPointSync() async {
    print('=== AccessPointService Sync Debug ===');
    try {
      final trustedAPs = await _accessPointService.getTrustedAccessPoints();
      final blockedAPs = await _accessPointService.getBlockedAccessPoints();
      final flaggedAPs = await _accessPointService.getFlaggedAccessPoints();
      
      print('AccessPointService Trusted: ${trustedAPs.map((n) => n.name).join(', ')}');
      print('AccessPointService Blocked: ${blockedAPs.map((n) => n.name).join(', ')}');
      print('AccessPointService Flagged: ${flaggedAPs.map((n) => n.name).join(', ')}');
      print('=====================================');
    } catch (e) {
      print('Error checking AccessPointService sync: $e');
    }
  }

  void _generateAlertsForSuspiciousNetworks() {
    if (_alertProvider == null) return;
    
    for (var network in _networks) {
      if (network.status == NetworkStatus.suspicious) {
        _alertProvider!.generateAlertForNetwork(network);
      }
    }
  }

  /// Trust a network - mark it as safe and allow direct connection
  Future<void> trustNetwork(String networkId) async {
    _trustedNetworkIds.add(networkId);
    _blockedNetworkIds.remove(networkId);
    _flaggedNetworkIds.remove(networkId);
    
    // Find the network and generate alert
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.trusted,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    // Generate alert for trusted network
    if (_alertProvider != null) {
      _alertProvider!.generateTrustedNetworkAlert(network);
    }
    
    // Sync with AccessPointService
    try {
      await _accessPointService.trustAccessPoint(network);
    } catch (e) {
      print('Failed to sync trusted network with AccessPointService: $e');
    }
    
    await _saveUserPreferences();
    _applyUserDefinedStatuses();
    notifyListeners();
    
    // Force refresh of filtered networks to ensure all tabs update
    filterNetworks(_searchQuery);
  }

  /// Flag a network - mark it as suspicious but still allow connection with warning
  Future<void> flagNetwork(String networkId) async {
    _flaggedNetworkIds.add(networkId);
    _trustedNetworkIds.remove(networkId);
    
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.flagged,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    // Generate alert for flagged network
    if (_alertProvider != null) {
      _alertProvider!.generateFlaggedNetworkAlert(network);
    }
    
    // Sync with AccessPointService
    try {
      await _accessPointService.flagAccessPoint(network);
    } catch (e) {
      print('Failed to sync flagged network with AccessPointService: $e');
    }
    
    await _saveUserPreferences();
    _applyUserDefinedStatuses();
    notifyListeners();
  }

  /// Block a network - hide it from all lists and prevent connection
  Future<void> blockNetwork(String networkId) async {
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.blocked,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    _blockedNetworkIds.add(networkId);
    _trustedNetworkIds.remove(networkId);
    _flaggedNetworkIds.remove(networkId);
    
    // Generate alert for blocked network
    if (_alertProvider != null) {
      _alertProvider!.generateBlockedNetworkAlert(network);
    }
    
    // Sync with AccessPointService
    try {
      await _accessPointService.blockAccessPoint(network);
    } catch (e) {
      print('Failed to sync blocked network with AccessPointService: $e');
    }
    
    await _saveUserPreferences();
    _applyUserDefinedStatuses();
    notifyListeners();
  }

  /// Remove trust from a network
  Future<void> untrustNetwork(String networkId) async {
    _trustedNetworkIds.remove(networkId);
    
    // Find the network for AccessPointService sync
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.unknown,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    // Sync with AccessPointService
    try {
      await _accessPointService.untrustAccessPoint(network);
    } catch (e) {
      print('Failed to sync untrusted network with AccessPointService: $e');
    }
    
    await _saveUserPreferences();
    _applyUserDefinedStatuses();
    notifyListeners();
  }

  /// Remove flag from a network
  Future<void> unflagNetwork(String networkId) async {
    _flaggedNetworkIds.remove(networkId);
    
    // Find the network for AccessPointService sync
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.unknown,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    // Sync with AccessPointService
    try {
      await _accessPointService.unflagAccessPoint(network);
    } catch (e) {
      print('Failed to sync unflagged network with AccessPointService: $e');
    }
    
    await _saveUserPreferences();
    _applyUserDefinedStatuses();
    notifyListeners();
  }

  /// Unblock a network
  Future<void> unblockNetwork(String networkId) async {
    _blockedNetworkIds.remove(networkId);
    
    // Find the network for AccessPointService sync
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.unknown,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    // Sync with AccessPointService
    try {
      await _accessPointService.unblockAccessPoint(network);
    } catch (e) {
      print('Failed to sync unblocked network with AccessPointService: $e');
    }
    
    await _saveUserPreferences();
    _applyUserDefinedStatuses();
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

  /// Apply user-defined statuses to networks
  void _applyUserDefinedStatuses() {
    bool hasChanges = false;
    
    for (int i = 0; i < _networks.length; i++) {
      final network = _networks[i];
      
      // Store original status if not already stored and not user-managed
      if (!_originalStatuses.containsKey(network.id) && !network.isUserManaged) {
        _originalStatuses[network.id] = network.status;
      }
      
      NetworkStatus newStatus;
      bool isUserManaged = false;
      
      // Check if this network has user-defined status overrides
      if (_blockedNetworkIds.contains(network.id)) {
        newStatus = NetworkStatus.blocked;
        isUserManaged = true;
      } else if (_trustedNetworkIds.contains(network.id)) {
        newStatus = NetworkStatus.trusted;
        isUserManaged = true;
      } else if (_flaggedNetworkIds.contains(network.id)) {
        newStatus = NetworkStatus.flagged;
        isUserManaged = true;
      } else {
        // No user-defined status, restore original or keep current
        newStatus = _originalStatuses[network.id] ?? network.status;
        isUserManaged = _originalStatuses.containsKey(network.id) && network.isUserManaged;
      }
      
      if (newStatus != network.status || isUserManaged != network.isUserManaged) {
        _networks[i] = network.copyWith(
          status: newStatus,
          isUserManaged: isUserManaged,
          lastActionDate: isUserManaged ? DateTime.now() : network.lastActionDate,
        );
        
        // Update current network if it's the same network
        if (_currentNetwork?.id == network.id) {
          _currentNetwork = _networks[i];
        }
        
        hasChanges = true;
      }
    }
    
    // Update filtered networks only if there were changes
    if (hasChanges) {
      filterNetworks(_searchQuery);
      
      // Recalculate statistics to reflect status changes
      _calculateScanStatistics();
    }
  }

  /// Save user preferences to SharedPreferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('trusted_networks', _trustedNetworkIds.toList());
      await prefs.setStringList('blocked_networks', _blockedNetworkIds.toList());
      await prefs.setStringList('flagged_networks', _flaggedNetworkIds.toList());
      
      // Save original statuses
      final originalStatusesJson = <String>[];
      _originalStatuses.forEach((networkId, status) {
        originalStatusesJson.add('$networkId:${status.toString().split('.').last}');
      });
      await prefs.setStringList('original_statuses', originalStatusesJson);
    } catch (e) {
      print('Error saving user preferences: $e');
    }
  }

  /// Load user preferences from SharedPreferences
  Future<void> loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _trustedNetworkIds.addAll(prefs.getStringList('trusted_networks') ?? []);
      _blockedNetworkIds.addAll(prefs.getStringList('blocked_networks') ?? []);
      _flaggedNetworkIds.addAll(prefs.getStringList('flagged_networks') ?? []);
      
      // Load original statuses
      final originalStatusesJson = prefs.getStringList('original_statuses') ?? [];
      for (final entry in originalStatusesJson) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final networkId = parts[0];
          final statusName = parts[1];
          try {
            final status = NetworkStatus.values.firstWhere(
              (e) => e.toString().split('.').last == statusName,
            );
            _originalStatuses[networkId] = status;
          } catch (e) {
            print('Error parsing original status for $networkId: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  /// Check if connection should show warning
  bool shouldShowConnectionWarning(String networkId) {
    return _flaggedNetworkIds.contains(networkId) || 
           _networks.any((n) => n.id == networkId && n.status == NetworkStatus.suspicious);
  }

  /// Get connection warning message
  String getConnectionWarningMessage(String networkId) {
    final network = _networks.firstWhere((n) => n.id == networkId, orElse: () => NetworkModel(
      id: networkId,
      name: 'Unknown Network',
      description: 'Network details not available',
      status: NetworkStatus.unknown,
      securityType: SecurityType.open,
      signalStrength: 0,
      macAddress: '00:00:00:00:00:00',
      lastSeen: DateTime.now(),
    ));
    
    if (network.status == NetworkStatus.suspicious) {
      return 'This network has been identified as potentially malicious. Connecting may put your device at risk.';
    } else if (_flaggedNetworkIds.contains(networkId)) {
      return 'You have flagged this network as suspicious. Proceed with caution.';
    } else {
      return 'This network is not verified. Use caution when connecting.';
    }
  }
  
  /// Add verified government networks
  Future<void> _addVerifiedGovernmentNetworks() async {
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
  }
  
  /// Add commercial networks
  Future<void> _addCommercialNetworks() async {
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
  }
  
  /// Add suspicious networks (evil twins)
  Future<void> _addSuspiciousNetworks() async {
    final suspiciousNetworks = _generateEvilTwinNetworks();
    _networks.addAll(suspiciousNetworks);
    _performEvilTwinDetection();
  }
  
  /// Add unknown networks
  Future<void> _addUnknownNetworks() async {
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
  }
  
  /// Perform realistic scan with progress tracking
  Future<void> _performRealisticScanWithProgress() async {
    _networks.clear();
    notifyListeners();
    
    final scanSteps = [
      () => _addVerifiedGovernmentNetworks(),
      () => _addCommercialNetworks(), 
      () => _addSuspiciousNetworks(),
      () => _addUnknownNetworks(),
    ];
    
    for (int i = 0; i < scanSteps.length; i++) {
      await scanSteps[i]();
      _scanProgress = (i + 1) / scanSteps.length;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }
  
  /// Perform Firebase-enhanced scan with progress tracking
  Future<void> _performFirebaseEnhancedScanWithProgress() async {
    _networks.clear();
    notifyListeners();
    
    // Step 1: Add verified networks from Firebase whitelist
    _scanProgress = 0.25;
    if (_currentWhitelist != null) {
      final nearbyWhitelistedAPs = _currentWhitelist!.accessPoints
          .where((ap) => ap.status == 'active')
          .take(3)
          .toList();
      
      for (final ap in nearbyWhitelistedAPs) {
        _networks.add(NetworkModel(
          id: 'whitelist_${ap.id}',
          name: ap.ssid,
          description: 'DICT Verified Access Point - ${ap.city}, ${ap.province}',
          status: NetworkStatus.verified,
          securityType: SecurityType.wpa2,
          signalStrength: 75 + (ap.ssid.hashCode % 20),
          macAddress: ap.macAddress,
          latitude: ap.latitude,
          longitude: ap.longitude,
          lastSeen: DateTime.now(),
          isConnected: ap.ssid == 'DICT-CALABARZON-OFFICIAL',
        ));
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Step 2: Add commercial networks
    _scanProgress = 0.5;
    await _addCommercialNetworks();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Step 3: Add suspicious networks with Firebase verification
    _scanProgress = 0.75;
    await _addSuspiciousNetworks();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Step 4: Add unknown networks
    _scanProgress = 1.0;
    await _addUnknownNetworks();
    notifyListeners();
  }
  
  /// Perform real Wi-Fi scan with progress tracking
  Future<void> _performRealWiFiScanWithProgress() async {
    print('Performing real Wi-Fi scan with progress...');
    
    _networks.clear();
    notifyListeners();
    
    try {
      // Step 1: Initialize scan
      _scanProgress = 0.1;
      notifyListeners();
      
      // Step 2: Perform Wi-Fi scan
      _scanProgress = 0.3;
      final scannedNetworks = await _wifiScanner.performScan();
      notifyListeners();
      
      // Step 3: Process networks
      _scanProgress = 0.6;
      _networks = scannedNetworks;
      notifyListeners();
      
      // Step 4: Threat detection
      _scanProgress = 0.8;
      _performEvilTwinDetection();
      notifyListeners();
      
      // Step 5: Cross-reference with whitelist
      _scanProgress = 0.9;
      if (_firebaseEnabled && _currentWhitelist != null) {
        _crossReferenceWithWhitelist();
      }
      notifyListeners();
      
      // Step 6: Identify current network
      _scanProgress = 1.0;
      await _identifyCurrentNetwork();
      
      print('Real Wi-Fi scan completed: ${_networks.length} networks found');
      
    } catch (e) {
      print('Real Wi-Fi scan failed: $e');
      await _performRealisticScanWithProgress();
    }
  }
  
  /// Calculate scan statistics
  void _calculateScanStatistics() {
    _totalNetworksFound = _networks.length;
    _verifiedNetworksFound = _networks.where((n) => n.status == NetworkStatus.verified || n.status == NetworkStatus.trusted).length;
    _suspiciousNetworksFound = _networks.where((n) => n.status == NetworkStatus.suspicious).length;
    _threatsDetected = _suspiciousNetworksFound + _networks.where((n) => n.status == NetworkStatus.flagged).length;
  }
  
  /// Generate real-time alerts based on scan results
  Future<void> _generateScanBasedAlerts() async {
    if (_alertProvider == null) return;
    
    // Generate alerts for newly detected threats (only if not already alerted)
    final newThreats = <NetworkModel>[];
    for (var network in _networks) {
      if (network.status == NetworkStatus.suspicious) {
        final networkKey = '${network.name}_${network.macAddress}';
        if (!_alertedNetworksThisSession.contains(networkKey)) {
          _alertProvider!.generateAlertForNetwork(network);
          _alertedNetworksThisSession.add(networkKey);
          newThreats.add(network);
        }
      }
    }
    
    // Generate summary alert only for manual scans
    if (_hasPerformedScan && _lastScanTime != null && _isManualScan) {
      _alertProvider!.generateScanSummaryAlert(_totalNetworksFound, _threatsDetected, _lastScanTime!);
    }
    
    // If we found new threats in this scan, show an immediate notification
    if (newThreats.isNotEmpty) {
      print('New threats detected in this scan: ${newThreats.length}');
      // Force UI refresh to show new alerts immediately
      notifyListeners();
    }
  }
}