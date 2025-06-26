import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/network_model.dart';
import '../../../widgets/status_badge.dart';

class ConnectionInfoWidget extends StatelessWidget {
  final NetworkModel? currentNetwork;

  const ConnectionInfoWidget({
    super.key,
    required this.currentNetwork,
  });

  @override
  Widget build(BuildContext context) {
    if (currentNetwork == null) {
      return _buildNoConnection();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Connection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.wifi,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentNetwork!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: currentNetwork!.status),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Signal Strength',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            _buildSignalStrength(currentNetwork!.signalBars),
          ],
        ),
      ],
    );
  }

  Widget _buildNoConnection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            'No active connection',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
            color: index < bars ? AppColors.primary : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}