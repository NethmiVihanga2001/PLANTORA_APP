import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'driver_drawer.dart';
import '../screens/seller/seller_drawer.dart';
import '../screens/profile_screen.dart';
import '../screens/market_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/loyalty_screen.dart';
import '../screens/invite_friend_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/chat_list_screen.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;

  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.home_rounded,         'title': 'Home',             'key': 'home',             'dividerAfter': false},
    {'icon': Icons.person_rounded,       'title': 'My Profile',       'key': 'my_profile',       'dividerAfter': false},
    {'icon': Icons.storefront_rounded,   'title': 'Marketplace',      'key': 'marketplace',      'dividerAfter': false},
    {'icon': Icons.shopping_cart_rounded,'title': 'My Cart',          'key': 'my_cart',          'dividerAfter': false},
    {'icon': Icons.receipt_long_rounded, 'title': 'My Orders',        'key': 'my_orders',        'dividerAfter': false},
    {'icon': Icons.chat_bubble_rounded,  'title': 'My Chats',         'key': 'my_chats',         'dividerAfter': false},
    {'icon': Icons.favorite_rounded,     'title': 'My Favourites',    'key': 'my_favourites',    'dividerAfter': false},
    {'icon': Icons.camera_alt_rounded,   'title': 'Scan Plant',       'key': 'scan_plant',       'dividerAfter': true},
    {'icon': Icons.settings_rounded,     'title': 'Settings',         'key': 'settings',         'dividerAfter': false},
    {'icon': Icons.card_giftcard_rounded,'title': 'Loyalty & Offers', 'key': 'loyalty_offers',   'dividerAfter': false},
    {'icon': Icons.group_add_rounded,    'title': 'Invite a Friend',  'key': 'invite_friend',    'dividerAfter': true},
    {'icon': Icons.person_off_rounded,   'title': 'Delete Account',   'key': 'delete_account',   'dividerAfter': false},
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
    _slideAnims = _controllers.map((c) =>
      Tween<Offset>(begin: const Offset(-1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
    ).toList();
    _fadeAnims = _controllers.map((c) =>
      Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))
    ).toList();

    // Staggered start: each item delayed by 55ms
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 55), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user?.role == 'Driver') {
      return const DriverDrawer(currentIndex: 99);
    }
    if (user?.role == 'Seller') {
      return SellerDrawer(
        currentIndex: 99,
        onNavigate: (i) {
          if (i == 0) Navigator.pushNamedAndRemoveUntil(context, '/seller-dashboard', (route) => false);
        },
      );
    }

    return Drawer(
      backgroundColor: context.cardBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header with logo/brand
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLANTORA',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        context.watch<LocalizationProvider>().translate('app_subtitle'),
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 1,
              color: context.border,
            ),
            const SizedBox(height: 12),

            // Animated menu items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return Column(
                    children: [
                      SlideTransition(
                        position: _slideAnims[i],
                        child: FadeTransition(
                          opacity: _fadeAnims[i],
                          child: _buildItem(
                            context,
                            icon: item['icon'] as IconData,
                            title: item['title'] as String,
                            itemKey: item['key'] as String?,
                            index: i,
                          ),
                        ),
                      ),
                      if (item['dividerAfter'] == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Container(height: 1, color: context.border),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  label: Text(
                    context.watch<LocalizationProvider>().translate('logout'),
                    style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

            // Bottom version tag
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'v1.0.0 · Plantora',
                style: TextStyle(color: context.textSecondary.withOpacity(0.5), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, {
    required IconData icon,
    required String title,
    String? itemKey,
    required int index,
  }) {
    final favCount = context.watch<FavoritesProvider>().count;
    final showBadge = title == 'My Favourites' && favCount > 0;
    final loc = context.watch<LocalizationProvider>();
    final displayTitle = itemKey != null ? loc.translate(itemKey) : title;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        onTap: () => _onTap(context, index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                color: title == 'My Favourites' ? Colors.redAccent : context.textPrimary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (showBadge)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$favCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              Icon(Icons.chevron_right_rounded,
                  color: context.textSecondary.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    Navigator.pop(context);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
        break;
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
        break;
      case 6:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
        break;
      case 7:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        break;
      case 8:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case 9:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen()));
        break;
      case 10:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteFriendScreen()));
        break;
      case 11:
        _showDeleteAccountDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.orange.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text('Logout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: context.textPrimary)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Are you sure you want to log out from Plantora?',
                  style: TextStyle(color: context.textSecondary, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<AuthProvider>().logout();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Yes, Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131F18) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Warning Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.22),
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
                  'Delete Account?',
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
                  'This action is permanent and cannot be reversed. Are you sure you want to proceed?',
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
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFEE2E2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildWarningBullet(context, Icons.eco_outlined, 'Saved plant collection & scans will be erased'),
                      const SizedBox(height: 8),
                      _buildWarningBullet(context, Icons.stars_rounded, 'Cheer Points & loyalty tiers will be forfeited'),
                      const SizedBox(height: 8),
                      _buildWarningBullet(context, Icons.receipt_long_outlined, 'Past orders, messages & profile will be wiped'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons Row (Equal Width, Balanced)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
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
                            elevation: 2,
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
        );
      },
    );
  }

  Widget _buildWarningBullet(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFEF4444)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
