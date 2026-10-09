import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../widgets/responsive_layout.dart';

class SellerAnalyticsView extends StatefulWidget {
  final VoidCallback onMenuTap;
  const SellerAnalyticsView({super.key, required this.onMenuTap});

  @override
  State<SellerAnalyticsView> createState() => _SellerAnalyticsViewState();
}

class _SellerAnalyticsViewState extends State<SellerAnalyticsView> {
  String _selectedTimeframe = 'This Month';
  int _selectedBarIndex = 3; // Default W4

  final List<String> _timeframes = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year'];

  final Map<String, Map<String, dynamic>> _analyticsData = {
    'Today': {
      'revenue': 'Rs. 18,500',
      'growth': '+24.2%',
      'orders': '8 Orders',
      'units': '14 Units',
      'avgOrder': 'Rs. 2,312',
      'satisfaction': '100%',
      'cogs': 'Rs. 5,550',
      'netProfit': 'Rs. 10,175',
      'logistics': 'Rs. 2,775',
      'bars': [
        {'label': '8 AM', 'val': 0.2, 'amount': 'Rs. 2,200', 'orders': '1 Order'},
        {'label': '10 AM', 'val': 0.45, 'amount': 'Rs. 4,500', 'orders': '2 Orders'},
        {'label': '12 PM', 'val': 0.7, 'amount': 'Rs. 6,800', 'orders': '3 Orders'},
        {'label': '2 PM', 'val': 0.35, 'amount': 'Rs. 3,100', 'orders': '1 Order'},
        {'label': '4 PM', 'val': 0.55, 'amount': 'Rs. 5,200', 'orders': '2 Orders'},
        {'label': '6 PM', 'val': 0.9, 'amount': 'Rs. 8,900', 'orders': '4 Orders'},
        {'label': '8 PM', 'val': 0.4, 'amount': 'Rs. 3,800', 'orders': '2 Orders'},
      ],
    },
    'This Week': {
      'revenue': 'Rs. 64,800',
      'growth': '+16.8%',
      'orders': '34 Orders',
      'units': '52 Units',
      'avgOrder': 'Rs. 1,905',
      'satisfaction': '99.2%',
      'cogs': 'Rs. 19,440',
      'netProfit': 'Rs. 35,640',
      'logistics': 'Rs. 9,720',
      'bars': [
        {'label': 'Mon', 'val': 0.4, 'amount': 'Rs. 8,200', 'orders': '4 Orders'},
        {'label': 'Tue', 'val': 0.6, 'amount': 'Rs. 11,400', 'orders': '6 Orders'},
        {'label': 'Wed', 'val': 0.5, 'amount': 'Rs. 9,800', 'orders': '5 Orders'},
        {'label': 'Thu', 'val': 0.8, 'amount': 'Rs. 15,200', 'orders': '8 Orders'},
        {'label': 'Fri', 'val': 0.75, 'amount': 'Rs. 13,900', 'orders': '7 Orders'},
        {'label': 'Sat', 'val': 1.0, 'amount': 'Rs. 18,500', 'orders': '10 Orders'},
        {'label': 'Sun', 'val': 0.85, 'amount': 'Rs. 16,100', 'orders': '8 Orders'},
      ],
    },
    'This Month': {
      'revenue': 'Rs. 248,500',
      'growth': '+24.8%',
      'orders': '186 Orders',
      'units': '342 Units',
      'avgOrder': 'Rs. 2,450',
      'satisfaction': '98.5%',
      'cogs': 'Rs. 74,550',
      'netProfit': 'Rs. 136,675',
      'logistics': 'Rs. 37,275',
      'bars': [
        {'label': 'W1', 'val': 0.55, 'amount': 'Rs. 52,400', 'orders': '42 Orders'},
        {'label': 'W2', 'val': 0.72, 'amount': 'Rs. 68,900', 'orders': '51 Orders'},
        {'label': 'W3', 'val': 0.88, 'amount': 'Rs. 84,200', 'orders': '63 Orders'},
        {'label': 'W4', 'val': 1.0, 'amount': 'Rs. 94,800', 'orders': '72 Orders'},
      ],
    },
    'This Quarter': {
      'revenue': 'Rs. 685,200',
      'growth': '+31.4%',
      'orders': '490 Orders',
      'units': '920 Units',
      'avgOrder': 'Rs. 2,580',
      'satisfaction': '98.8%',
      'cogs': 'Rs. 205,560',
      'netProfit': 'Rs. 376,860',
      'logistics': 'Rs. 102,780',
      'bars': [
        {'label': 'Month 1', 'val': 0.65, 'amount': 'Rs. 192,000', 'orders': '138 Orders'},
        {'label': 'Month 2', 'val': 0.85, 'amount': 'Rs. 244,700', 'orders': '174 Orders'},
        {'label': 'Month 3', 'val': 1.0, 'amount': 'Rs. 248,500', 'orders': '186 Orders'},
      ],
    },
    'This Year': {
      'revenue': 'Rs. 2,145,000',
      'growth': '+42.5%',
      'orders': '1,420 Orders',
      'units': '2,840 Units',
      'avgOrder': 'Rs. 2,610',
      'satisfaction': '99.0%',
      'cogs': 'Rs. 643,500',
      'netProfit': 'Rs. 1,179,750',
      'logistics': 'Rs. 321,750',
      'bars': [
        {'label': 'Q1', 'val': 0.5, 'amount': 'Rs. 420,000', 'orders': '280 Orders'},
        {'label': 'Q2', 'val': 0.7, 'amount': 'Rs. 580,000', 'orders': '380 Orders'},
        {'label': 'Q3', 'val': 0.85, 'amount': 'Rs. 685,200', 'orders': '490 Orders'},
        {'label': 'Q4', 'val': 1.0, 'amount': 'Rs. 840,000', 'orders': '560 Orders'},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final activeData = _analyticsData[_selectedTimeframe] ?? _analyticsData['This Month']!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeader(context, activeData['growth'] as String)),
        ],
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeframeSelector(),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(activeData),
                  const SizedBox(height: 20),
                  _buildProfitMarginBreakdownCard(activeData),
                  const SizedBox(height: 20),
                  _buildRevenueChartCard(activeData),
                  const SizedBox(height: 20),
                  _buildCategoryDistributionCard(),
                  const SizedBox(height: 20),
                  _buildTopProductsLeaderboard(),
                  const SizedBox(height: 20),
                  _buildCustomerRetentionCard(),
                  const SizedBox(height: 20),
                  _buildRegionalDemographicsCard(),
                  const SizedBox(height: 20),
                  _buildConversionFunnelCard(),
                  const SizedBox(height: 20),
                  _buildRecentTransactionsLog(),
                  const SizedBox(height: 24),
                  _buildExportReportsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String overallGrowth) {
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
            color: const Color(0xFF34D399).withOpacity(0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
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
                        'Business Intelligence',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
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
                          Expanded(
                            child: Text(
                              'Live Sales & Revenue Metrics',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFA7F3D0),
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
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      overallGrowth,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final tf = _timeframes[index];
          final isSelected = _selectedTimeframe == tf;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              backgroundColor: context.cardBg,
              selectedColor: const Color(0xFF10B981),
              side: BorderSide(
                color: isSelected ? const Color(0xFF10B981) : context.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              label: Text(
                tf,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : context.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedTimeframe = tf;
                  _selectedBarIndex = 0;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> activeData) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          title: 'Gross Revenue',
          value: activeData['revenue'] as String,
          growth: activeData['growth'] as String,
          subtext: 'Avg ${activeData['avgOrder']} / order',
          isPositive: true,
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF10B981),
        ),
        _buildMetricCard(
          title: 'Orders Processed',
          value: activeData['orders'] as String,
          growth: '+14.2%',
          subtext: '99.4% Fulfillment Rate',
          isPositive: true,
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF3B82F6),
        ),
        _buildMetricCard(
          title: 'Plants Delivered',
          value: activeData['units'] as String,
          growth: '+18.0%',
          subtext: 'Zero Damage Claims',
          isPositive: true,
          icon: Icons.local_florist_outlined,
          color: const Color(0xFF8B5CF6),
        ),
        _buildMetricCard(
          title: 'Store Satisfaction',
          value: activeData['satisfaction'] as String,
          growth: '+1.2%',
          subtext: '4.9 ★ (142 Reviews)',
          isPositive: true,
          icon: Icons.star_outline_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String growth,
    required String subtext,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6.5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (isPositive ? const Color(0xFF10B981) : Colors.redAccent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  growth,
                  style: GoogleFonts.inter(
                    color: isPositive ? const Color(0xFF10B981) : Colors.redAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: GoogleFonts.inter(
                  color: const Color(0xFF10B981),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMarginBreakdownCard(Map<String, dynamic> activeData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Financial Margin Overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '55% Net Margin',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-color segmented progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: 55, child: Container(color: const Color(0xFF10B981))),
                  Expanded(flex: 30, child: Container(color: const Color(0xFF3B82F6))),
                  Expanded(flex: 15, child: Container(color: const Color(0xFFF59E0B))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildLegendDot(color: const Color(0xFF10B981), label: 'Net Profit: ${activeData['netProfit']} (55%)'),
              _buildLegendDot(color: const Color(0xFF3B82F6), label: 'COGS: ${activeData['cogs']} (30%)'),
              _buildLegendDot(color: const Color(0xFFF59E0B), label: 'Logistics: ${activeData['logistics']} (15%)'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRevenueChartCard(Map<String, dynamic> activeData) {
    final List<Map<String, dynamic>> bars = (activeData['bars'] as List<dynamic>).cast<Map<String, dynamic>>();
    final selectedBar = _selectedBarIndex < bars.length ? bars[_selectedBarIndex] : bars.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Growth Bar Chart',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'Tap pillar to inspect earnings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${selectedBar['label']}: ${selectedBar['amount']}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Interactive Pillars Chart
          SizedBox(
            height: 155,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (index) {
                final b = bars[index];
                final double heightFactor = (b['val'] as num).toDouble();
                final isSelected = _selectedBarIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedBarIndex = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b['amount'] as String,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 100 * heightFactor,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                : [const Color(0xFF10B981).withOpacity(0.4), const Color(0xFF10B981).withOpacity(0.15)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF34D399) : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 10,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b['label'] as String,
                        style: GoogleFonts.inter(
                          color: isSelected ? const Color(0xFF10B981) : context.textSecondary,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildCategoryDistributionCard() {
    final categories = [
      {'name': '🪴 Indoor Foliage Plants', 'pct': 0.48, 'val': 'Rs. 119,280', 'count': '142 sold', 'color': const Color(0xFF10B981)},
      {'name': '🌳 Outdoor & Garden Shrubs', 'pct': 0.28, 'val': 'Rs. 69,580', 'count': '84 sold', 'color': const Color(0xFF3B82F6)},
      {'name': '✨ Rare Variegated Collectibles', 'pct': 0.16, 'val': 'Rs. 39,760', 'count': '38 sold', 'color': const Color(0xFF8B5CF6)},
      {'name': '🌸 Flowering Plants & Pots', 'pct': 0.08, 'val': 'Rs. 19,880', 'count': '26 sold', 'color': const Color(0xFFF59E0B)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Breakdown by Plant Category',
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((c) {
            final color = c['color'] as Color;
            final pct = c['pct'] as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${c['val']} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: context.border.withOpacity(0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTopProductsLeaderboard() {
    final products = [
      {'name': 'Monstera Deliciosa (Swiss Cheese)', 'sales': '42 Sold', 'rev': 'Rs. 147,000', 'badge': '🔥 #1 Seller', 'emoji': '🪴'},
      {'name': 'Fiddle Leaf Fig Tree (Ficus)', 'sales': '28 Sold', 'rev': 'Rs. 190,400', 'badge': '💎 High Value', 'emoji': '🌿'},
      {'name': 'Golden Pothos Hanging Vine', 'sales': '35 Sold', 'rev': 'Rs. 50,750', 'badge': '⚡ Fast Moving', 'emoji': '🍃'},
      {'name': 'Sansevieria Snake Plant', 'sales': '24 Sold', 'rev': 'Rs. 52,800', 'badge': '⭐ Top Rated', 'emoji': '🪴'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Plant Products',
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final p = products[index];
              return Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        p['emoji']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name']!,
                          style: GoogleFonts.outfit(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p['sales']} • ${p['rev']}',
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p['badge']!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildCustomerRetentionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Customer Retention & Behavior',
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.psychology_outlined, color: Color(0xFF10B981), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildRetentionMetricTile(
                  icon: Icons.repeat_rounded,
                  label: 'Repeat Buyers',
                  value: '68.4%',
                  subtext: 'vs 45% Industry Avg',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRetentionMetricTile(
                  icon: Icons.schedule_rounded,
                  label: 'Peak Sales Hours',
                  value: '2 - 6 PM',
                  subtext: 'Afternoon Surge',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRetentionMetricTile(
                  icon: Icons.speed_rounded,
                  label: 'Avg Dispatch Time',
                  value: '1.8 Days',
                  subtext: 'Same Day Processing',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 270.ms);
  }

  Widget _buildRetentionMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: context.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtext,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: context.textSecondary,
              fontSize: 8.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalDemographicsCard() {
    final regions = [
      {'city': 'Colombo & Suburbs', 'pct': '42%', 'orders': '78 Orders'},
      {'city': 'Kandy & Central', 'pct': '24%', 'orders': '45 Orders'},
      {'city': 'Galle & Southern', 'pct': '18%', 'orders': '33 Orders'},
      {'city': 'Negombo & Western', 'pct': '16%', 'orders': '30 Orders'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Shipping Regions',
                style: GoogleFonts.outfit(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const Icon(Icons.map_outlined, color: Color(0xFF10B981), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: regions.map((r) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        r['pct']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF10B981),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r['city']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: context.textPrimary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 280.ms);
  }

  Widget _buildConversionFunnelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Store Conversion Funnel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '10.05% Conv.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildFunnelCol('Store Views', '1,850', Icons.visibility_outlined)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ),
              Expanded(child: _buildFunnelCol('Cart Adds', '520', Icons.shopping_cart_outlined)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ),
              Expanded(child: _buildFunnelCol('Paid Orders', '186', Icons.task_alt_rounded)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFunnelCol(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 22),
        const SizedBox(height: 6),
        Text(
          count,
          style: GoogleFonts.outfit(
            color: context.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: context.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsLog() {
    final transactions = [
      {'name': 'Amal Perera', 'item': 'Monstera Deliciosa', 'amount': 'Rs. 4,105', 'time': '10 mins ago', 'status': 'Paid'},
      {'name': 'Nipuni Fernando', 'item': 'Fiddle Leaf Fig', 'amount': 'Rs. 6,800', 'time': '35 mins ago', 'status': 'Paid'},
      {'name': 'Kavinda Silva', 'item': 'Snake Plant Pot', 'amount': 'Rs. 2,200', 'time': '2 hours ago', 'status': 'In Transit'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sales Transactions',
                style: GoogleFonts.outfit(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF10B981), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.14),
                    child: Text(
                      tx['name']!.substring(0, 1),
                      style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['name']!,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${tx['item']} • ${tx['time']}',
                          style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tx['amount']!,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13.5, color: const Color(0xFF10B981)),
                      ),
                      Text(
                        tx['status']!,
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 320.ms);
  }

  Future<void> _exportPdfReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 10),
              Text('Generating PDF Financial P&L Report...'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      final pdf = pw.Document();
      final activeData = _analyticsData[_selectedTimeframe]!;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfCtx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PLANTORA - SELLER P&L REPORT',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.green700, thickness: 1.5),
                pw.SizedBox(height: 12),
                pw.Text('Executive Summary (${_selectedTimeframe})', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  context: pdfCtx,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                  rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  data: <List<String>>[
                    <String>['Financial Metric', 'Value', 'Performance vs Prior'],
                    <String>['Gross Revenue', activeData['revenue'] as String, activeData['growth'] as String],
                    <String>['Orders Processed', activeData['orders'] as String, '+14.2%'],
                    <String>['Plants Delivered', activeData['units'] as String, '+18.0%'],
                    <String>['Average Order Value', activeData['avgOrder'] as String, 'N/A'],
                    <String>['Net Profit (55%)', activeData['netProfit'] as String, '55% Net Margin'],
                    <String>['COGS / Sourcing (30%)', activeData['cogs'] as String, '30% Cost Share'],
                    <String>['Logistics & Delivery (15%)', activeData['logistics'] as String, '15% Logistics'],
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Text('Top Performing Plant Products', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  context: pdfCtx,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                  data: <List<String>>[
                    <String>['Product Name', 'Sales Volume', 'Revenue Generated'],
                    <String>['Monstera Deliciosa (Swiss Cheese)', '42 Units', 'Rs. 147,000'],
                    <String>['Fiddle Leaf Fig Tree (Ficus)', '28 Units', 'Rs. 190,400'],
                    <String>['Golden Pothos Hanging Vine', '35 Units', 'Rs. 50,750'],
                    <String>['Sansevieria Snake Plant', '24 Units', 'Rs. 52,800'],
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.Center(
                  child: pw.Text('Official Report Generated by Plantora Business Intelligence | www.plantora.app',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      Directory targetDir;
      try {
        final extDir = await getExternalStorageDirectory();
        targetDir = extDir ?? await getApplicationDocumentsDirectory();
      } catch (_) {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'Plantora_PL_Report_${_selectedTimeframe.replaceAll(' ', '_')}.pdf';
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF Generated: $fileName'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () {
                Share.shareXFiles([XFile(file.path)], text: 'Plantora Seller P&L Financial Report');
              },
            ),
          ),
        );
      }

      try {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } catch (printErr) {
        debugPrint('Printing share error: $printErr');
        await Share.shareXFiles([XFile(file.path)], text: 'Plantora Seller P&L Financial Report');
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportCsvReport() async {
    try {
      final activeData = _analyticsData[_selectedTimeframe]!;
      final StringBuffer csv = StringBuffer();

      csv.writeln('PLANTORA SELLER SALES LEDGER REPORT');
      csv.writeln('Timeframe,"${_selectedTimeframe}"');
      csv.writeln('Generated,"${DateTime.now()}"');
      csv.writeln();

      csv.writeln('Financial Metric,Value,Growth');
      csv.writeln('Gross Revenue,"${activeData['revenue']}",${activeData['growth']}');
      csv.writeln('Orders Processed,"${activeData['orders']}",+14.2%');
      csv.writeln('Units Delivered,"${activeData['units']}",+18.0%');
      csv.writeln('Average Order Value,"${activeData['avgOrder']}",N/A');
      csv.writeln('Net Profit (55%),"${activeData['netProfit']}",55%');
      csv.writeln('COGS (30%),"${activeData['cogs']}",30%');
      csv.writeln('Logistics (15%),"${activeData['logistics']}",15%');
      csv.writeln();

      csv.writeln('Category Name,Sales Share,Gross Revenue');
      csv.writeln('Indoor Foliage Plants,48%,Rs. 119280');
      csv.writeln('Outdoor & Garden Shrubs,28%,Rs. 69580');
      csv.writeln('Rare Variegated Collectibles,16%,Rs. 39760');
      csv.writeln('Flowering Plants & Pots,8%,Rs. 19880');
      csv.writeln();

      csv.writeln('Product Name,Sales Volume,Revenue Generated,Badge');
      csv.writeln('Monstera Deliciosa,42 Sold,Rs. 147000,#1 Seller');
      csv.writeln('Fiddle Leaf Fig Tree,28 Sold,Rs. 190400,High Value');
      csv.writeln('Golden Pothos Hanging Vine,35 Sold,Rs. 50750,Fast Moving');
      csv.writeln('Sansevieria Snake Plant,24 Sold,Rs. 52800,Top Rated');

      Directory targetDir;
      try {
        final extDir = await getExternalStorageDirectory();
        targetDir = extDir ?? await getApplicationDocumentsDirectory();
      } catch (_) {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'Plantora_Sales_Ledger_${_selectedTimeframe.replaceAll(' ', '_')}.csv';
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsString(csv.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ CSV Saved: $fileName'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () {
                Share.shareXFiles([XFile(file.path)], text: 'Plantora Seller Sales Ledger CSV');
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildExportReportsSection() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportPdfReport,
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF10B981), size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Export PDF Report',
                style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF10B981)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportCsvReport,
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Download CSV',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }
}
