import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/seller_desktop_sidebar.dart';
import 'seller/seller_drawer.dart';
import 'seller/seller_home_view.dart';
import 'seller/seller_products_view.dart';
import 'seller/seller_orders_view.dart';
import 'seller/seller_delivery_view.dart';
import 'seller/seller_offers_screen.dart';
import 'seller/seller_analytics_view.dart';
import 'seller/seller_settings_view.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  late AnimationController _navAnimController;

  late List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 96) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
      return;
    }
    if (index == 98) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }
    if (index == 99) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      return;
    }

    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _navAnimController
        ..reset()
        ..forward();
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return SellerHomeView(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateTab: _onNavTap,
      );
      case 1: return SellerProductsView(onMenuTap: () => _scaffoldKey.currentState?.openDrawer());
      case 2: return SellerOrdersView(onMenuTap: () => _scaffoldKey.currentState?.openDrawer());
      case 3: return SellerDeliveryView(onMenuTap: () => _scaffoldKey.currentState?.openDrawer());
      case 4: return SellerOffersScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer());
      case 5: return SellerAnalyticsView(onMenuTap: () => _scaffoldKey.currentState?.openDrawer());
      case 97: return SellerSettingsView(onMenuTap: () => _scaffoldKey.currentState?.openDrawer());
      default: return SellerHomeView(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateTab: _onNavTap,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final loc = context.watch<LocalizationProvider>();

    _navItems = [
      _NavItem(icon: Icons.dashboard_rounded,    label: loc.translate('dashboard')),
      _NavItem(icon: Icons.inventory_2_rounded,  label: loc.translate('products')),
      _NavItem(icon: Icons.receipt_long_rounded, label: loc.translate('orders')),
      _NavItem(icon: Icons.two_wheeler_rounded,  label: loc.translate('delivery')),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isDesktop ? null : SellerDrawer(
        currentIndex: _currentIndex,
        onNavigate: _onNavTap,
      ),
      body: Row(
        children: [
          if (isDesktop)
            SellerDesktopSidebar(
              selectedIndex: _currentIndex,
              onIndexChanged: _onNavTap,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.cardBg.withOpacity(0.95),
                context.cardBg.withOpacity(0.98),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.15),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final isActive = _currentIndex == i;
                  return GestureDetector(
                    onTap: () => _onNavTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 76,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isActive
                                  ? Border.all(color: const Color(0xFF10B981).withOpacity(0.3))
                                  : null,
                            ),
                            child: Icon(
                              item.icon,
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white.withOpacity(0.4) : Colors.black45),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white.withOpacity(0.4) : Colors.black45),
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
