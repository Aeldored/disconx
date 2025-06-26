import 'package:flutter/foundation.dart';
import '../data/models/network_model.dart';

class NetworkProvider extends ChangeNotifier {
  List<NetworkModel> _networks = [];
  List<NetworkModel> _filteredNetworks = [];
  NetworkModel? _currentNetwork;
  bool _isLoading = false;
  String _searchQuery = '';
  final Set<String> _blockedNetworkIds = {};

  List<NetworkModel> get networks => _networks;
  List<NetworkModel> get filteredNetworks => _filteredNetworks;
  NetworkModel? get currentNetwork => _currentNetwork;
  bool get isLoading => _isLoading;

  NetworkProvider() {
    _initializeMockData();
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

    // Simulate network loading delay
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual network scanning and Firebase fetch
    // For now, just refresh the mock data
    _initializeMockData();

    _isLoading = false;
    notifyListeners();
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

  void blockNetwork(String networkId) {
    _blockedNetworkIds.add(networkId);
    _networks.removeWhere((n) => n.id == networkId);
    _filteredNetworks.removeWhere((n) => n.id == networkId);
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
}