import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/privacy_policy_screen.dart';
import '../auth/terms_conditions_screen.dart';
class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});
  @override
  ConsumerState<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}
class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  bool _twoFactorAuth = false;
  bool _biometricLogin = true;
  bool _shareDataWithTechnicians = true;
  bool _allowLocationTracking = true;
  static const _k2FA = 'priv_2fa';
  static const _kBio = 'priv_biometric';
  static const _kShare = 'priv_share_data';
  static const _kLocation = 'priv_location';
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _twoFactorAuth = prefs.getBool(_k2FA) ?? false;
      _biometricLogin = prefs.getBool(_kBio) ?? true;
      _shareDataWithTechnicians = prefs.getBool(_kShare) ?? true;
      _allowLocationTracking = prefs.getBool(_kLocation) ?? true;
    });
  }
  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  void _changePassword() {
    final email = ref.read(currentUserProvider).value?.email ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePasswordSheet(email: email),
    );
  }
  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppTheme.errorColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimaryColor,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deletion requested'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _SectionHeader(
              icon: Icons.shield_rounded,
              iconColor: AppTheme.deepBlue,
              title: 'Security',
            ),
            const SizedBox(height: 12),
            _ModernTile(
              icon: Icons.lock_rounded,
              iconColor: AppTheme.deepBlue,
              title: 'Change Password',
              subtitle: 'Update your account password',
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.deepBlue, size: 20),
              ),
              onTap: _changePassword,
            ),
            const SizedBox(height: 10),
            _ModernTile(
              icon: Icons.security_rounded,
              iconColor: AppTheme.primaryCyan,
              title: 'Two-Factor Authentication',
              subtitle: 'Add extra security to your account',
              trailing: Switch(
                value: _twoFactorAuth,
                onChanged: (value) {
                  setState(() => _twoFactorAuth = value);
                  _saveToggle(_k2FA, value);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryCyan,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              onTap: null,
            ),
            const SizedBox(height: 10),
            _ModernTile(
              icon: Icons.fingerprint_rounded,
              iconColor: AppTheme.successColor,
              title: 'Biometric Login',
              subtitle: 'Use fingerprint or Face ID',
              trailing: Switch(
                value: _biometricLogin,
                onChanged: (value) {
                  setState(() => _biometricLogin = value);
                  _saveToggle(_kBio, value);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.successColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              onTap: null,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.privacy_tip_rounded,
              iconColor: AppTheme.accentPurple,
              title: 'Privacy',
            ),
            const SizedBox(height: 12),
            _ModernTile(
              icon: Icons.share_rounded,
              iconColor: AppTheme.lightBlue,
              title: 'Share Data with Technicians',
              subtitle: 'Allow technicians to see your info',
              trailing: Switch(
                value: _shareDataWithTechnicians,
                onChanged: (value) {
                  setState(() => _shareDataWithTechnicians = value);
                  _saveToggle(_kShare, value);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.lightBlue,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              onTap: null,
            ),
            const SizedBox(height: 10),
            _ModernTile(
              icon: Icons.location_on_rounded,
              iconColor: AppTheme.warningColor,
              title: 'Location Tracking',
              subtitle: 'Allow app to track your location',
              trailing: Switch(
                value: _allowLocationTracking,
                onChanged: (value) {
                  setState(() => _allowLocationTracking = value);
                  _saveToggle(_kLocation, value);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.warningColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              onTap: null,
            ),
            const SizedBox(height: 10),
            _ModernTile(
              icon: Icons.description_rounded,
              iconColor: AppTheme.textSecondaryColor,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade500, size: 20),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _ModernTile(
              icon: Icons.gavel_rounded,
              iconColor: AppTheme.textSecondaryColor,
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade500, size: 20),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.manage_accounts_rounded,
              iconColor: AppTheme.errorColor,
              title: 'Account Management',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _deleteAccount,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.25),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_forever_rounded,
                          color: AppTheme.errorColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Permanently remove your account & data',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.errorColor.withValues(alpha: 0.5),
                        size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: iconColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
class _ModernTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  const _ModernTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
class _ChangePasswordSheet extends StatefulWidget {
  final String email;
  const _ChangePasswordSheet({required this.email});
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}
class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _snack('Please fill all fields');
      return;
    }
    if (newPass != confirm) {
      _snack('Passwords do not match');
      return;
    }
    if (newPass.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithPassword(
        email: widget.email,
        password: current,
      );
      await supabase.auth.updateUser(UserAttributes(password: newPass));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } on AuthException catch (e) {
      setState(() => _loading = false);
      _snack(e.message.contains('Invalid')
          ? 'Current password is incorrect'
          : e.message);
    } catch (_) {
      setState(() => _loading = false);
      _snack('Something went wrong. Please try again.');
    }
  }
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  InputDecoration _inputDec(
      String hint, bool obscure, VoidCallback toggle, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondaryColor, size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppTheme.deepBlue, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: AppTheme.textSecondaryColor,
          size: 20,
        ),
        onPressed: toggle,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.deepBlue, AppTheme.lightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepBlue.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Keep your account secure',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _FieldLabel('Current Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                decoration: _inputDec(
                  'Enter current password',
                  _obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent),
                  Icons.lock_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel('New Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                decoration: _inputDec(
                  'Enter new password',
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                  Icons.lock_open_rounded,
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel('Confirm New Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: _inputDec(
                  'Confirm new password',
                  _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                  Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondaryColor,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}