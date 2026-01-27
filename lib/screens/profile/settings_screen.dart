import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // App Preferences
  bool _darkMode = false;
  String _language = 'English';
  String _currency = 'PHP (₱)';

  // Display Settings
  bool _highContrast = false;
  String _fontSize = 'Medium';

  // Booking Settings
  bool _autoConfirm = true;
  bool _locationServices = true;
  String _defaultServiceType = 'Same Day';

  // Data & Storage
  bool _autoDownloadUpdates = true;
  bool _cacheEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App Preferences Section
          const Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            children: [
              _SwitchSetting(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Enable dark theme',
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_darkMode ? 'Dark mode enabled' : 'Light mode enabled'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _SelectSetting(
                icon: Icons.language,
                title: 'Language',
                subtitle: _language,
                onTap: () => _showLanguagePicker(),
              ),
              const Divider(height: 1),
              _SelectSetting(
                icon: Icons.attach_money,
                title: 'Currency',
                subtitle: _currency,
                onTap: () => _showCurrencyPicker(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Display Settings Section
          const Text(
            'Display Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            children: [
              _SwitchSetting(
                icon: Icons.contrast,
                title: 'High Contrast',
                subtitle: 'Improve readability',
                value: _highContrast,
                onChanged: (value) {
                  setState(() => _highContrast = value);
                },
              ),
              const Divider(height: 1),
              _SelectSetting(
                icon: Icons.text_fields,
                title: 'Font Size',
                subtitle: _fontSize,
                onTap: () => _showFontSizePicker(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Booking Settings Section
          const Text(
            'Booking Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            children: [
              _SwitchSetting(
                icon: Icons.check_circle,
                title: 'Auto-Confirm Bookings',
                subtitle: 'Skip confirmation step',
                value: _autoConfirm,
                onChanged: (value) {
                  setState(() => _autoConfirm = value);
                },
              ),
              const Divider(height: 1),
              _SwitchSetting(
                icon: Icons.location_on,
                title: 'Location Services',
                subtitle: 'Allow location access',
                value: _locationServices,
                onChanged: (value) {
                  setState(() => _locationServices = value);
                },
              ),
              const Divider(height: 1),
              _SelectSetting(
                icon: Icons.schedule,
                title: 'Default Service Type',
                subtitle: _defaultServiceType,
                onTap: () => _showServiceTypePicker(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data & Storage Section
          const Text(
            'Data & Storage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            children: [
              _SwitchSetting(
                icon: Icons.cloud_download,
                title: 'Auto-Download Updates',
                subtitle: 'Download updates automatically',
                value: _autoDownloadUpdates,
                onChanged: (value) {
                  setState(() => _autoDownloadUpdates = value);
                },
              ),
              const Divider(height: 1),
              _SwitchSetting(
                icon: Icons.storage,
                title: 'Cache Data',
                subtitle: 'Store data locally for faster access',
                value: _cacheEnabled,
                onChanged: (value) {
                  setState(() => _cacheEnabled = value);
                },
              ),
              const Divider(height: 1),
              _ActionSetting(
                icon: Icons.delete_sweep,
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                onTap: () => _showClearCacheDialog(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Advanced Settings Section
          const Text(
            'Advanced',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            children: [
              _ActionSetting(
                icon: Icons.refresh,
                title: 'Reset Settings',
                subtitle: 'Restore default settings',
                onTap: () => _showResetDialog(),
              ),
              const Divider(height: 1),
              _ActionSetting(
                icon: Icons.info,
                title: 'App Version',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'FixIt',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.build, size: 48, color: AppTheme.deepBlue),
                    children: const [
                      Text('Device repair service platform connecting customers with certified technicians.'),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'English',
              'Filipino',
              'Spanish',
              'Chinese',
            ].map((lang) => ListTile(
              title: Text(lang),
              trailing: _language == lang ? const Icon(Icons.check, color: AppTheme.deepBlue) : null,
              onTap: () {
                setState(() => _language = lang);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $lang')),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'PHP (₱)',
              'USD (\$)',
              'EUR (€)',
              'GBP (£)',
            ].map((curr) => ListTile(
              title: Text(curr),
              trailing: _currency == curr ? const Icon(Icons.check, color: AppTheme.deepBlue) : null,
              onTap: () {
                setState(() => _currency = curr);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFontSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Font Size',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'Small',
              'Medium',
              'Large',
              'Extra Large',
            ].map((size) => ListTile(
              title: Text(size),
              trailing: _fontSize == size ? const Icon(Icons.check, color: AppTheme.deepBlue) : null,
              onTap: () {
                setState(() => _fontSize = size);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showServiceTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Service Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'Emergency',
              'Same Day',
              'A Week',
            ].map((type) => ListTile(
              title: Text(type),
              trailing: _defaultServiceType == type ? const Icon(Icons.check, color: AppTheme.deepBlue) : null,
              onTap: () {
                setState(() => _defaultServiceType = type);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache'),
        content: const Text('This will delete all cached data. The app may take longer to load the first time after clearing cache.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Settings'),
        content: const Text('This will restore all settings to their default values. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _darkMode = false;
                _language = 'English';
                _currency = 'PHP (₱)';
                _highContrast = false;
                _fontSize = 'Medium';
                _autoConfirm = true;
                _locationServices = true;
                _defaultServiceType = 'Same Day';
                _autoDownloadUpdates = true;
                _cacheEnabled = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.deepBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.deepBlue,
          ),
        ],
      ),
    );
  }
}

class _SelectSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.deepBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.deepBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
