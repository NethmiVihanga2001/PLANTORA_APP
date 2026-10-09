import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/premium_app_bar.dart';
import '../profile_screen.dart';
import '../settings/change_password_screen.dart';
import '../settings/payment_methods_screen.dart';
import '../settings/info_screen.dart';
import '../welcome_screen.dart';
import 'package:flutter/services.dart';

class SellerSettingsView extends StatefulWidget {
  final VoidCallback onMenuTap;
  const SellerSettingsView({super.key, required this.onMenuTap});

  @override
  State<SellerSettingsView> createState() => _SellerSettingsViewState();
}

class _SellerSettingsViewState extends State<SellerSettingsView> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final user = context.watch<AuthProvider>().user;
    final notificationsEnabled = context.watch<NotificationProvider>().notificationsEnabled;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Store & Account Section
                _buildSectionHeader(context, 'Store & Security'),
                _buildSectionCard(context, [
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Edit Store & Profile',
                    subtitle: 'Seller details, bio & store photo',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Change Password',
                    subtitle: 'Update account password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Payout & Payment Methods',
                    subtitle: 'Bank account & payout details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.person_off_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Delete Seller Account',
                    subtitle: 'Permanently remove store & all plant listings',
                    onTap: () => _showDeleteAccountConfirmation(context),
                    showDivider: false,
                  ),
                ]),

                // Preferences Section
                _buildSectionHeader(context, 'App Preferences'),
                _buildSectionCard(context, [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Push Notifications',
                    value: notificationsEnabled,
                    onChanged: (val) => context.read<NotificationProvider>().toggleNotifications(val),
                    showDivider: true,
                  ),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Dark Mode',
                    value: isDark,
                    onChanged: (val) => context.read<ThemeProvider>().toggleTheme(),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () => Navigator.pushNamed(context, '/language'),
                    showDivider: false,
                  ),
                ]),

                // Support & Legal Section
                _buildSectionHeader(context, 'Support & Legal'),
                _buildSectionCard(context, [
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF14B8A6),
                    title: 'Privacy Policy',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(title: 'Privacy Policy', content: 'Plantora Privacy Policy & Data Protections'),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF64748B),
                    title: 'Terms of Service',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(title: 'Terms of Service', content: 'Plantora Seller Terms & Conditions'),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.help_center_outlined,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Help Center',
                    subtitle: 'Seller support & FAQs',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(title: 'Help Center', content: 'Contact Seller Support'),
                      ),
                    ),
                    showDivider: false,
                  ),
                ]),

                // Logout & Version Footer
                _buildLogoutSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF012E23),
            Color(0xFF044E39),
            Color(0xFF065F46),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF34D399).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PremiumAppBar.buildEmblemButton(
            icon: Icons.menu_rounded,
            onTap: widget.onMenuTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seller Settings',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF34D399),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Preferences & Store Account Settings',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA7F3D0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                activeTrackColor: const Color(0xFFF59E0B),
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

  Widget _buildLogoutSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF10B981), size: 20),
            label: Text(
              'Log Out',
              style: GoogleFonts.inter(
                color: const Color(0xFF10B981),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                width: 1.5,
              ),
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteAccountConfirmation(context),
            icon: const Icon(Icons.person_off_rounded, color: Colors.redAccent, size: 19),
            label: Text(
              'Delete Seller Account',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontSize: 14.5,
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

  void _showDeleteAccountConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 32),
                  ),
                ),
                const SizedBox(height: 18),

                // Dialog Title
                Text(
                  'Delete Seller Account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.3,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'This action is permanent and cannot be reversed. Are you sure you want to delete your seller storefront?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Consequences Bullet Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFFEE2E2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildWarningBullet(context, Icons.inventory_2_outlined, 'All active plant listings & inventory will be removed'),
                      const SizedBox(height: 8),
                      _buildWarningBullet(context, Icons.storefront_outlined, 'Store profile, ratings & seller badges will be erased'),
                      const SizedBox(height: 8),
                      _buildWarningBullet(context, Icons.receipt_long_outlined, 'Order history, customer chats & payout records will be wiped'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Keep Account',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            Navigator.pop(ctx);
                            final success = await context.read<AuthProvider>().deleteAccount();
                            if (context.mounted) {
                              if (success) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to delete account. Please try again later.'),
                                    backgroundColor: Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBullet(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFEF4444)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textPrimary.withOpacity(0.85),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
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
              'Log Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your Plantora account?',
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
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
              'Log Out',
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
