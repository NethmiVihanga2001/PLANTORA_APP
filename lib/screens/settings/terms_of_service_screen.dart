import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  final Set<int> _expandedSections = {0, 1}; // Default first two open

  void _toggleSection(int index) {
    setState(() {
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Terms of Service',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Responsive.centered(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              _buildHeroCard(context),
              const SizedBox(height: 18),

              // 48-Hour Live Plant Guarantee Highlight
              _buildGuaranteeBanner(context),
              const SizedBox(height: 22),

              // Section Header
              Text(
                'Binding Terms & Operating Guidelines',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Expandable Terms Clauses
              ..._buildTermsSections(context),
              const SizedBox(height: 24),

              // Acceptance & Legal Inquiries Card
              _buildLegalDeskCard(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F5A32),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: Color(0xFF4ADE80),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plantora User Agreement',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Effective Date: October 2026 • v3.1',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Plantora. These terms establish transparent, fair rules for botanical buyers, verified nurseries, and smart garden enthusiasts across our global community.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.55,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildGuaranteeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plantora 48-Hour Live Plant Guarantee',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every botanical specimen purchased through verified nurseries is guaranteed to arrive alive, hydrated, and healthy. If transit damages occur, snap a photo within 48 hours for an instant replacement or escrow refund.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTermsSections(BuildContext context) {
    final sections = [
      {
        'title': '1. Acceptance & User Accounts',
        'subtitle': 'Eligibility and security of your Plantora profile.',
        'content': '''• Agreement: By accessing Plantora or creating an account, you legally agree to be bound by these terms and our Privacy Policy.
• Eligibility: You must be at least 13 years old to utilize Plantora services.
• Account Integrity: You are responsible for safeguarding your login credentials. Notify us immediately of any unauthorized access.
• Multiple Roles: A single user profile may switch between Buyer, Nursery Seller, and Green Courier modes subject to identity verification.''',
      },
      {
        'title': '2. Marketplace Orders & Escrow Security',
        'subtitle': 'Purchase flow, order confirmation, and financial protection.',
        'content': '''• Escrow Protection: When purchasing plants or gardening equipment, funds are held in secure escrow and released to the nursery only upon confirmed live delivery.
• Accurate Pricing: All prices are shown in Sri Lankan Rupees (LKR) or local currency, including all applicable marketplace service fees.
• Cancellations: Orders may be cancelled penalty-free prior to nursery packaging and carrier dispatch.''',
      },
      {
        'title': '3. Nursery Seller Standards & Botanical Ethics',
        'subtitle': 'Quality control, packaging guidelines, and plant authenticity.',
        'content': '''• Healthy Botanical Deliveries: Sellers guarantee that all live specimens are rooted, parasite-free, and packaged with root moisture protection.
• Prohibited Flora: Listing invasive botanical species, narcotics, or protected wild forest reserves is strictly prohibited and results in immediate permanent ban.
• Authentic Photos: Nurseries must provide genuine photos accurately reflecting the size, pot type, and foliage condition of the plants being offered.''',
      },
      {
        'title': '4. Plantora AI Scanner & Diagnostic Disclaimer',
        'subtitle': 'Educational purpose of our machine learning features.',
        'content': '''• Advisory Intelligence: Plantora AI identifies species and suggests care guidelines with over 96% diagnostic accuracy.
• Non-Agronomic Warranty: AI health diagnoses (fungal infections, nutrient deficiencies) are informational guidance and do not substitute certified laboratory agricultural inspections.
• Continuous Learning: Photos contributed anonymously assist in training our tropical neural models for the benefit of all gardeners.''',
      },
      {
        'title': '5. Intellectual Property & Community Content',
        'subtitle': 'Ownership of photos, reviews, and botanical guides.',
        'content': '''• Your Content: You retain full copyright ownership of all photos, plant care reviews, and forum posts you submit.
• License to Display: You grant Plantora a non-exclusive, worldwide, royalty-free license to display your listing photos on our mobile platform.
• Brand Assets: The Plantora trademark, leaf logo, and proprietary application interface are protected intellectual property.''',
      },
      {
        'title': '6. Governing Law & Dispute Resolution',
        'subtitle': 'Legal jurisdiction and arbitration protocols.',
        'content': '''• Governing Jurisdiction: These terms are governed under the laws of the Democratic Socialist Republic of Sri Lanka, including the Electronic Transactions Act.
• Informal Resolution: In the event of a dispute between a buyer and seller, our support mediation team will adjudicate within 48 business hours.
• Fair Arbitration: Unresolved claims will be submitted to confidential arbitration in Colombo, Sri Lanka.''',
      },
    ];

    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final sec = entry.value;
      final isExpanded = _expandedSections.contains(index);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded
                ? AppColors.primaryGreen.withOpacity(0.4)
                : (context.isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            width: isExpanded ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              InkWell(
                onTap: () => _toggleSection(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppColors.primaryGreen.withOpacity(0.12)
                              : (context.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isExpanded ? AppColors.primaryGreen : context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sec['title']!,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sec['subtitle']!,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? AppColors.primaryGreen : context.textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Text(
                    sec['content']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.6,
                      color: context.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLegalDeskCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'Plantora Legal Counsel Desk',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'For commercial partnerships, nursery licensing inquiries, or legal notifications, reach out to our legal department:',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.primaryGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'supportplantora@gmail.com',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'supportplantora@gmail.com'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Legal email copied to clipboard!'),
                      backgroundColor: AppColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
