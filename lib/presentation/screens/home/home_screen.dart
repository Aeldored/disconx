import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/network_model.dart';
import '../../../data/services/access_point_service.dart';
import '../../../data/services/wifi_connection_service.dart';
import '../../../providers/network_provider.dart';
import 'widgets/network_map_widget.dart';
import 'widgets/connection_info_widget.dart';
import 'widgets/network_card.dart';
import '../main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AccessPointService _accessPointService = AccessPointService();
  final WiFiConnectionService _wifiConnectionService = WiFiConnectionService();

  @override
  void initState() {
    super.initState();
    _accessPointService.initialize();
    // Load networks after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNetworks();
    });
  }

  Future<void> _loadNetworks() async {
    final provider = context.read<NetworkProvider>();
    await provider.startNetworkScan(forceRescan: false, isManualScan: false);
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<NetworkProvider>();
    await provider.startNetworkScan(forceRescan: true, isManualScan: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildScanPrompt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final availableHeight = constraints.maxHeight;
        final isSmallScreen = screenHeight < 600;
        
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_find,
                          size: isSmallScreen ? 48 : 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Text(
                      'No Networks Discovered',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Flexible(
                      child: Text(
                        'Start a scan to discover nearby Wi-Fi networks and check for potential security threats.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    ElevatedButton.icon(
                      onPressed: _navigateToScan,
                      icon: const Icon(Icons.search),
                      label: const Text('Start Network Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 24 : 32,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        textStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    TextButton(
                      onPressed: () => _loadNetworks(),
                      child: Text(
                        'Load Sample Networks',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24), // Bottom spacing
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyNetworksState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 600;
        
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off,
                          size: isSmallScreen ? 48 : 64,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Text(
                      'No Networks Found',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Flexible(
                      child: Text(
                        'The scan completed but no Wi-Fi networks were detected in your area. This could be due to distance from access points or network availability.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    ElevatedButton.icon(
                      onPressed: _navigateToScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 24 : 32,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        textStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToScan() {
    // Start scanning using the shared provider
    final provider = context.read<NetworkProvider>();
    provider.startNetworkScan(forceRescan: true, isManualScan: true);
    
    // Navigate to the Scan tab (index 1)
    MainScreen.navigateToTab(context, 1);
    
    // Show a brief message indicating scan has started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Network scan started'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshConnectionInfo() async {
    final provider = context.read<NetworkProvider>();
    // Force refresh of current connection info
    await provider.refreshNetworks();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Map Section
          const SliverToBoxAdapter(
            child: NetworkMapWidget(),
          ),
          
          // Connection Info and Search Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Consumer<NetworkProvider>(
                    builder: (context, provider, child) {
                      return ConnectionInfoWidget(
                        currentNetwork: provider.currentNetwork,
                        onScanTap: () => _navigateToScan(),
                        onRefreshConnection: () => _refreshConnectionInfo(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Search Bar - only show if networks exist
                  Consumer<NetworkProvider>(
                    builder: (context, provider, child) {
                      if (provider.networks.isEmpty && !provider.isLoading) {
                        return const SizedBox.shrink();
                      }
                      return TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for Wi-Fi networks...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: AppColors.bgGray,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          context.read<NetworkProvider>().filterNetworks(value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Nearby Networks Section with Scanning Status
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Consumer<NetworkProvider>(
                builder: (context, provider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nearby Networks',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (provider.wifiScanningEnabled) ...[
                        Icon(
                          Icons.wifi_find,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live Scan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Demo Mode',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Network List
          Consumer<NetworkProvider>(
            builder: (context, provider, child) {
              final networks = provider.filteredNetworks.where((n) => n.status != NetworkStatus.blocked).toList();
              
              if (provider.isLoading && networks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Show scan prompt if no scan has been performed or no networks found
              if (networks.isEmpty && !provider.isLoading && !provider.hasPerformedScan) {
                return SliverFillRemaining(
                  child: _buildScanPrompt(),
                );
              }
              
              // Show empty state if scan was performed but no networks found
              if (networks.isEmpty && !provider.isLoading && provider.hasPerformedScan) {
                return SliverFillRemaining(
                  child: _buildEmptyNetworksState(),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return NetworkCard(
                        network: networks[index],
                        onConnect: () => _handleConnect(networks[index]),
                        onReview: () => _handleReview(networks[index]),
                        onAccessPointAction: (action) => _handleAccessPointAction(networks[index], action),
                      );
                    },
                    childCount: networks.length,
                  ),
                ),
              );
            },
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnect(NetworkModel network) async {
    try {
      String? password;
      
      // Show password dialog if network is secured
      if (network.securityType != SecurityType.open) {
        password = await _wifiConnectionService.showPasswordDialog(context, network);
        if (password == null) {
          // User cancelled password dialog
          return;
        }
      }
      
      // Show connecting snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting to ${network.name}...'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Attempt connection
      final result = await _wifiConnectionService.connectToNetwork(
        context,
        network,
        password: password,
      );
      
      // Handle connection result
      if (mounted) {
        _handleConnectionResult(result, network);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to ${network.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _handleConnectionResult(WiFiConnectionResult result, NetworkModel network) {
    String message;
    Color backgroundColor;
    
    switch (result) {
      case WiFiConnectionResult.success:
        message = 'Successfully connected to ${network.name}';
        backgroundColor = Colors.green;
        break;
      case WiFiConnectionResult.redirectedToSettings:
        message = 'Redirected to Wi-Fi settings. Find "${network.name}" to complete connection.';
        backgroundColor = AppColors.primary;
        break;
      case WiFiConnectionResult.failed:
        message = 'Failed to connect to ${network.name}';
        backgroundColor = Colors.red;
        break;
      case WiFiConnectionResult.passwordRequired:
        message = 'Password required for ${network.name}';
        backgroundColor = Colors.orange;
        break;
      case WiFiConnectionResult.permissionDenied:
        message = 'Permission denied. Please grant Wi-Fi and location permissions.';
        backgroundColor = Colors.red;
        break;
      case WiFiConnectionResult.userCancelled:
        return; // Don't show message for user cancellation
      case WiFiConnectionResult.notSupported:
        message = 'Direct connection not supported. Use device Wi-Fi settings.';
        backgroundColor = Colors.orange;
        break;
      case WiFiConnectionResult.error:
        message = 'Connection error occurred';
        backgroundColor = Colors.red;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        action: result == WiFiConnectionResult.permissionDenied
            ? SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Open app settings
                },
              )
            : null,
      ),
    );
  }

  void _handleReview(NetworkModel network) {
    // TODO: Implement review logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Network'),
        content: Text(
          'Review the security status of "${network.name}"?\n\n'
          'This will help improve our database and protect other users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Submit review
            },
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccessPointAction(NetworkModel network, AccessPointAction action) async {
    if (!mounted) return;
    
    final provider = context.read<NetworkProvider>();
    String actionText = '';
    Color feedbackColor = Colors.green;
    
    try {
      switch (action) {
        case AccessPointAction.block:
          await provider.blockNetwork(network.id);
          actionText = 'blocked';
          feedbackColor = Colors.red;
          break;
        case AccessPointAction.trust:
          await provider.trustNetwork(network.id);
          actionText = 'added to trusted list';
          feedbackColor = Colors.green;
          break;
        case AccessPointAction.flag:
          await provider.flagNetwork(network.id);
          actionText = 'flagged as suspicious';
          feedbackColor = Colors.orange;
          break;
        case AccessPointAction.unblock:
          await provider.unblockNetwork(network.id);
          actionText = 'unblocked';
          feedbackColor = Colors.blue;
          break;
        case AccessPointAction.untrust:
          await provider.untrustNetwork(network.id);
          actionText = 'removed from trusted list';
          feedbackColor = Colors.grey;
          break;
        case AccessPointAction.unflag:
          await provider.unflagNetwork(network.id);
          actionText = 'unflagged';
          feedbackColor = Colors.blue;
          break;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _getActionIcon(action),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('"${network.name}" has been $actionText'),
                ),
              ],
            ),
            backgroundColor: feedbackColor,
            duration: const Duration(seconds: 3),
            action: action == AccessPointAction.block
                ? SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () => _handleAccessPointAction(network, AccessPointAction.unblock),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.name.toLowerCase()} "${network.name}": $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  IconData _getActionIcon(AccessPointAction action) {
    switch (action) {
      case AccessPointAction.trust:
        return Icons.shield;
      case AccessPointAction.flag:
        return Icons.flag;
      case AccessPointAction.block:
        return Icons.block;
      case AccessPointAction.untrust:
        return Icons.remove_circle;
      case AccessPointAction.unflag:
        return Icons.outlined_flag;
      case AccessPointAction.unblock:
        return Icons.lock_open;
    }
  }
}