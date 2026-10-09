import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/product_model.dart';
import '../../../models/order_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/order_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/premium_app_bar.dart';
import 'seller_payments_screen.dart';
import 'seller_store_rating_screen.dart';

class SellerHomeView extends StatefulWidget {
  final VoidCallback onMenuTap;
  final Function(int)? onNavigateTab;
  const SellerHomeView({super.key, required this.onMenuTap, this.onNavigateTab});

  @override
  State<SellerHomeView> createState() => _SellerHomeViewState();
}

class _SellerHomeViewState extends State<SellerHomeView> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final MarketplaceService _marketplaceService = MarketplaceService();
  final OrderService _orderService = OrderService();

  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  int _totalProducts = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final allProducts = await _marketplaceService.getProductsByCategory('all');
      final orders = await _orderService.getOrders();

      _products = allProducts.where((p) => p.sellerId == user.id).toList();
      _orders = orders.where((o) => o.items.any((item) => item.sellerId == user.id)).toList();

      _totalProducts = _products.length;
      _totalOrders = _orders.length;
      _pendingOrders = _orders.where((o) => o.status == 'Pending').length;
    } catch (e) {
      debugPrint('Error loading seller data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryGreen,
        backgroundColor: context.cardBg,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(user?.name ?? 'Seller')),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildBalancedGrid()),
              if (_pendingOrders > 0)
                SliverToBoxAdapter(child: _buildActionableAlerts()),
              SliverToBoxAdapter(child: _buildSalesChart()),
              SliverToBoxAdapter(child: _buildRecentActivity()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String sellerName) {
    final topPadding = MediaQuery.of(context).padding.top;
    final cleanGreeting = _getGreeting().replaceAll('•', '').trim();
    final greetingText = cleanGreeting.endsWith(',') ? cleanGreeting : '$cleanGreeting,';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.headerGradient[0],
            context.headerGradient.last,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated decorative ambient circles matching customer side header
          Positioned.fill(
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: 10,
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
                  top: -10,
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
                  bottom: 20,
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
                  top: 40,
                  child: Icon(Icons.eco_rounded,
                      size: 20, color: Colors.white.withOpacity(0.12)),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PremiumAppBar.buildEmblemButton(
                      icon: Icons.menu_rounded,
                      onTap: widget.onMenuTap,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greetingText,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sellerName,
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
                    const SizedBox(width: 8),
                    // Notification Button matching customer side
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/notifications'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 21),
                          ),
                          Consumer<NotificationProvider>(
                            builder: (context, notifProvider, child) {
                              if (notifProvider.sellerUnreadCount == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  child: Text(
                                    '${notifProvider.sellerUnreadCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancedGrid() {
    final financeService = context.watch<FinanceService>();
    final revenueVal = 'Rs. ${financeService.sellerBalance.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildEqualStatCard(
                  title: 'Total Revenue',
                  value: revenueVal,
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF10B981),
                  badgeText: '+12%',
                  badgeColor: const Color(0xFF10B981),
                  isFeatured: true,
                  onTap: () {
                    Navigator.pushNamed(context, '/seller-payments');
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildEqualStatCard(
                  title: 'Active Orders',
                  value: '$_pendingOrders',
                  icon: Icons.local_shipping_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  badgeText: _pendingOrders > 0 ? 'Needs Action' : 'All Clear',
                  badgeColor: _pendingOrders > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  isFeatured: false,
                  onTap: () {
                    widget.onNavigateTab?.call(2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildEqualStatCard(
                  title: 'Products Listed',
                  value: '$_totalProducts',
                  icon: Icons.inventory_2_rounded,
                  accentColor: const Color(0xFF6366F1),
                  badgeText: 'All Active',
                  badgeColor: const Color(0xFF6366F1),
                  isFeatured: false,
                  onTap: () {
                    widget.onNavigateTab?.call(1);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildEqualStatCard(
                  title: 'Store Rating',
                  value: '4.8 ★',
                  icon: Icons.star_rounded,
                  accentColor: const Color(0xFFEAB308),
                  badgeText: 'Top Seller',
                  badgeColor: const Color(0xFFEAB308),
                  isFeatured: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerStoreRatingScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildEqualStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required Color badgeColor,
    required bool isFeatured,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accentColor.withOpacity(0.12),
        highlightColor: accentColor.withOpacity(0.06),
        child: Container(
      height: 155, // Fixed height for 100% equal balance across all 4 cards
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFeatured
            ? (isDark ? const Color(0xFF06301D) : const Color(0xFFE6F5EC))
            : context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFeatured ? accentColor.withOpacity(0.35) : context.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured ? accentColor.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Icon + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Content: Title + Fitted Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: isFeatured ? accentColor : context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
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

  Widget _buildActionableAlerts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action Required',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF991B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You have $_pendingOrders pending order${_pendingOrders > 1 ? 's' : ''} to fulfill.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB91C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFFB91C1C), size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSalesChart() {
    final List<Map<String, dynamic>> weeklySales = [
      {'day': 'Mon', 'sales': 12},
      {'day': 'Tue', 'sales': 18},
      {'day': 'Wed', 'sales': 8},
      {'day': 'Thu', 'sales': 24},
      {'day': 'Fri', 'sales': 15},
      {'day': 'Sat', 'sales': 30},
      {'day': 'Sun', 'sales': 22},
    ];

    double maxSales = 30.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.bar_chart_rounded, color: AppColors.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Plants Sold (This Week)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+24%',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryGreen,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeklySales.map((data) {
                  double barHeight = (data['sales'] / maxSales) * 98;
                  bool isToday = data['day'] == 'Sat';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: barHeight,
                        width: 22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isToday
                                ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                : [context.textPrimary.withOpacity(0.08), context.textPrimary.withOpacity(0.18)],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['day'],
                        style: GoogleFonts.inter(
                          color: isToday ? AppColors.primaryGreen : context.textSecondary,
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.06);
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Orders',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  widget.onNavigateTab?.call(2);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, color: context.textSecondary, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'No orders placed yet',
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(5, _orders.length),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = _orders[index];
                final isPending = order.status == 'Pending';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt_rounded, color: AppColors.primaryGreen, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                                  style: GoogleFonts.inter(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                                  style: GoogleFonts.inter(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? const Color(0xFFF59E0B).withOpacity(0.12)
                                      : const Color(0xFF10B981).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.status,
                                  style: GoogleFonts.inter(
                                    color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                            label: const Text('Assign to Driver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final finance = context.read<FinanceService>();
                              finance.assignOrderToDriver(order.id);

                              final i = _orders.indexWhere((o) => o.id == order.id);
                              if (i != -1) {
                                setState(() {
                                  _orders[i] = order.copyWith(status: 'Assigned');
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Order assigned to driver! Rs. ${finance.driverFee.toStringAsFixed(0)} deducted for delivery.',
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}
