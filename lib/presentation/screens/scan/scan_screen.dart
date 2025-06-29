import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/network_model.dart';
import '../../../providers/network_provider.dart';
import 'widgets/scan_animation_widget.dart';
import 'widgets/scan_result_item.dart' show ScanResult, ScanStatus, ScanResultItem;
import '../main_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Start scanning using the centralized provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NetworkProvider>();
      if (!provider.hasPerformedScan || provider.networks.isEmpty) {
        // Auto-scan when entering the screen (not manual)
        provider.startNetworkScan(forceRescan: false, isManualScan: false);
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startScanning() {
    final provider = context.read<NetworkProvider>();
    provider.startNetworkScan(forceRescan: true, isManualScan: true);
  }

  List<ScanResult> _convertNetworksToScanResults(List<NetworkModel> networks) {
    return networks.where((network) => network.status != NetworkStatus.blocked).map((network) {
      ScanStatus status;
      String description;
      
      switch (network.status) {
        case NetworkStatus.verified:
        case NetworkStatus.trusted:
          status = ScanStatus.verified;
          description = network.status == NetworkStatus.trusted 
              ? 'Trusted by user' 
              : (network.description ?? 'Verified network');
          break;
        case NetworkStatus.suspicious:
          status = ScanStatus.suspicious;
          description = 'Suspicious - potential threat detected';
          break;
        case NetworkStatus.flagged:
          status = ScanStatus.suspicious;
          description = 'Flagged as suspicious by user';
          break;
        case NetworkStatus.blocked:
          // Blocked networks are filtered out above
          status = ScanStatus.suspicious;
          description = 'Blocked network';
          break;
        default:
          status = ScanStatus.unknown;
          description = network.description ?? 'Unknown network';
      }
      
      final timeAgo = _formatTimeAgo(network.lastSeen);
      
      return ScanResult(
        networkName: network.name,
        status: status,
        description: description,
        timeAgo: timeAgo,
      );
    }).toList();
  }
  
  String _formatTimeAgo(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _stopScanning() {
    final provider = context.read<NetworkProvider>();
    provider.stopNetworkScan();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        final scanResults = _convertNetworksToScanResults(networkProvider.networks);
        final isScanning = networkProvider.isScanning;
        final scanProgress = networkProvider.scanProgress;
        final networksFound = networkProvider.totalNetworksFound;
        final verifiedNetworks = networkProvider.verifiedNetworksFound;
        final threatsDetected = networkProvider.threatsDetected;
        
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Scan animation
                ScanAnimationWidget(isScanning: isScanning),
                const SizedBox(height: 32),
                
                // Title and description
                Text(
                  isScanning ? 'Scanning for Networks' : 'Scan Complete',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isScanning
                      ? 'Detecting nearby Wi-Fi networks and checking them against DICT\'s verified database'
                      : 'Found $networksFound networks, $verifiedNetworks verified${threatsDetected > 0 ? ', $threatsDetected threats detected' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Progress section
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Networks found: $networksFound',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Verified: $verifiedNetworks',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (threatsDetected > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Threats detected: $threatsDetected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: scanProgress,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            threatsDetected > 0 ? Colors.red : AppColors.primary
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Recent findings
                if (scanResults.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Findings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(scanResults.map((result) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScanResultItem(result: result),
                  ))),
                ],
                
                const SizedBox(height: 24),
                
                // Action button
                ElevatedButton.icon(
                  onPressed: isScanning ? _stopScanning : _startScanning,
                  icon: Icon(isScanning ? Icons.stop_circle : Icons.play_circle),
                  label: Text(isScanning ? 'Stop Scanning' : 'Start Scanning'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(200, 48),
                    backgroundColor: threatsDetected > 0 && !isScanning ? Colors.red : null,
                  ),
                ),
                
                // Navigation to alerts if threats detected
                if (threatsDetected > 0 && !isScanning) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _navigateToAlerts(),
                    icon: const Icon(Icons.shield),
                    label: const Text('View Security Alerts'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[600]!),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _navigateToAlerts() {
    // Navigate directly to the Alerts tab (index 2)
    MainScreen.navigateToTab(context, 2);
    
    // Show a brief confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Viewing security alerts'),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}