import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/network_model.dart';
import '../../../widgets/status_badge.dart';

class NetworkCard extends StatelessWidget {
  final NetworkModel network;
  final VoidCallback? onConnect;
  final VoidCallback? onReview;
  final VoidCallback? onBlock;

  const NetworkCard({
    super.key,
    required this.network,
    this.onConnect,
    this.onReview,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showNetworkDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (network.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            network.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: network.status),
                ],
              ),
              
              // Alert if needed
              if (network.status == NetworkStatus.suspicious) ...[
                const SizedBox(height: 12),
                _buildAlert(
                  icon: Icons.shield,
                  message: 'Potential evil twin attack detected! Avoid connecting to this network.',
                  type: AlertType.danger,
                ),
              ] else if (network.status == NetworkStatus.unknown) ...[
                const SizedBox(height: 12),
                _buildAlert(
                  icon: Icons.warning_amber_rounded,
                  message: 'This network is not on DICT\'s verified list. Use with caution.',
                  type: AlertType.warning,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Network info
                  Row(
                    children: [
                      Icon(
                        network.securityType == SecurityType.open
                            ? Icons.lock_open
                            : Icons.lock,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        network.securityTypeString,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.signal_cellular_4_bar,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        network.signalStrengthString,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // Action button
                  _buildActionButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlert({
    required IconData icon,
    required String message,
    required AlertType type,
  }) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case AlertType.danger:
        bgColor = AppColors.alertDangerBg;
        textColor = AppColors.alertDangerText;
        borderColor = AppColors.alertDangerBorder;
        break;
      case AlertType.warning:
        bgColor = AppColors.alertWarningBg;
        textColor = AppColors.alertWarningText;
        borderColor = AppColors.alertWarningBorder;
        break;
      case AlertType.success:
        bgColor = AppColors.alertSuccessBg;
        textColor = AppColors.alertSuccessText;
        borderColor = AppColors.alertSuccessBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (network.status == NetworkStatus.verified) {
      return ElevatedButton(
        onPressed: onConnect,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(80, 32),
        ),
        child: const Text('Connect', style: TextStyle(fontSize: 14)),
      );
    } else if (network.status == NetworkStatus.unknown) {
      return ElevatedButton(
        onPressed: onReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(80, 32),
        ),
        child: const Text('Review', style: TextStyle(fontSize: 14)),
      );
    } else {
      return ElevatedButton(
        onPressed: onBlock,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(80, 32),
        ),
        child: const Text('Block', style: TextStyle(fontSize: 14)),
      );
    }
  }

  void _showNetworkDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Network name and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          network.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StatusBadge(status: network.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Details grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Network Name', network.name),
                        const SizedBox(height: 12),
                        _buildDetailRow('Security', network.securityTypeString),
                        const SizedBox(height: 12),
                        _buildDetailRow('MAC Address', network.macAddress),
                        const SizedBox(height: 12),
                        _buildDetailRow('Signal Strength', '${network.signalStrength}%'),
                        if (network.description != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow('Location', network.description!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

enum AlertType { danger, warning, success }