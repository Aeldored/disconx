import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/network_provider.dart';

class NetworkMapWidget extends StatefulWidget {
  const NetworkMapWidget({super.key});

  @override
  State<NetworkMapWidget> createState() => _NetworkMapWidgetState();
}

class _NetworkMapWidgetState extends State<NetworkMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Map View (Offline Mode)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enable internet to view network locations',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}