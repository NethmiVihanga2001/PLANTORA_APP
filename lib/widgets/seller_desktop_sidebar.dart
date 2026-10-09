import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SellerDesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const SellerDesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final mainItems = [
      _SidebarItem(icon: Icons.dashboard_rounded,    label: 'Dashboard',       index: 0),
      _SidebarItem(icon: Icons.inventory_2_rounded,  label: 'Products',        index: 1),
      _SidebarItem(icon: Icons.receipt_long_rounded, label: 'Orders',          index: 2),
      _SidebarItem(icon: Icons.two_wheeler_rounded,  label: 'Delivery',        index: 3),
      _SidebarItem(icon: Icons.local_offer_rounded,  label: 'Offers & Deals',  index: 4),
    ];

    final storeItems = [
      _SidebarItem(icon: Icons.storefront_rounded,         label: 'View as Customer', index: 99),
      _SidebarItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages',         index: 96),
      _SidebarItem(icon: Icons.person_rounded,              label: 'My Profile',       index: 98),
      _SidebarItem(icon: Icons.settings_rounded,            label: 'Settings',         index: 97),
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
                        'Seller Portal',
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

            Divider(color: context.border, height: 1),

            // ── Scrollable nav sections ──────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  // MAIN MENU
                  _buildSectionLabel('MAIN MENU', context),
                  const SizedBox(height: 4),
                  ...mainItems.map((item) => _buildNavItem(item, context, isDark)),

                  const SizedBox(height: 12),
                  Divider(color: context.border, height: 1),
                  const SizedBox(height: 12),

                  // STORE
                  _buildSectionLabel('STORE', context),
                  const SizedBox(height: 4),
                  ...storeItems.map((item) => _buildNavItem(item, context, isDark)),
                ],
              ),
            ),

            // ── Footer (User, Theme toggle, Logout) ─────────────────────
            Divider(color: context.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Seller',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? 'seller',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: context.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      context.read<ThemeProvider>().toggleTheme();
                    },
                    tooltip: 'Toggle Theme',
                  ),
                ],
              ),
            ),
            // Logout button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<AuthProvider>().logout();
                    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
                  },
                  borderRadius: BorderRadius.circular(12),
                  hoverColor: Colors.red.withOpacity(0.08),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red.withOpacity(0.8), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          color: context.textSecondary.withOpacity(0.5),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(_SidebarItem item, BuildContext context, bool isDark) {
    final isSelected = selectedIndex == item.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onIndexChanged(item.index),
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.primaryGreen.withOpacity(0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGreen.withOpacity(0.13) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryGreen.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.primaryGreen : context.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryGreen : context.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
  final int index;

  _SidebarItem({required this.icon, required this.label, required this.index});
}
