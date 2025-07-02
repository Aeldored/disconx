import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/network_provider.dart';
import '../../../../data/services/geocoding_service.dart';
import '../../../../data/services/access_point_service.dart';
import '../../../../data/services/permission_service.dart';
import '../../../../data/models/network_model.dart';

class NetworkMapWidget extends StatefulWidget {
  const NetworkMapWidget({super.key});

  @override
  State<NetworkMapWidget> createState() => _NetworkMapWidgetState();
}

class _NetworkMapWidgetState extends State<NetworkMapWidget> {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();
  final AccessPointService _accessPointService = AccessPointService();
  final PermissionService _permissionService = PermissionService();
  
  bool _isFullScreen = false;
  String _selectedProvince = 'All';
  LatLng? _currentLocation;
  bool _isLocating = false;
  bool _hasLocationPermission = false;
  bool _isLegendExpanded = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _accessPointService.initialize();
    _checkLocationPermission();
    
    // Set map as ready after a brief delay to allow for initialization
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    try {
      final status = await _permissionService.checkLocationPermission();
      if (mounted) {
        setState(() {
          _hasLocationPermission = status == PermissionStatus.granted;
        });
      }
    } catch (e) {
      developer.log('Error checking location permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Container(
      height: _isFullScreen 
          ? screenSize.height * 0.85 
          : isSmallScreen ? 280 : 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _buildMap(),
            
            // Loading overlay
            if (!_isMapReady)
              _buildLoadingOverlay(),
            
            // Map controls (only show when map is ready)
            if (_isMapReady)
              _buildMapControls(),
            
            // Legend (only show when map is ready and not in fullscreen on small screens)
            if (_isMapReady && (!_isFullScreen || !isSmallScreen))
              _buildLegend(),
              
            // Network status indicator
            if (_isMapReady)
              _buildNetworkStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading map...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusIndicator() {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        final networks = networkProvider.networks;
        if (networks.isEmpty) return const SizedBox.shrink();
        
        final suspiciousCount = networks.where((n) => n.status == NetworkStatus.suspicious).length;
        final totalCount = networks.length;
        
        return Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (suspiciousCount > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.warning, size: 12, color: Colors.orange),
                  const SizedBox(width: 2),
                  Text(
                    '$suspiciousCount',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        final networks = networkProvider.networks;
        
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _geocodingService.getCalabarzonCenter(),
            initialZoom: 9.0,
            minZoom: 8.0,
            maxZoom: 18.0,
            // Restrict bounds to CALABARZON region
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(13.0, 120.0), // Southwest
                const LatLng(15.0, 122.0), // Northeast
              ),
            ),
            onTap: (tapPosition, point) => _onMapTap(point),
            // Enhanced gesture handling
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Base map tiles with enhanced performance
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dict.disconx',
              maxZoom: 18,
              // Performance optimizations
              keepBuffer: 2,
              panBuffer: 1,
              // Error handling
              errorTileCallback: (tile, error, stackTrace) {
                developer.log('Map tile error: $error');
              },
            ),
            
            // Province boundaries (simplified)
            PolygonLayer(
              polygons: _buildProvincePolygons(),
            ),
            
            // Access point markers with performance optimization
            MarkerLayer(
              markers: _buildAccessPointMarkers(networks),
            ),
            
            // Current location marker
            if (_currentLocation != null)
              MarkerLayer(
                markers: [_buildCurrentLocationMarker()],
              ),
            
            // City labels
            MarkerLayer(
              markers: _buildCityLabels(),
            ),
          ],
        );
      },
    );
  }

  List<Polygon> _buildProvincePolygons() {
    final provinceColors = GeocodingService.getProvinceColors();
    final polygons = <Polygon>[];

    // Simplified province boundaries (in real implementation, use proper GeoJSON)
    final provinceBounds = {
      'Cavite': [
        const LatLng(14.6, 120.7),
        const LatLng(14.6, 121.2),
        const LatLng(14.0, 121.2),
        const LatLng(14.0, 120.7),
      ],
      'Laguna': [
        const LatLng(14.6, 121.0),
        const LatLng(14.6, 121.7),
        const LatLng(14.0, 121.7),
        const LatLng(14.0, 121.0),
      ],
      'Batangas': [
        const LatLng(14.2, 120.6),
        const LatLng(14.2, 121.6),
        const LatLng(13.4, 121.6),
        const LatLng(13.4, 120.6),
      ],
      'Rizal': [
        const LatLng(14.9, 121.0),
        const LatLng(14.9, 121.4),
        const LatLng(14.4, 121.4),
        const LatLng(14.4, 121.0),
      ],
      'Quezon': [
        const LatLng(14.3, 121.2),
        const LatLng(14.3, 122.2),
        const LatLng(13.5, 122.2),
        const LatLng(13.5, 121.2),
      ],
    };

    for (final entry in provinceBounds.entries) {
      final province = entry.key;
      final bounds = entry.value;
      final color = Color(provinceColors[province] ?? 0xFF9E9E9E);

      if (_selectedProvince == 'All' || _selectedProvince == province) {
        polygons.add(
          Polygon(
            points: bounds,
            color: color.withValues(alpha: 0.1),
            borderColor: color.withValues(alpha: 0.3),
            borderStrokeWidth: 1.0,
          ),
        );
      }
    }

    return polygons;
  }

  List<Marker> _buildAccessPointMarkers(List<NetworkModel> networks) {
    final markers = <Marker>[];
    
    // Performance optimization: limit markers based on zoom level
    // Use a default max markers approach since camera state might not be available
    final maxMarkers = networks.length > 100 ? 50 : networks.length;
    
    int markersAdded = 0;
    for (final network in networks) {
      if (markersAdded >= maxMarkers) break;
      
      if (network.latitude != null && network.longitude != null) {
        final position = LatLng(network.latitude!, network.longitude!);
        
        // Filter by province if selected
        if (_selectedProvince != 'All') {
          final cityInfo = _geocodingService.getCityInfo(network.cityName ?? '');
          if (cityInfo?['province'] != _selectedProvince) continue;
        }
        
        // Prioritize connected and suspicious networks
        if (markersAdded >= maxMarkers - 10 && 
            !network.isConnected && 
            network.status != NetworkStatus.suspicious) {
          continue;
        }

        markers.add(
          Marker(
            point: position,
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () => _showAccessPointDetails(network),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.8, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAccessPointColor(network),
                        border: Border.all(
                          color: Colors.white, 
                          width: network.isConnected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getAccessPointColor(network).withValues(alpha: 0.3),
                            blurRadius: network.isConnected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              _getAccessPointIcon(network),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          // Connection indicator
                          if (network.isConnected)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        markersAdded++;
      }
    }

    return markers;
  }

  List<Marker> _buildCityLabels() {
    final markers = <Marker>[];
    final cities = _geocodingService.getAllCities();

    for (final city in cities) {
      final coordinates = _geocodingService.getRandomCityCoordinates(city);
      if (coordinates != null) {
        final cityInfo = _geocodingService.getCityInfo(city);
        
        // Filter by province if selected
        if (_selectedProvince != 'All' && cityInfo?['province'] != _selectedProvince) {
          continue;
        }

        markers.add(
          Marker(
            point: coordinates,
            width: 80,
            height: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                city,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Marker _buildCurrentLocationMarker() {
    return Marker(
      point: _currentLocation!,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.person_pin,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Stack(
      children: [
        // Top-right controls (Province filter + Fullscreen)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Province filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedProvince,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  items: ['All', ..._geocodingService.getProvinces()]
                      .map((province) => DropdownMenuItem(
                            value: province,
                            child: Text(
                              province,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value ?? 'All';
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Fullscreen toggle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FloatingActionButton.small(
                  heroTag: "fullscreen_button",
                  onPressed: () {
                    setState(() {
                      _isFullScreen = !_isFullScreen;
                    });
                  },
                  backgroundColor: Colors.white,
                  elevation: 0,
                  child: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bottom-right controls (Location button)
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton.small(
              heroTag: "location_button",
              backgroundColor: _hasLocationPermission ? AppColors.primary : Colors.grey,
              elevation: 0,
              onPressed: _isLocating ? null : _centerOnCurrentLocation,
              child: _isLocating 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _hasLocationPermission ? Icons.my_location : Icons.location_disabled,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Positioned(
      bottom: isSmallScreen ? 70 : 80, // Position above the location button
      left: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7, // Responsive width
          maxHeight: _isLegendExpanded ? 200 : 50,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with toggle button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isLegendExpanded = !_isLegendExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Legend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isLegendExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Expandable content
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isLegendExpanded ? null : 0,
                child: _isLegendExpanded ? _buildLegendContent() : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Organize legend items in a more compact grid for mobile
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildCompactLegendItem(Icons.verified, Colors.green, 'Verified'),
              _buildCompactLegendItem(Icons.shield, Colors.blue, 'Trusted'),
              _buildCompactLegendItem(Icons.warning, Colors.orange, 'Suspicious'),
              _buildCompactLegendItem(Icons.block, Colors.red, 'Blocked'),
              _buildCompactLegendItem(Icons.flag, Colors.purple, 'Flagged'),
              _buildCompactLegendItem(Icons.help_outline, Colors.grey, 'Unknown'),
            ],
          ),
          const SizedBox(height: 8),
          // Additional helpful info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 12, color: Colors.blue[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tap markers for details',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }


  Color _getAccessPointColor(NetworkModel network) {
    switch (network.status) {
      case NetworkStatus.verified:
        return Colors.green;
      case NetworkStatus.trusted:
        return Colors.blue;
      case NetworkStatus.suspicious:
        return Colors.orange;
      case NetworkStatus.blocked:
        return Colors.red;
      case NetworkStatus.flagged:
        return Colors.purple;
      case NetworkStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getAccessPointIcon(NetworkModel network) {
    switch (network.status) {
      case NetworkStatus.verified:
        return Icons.verified;
      case NetworkStatus.trusted:
        return Icons.shield;
      case NetworkStatus.suspicious:
        return Icons.warning;
      case NetworkStatus.blocked:
        return Icons.block;
      case NetworkStatus.flagged:
        return Icons.flag;
      case NetworkStatus.unknown:
        return Icons.wifi;
    }
  }

  void _onMapTap(LatLng point) {
    // Future: Add new access point at tapped location
    developer.log('Map tapped at: ${point.latitude}, ${point.longitude}');
  }

  void _showAccessPointDetails(NetworkModel network) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccessPointDetailsSheet(
        network: network,
        onAction: (action) => _handleAccessPointAction(network, action),
      ),
    );
  }

  Future<void> _handleAccessPointAction(NetworkModel network, AccessPointAction action) async {
    try {
      switch (action) {
        case AccessPointAction.block:
          await _accessPointService.blockAccessPoint(network);
          break;
        case AccessPointAction.trust:
          await _accessPointService.trustAccessPoint(network);
          break;
        case AccessPointAction.flag:
          await _accessPointService.flagAccessPoint(network);
          break;
        case AccessPointAction.unblock:
          await _accessPointService.unblockAccessPoint(network);
          break;
        case AccessPointAction.untrust:
          await _accessPointService.untrustAccessPoint(network);
          break;
        case AccessPointAction.unflag:
          await _accessPointService.unflagAccessPoint(network);
          break;
      }

      // Refresh the network provider to update the UI
      if (mounted) {
        context.read<NetworkProvider>().refreshNetworks();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access point ${action.name}ed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.name} access point: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _centerOnCurrentLocation() async {
    if (_isLocating) return;

    // Early permission check
    if (!_hasLocationPermission) {
      await _requestLocationPermission();
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      // Double-check location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationSettingsDialog();
        return;
      }

      // Get current position with timeout and error handling
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception('Location request timed out'),
        );
      } catch (e) {
        developer.log('Location fetch error: $e');
        throw Exception('Unable to get your current location. Please try again.');
      }

      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      // Validate coordinates are reasonable (within CALABARZON region or nearby)
      if (!_isLocationValid(currentLatLng)) {
        throw Exception('Location seems inaccurate. Please check your GPS signal.');
      }
      
      if (!mounted) return;

      setState(() {
        _currentLocation = currentLatLng;
      });

      // Animate to current location with smooth transition
      try {
        _mapController.move(currentLatLng, 14.0);
      } catch (e) {
        developer.log('Map animation error: $e');
        // Fallback: try without animation
        _mapController.move(currentLatLng, 14.0);
      }

      if (mounted) {
        // Get location name asynchronously to avoid blocking UI
        String locationName = 'your location';
        try {
          final name = _geocodingService.getCityName(
            position.latitude, 
            position.longitude,
          );
          locationName = name ?? locationName;
        } catch (e) {
          developer.log('Geocoding error: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Centered on $locationName')),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      developer.log('Location centering failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _centerOnCurrentLocation,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  bool _isLocationValid(LatLng location) {
    // Check if location is within reasonable bounds (Philippines + buffer)
    const double minLat = 4.0;   // Southern Philippines
    const double maxLat = 21.0;  // Northern Philippines
    const double minLng = 116.0; // Western Philippines
    const double maxLng = 127.0; // Eastern Philippines
    
    return location.latitude >= minLat && 
           location.latitude <= maxLat &&
           location.longitude >= minLng && 
           location.longitude <= maxLng;
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Show rationale first
      final shouldRequest = await _permissionService.showPermissionRationale(
        context, 
        'location',
      );
      
      if (!shouldRequest || !mounted) return;

      final status = await _permissionService.requestLocationPermission();
      
      if (mounted) {
        setState(() {
          _hasLocationPermission = status == PermissionStatus.granted;
        });

        if (status == PermissionStatus.granted) {
          // Permission granted, now try to center location
          _centerOnCurrentLocation();
        } else if (status == PermissionStatus.permanentlyDenied) {
          // Show settings dialog
          await _permissionService.showSettingsDialog(context);
        } else {
          // Permission denied
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to center the map'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Permission request error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationSettingsDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Services Disabled'),
          ],
        ),
        content: const Text(
          'Location services are turned off. Please enable them in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// Access Point Details Bottom Sheet
class AccessPointDetailsSheet extends StatelessWidget {
  final NetworkModel network;
  final Function(AccessPointAction) onAction;

  const AccessPointDetailsSheet({
    super.key,
    required this.network,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getStatusIcon(network.status),
                  color: _getStatusColor(network.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        network.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        network.statusDisplayName,
                        style: TextStyle(
                          color: _getStatusColor(network.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Details
            _buildDetailRow('Location', network.displayLocation),
            _buildDetailRow('MAC Address', network.macAddress),
            _buildDetailRow('Security', network.securityTypeString),
            _buildDetailRow('Signal Strength', '${network.signalStrength}% (${network.signalStrengthString})'),
            _buildDetailRow('Last Seen', _formatDateTime(network.lastSeen)),
            
            if (network.address != null)
              _buildDetailRow('Address', network.address!),
            
            if (network.isUserManaged && network.lastActionDate != null)
              _buildDetailRow('Last Action', _formatDateTime(network.lastActionDate!)),

            const SizedBox(height: 24),

            // Action buttons
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildActionButtons(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];

    switch (network.status) {
      case NetworkStatus.blocked:
        buttons.add(_buildActionButton(
          'Unblock',
          Icons.check_circle,
          Colors.green,
          () => onAction(AccessPointAction.unblock),
        ));
        break;
        
      case NetworkStatus.trusted:
        buttons.add(_buildActionButton(
          'Untrust',
          Icons.remove_circle,
          Colors.orange,
          () => onAction(AccessPointAction.untrust),
        ));
        buttons.add(_buildActionButton(
          'Block',
          Icons.block,
          Colors.red,
          () => onAction(AccessPointAction.block),
        ));
        break;
        
      case NetworkStatus.flagged:
        buttons.add(_buildActionButton(
          'Unflag',
          Icons.outlined_flag,
          Colors.grey,
          () => onAction(AccessPointAction.unflag),
        ));
        buttons.add(_buildActionButton(
          'Block',
          Icons.block,
          Colors.red,
          () => onAction(AccessPointAction.block),
        ));
        break;
        
      default:
        buttons.add(_buildActionButton(
          'Trust',
          Icons.shield,
          Colors.blue,
          () => onAction(AccessPointAction.trust),
        ));
        buttons.add(_buildActionButton(
          'Block',
          Icons.block,
          Colors.red,
          () => onAction(AccessPointAction.block),
        ));
        buttons.add(_buildActionButton(
          'Flag',
          Icons.flag,
          Colors.purple,
          () => onAction(AccessPointAction.flag),
        ));
        break;
    }

    return buttons;
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getStatusColor(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.verified:
        return Colors.green;
      case NetworkStatus.trusted:
        return Colors.blue;
      case NetworkStatus.suspicious:
        return Colors.orange;
      case NetworkStatus.blocked:
        return Colors.red;
      case NetworkStatus.flagged:
        return Colors.purple;
      case NetworkStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.verified:
        return Icons.verified;
      case NetworkStatus.trusted:
        return Icons.shield;
      case NetworkStatus.suspicious:
        return Icons.warning;
      case NetworkStatus.blocked:
        return Icons.block;
      case NetworkStatus.flagged:
        return Icons.flag;
      case NetworkStatus.unknown:
        return Icons.wifi;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}