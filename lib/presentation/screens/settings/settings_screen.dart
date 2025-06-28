import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_item.dart';
import 'access_point_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize DisConX to match your preferences',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // General Settings
          SettingsSection(
            title: 'General Settings',
            children: [
              SettingsItem(
                icon: Icons.language,
                iconColor: AppColors.primary,
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('English', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppColors.gray),
                  ],
                ),
                onTap: () => _showLanguageDialog(context),
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SettingsItem(
                    icon: Icons.dark_mode,
                    iconColor: AppColors.primary,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: settings.isDarkMode,
                      onChanged: (value) => settings.toggleDarkMode(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SettingsItem(
                    icon: Icons.location_on,
                    iconColor: AppColors.primary,
                    title: 'Location Services',
                    subtitle: 'Required for finding nearby networks',
                    trailing: Switch(
                      value: settings.locationEnabled,
                      onChanged: (value) => settings.toggleLocation(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Security Settings
          SettingsSection(
            title: 'Security Settings',
            children: [
              SettingsItem(
                icon: Icons.router,
                iconColor: Colors.orange,
                title: 'Access Point Manager',
                subtitle: 'Manage blocked, trusted, and flagged networks',
                trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccessPointManagerScreen(),
                  ),
                ),
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SettingsItem(
                    icon: Icons.shield,
                    iconColor: AppColors.danger,
                    title: 'Auto-Block Suspicious Networks',
                    subtitle: 'Automatically block detected evil twin networks',
                    trailing: Switch(
                      value: settings.autoBlockSuspicious,
                      onChanged: (value) => settings.toggleAutoBlock(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SettingsItem(
                    icon: Icons.notifications,
                    iconColor: AppColors.warning,
                    title: 'Alert Notifications',
                    subtitle: 'Receive alerts for security threats',
                    trailing: Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (value) => settings.toggleNotifications(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SettingsItem(
                    icon: Icons.wifi_find,
                    iconColor: AppColors.primary,
                    title: 'Background Scanning',
                    subtitle: 'Periodically scan for networks in the background',
                    trailing: Switch(
                      value: settings.backgroundScanEnabled,
                      onChanged: (value) => settings.toggleBackgroundScan(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SettingsItem(
                    icon: Icons.vpn_lock,
                    iconColor: AppColors.success,
                    title: 'VPN Suggestions',
                    subtitle: 'Suggest using VPN on unsecured networks',
                    trailing: Switch(
                      value: settings.vpnSuggestionsEnabled,
                      onChanged: (value) => settings.toggleVpnSuggestions(),
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Data Management
          SettingsSection(
            title: 'Data Management',
            children: [
              SettingsItem(
                icon: Icons.storage,
                iconColor: Colors.purple,
                title: 'Storage Used',
                trailing: const Text('24.5 MB', style: TextStyle(color: AppColors.gray)),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.25,
                        backgroundColor: AppColors.lightGray,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              SettingsItem(
                icon: Icons.history,
                iconColor: AppColors.primary,
                title: 'Network History',
                subtitle: 'Set how long to keep your network history',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('30 days', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppColors.gray),
                  ],
                ),
                onTap: () => _showHistoryDialog(context),
              ),
              SettingsItem(
                icon: Icons.delete_outline,
                iconColor: AppColors.danger,
                title: 'Clear All Data',
                textColor: AppColors.danger,
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // About
          SettingsSection(
            title: 'About',
            children: [
              SettingsItem(
                icon: Icons.help_outline,
                iconColor: AppColors.primary,
                title: 'Help Center',
                onTap: () {},
              ),
              SettingsItem(
                icon: Icons.bug_report_outlined,
                iconColor: AppColors.primary,
                title: 'Report a Problem',
                onTap: () {},
              ),
              SettingsItem(
                icon: Icons.info_outline,
                iconColor: AppColors.primary,
                title: 'About DiSCon-X',
                trailing: const Text('v1.2.5', style: TextStyle(color: AppColors.gray, fontSize: 12)),
                onTap: () => _showAboutDialog(context),
              ),
              SettingsItem(
                icon: Icons.description_outlined,
                iconColor: AppColors.primary,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              SettingsItem(
                icon: Icons.article_outlined,
                iconColor: AppColors.primary,
                title: 'Terms of Service',
                onTap: () {},
              ),
            ],
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'DisConX: DICT-CALABARZON Secure Connect\n'
              'Department of Information and Communications Technology',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('English'),
              value: 'en',
              groupValue: 'en',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile(
              title: const Text('Filipino'),
              value: 'fil',
              groupValue: 'en',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network History Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('7 days'),
              value: 7,
              groupValue: 30,
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile(
              title: const Text('30 days'),
              value: 30,
              groupValue: 30,
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile(
              title: const Text('90 days'),
              value: 90,
              groupValue: 30,
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your network history, saved preferences, '
          'and blocked networks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About DiSCon-X'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DiSCon-X v1.2.5',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'DICT Secure Connect is the official Wi-Fi security app '
              'developed by the Department of Information and Communications '
              'Technology - CALABARZON for detecting and preventing evil twin '
              'attacks on public Wi-Fi networks.',
            ),
            SizedBox(height: 16),
            Text(
              '© 2025 DICT-CALABARZON',
              style: TextStyle(fontSize: 12, color: AppColors.gray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}