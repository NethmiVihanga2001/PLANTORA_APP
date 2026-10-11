import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/localization_provider.dart';

/// Full-width desktop sidebar shown on screens wider than 1200px.
class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cart = context.watch<CartProvider>();
    final favs = context.watch<FavoritesProvider>();
    final loc = context.watch<LocalizationProvider>();

    final mainItems = [
      _SidebarItem(icon: Icons.home_rounded, label: loc.translate('home')),
      _SidebarItem(icon: Icons.camera_alt_rounded, label: loc.translate('scan_plant')),
      _SidebarItem(icon: Icons.storefront_rounded, label: loc.translate('marketplace')),
    ];

    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(right: BorderSide(color: context.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Brand header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF15803D).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 20)),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        loc.translate('app_subtitle'),
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(height: 1, color: context.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
            const SizedBox(height: 12),

            // ── Section label ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                loc.translate('main_menu'),
                style: TextStyle(
                  color: context.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // ── Main nav items ───────────────────────────────────────────
            for (int i = 0; i < mainItems.length; i++)
              _buildNavItem(
                context,
                item: mainItems[i],
                index: i,
                isSelected: selectedIndex == i,
                onTap: () => onIndexChanged(i),
              ),

            const SizedBox(height: 16),
            Container(height: 1, color: context.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'ACCOUNT',
                style: TextStyle(
                  color: context.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // ── Secondary nav items ──────────────────────────────────────
            _buildSecondaryItem(
              context,
              icon: Icons.person_rounded,
              label: loc.translate('my_profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            _buildSecondaryItem(
              context,
              icon: Icons.shopping_bag_rounded,
              label: loc.translate('my_cart'),
              badge: cart.itemCount > 0 ? '${cart.itemCount}' : null,
              badgeColor: const Color(0xFFF97316),
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
            _buildSecondaryItem(
              context,
              icon: Icons.favorite_rounded,
              label: loc.translate('my_favourites'),
              badge: favs.count > 0 ? '${favs.count}' : null,
              badgeColor: Colors.redAccent,
              iconColor: favs.count > 0 ? Colors.redAccent : null,
              onTap: () => Navigator.pushNamed(context, '/favorites'),
            ),
            _buildSecondaryItem(
              context,
              icon: Icons.receipt_long_rounded,
              label: loc.translate('my_orders'),
              onTap: () => Navigator.pushNamed(context, '/orders'),
            ),
            _buildSecondaryItem(
              context,
              icon: Icons.settings_rounded,
              label: loc.translate('settings'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),

            const Spacer(),
            Container(height: 1, color: context.border, margin: const EdgeInsets.symmetric(horizontal: 16)),

            // ── User avatar footer ───────────────────────────────────────
            if (user != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                      backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!.startsWith('http') ? user.avatarUrl! : '${AppConfig.baseUrl}${user.avatarUrl}')
                          : null,
                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '🌿',
                              style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.role,
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert_rounded, color: context.iconSecondary, size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required _SidebarItem item,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withOpacity(context.isDark ? 0.25 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primaryGreen.withOpacity(0.08),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Accent indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected ? context.primary : context.iconSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? context.primary : context.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primaryGreen.withOpacity(0.06),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const SizedBox(width: 13),
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? context.iconSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablet collapsed rail (icon-only).
class TabletRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const TabletRail({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.camera_alt_outlined),
        selectedIcon: Icon(Icons.camera_alt_rounded),
        label: Text('Scan'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: Text('Market'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(right: BorderSide(color: context.border, width: 1)),
      ),
      child: SafeArea(
        child: NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onIndexChanged,
          extended: false,
          minWidth: 64,
          backgroundColor: Colors.transparent,
          selectedIconTheme: IconThemeData(color: context.primary, size: 24),
          unselectedIconTheme: IconThemeData(color: context.iconSecondary, size: 22),
          indicatorColor: context.primary.withOpacity(0.12),
          destinations: items,
          leading: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});
}
