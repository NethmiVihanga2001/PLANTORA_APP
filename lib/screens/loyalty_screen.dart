import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../widgets/loyalty_card.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _claimOffer(String title, int cost) {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final currentPoints = authProvider.user?.points ?? 250;

    if (currentPoints >= cost) {
      authProvider.deductPoints(cost);

      double percentage = 0.0;
      bool freeDelivery = false;

      if (title.contains('20%')) {
        percentage = 20.0;
      } else if (title.contains('30%')) {
        percentage = 30.0;
      } else if (title.contains('Express Delivery') || title.contains('Delivery')) {
        freeDelivery = true;
      } else if (title.contains('Succulent') || title.contains('Gift')) {
        freeDelivery = true;
      }

      cartProvider.applyReward(
        title: title,
        percentage: percentage,
        freeDelivery: freeDelivery,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Successfully claimed "$title"! Applied to your plant cart.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Need ${cost - currentPoints} more Cheer Points to claim "$title".',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      appBar: const PremiumAppBar(
        title: 'Loyalty & Rewards',
        subtitle: 'Earn Cheer Points & unlock VIP perks',
        showMenuButton: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Responsive.formContainer(
          context: context,
          maxWidth: 800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Full-Width Membership Loyalty Card (Enlarged)
              const LoyaltyCard(padding: EdgeInsets.zero)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 20),

              // Custom Segmented Navigation Tabs
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF122218) : const Color(0xFFE2E8F0).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '🎁 Rewards'),
                    Tab(text: '⭐ Earn Points'),
                    Tab(text: '👑 VIP Tiers'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tab Views
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRewardsTab(),
                    _buildEarnTab(),
                    _buildTiersTab(),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    final offers = [
      {
        'title': 'Free Express Delivery',
        'description': 'Enjoy 100% free delivery on your next plant purchase.',
        'icon': Icons.local_shipping_rounded,
        'cost': 50,
        'discount': 'FREE',
        'gradient': [const Color(0xFF10B981), const Color(0xFF047857)],
      },
      {
        'title': '20% Off Order Discount',
        'description': 'Apply a 20% discount code to your entire shopping cart.',
        'icon': Icons.confirmation_number_rounded,
        'cost': 150,
        'discount': '20% OFF',
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      },
      {
        'title': '30% Super Plant Voucher',
        'description': 'Unlock a huge 30% discount on any rare plant order.',
        'icon': Icons.stars_rounded,
        'cost': 300,
        'discount': '30% OFF',
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        'title': 'Free Mystery Succulent',
        'description': 'Receive a free rare succulent with your next marketplace order.',
        'icon': Icons.card_giftcard_rounded,
        'cost': 500,
        'discount': 'FREE GIFT',
        'gradient': [const Color(0xFFEC4899), const Color(0xFFBE185D)],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _buildVoucherCard(
          title: offer['title'] as String,
          description: offer['description'] as String,
          icon: offer['icon'] as IconData,
          cost: offer['cost'] as int,
          discountTag: offer['discount'] as String,
          gradientColors: offer['gradient'] as List<Color>,
          index: index,
        );
      },
    );
  }

  Widget _buildVoucherCard({
    required String title,
    required String description,
    required IconData icon,
    required int cost,
    required String discountTag,
    required List<Color> gradientColors,
    required int index,
  }) {
    final isDark = context.isDark;
    final currentPoints = context.watch<AuthProvider>().user?.points ?? 250;
    final cartProvider = context.watch<CartProvider>();
    final bool isActiveInCart = cartProvider.activeRewardTitle == title;
    final bool canAfford = currentPoints >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E16) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActiveInCart
              ? const Color(0xFF10B981)
              : (canAfford ? gradientColors[0].withOpacity(0.4) : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0))),
          width: isActiveInCart ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isActiveInCart
                ? const Color(0xFF10B981).withOpacity(0.2)
                : (canAfford ? gradientColors[0].withOpacity(0.12) : Colors.black.withOpacity(0.04)),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row inside Voucher
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientColors[0].withOpacity(0.2), gradientColors[1].withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gradientColors[0].withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: gradientColors[0], size: 24),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActiveInCart ? const Color(0xFF10B981).withOpacity(0.2) : gradientColors[0].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActiveInCart ? 'ACTIVE IN CART ✓' : discountTag,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isActiveInCart ? const Color(0xFF10B981) : gradientColors[0],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: context.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Separator Line
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DashedLinePainter(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
          ),

          // Bottom Action Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: canAfford ? const Color(0xFF10B981) : context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$cost Cheer Points',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: canAfford ? const Color(0xFF10B981) : context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: canAfford ? () => _claimOffer(title, cost) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActiveInCart
                          ? const Color(0xFF10B981)
                          : (canAfford ? gradientColors[0] : (isDark ? Colors.white10 : const Color(0xFFCBD5E1))),
                      foregroundColor: canAfford || isActiveInCart ? Colors.white : context.textSecondary,
                      elevation: canAfford ? 3 : 0,
                      shadowColor: gradientColors[0].withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActiveInCart) ...[
                          const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isActiveInCart
                              ? 'Active in Cart'
                              : (canAfford ? 'Claim Reward' : 'Need $cost pts'),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEarnTab() {
    final earnSteps = [
      {
        'title': 'Buy Marketplace Plants',
        'subtitle': 'Earn 5 Cheer Points for every Rs. 100 spent on plant listings',
        'badge': '+5 pts / Rs. 100',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Invite Friends to Plantora',
        'subtitle': 'Earn 500 bonus points when a friend registers using your link',
        'badge': '+500 pts',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Daily Botanical Check-in',
        'subtitle': 'Open the app daily to collect your daily streak points',
        'badge': 'Daily Streak',
        'icon': Icons.calendar_today_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'AI Plant Scans & Diagnosis',
        'subtitle': 'Identify plant diseases with AI to unlock Explorer badges',
        'badge': 'Badges',
        'icon': Icons.qr_code_scanner_rounded,
        'color': const Color(0xFFEC4899),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: earnSteps.length,
      itemBuilder: (context, index) {
        final step = earnSteps[index];
        final color = step['color'] as Color;
        final isDark = context.isDark;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E16) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(step['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step['subtitle'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  step['badge'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms);
      },
    );
  }

  Widget _buildTiersTab() {
    final tiers = LoyaltyCard.levels;
    final currentPoints = context.watch<AuthProvider>().user?.points ?? 250;
    final isDark = context.isDark;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        final isCurrent = currentPoints >= (tier['minPoints'] as int) && currentPoints < (tier['maxPoints'] as int);
        final grad = tier['gradient'] as List<Color>;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E16) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent ? grad[0] : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
              width: isCurrent ? 2.0 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: grad[0].withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(tier['emoji'] as String, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier['name'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: grad[0],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CURRENT TIER',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requires ${tier['minPoints']} Cheer Points',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCurrent ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                color: isCurrent ? grad[0] : context.textSecondary,
                size: 22,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms);
      },
    );
  }
}

// Custom Painter for dashed lines
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 4, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

