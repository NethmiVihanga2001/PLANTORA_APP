import 'dart:ui';
import 'dart:convert';
import '../../../config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/localization_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/welcome_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../screens/chat_list_screen.dart';

class SellerDrawer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const SellerDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<SellerDrawer> createState() => _SellerDrawerState();
}

class _SellerDrawerState extends State<SellerDrawer>
    with TickerProviderStateMixin {
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final loc = context.watch<LocalizationProvider>();

    final List<_DrawerItem> mainItems = [
      _DrawerItem(icon: Icons.dashboard_rounded,              label: loc.translate('dashboard'),         index: 0),
      _DrawerItem(icon: Icons.account_balance_wallet_rounded, label: loc.translate('payments_ledger'),  index: 95, badge: 'HOT'),
      _DrawerItem(icon: Icons.inventory_2_rounded,            label: loc.translate('my_products'),       index: 1),
      _DrawerItem(icon: Icons.receipt_long_rounded,           label: loc.translate('orders'),            index: 2),
      _DrawerItem(icon: Icons.two_wheeler_rounded,            label: loc.translate('delivery_dispatch'), index: 3, badge: 'LIVE'),
      _DrawerItem(icon: Icons.bar_chart_rounded,              label: loc.translate('analytics'),         index: 5, badge: 'NEW'),
      _DrawerItem(icon: Icons.local_offer_rounded,            label: loc.translate('offers_deals'),    index: 4),
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
                      _buildSectionLabel(loc.translate('main_menu')),
                      ...mainItems.asMap().entries.map((e) =>
                        _buildNavItem(e.value, e.key)
                      ),
                      const SizedBox(height: 8),
                      _buildDivider(),
                      const SizedBox(height: 8),
                      _buildSectionLabel(loc.translate('store')),
                      _buildNavItem(_DrawerItem(icon: Icons.storefront_rounded, label: loc.translate('view_as_customer'), index: 99), mainItems.length + 1),
                      _buildNavItem(_DrawerItem(icon: Icons.chat_bubble_outline_rounded, label: loc.translate('messages'), index: 96), mainItems.length + 2),
                      _buildNavItem(_DrawerItem(icon: Icons.person_rounded, label: loc.translate('my_profile'), index: 98), mainItems.length + 3),
                      _buildNavItem(_DrawerItem(icon: Icons.settings_rounded, label: loc.translate('settings'), index: 97), mainItems.length + 4),
                      _buildNavItem(_DrawerItem(icon: Icons.person_off_rounded, label: loc.translate('delete_account'), index: 94, isDanger: true), mainItems.length + 5),
                    ],
                  ),
                ),
              ),
              _buildDivider(),
              _buildLogoutButton(loc),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'v1.0.0 · Plantora Seller',
                  style: TextStyle(
                    color: context.textPrimary.withOpacity(0.2),
                    fontSize: 10,
                    letterSpacing: 1,
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
    final String shopName = (user?.businessName != null && user!.businessName!.trim().isNotEmpty)
        ? user.businessName!
        : (user?.name ?? 'Seller Store');
    final String ownerName = user?.name ?? 'Seller Owner';
    final avatar = user?.avatarUrl ?? user?.shopImage;
    final bool hasAvatar = avatar != null && avatar.trim().isNotEmpty && avatar != 'null';

    String? avatarFullUrl;
    if (hasAvatar) {
      if (avatar.startsWith('http') || avatar.startsWith('data:image')) {
        avatarFullUrl = avatar;
      } else {
        avatarFullUrl = '${AppConfig.baseUrl}$avatar';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          // Avatar with glow & image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981), width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: hasAvatar && avatarFullUrl != null
                  ? (avatarFullUrl.startsWith('data:image')
                      ? Image.memory(base64Decode(avatarFullUrl.split(',').last), fit: BoxFit.cover)
                      : Image.network(
                          avatarFullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
                              style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ))
                  : Center(
                      child: Text(
                        shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
                        style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user?.businessName != null ? 'Owner: $ownerName' : loc.translate('seller_account'),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
            context.textPrimary.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
      child: Text(
        label,
        style: TextStyle(
          color: context.textPrimary.withOpacity(0.3),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(_DrawerItem item, int animIndex) {
    final isActive = widget.currentIndex == item.index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: (Theme.of(context).brightness == Brightness.dark) ? Colors.white : Colors.black12,
          highlightColor: (Theme.of(context).brightness == Brightness.dark) ? Colors.white : Colors.black12,
          onTap: () {
            Navigator.pop(context);
            if (item.index == 94) {
              _showDeleteAccountDialog();
            } else if (item.index == 95) {
              Navigator.pushNamed(context, '/seller-payments');
            } else if (item.index == 99) {
              Navigator.pushNamed(context, '/home');
            } else if (item.index == 98) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            } else if (item.index == 96) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
            } else {
              widget.onNavigate(item.index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive
                  ? (context.textPrimary).withOpacity(0.12)
                  : Colors.transparent,
              border: isActive
                  ? Border.all(color: context.textPrimary.withOpacity(0.15), width: 1)
                  : null,
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
                    style: TextStyle(
                      color: item.isDanger
                          ? const Color(0xFFEF4444)
                          : (isActive ? (context.textPrimary) : context.textPrimary.withOpacity(0.8)),
                      fontSize: 14.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
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
                      style: TextStyle(color: context.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isActive)
                  Icon(Icons.chevron_right_rounded, color: const Color(0xFF10B981).withOpacity(0.7), size: 18),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 + animIndex * 50), duration: 300.ms)
     .slideX(begin: -0.15, delay: Duration(milliseconds: 80 + animIndex * 50));
  }

  Widget _buildLogoutButton(LocalizationProvider loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(),
          icon: Icon(Icons.logout_rounded, color: context.textPrimary, size: 18),
          label: Text(
            loc.translate('logout'),
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.textPrimary.withOpacity(0.3), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to log out from your Seller account?',
          style: TextStyle(color: context.textPrimary.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark) ? Colors.white : Colors.black54)),
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
              backgroundColor: Color(0xFF10B981),
              foregroundColor: context.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final int index;
  final String? badge;
  final bool isDanger;

  _DrawerItem({
    required this.icon,
    required this.label,
    required this.index,
    this.badge,
    this.isDanger = false,
  });
}
