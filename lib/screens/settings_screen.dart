import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/localization_provider.dart';
import 'settings/change_password_screen.dart';
import 'settings/payment_methods_screen.dart';
import 'settings/info_screen.dart';
import 'settings/privacy_policy_screen.dart';
import 'settings/terms_of_service_screen.dart';
import 'settings/help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final user = context.watch<AuthProvider>().user;
    final notificationsEnabled = context.watch<NotificationProvider>().notificationsEnabled;
    final loc = context.watch<LocalizationProvider>();

    final langName = loc.locale.languageCode == 'si'
        ? 'සිංහල'
        : (loc.locale.languageCode == 'ta' ? 'தமிழ்' : 'English');

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      appBar: PremiumAppBar(
        title: loc.translate('settings'),
        subtitle: loc.translate('app_preferences'),
        showMenuButton: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Responsive.centered(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader(context, loc.translate('account_security')),
              _buildSectionCard(context, [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: loc.translate('edit_profile'),
                  subtitle: loc.translate('personal_details'),
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  showDivider: true,
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: loc.translate('change_password'),
                  subtitle: loc.translate('change_password'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                  showDivider: true,
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: loc.translate('payment_methods'),
                  subtitle: loc.translate('payment_methods'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                  ),
                  showDivider: false,
                ),
              ]),

              // Preferences Section
              _buildSectionHeader(context, loc.translate('app_preferences')),
              _buildSectionCard(context, [
                _buildSwitchTile(
                  context: context,
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: loc.translate('push_notifications'),
                  value: notificationsEnabled,
                  onChanged: (val) => context.read<NotificationProvider>().toggleNotifications(val),
                  showDivider: true,
                ),
                _buildSwitchTile(
                  context: context,
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: loc.translate('dark_mode'),
                  value: isDark,
                  onChanged: (val) => context.read<ThemeProvider>().toggleTheme(),
                  showDivider: true,
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: loc.translate('language'),
                  subtitle: langName,
                  onTap: () => Navigator.pushNamed(context, '/language'),
                  showDivider: false,
                ),
              ]),

              // Support & Legal Section
              _buildSectionHeader(context, loc.translate('support_legal')),
              _buildSectionCard(context, [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF14B8A6),
                  title: loc.translate('privacy_policy'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                  showDivider: true,
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: loc.translate('terms_of_service'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  ),
                  showDivider: true,
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.help_center_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  title: loc.translate('help_center'),
                  subtitle: loc.translate('help_center'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpCenterScreen(),
                    ),
                  ),
                  showDivider: false,
                ),
              ]),

              // Logout & Version Footer
              _buildLogoutSection(context, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: context.textSecondary.withValues(alpha: 0.8),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: context.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: context.textSecondary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: context.border.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF10B981),
                inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE2E8F0),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: context.border.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context, LocalizationProvider loc) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(context, loc),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            label: Text(
              loc.translate('log_out'),
              style: GoogleFonts.inter(
                 color: Colors.redAccent,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.35),
                width: 1.5,
              ),
              backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            'v1.0.0 (Build 104) · Plantora Ecosystem',
            style: GoogleFonts.inter(
              color: context.textSecondary.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, LocalizationProvider loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(
              loc.translate('log_out'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          loc.translate('logout'),
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.translate('cancel'),
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: Text(
              loc.translate('log_out'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
