import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/network_model.dart';
import '../../../widgets/status_badge.dart';

class ConnectionInfoWidget extends StatelessWidget {
  final NetworkModel? currentNetwork;
  final VoidCallback? onScanTap;
  final VoidCallback? onRefreshConnection;

  const ConnectionInfoWidget({
    super.key,
    required this.currentNetwork,
    this.onScanTap,
    this.onRefreshConnection,
  });

  @override
  Widget build(BuildContext context) {
    if (currentNetwork == null) {
      return _buildNoConnection();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getConnectionBorderColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Connected to',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: currentNetwork!.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _getConnectionIcon(),
                          color: _getConnectionColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currentNetwork!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: _getConnectionColor(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (currentNetwork!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentNetwork!.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefreshConnection,
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Refresh connection',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signal Strength',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildSignalStrength(currentNetwork!.signalBars),
                      const SizedBox(width: 8),
                      Text(
                        '${currentNetwork!.signalStrength}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        currentNetwork!.securityType == SecurityType.open
                            ? Icons.lock_open
                            : Icons.lock,
                        size: 14,
                        color: currentNetwork!.securityType == SecurityType.open
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentNetwork!.securityTypeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoConnection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Connection',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Not connected to any Wi-Fi network',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefreshConnection,
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Refresh connection info',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onScanTap,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Find Networks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStrength(int bars) {
    return Row(
      children: List.generate(
        4,
        (index) => Container(
          width: 6,
          height: 12 + (index * 3),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: index < bars ? _getSignalColor(bars) : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Color _getConnectionBorderColor() {
    if (currentNetwork == null) return Colors.grey[300]!;
    
    switch (currentNetwork!.status) {
      case NetworkStatus.verified:
      case NetworkStatus.trusted:
        return Colors.green;
      case NetworkStatus.suspicious:
        return Colors.red;
      case NetworkStatus.flagged:
        return Colors.orange;
      case NetworkStatus.unknown:
        return Colors.blue;
      case NetworkStatus.blocked:
        return Colors.red;
    }
  }

  Color _getConnectionColor() {
    if (currentNetwork == null) return Colors.grey[600]!;
    
    switch (currentNetwork!.status) {
      case NetworkStatus.verified:
      case NetworkStatus.trusted:
        return Colors.green[700]!;
      case NetworkStatus.suspicious:
        return Colors.red[700]!;
      case NetworkStatus.flagged:
        return Colors.orange[700]!;
      case NetworkStatus.unknown:
        return Colors.blue[700]!;
      case NetworkStatus.blocked:
        return Colors.red[700]!;
    }
  }

  IconData _getConnectionIcon() {
    if (currentNetwork == null) return Icons.wifi_off;
    
    switch (currentNetwork!.status) {
      case NetworkStatus.verified:
      case NetworkStatus.trusted:
        return Icons.wifi_protected_setup;
      case NetworkStatus.suspicious:
        return Icons.warning;
      case NetworkStatus.flagged:
        return Icons.flag;
      case NetworkStatus.unknown:
        return Icons.wifi;
      case NetworkStatus.blocked:
        return Icons.block;
    }
  }

  Color _getSignalColor(int bars) {
    if (bars >= 3) return Colors.green;
    if (bars >= 2) return Colors.orange;
    return Colors.red;
  }
}