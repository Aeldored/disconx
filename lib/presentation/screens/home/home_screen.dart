import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/network_model.dart';
import '../../../data/services/access_point_service.dart';
import '../../../providers/network_provider.dart';
import 'widgets/network_map_widget.dart';
import 'widgets/connection_info_widget.dart';
import 'widgets/network_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AccessPointService _accessPointService = AccessPointService();

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
    await provider.loadNearbyNetworks();
  }

  Future<void> _handleRefresh() async {
    setState(() {
    });
    
    await _loadNetworks();
    
    setState(() {
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
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
                  ),
                ],
              ),
            ),
          ),
          
          // Nearby Networks Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Nearby Networks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Network List
          Consumer<NetworkProvider>(
            builder: (context, provider, child) {
              final networks = provider.filteredNetworks;
              
              if (provider.isLoading && networks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (networks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No networks found',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  ),
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

  void _handleConnect(NetworkModel network) {
    // TODO: Implement connection logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to ${network.name}...'),
        backgroundColor: AppColors.primary,
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

      // Refresh the networks list to show updated status
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
}