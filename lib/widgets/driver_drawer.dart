import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/localization_provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/welcome_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/driver_history_screen.dart';
import '../screens/driver_payout_screen.dart';
import '../screens/driver_vehicle_screen.dart';
import '../screens/driver_settings_screen.dart';
import '../screens/driver_active_delivery_screen.dart';
import '../screens/driver_chats_screen.dart';
import '../models/order_model.dart';

class DriverDrawer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onNavigate;

  const DriverDrawer({
    super.key,
    this.currentIndex = 0,
    this.onNavigate,
  });

  @override
  State<DriverDrawer> createState() => _DriverDrawerState();
}

class _DriverDrawerState extends State<DriverDrawer> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final loc = context.watch<LocalizationProvider>();

    final List<_DriverDrawerItem> mainItems = [
      _DriverDrawerItem(icon: Icons.local_shipping_rounded, label: loc.translate('live_deliveries'), index: 0, badge: 'LIVE'),
      _DriverDrawerItem(icon: Icons.near_me_rounded, label: loc.translate('active_trip_navigation'), index: 10, badge: 'GPS'),
      _DriverDrawerItem(icon: Icons.history_rounded, label: loc.translate('delivery_history'), index: 11),
      _DriverDrawerItem(icon: Icons.chat_bubble_outline_rounded, label: loc.translate('driver_chats'), index: 1),
      _DriverDrawerItem(icon: Icons.account_balance_wallet_rounded, label: loc.translate('earnings'), index: 12, badge: 'Rs. 45k'),
      _DriverDrawerItem(icon: Icons.two_wheeler_rounded, label: loc.translate('vehicle_profile'), index: 13),
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _bgAnim,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: (Theme.of(context).brightness == Brightness.dark)
                    ? [
                        context.scaffoldBg,
                        context.scaffoldBg,
                      ]
                    : [
                        Color.lerp(Colors.white, const Color(0xFFF0F7F3), _bgAnim.value)!,
                        Color.lerp(const Color(0xFFF0F7F3), const Color(0xFFE8F5EE), _bgAnim.value)!,
                        Color.lerp(const Color(0xFFE8F5EE), Colors.white, _bgAnim.value)!,
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(user, loc),
              _buildDivider(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(loc.translate('dispatch_trips')),
                      ...mainItems.asMap().entries.map((e) => _buildNavItem(e.value, e.key)),
                      const SizedBox(height: 8),
                      _buildDivider(),
                      const SizedBox(height: 8),
                      _buildSectionLabel(loc.translate('driver_account')),
                      _buildNavItem(
                        _DriverDrawerItem(icon: Icons.person_rounded, label: loc.translate('driver_profile'), index: 2),
                        mainItems.length + 1,
                      ),
                      _buildNavItem(
                        _DriverDrawerItem(icon: Icons.settings_rounded, label: loc.translate('driver_settings'), index: 14),
                        mainItems.length + 2,
                      ),
                      _buildNavItem(
                        _DriverDrawerItem(icon: Icons.person_off_rounded, label: loc.translate('delete_account'), index: 94, isDanger: true),
                        mainItems.length + 3,
                      ),
                    ],
                  ),
                ),
              ),
              _buildDivider(),
              _buildLogoutButton(loc),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'v1.0.0 · Plantora Eco-Courier Fleet',
                  style: TextStyle(
                    color: context.textPrimary.withOpacity(0.35),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(user, LocalizationProvider loc) {
    final initials = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'D';
    final name = user?.name ?? 'Driver Partner';
    final email = user?.email ?? 'driver@plantora.com';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          // Avatar with glow ring
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name, Email, and Driver Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.two_wheeler_rounded, color: Color(0xFF10B981), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${loc.translate('verified_driver')} · 4.9 ★',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF059669),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            context.textPrimary.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Text(
        label,
        style: TextStyle(
          color: context.textPrimary.withOpacity(0.4),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(_DriverDrawerItem item, int animIndex) {
    final isActive = widget.currentIndex == item.index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            if (item.index == 94) {
              _showDeleteAccountDialog();
            } else if (item.index == 10) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverActiveDeliveryScreen()));
            } else if (item.index == 11) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHistoryScreen()));
            } else if (item.index == 12) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPayoutScreen()));
            } else if (item.index == 13) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverVehicleScreen()));
            } else if (item.index == 14) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSettingsScreen()));
            } else {
              if (widget.onNavigate != null) {
                widget.onNavigate!(item.index);
              } else {
                if (item.index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                } else if (item.index == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverChatsScreen(showMenuButton: true)));
                }
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive ? context.textPrimary.withOpacity(0.10) : Colors.transparent,
              border: isActive ? Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1) : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: item.isDanger
                      ? const Color(0xFFEF4444)
                      : (isActive ? const Color(0xFF10B981) : context.textPrimary.withOpacity(0.75)),
                  size: 21,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: item.isDanger
                          ? const Color(0xFFEF4444)
                          : (isActive ? const Color(0xFF10B981) : context.textPrimary.withOpacity(0.85)),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isActive)
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981), size: 18),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 + animIndex * 40), duration: 250.ms).slideX(begin: -0.1);
  }

  Widget _buildLogoutButton(LocalizationProvider loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(),
          icon: Icon(Icons.logout_rounded, color: context.textPrimary, size: 18),
          label: Text(
            loc.translate('log_out'),
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.textPrimary.withOpacity(0.25), width: 1.3),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            Text('Log Out', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to log out from your Driver account?',
          style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
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
                  'Delete Driver Account?',
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
                  'This action is permanent and cannot be reversed. Are you sure you want to delete your driver partner account?',
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
                      _buildWarningBullet(context, Icons.electric_moped_outlined, 'Vehicle registration, driver license & documents will be erased'),
                      const SizedBox(height: 8),
                      _buildWarningBullet(context, Icons.star_outline_rounded, 'Driver rating, completed trips & fleet badge will be removed'),
                      const SizedBox(height: 8),
                      _buildWarningBullet(context, Icons.account_balance_wallet_outlined, 'Payout history, wallet balance & trip logs will be wiped'),
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
                            if (mounted) {
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
}

class _DriverDrawerItem {
  final IconData icon;
  final String label;
  final int index;
  final String? badge;
  final bool isDanger;

  _DriverDrawerItem({
    required this.icon,
    required this.label,
    required this.index,
    this.badge,
    this.isDanger = false,
  });
}
