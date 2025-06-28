import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/network_provider.dart';
import '../../../../data/services/geocoding_service.dart';
import '../../../../data/services/access_point_service.dart';
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
  
  bool _isFullScreen = false;
  String _selectedProvince = 'All';
  LatLng? _currentLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _accessPointService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _isFullScreen ? MediaQuery.of(context).size.height * 0.8 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _buildMap(),
            _buildMapControls(),
            _buildLegend(),
            _buildCurrentLocationButton(),
          ],
        ),
      ),
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
            maxZoom: 16.0,
            // Restrict bounds to CALABARZON region
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(13.0, 120.0), // Southwest
                const LatLng(15.0, 122.0), // Northeast
              ),
            ),
            onTap: (tapPosition, point) => _onMapTap(point),
          ),
          children: [
            // Base map tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dict.disconx',
              maxZoom: 16,
            ),
            
            // Province boundaries (simplified)
            PolygonLayer(
              polygons: _buildProvincePolygons(),
            ),
            
            // Access point markers
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
            color: color.withOpacity(0.1),
            borderColor: color.withOpacity(0.3),
            borderStrokeWidth: 1.0,
          ),
        );
      }
    }

    return polygons;
  }

  List<Marker> _buildAccessPointMarkers(List<NetworkModel> networks) {
    final markers = <Marker>[];

    for (final network in networks) {
      if (network.latitude != null && network.longitude != null) {
        final position = LatLng(network.latitude!, network.longitude!);
        
        // Filter by province if selected
        if (_selectedProvince != 'All') {
          final cityInfo = _geocodingService.getCityInfo(network.cityName ?? '');
          if (cityInfo?['province'] != _selectedProvince) continue;
        }

        markers.add(
          Marker(
            point: position,
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () => _showAccessPointDetails(network),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getAccessPointColor(network),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getAccessPointIcon(network),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        );
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
              color: Colors.black.withOpacity(0.3),
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
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Province filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
          FloatingActionButton.small(
            heroTag: "fullscreen_button",
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
            },
            backgroundColor: Colors.white,
            elevation: 4,
            child: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Access Points',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Icons.verified, Colors.green, 'Verified'),
            _buildLegendItem(Icons.shield, Colors.blue, 'Trusted'),
            _buildLegendItem(Icons.warning, Colors.orange, 'Suspicious'),
            _buildLegendItem(Icons.block, Colors.red, 'Blocked'),
            _buildLegendItem(Icons.flag, Colors.purple, 'Flagged'),
            _buildLegendItem(Icons.help_outline, Colors.grey, 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
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
    print('Map tapped at: ${point.latitude}, ${point.longitude}');
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

  Widget _buildCurrentLocationButton() {
    return Positioned(
      bottom: 140,
      right: 16,
      child: FloatingActionButton.small(
        heroTag: "location_button",
        backgroundColor: AppColors.primary,
        elevation: 4,
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
            : const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      // Check permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = currentLatLng;
      });

      // Animate to current location
      _mapController.move(currentLatLng, 14.0);

      if (mounted) {
        // Get location name
        final locationName = _geocodingService.getCityName(
          position.latitude, 
          position.longitude,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Centered on ${locationName ?? 'your location'}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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