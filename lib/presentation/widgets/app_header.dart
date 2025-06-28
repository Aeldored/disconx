import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final bool showSettingsIcon;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const AppHeader({
    super.key,
    required this.title,
    this.showNotificationIcon = true,
    this.showSettingsIcon = true,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      title: Row(
        children: [
          if (title == 'DisConX') ...[
            const Icon(
              Icons.shield,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (showNotificationIcon)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationTap,
            color: Colors.white,
          ),
        if (showSettingsIcon)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onSettingsTap,
            color: Colors.white,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}