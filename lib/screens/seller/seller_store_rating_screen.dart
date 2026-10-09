import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_app_bar.dart';

class SellerStoreRatingScreen extends StatefulWidget {
  const SellerStoreRatingScreen({super.key});

  @override
  State<SellerStoreRatingScreen> createState() => _SellerStoreRatingScreenState();
}

class _SellerStoreRatingScreenState extends State<SellerStoreRatingScreen> {
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _reviews = [
    {
      'customerName': 'Nethmi Vihanga',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      'rating': 5.0,
      'date': 'Oct 06, 2026',
      'productName': 'Monstera Deliciosa (Swiss Cheese)',
      'comment': 'The plant arrived extremely healthy and well-packaged! The potting soil was rich and moist. Highly recommend this seller!',
      'sellerReply': 'Thank you so much Nethmi! We take extra care in packing our greenhouse plants. Happy gardening! 🌿',
      'isVerified': true,
      'helpfulCount': 14,
    },
    {
      'customerName': 'Kasun Perera',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      'rating': 5.0,
      'date': 'Oct 04, 2026',
      'productName': 'Fiddle Leaf Fig (Ficus Lyrata)',
      'comment': 'Super fast delivery in Colombo! The tree looks stunning in my living room. Zero leaf drop or pest damage.',
      'sellerReply': 'Appreciate your awesome feedback Kasun! Enjoy your new green companion! 🪴',
      'isVerified': true,
      'helpfulCount': 9,
    },
    {
      'customerName': 'Dilini Silva',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      'rating': 4.5,
      'date': 'Sep 29, 2026',
      'productName': 'Calathea Orbifolia',
      'comment': 'Very pretty leaves! Delivered on time. Included organic fertilizer sample which was a nice bonus.',
      'sellerReply': null,
      'isVerified': true,
      'helpfulCount': 6,
    },
    {
      'customerName': 'Chathura Ranasinghe',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      'rating': 5.0,
      'date': 'Sep 25, 2026',
      'productName': 'Golden Pothos (Devil\'s Ivy)',
      'comment': 'Vibrant green vines and strong roots. Already sprouting new shoots after one week!',
      'sellerReply': 'Thank you Chathura! Golden Pothos loves bright indirect light! 🌿✨',
      'isVerified': true,
      'helpfulCount': 11,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Store Rating & Reviews',
        subtitle: 'Customer feedback & satisfaction metrics',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary Banner Card
            _buildOverallRatingCard(context),
            const SizedBox(height: 20),

            // Performance Badge Chips
            _buildMetricsRow(context),
            const SizedBox(height: 24),

            // Filter Tabs
            _buildFilterChips(context),
            const SizedBox(height: 16),

            // Customer Reviews List
            Text(
              'Verified Customer Feedback',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._reviews.map((rev) => _buildReviewCard(context, rev)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF012E23),
            Color(0xFF044E39),
            Color(0xFF065F46),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF34D399).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Rating Score Left Block
          Column(
            children: [
              Text(
                '4.8',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                    color: const Color(0xFFFBBF24),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '128 Ratings',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA7F3D0),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 85, color: Colors.white24),
          const SizedBox(width: 18),

          // Rating Bars Right Block
          Expanded(
            child: Column(
              children: [
                _buildStarBar('5 ★', 0.85, '85%'),
                const SizedBox(height: 5),
                _buildStarBar('4 ★', 0.10, '10%'),
                const SizedBox(height: 5),
                _buildStarBar('3 ★', 0.03, '3%'),
                const SizedBox(height: 5),
                _buildStarBar('2 ★', 0.01, '1%'),
                const SizedBox(height: 5),
                _buildStarBar('1 ★', 0.01, '1%'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _buildStarBar(String label, double ratio, String pctStr) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            pctStr,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA7F3D0), fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            context,
            icon: Icons.thumb_up_rounded,
            title: '98% Positive',
            subtitle: 'Buyer Satisfaction',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            context,
            icon: Icons.local_shipping_rounded,
            title: '99% On-Time',
            subtitle: 'Swift Dispatch',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            context,
            icon: Icons.verified_rounded,
            title: '100% Quality',
            subtitle: 'Verified Pest-Free',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 9.5, color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = ['All (128)', '5 Stars (110)', '4 Stars (12)', 'With Photos (45)'];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filters[index],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : context.textPrimary,
                ),
              ),
              backgroundColor: context.cardBg,
              selectedColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF10B981) : context.border,
                ),
              ),
              onSelected: (_) => setState(() => _selectedFilterIndex = index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> rev) {
    final double rating = rev['rating'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(rev['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rev['customerName'],
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: context.textPrimary),
                        ),
                        if (rev['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                        ],
                      ],
                    ),
                    Text(
                      'Purchased: ${rev['productName']}',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rev['date'],
                    style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review Comment Text
          Text(
            rev['comment'],
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.4,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Seller Reply if available
          if (rev['sellerReply'] != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'Your Store Response',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rev['sellerReply'],
                    style: GoogleFonts.inter(fontSize: 12.5, color: context.textPrimary, height: 1.3),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
