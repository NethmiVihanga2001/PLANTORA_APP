import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shop_screen.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/localization_provider.dart';
import '../data/plant_database.dart';
import '../data/marketplace_data.dart';
import 'scan_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';
import 'plantora_assistant_screen.dart';
import '../models/plant_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/marketplace_service.dart';
import '../widgets/loyalty_card.dart';
import '../providers/notification_provider.dart';
import '../config/app_config.dart';
import '../widgets/app_drawer.dart';
import '../services/socket_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/desktop_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  double _fabX = -1;
  double _fabY = -1;

  late final List<Widget> _screens;

  // FAB pulse animation
  late AnimationController _fabPulseCtrl;
  late Animation<double> _fabPulse;

  @override
  void initState() {
    super.initState();
    SocketService().connect(); // Connect for global socket listeners
    _screens = [const HomeContent(), const ScanScreen(), const MarketScreen()];

    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fabPulse = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fabPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Default FAB to bottom-right corner
    if (_fabX < 0) {
      _fabX = screenWidth - 76;
    }
    if (_fabY < 0) {
      _fabY = screenHeight - 180;
    }
    // Sidebar offsets so FAB stays in content area
    final sidebarWidth = isDesktop ? 240.0 : (isTablet ? 64.0 : 0.0);
    final contentMaxX = screenWidth - sidebarWidth - 60.0;
    final clampedFabX = _fabX.clamp(0.0, contentMaxX < 0.0 ? 0.0 : contentMaxX);
    final clampedFabY = _fabY.clamp(0.0, screenHeight - 150.0);

    if (isDesktop || isTablet) {
      // ── Widescreen: sidebar/rail + content side by side ─────────────
      return Scaffold(
        body: Row(
          children: [
            if (isDesktop)
              DesktopSidebar(
                selectedIndex: _selectedIndex,
                onIndexChanged: (i) => setState(() => _selectedIndex = i),
              )
            else
              TabletRail(
                selectedIndex: _selectedIndex,
                onIndexChanged: (i) => setState(() => _selectedIndex = i),
              ),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(index: _selectedIndex, children: _screens),
                  if (_selectedIndex != 1)
                    Positioned(
                      left: clampedFabX,
                      top: clampedFabY,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _fabX = (_fabX + details.delta.dx).clamp(
                              0.0,
                              contentMaxX < 0.0 ? 0.0 : contentMaxX,
                            );
                            _fabY = (_fabY + details.delta.dy).clamp(
                              0.0,
                              screenHeight - 150.0,
                            );
                          });
                        },
                        child: _buildChatFAB(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: bottom nav (original layout) ──────────────────────────
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          if (_selectedIndex != 1)
            Positioned(
              left: _fabX,
              top: _fabY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _fabX = (_fabX + details.delta.dx).clamp(
                      0.0,
                      screenWidth - 60,
                    );
                    _fabY = (_fabY + details.delta.dy).clamp(
                      0.0,
                      screenHeight - 150,
                    );
                  });
                },
                child: _buildChatFAB(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      drawer: const AppDrawer(),
    );
  }

  Widget _buildChatFAB() {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder:
          (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Transform.scale(
                scale: _fabPulse.value * 1.25,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen.withOpacity(
                      0.18 * _fabPulse.value,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlantoraAssistantScreen(),
                ),
              );
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  'https://cdn-icons-png.flaticon.com/512/4712/4712109.png',
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final loc = context.watch<LocalizationProvider>();
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'label': loc.translate('home'),
      },
      {
        'icon': Icons.camera_alt_outlined,
        'activeIcon': Icons.camera_alt_rounded,
        'label': loc.translate('scan'),
      },
      {
        'icon': Icons.storefront_outlined,
        'activeIcon': Icons.storefront_rounded,
        'label': loc.translate('marketplace'),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(top: BorderSide(color: context.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = _selectedIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.primaryGreen.withOpacity(0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected
                              ? items[i]['activeIcon'] as IconData
                              : items[i]['icon'] as IconData,
                          key: ValueKey(isSelected),
                          color:
                              isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.94);
  Timer? _offerTimer;
  int _currentOfferPage = 0;
  List<ProductModel> _popularProducts = [];
  ProductModel? _dealOfDay;
  bool _loadingPopular = true;

  List<dynamic> _activeAds = [];
  bool _isLoadingAds = true;

  Color _parseColor(String? hexStr, Color defaultColor) {
    if (hexStr == null || hexStr.isEmpty) return defaultColor;
    try {
      if (hexStr.startsWith('0xFF') || hexStr.startsWith('0xff')) {
        return Color(int.parse(hexStr));
      }
      if (hexStr.startsWith('#')) {
        return Color(int.parse(hexStr.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(hexStr));
    } catch (e) {
      return defaultColor;
    }
  }

  // Header leaf float animation
  late AnimationController _leafCtrl;
  late Animation<double> _leafFloat;
  // Shimmer for deal of day
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  // Pulse for LIVE badge
  late AnimationController _liveCtrl;
  late Animation<double> _livePulse;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.spa,
      'color': const Color(0xFF22C55E),
      'selected': true,
    },
    {
      'name': 'Indoor',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF60A5FA),
      'selected': false,
    },
    {
      'name': 'Outdoor',
      'icon': Icons.park_rounded,
      'color': const Color(0xFF34D399),
      'selected': false,
    },
    {
      'name': 'Rare',
      'icon': Icons.auto_awesome,
      'color': const Color(0xFFA78BFA),
      'selected': false,
    },
    {
      'name': 'Medicinal',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFFF97316),
      'selected': false,
    },
    {
      'name': 'Culinary',
      'icon': Icons.restaurant_menu_rounded,
      'color': const Color(0xFFFBBF24),
      'selected': false,
    },
    {
      'name': 'Aromatic',
      'icon': Icons.air_rounded,
      'color': const Color(0xFF818CF8),
      'selected': false,
    },
    {
      'name': 'Teas',
      'icon': Icons.emoji_food_beverage_rounded,
      'color': const Color(0xFF6EE7B7),
      'selected': false,
    },
    {
      'name': 'Seeds',
      'icon': Icons.grain_rounded,
      'color': const Color(0xFFF59E0B),
      'selected': false,
    },
    {
      'name': 'Tools',
      'icon': Icons.build_rounded,
      'color': const Color(0xFF9CA3AF),
      'selected': false,
    },
  ];

  @override
  void initState() {
    super.initState();

    _leafCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _leafFloat = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _leafCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _liveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _livePulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _liveCtrl, curve: Curves.easeInOut));

    _offerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final count = _activeAds.isNotEmpty ? _activeAds.length : 3;
        _currentOfferPage = (_currentOfferPage + 1) % count;
        _pageController.animateToPage(
          _currentOfferPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    _fetchActiveAds();
    final service = MarketplaceService();
    try {
      final popular = await service.getPopularProducts();
      if (mounted) {
        setState(() {
          _popularProducts = popular;
        });
      }
    } catch (e) {
      debugPrint('Error loading popular products: $e');
    }

    try {
      final deal = await service.getDealOfDay();
      if (mounted) {
        setState(() {
          _dealOfDay = deal;
          _loadingPopular = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading deal of day: $e');
      if (mounted) {
        setState(() {
          _loadingPopular = false;
        });
      }
    }
  }

  Future<void> _fetchActiveAds() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/ads'),
        headers: AppConfig.defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> loadedAds = json.decode(response.body);
        if (mounted) {
          setState(() {
            _activeAds = loadedAds;
            _isLoadingAds = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingAds = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching active ads for home content: $e');
      if (mounted) {
        setState(() => _isLoadingAds = false);
      }
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    final loc = context.watch<LocalizationProvider>();
    if (hour < 12) return loc.translate('good_morning');
    if (hour < 17) return loc.translate('good_afternoon');
    return loc.translate('good_evening');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _offerTimer?.cancel();
    _leafCtrl.dispose();
    _shimmerCtrl.dispose();
    _liveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final allPlants = PlantDatabase.allPlants;
    final popularPlants =
        _popularProducts.isEmpty ? allPlants.take(5).toList() : <PlantModel>[];
    final isWide = !Responsive.isMobile(context);

    return Container(
      color: context.scaffoldBg,
      child: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          await _loadData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(user?.displayName ?? 'Plant Lover'),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24),
                      _buildOffersCarousel(),
                      SizedBox(height: 28),
                      _buildMiniCheerCard(),
                      SizedBox(height: 32),
                      _buildSectionHeader(
                        context.watch<LocalizationProvider>().translate(
                          'categories',
                        ),
                        context.watch<LocalizationProvider>().translate(
                          'see_all',
                        ),
                        () => Navigator.pushNamed(context, '/plant-library'),
                      ),
                      SizedBox(height: 16),
                      _buildCategoryChips(),
                      SizedBox(height: 32),
                      _buildDealOfDay(),
                      SizedBox(height: 32),
                      _buildSectionHeader(
                        context.watch<LocalizationProvider>().translate(
                          'popular_plants',
                        ),
                        context.watch<LocalizationProvider>().translate(
                          'see_all',
                        ),
                        () => Navigator.pushNamed(context, '/market'),
                      ),
                      SizedBox(height: 16),
                      _buildPopularPlants(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.headerGradient[0], context.headerGradient.last],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated decorative circles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _leafFloat,
                builder:
                    (_, __) => Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: 10 + _leafFloat.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.cardBg.withOpacity(0.04),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          top: -10 + _leafFloat.value * 0.6,
                          child: Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4ADE80).withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: 20 - _leafFloat.value * 0.4,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.cardBg.withOpacity(0.03),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 60,
                          top: 40 + _leafFloat.value * 0.8,
                          child: Icon(
                            Icons.eco_rounded,
                            size: 20,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            // Header Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Menu, Greeting + User Name, Notifications
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Builder(
                          builder:
                              (menuCtx) => IconButton(
                                onPressed:
                                    () => Scaffold.of(menuCtx).openDrawer(),
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                tooltip: 'Open Menu',
                              ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getGreeting(),
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/notifications',
                              ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color:
                                      context.isDark
                                          ? Colors.white.withOpacity(0.12)
                                          : Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                              Consumer<NotificationProvider>(
                                builder: (context, notifProvider, child) {
                                  if (notifProvider.unreadCount == 0)
                                    return const SizedBox.shrink();
                                  return Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${notifProvider.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    GestureDetector(
                      onTap:
                          () => Navigator.pushNamed(context, '/plant-library'),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color:
                              context.isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.search_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.watch<LocalizationProvider>().translate(
                                  'search_hint',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersCarousel() {
    final hasDynamicAds = _activeAds.isNotEmpty;
    final int count = hasDynamicAds ? _activeAds.length : 3;

    return Column(
      children: [
        SizedBox(
          height: 84,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (p) => setState(() => _currentOfferPage = p),
            itemCount: count,
            itemBuilder: (_, i) {
              if (hasDynamicAds) {
                return _buildDynamicOfferCard(_activeAds[i]);
              } else {
                final offers = [
                  {
                    'title': 'Summer Sale',
                    'desc': 'Get 30% OFF on all indoor plants!',
                    'color1': const Color(0xFF22C55E),
                    'color2': const Color(0xFF0D9044),
                    'icon': Icons.local_offer_rounded,
                    'tag': '30% OFF',
                  },
                  {
                    'title': 'Free Delivery',
                    'desc': 'On your very first order with us.',
                    'color1': const Color(0xFF3B82F6),
                    'color2': const Color(0xFF1D4ED8),
                    'icon': Icons.local_shipping_rounded,
                    'tag': 'FREE',
                  },
                  {
                    'title': 'Rare Finds',
                    'desc': 'Discover exotic additions today.',
                    'color1': const Color(0xFF8B5CF6),
                    'color2': const Color(0xFF6D28D9),
                    'icon': Icons.auto_awesome_rounded,
                    'tag': 'NEW',
                  },
                ];
                return _buildOfferCard(offers[i]);
              }
            },
          ),
        ),

        const SizedBox(height: 8),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final isActive = i == _currentOfferPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 18 : 5,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryGreen : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDynamicOfferCard(dynamic ad) {
    final color1 = _parseColor(ad['colorHex'], const Color(0xFF0F5A32));
    final color2 = _parseColor(
      ad['colorHexSecondary'],
      const Color(0xFF34D399),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ShopScreen(
                  sellerId: ad['sellerId'] ?? '',
                  sellerName: ad['sellerName'] ?? 'Seller',
                  sellerLocation: ad['sellerLocation'] ?? 'Unknown Location',
                  sellerAvatar: ad['sellerAvatar'],
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${ad['discountPercentage']}% OFF',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ad['title'] ?? 'Special Offer',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (ad['description'] != null &&
                            ad['description'].toString().isNotEmpty)
                        ? ad['description'].toString()
                        : 'Limited time offer!',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Shop Now →',
                style: GoogleFonts.inter(
                  color: color1,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final color1 = offer['color1'] as Color;
    final color2 = offer['color2'] as Color;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarketScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer['tag'] as String,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    offer['title'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    offer['desc'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Shop Now →',
                style: GoogleFonts.inter(
                  color: color1,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action,
    VoidCallback onActionTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                action,
                style: GoogleFonts.inter(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ), // Reduced by 5 since margin provides 5
      child: Row(
        children: List.generate(_categories.length, (index) {
          final cat = _categories[index];
          final isSelected = cat['selected'] as bool? ?? false;
          final color = cat['color'] as Color;
          return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/market',
                    arguments: cat['name'].toString().toLowerCase(),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected
                            ? LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    color: isSelected ? null : context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ]
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? Colors.white : color,
                        size: 22,
                      ),
                      SizedBox(height: 5),
                      Text(
                        context.watch<LocalizationProvider>().translate(
                          cat['name'] as String,
                        ),
                        style: GoogleFonts.inter(
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF374151),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .slideX(
                begin: 0.2,
                delay: Duration(milliseconds: 60 * index),
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(
                delay: Duration(milliseconds: 60 * index),
                duration: 300.ms,
              );
        }),
      ),
    );
  }

  Widget _buildMiniCheerCard() {
    return const LoyaltyCard();
  }

  Widget _buildDealOfDay() {
    final deal = _dealOfDay;
    final price = deal?.price ?? 3500.0;
    final originalPrice = deal?.originalPrice;
    final title = deal?.title ?? 'Monstera Deliciosa (Swiss Cheese Plant)';
    final seller = deal?.sellerName ?? 'Lanka Botanical Oasis';
    final discountPct =
        (originalPrice != null && originalPrice > price)
            ? ((originalPrice - price) / originalPrice * 100).round()
            : 0;

    String exactImageUrl =
        'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=800&q=80';
    if (deal != null && deal.imageUrl.isNotEmpty) {
      exactImageUrl =
          deal.imageUrl.startsWith('http')
              ? deal.imageUrl
              : '${AppConfig.baseUrl}${deal.imageUrl}';
    }

    return GestureDetector(
      onTap: () {
        if (deal != null) Navigator.pushNamed(context, '/market');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 195,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Exact Plant Photo
              Image.network(
                exactImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (c, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.eco_rounded,
                          size: 50,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
              ),

              // Gradient overlay for contrast
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.88),
                    ],
                  ),
                ),
              ),

              // Shimmer sweep overlay
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder:
                    (_, __) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnim.value - 1, 0),
                          end: Alignment(_shimmerAnim.value, 0),
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
              ),

              // Top row: LIVE badge + discount badge
              Positioned(
                top: 16,
                left: 18,
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _livePulse,
                      builder:
                          (_, __) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEF4444,
                              ).withOpacity(_livePulse.value),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.4 * _livePulse.value),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 6,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'LIVE DEAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                    if (discountPct > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '-$discountPct%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom details
              Positioned(
                bottom: 18,
                left: 18,
                right: 74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (seller.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        seller,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Rs. ${price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4ADE80),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Rs. ${originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Cart button
              Positioned(
                bottom: 18,
                right: 18,
                child: GestureDetector(
                  onTap: () {
                    if (deal != null) {
                      final cart = context.read<CartProvider>();
                      cart.addItem(
                        CartItem(
                          productId: deal.id,
                          title: deal.title,
                          price: deal.price,
                          sellerId: deal.sellerId,
                          imageUrl: deal.imageUrl,
                          emoji: deal.emoji,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${deal.title} added to cart!',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularPlants() {
    final bool useBackend = _popularProducts.isNotEmpty;
    final int count =
        useBackend
            ? _popularProducts.length
            : PlantDatabase.allPlants.take(5).length;
    final plants = PlantDatabase.allPlants.take(5).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 768;

    if (isWide) {
      // Desktop/Tablet: responsive grid
      final cols = screenWidth >= 1200 ? 4 : (screenWidth >= 900 ? 3 : 2);
      if (_loadingPopular) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.7,
            ),
            itemCount: cols,
            itemBuilder: (_, i) => _buildPlantCardSkeleton(),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final bool isProduct = useBackend;
            final String name =
                isProduct ? _popularProducts[index].title : plants[index].name;
            final String emoji =
                isProduct ? _popularProducts[index].emoji : plants[index].emoji;
            final String imageUrl =
                isProduct
                    ? _popularProducts[index].imageUrl
                    : plants[index].imageUrl;
            final String seller =
                isProduct ? _popularProducts[index].sellerName : '';
            final int orderCount =
                isProduct ? _popularProducts[index].orderCount : 0;
            final double price =
                isProduct ? _popularProducts[index].price : 1850.0;
            final double rating =
                isProduct ? _popularProducts[index].rating : 4.8;
            final String fullImgUrl =
                imageUrl.isNotEmpty
                    ? (imageUrl.startsWith('http')
                        ? imageUrl
                        : '${AppConfig.baseUrl}$imageUrl')
                    : '';
            return _buildPopularPlantCard(
              name: name,
              emoji: emoji,
              fullImgUrl: fullImgUrl,
              seller: seller,
              orderCount: orderCount,
              price: price,
              rating: rating,
              isProduct: isProduct,
              index: index,
              plants: plants,
            );
          },
        ),
      );
    }

    // Mobile: horizontal scroll list (original)
    return SizedBox(
      height: 290,
      child:
          _loadingPopular
              ? ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (_, i) => _buildPlantCardSkeleton(),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: count,
                itemBuilder: (context, index) {
                  final bool isProduct = useBackend;
                  final String name =
                      isProduct
                          ? _popularProducts[index].title
                          : plants[index].name;
                  final String emoji =
                      isProduct
                          ? _popularProducts[index].emoji
                          : plants[index].emoji;
                  final String imageUrl =
                      isProduct
                          ? _popularProducts[index].imageUrl
                          : plants[index].imageUrl;
                  final String seller =
                      isProduct ? _popularProducts[index].sellerName : '';
                  final int orderCount =
                      isProduct ? _popularProducts[index].orderCount : 0;
                  final double price =
                      isProduct ? _popularProducts[index].price : 1850.0;
                  final double rating =
                      isProduct ? _popularProducts[index].rating : 4.8;
                  final String fullImgUrl =
                      imageUrl.isNotEmpty
                          ? (imageUrl.startsWith('http')
                              ? imageUrl
                              : '${AppConfig.baseUrl}$imageUrl')
                          : '';
                  return _buildPopularPlantCard(
                    name: name,
                    emoji: emoji,
                    fullImgUrl: fullImgUrl,
                    seller: seller,
                    orderCount: orderCount,
                    price: price,
                    rating: rating,
                    isProduct: isProduct,
                    index: index,
                    plants: plants,
                    fixedWidth: 185,
                  );
                },
              ),
    );
  }

  Widget _buildPopularPlantCard({
    required String name,
    required String emoji,
    required String fullImgUrl,
    required String seller,
    required int orderCount,
    required double price,
    required double rating,
    required bool isProduct,
    required int index,
    required List<dynamic> plants,
    double? fixedWidth,
  }) {
    return GestureDetector(
          onTap: () {
            if (isProduct) {
              Navigator.pushNamed(context, '/market');
            } else {
              Navigator.pushNamed(
                context,
                '/plant-detail',
                arguments: plants[index],
              );
            }
          },
          child: Container(
            width: fixedWidth,
            margin: EdgeInsets.symmetric(
              horizontal: fixedWidth != null ? 8 : 0,
            ),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE SECTION
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFFEDF7EF)),
                        if (fullImgUrl.isNotEmpty)
                          Image.network(
                            fullImgUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (ctx, err, stack) => Center(
                                  child: Text(
                                    emoji,
                                    style: TextStyle(fontSize: 56),
                                  ),
                                ),
                          )
                        else
                          Center(
                            child: Text(emoji, style: TextStyle(fontSize: 56)),
                          ),
                        // Hot badge
                        if (orderCount > 0)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF15803D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🔥 $orderCount sold',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (!isProduct)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.cardBg.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // INFO SECTION
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      if (seller.isNotEmpty)
                        Text(
                          seller,
                          style: GoogleFonts.inter(
                            color: AppColors.grey,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              ' (120)',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 8),
                      Text(
                        'Rs. ${price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .slideX(
          begin: 0.3,
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: Duration(milliseconds: 80 * index), duration: 400.ms);
  }

  Widget _buildPlantCardSkeleton() {
    return Container(
          width: 185,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.only(bottom: 6),
                    ),
                    Container(
                      height: 11,
                      width: 80,
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    Container(
                      height: 16,
                      width: 70,
                      color: Colors.grey.shade100,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: Colors.grey.shade200);
  }
}
