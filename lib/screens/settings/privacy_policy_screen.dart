import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
        title: 'Privacy Policy',
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
              const SizedBox(height: 20),

              // 4 Core Guarantees Grid
              _buildPillarsGrid(context),
              const SizedBox(height: 24),

              // Section Header
              Text(
                'Detailed Privacy Statements',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Expandable Policy Sections
              ..._buildPolicySections(context),
              const SizedBox(height: 24),

              // Data Rights & DPO Contact Card
              _buildDpoCard(context),
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
            Color(0xFF064E3B),
            Color(0xFF047857),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withOpacity(0.25),
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
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plantora Privacy Promise',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GDPR & PDPA Compliant • Oct 2026',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We believe your garden, plant collection, and personal information belong solely to you. We safeguard your data with bank-level security and strict confidentiality.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.55,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildPillarsGrid(BuildContext context) {
    final pillars = [
      {
        'icon': Icons.lock_rounded,
        'color': const Color(0xFF10B981),
        'title': 'Zero Data Selling',
        'desc': 'We never sell your botanical scans, identity, or browsing logs to ad networks.',
      },
      {
        'icon': Icons.enhanced_encryption_rounded,
        'color': const Color(0xFF3B82F6),
        'title': '256-bit Encryption',
        'desc': 'All chats, transactions, and passwords are protected with AES-256 protocols.',
      },
      {
        'icon': Icons.location_off_rounded,
        'color': const Color(0xFFF59E0B),
        'title': 'Location Privacy',
        'desc': 'GPS is accessed only to calculate local delivery from verified nurseries.',
      },
      {
        'icon': Icons.delete_sweep_rounded,
        'color': const Color(0xFF8B5CF6),
        'title': 'Right to Delete',
        'desc': 'You can export or permanently purge all account data in one click.',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pillars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final p = pillars[index];
        final color = p['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  p['icon'] as IconData,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                p['title'] as String,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p['desc'] as String,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.35,
                  color: context.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPolicySections(BuildContext context) {
    final sections = [
      {
        'title': '1. Information We Collect',
        'subtitle': 'Details required to provide plant care and marketplace services.',
        'content': '''• Profile Information: When registering, we collect your full name, email address, phone number, and delivery address.
• Plant Scans & Photos: Photos you take using the Plantora Camera are processed by our machine learning neural net to identify plants, detect diseases, and recommend optimal watering.
• Marketplace Orders: Purchase logs, items ordered, delivery status, and encrypted transaction identifiers. We do not store raw card numbers or CVVs.
• Device & Performance Data: Device model, operating system, and crash reports to maintain high application performance and stability.''',
      },
      {
        'title': '2. How We Use Your Data',
        'subtitle': 'Purpose-driven processing for an enhanced gardening experience.',
        'content': '''• Tailored Plant Health: Feeding your plant images into our botanical engine to generate precise health scores, nutrient tips, and sunlight calibrations.
• Marketplace Fulfillment: Transmitting destination addresses to verified nursery sellers and delivery drivers so your live plants arrive safely and fresh.
• Smart Botanical Alerts: Sending timely push notifications for watering reminders and seasonal pest alerts based on your local microclimate.
• Fraud Prevention: Protecting our community against unauthorized transactions and suspicious account activities.''',
      },
      {
        'title': '3. Information Sharing & Third Parties',
        'subtitle': 'Strictly limited to order fulfillment and essential partners.',
        'content': '''• Verified Nurseries: Sellers receive customer names and delivery destinations solely for packaging and order dispatch.
• Logistic Drivers: Drivers receive contact numbers and GPS coordinates solely during active delivery runs.
• Secure Payment Providers: Credit card and payment processing is handled through PCI-DSS Level 1 compliant financial gateways.
• Zero Advertisers: We do not share or monetize your botanical data with third-party advertisers or behavioral tracking brokers.''',
      },
      {
        'title': '4. Data Retention & Your Rights',
        'subtitle': 'Full control over your botanical records and account information.',
        'content': '''• Right to Access: You can request an electronic copy of all data Plantora holds about your profile and garden at any time.
• Right to Rectification: You can update your contact information, addresses, and nursery details directly in Settings.
• Right to Erasure: You may request complete account deletion. All personal details and plant photos will be permanently expunged within 30 days.
• Data Portability: You may request an export of your garden inventory and care schedules in standard JSON or CSV format.''',
      },
      {
        'title': '5. Cookies, Storage & Security Standards',
        'subtitle': 'State-of-the-art infrastructure and data isolation.',
        'content': '''• Encrypted Transmission: All network traffic between your mobile app and Plantora servers uses TLS 1.3 cryptographic protocols.
• Secure Local Storage: Authentication tokens and offline plant databases are stored in encrypted system storage (Keychain / EncryptedSharedPreferences).
• Children's Privacy: Plantora is designed for garden enthusiasts aged 13 and above. We never knowingly collect information from minors.''',
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

  Widget _buildDpoCard(BuildContext context) {
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
              const Icon(Icons.security_rounded, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'Data Protection Officer (DPO)',
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
            'Have questions regarding how your botanical scans or customer profile is handled? Contact our dedicated privacy desk directly:',
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
                      content: const Text('DPO email copied to clipboard!'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
