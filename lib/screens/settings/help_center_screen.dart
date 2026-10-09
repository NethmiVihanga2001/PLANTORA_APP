import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../plantora_assistant_screen.dart';
import '../orders_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Set<int> _expandedFaqIndices = {0}; // First FAQ open by default

  final List<String> _categories = [
    'All',
    'Orders & Delivery',
    'AI Scanner & Care',
    'Returns & Refunds',
    'Nursery Sellers',
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Orders & Delivery',
      'question': 'How long does live plant delivery take?',
      'answer': 'Orders within Colombo Metro and Gampaha arrive same-day or within 24 hours. Islandwide deliveries take 24–48 hours using specialized ventilated moisture-lock packaging to ensure plants arrive fresh, hydrated, and undamaged.',
    },
    {
      'category': 'Orders & Delivery',
      'question': 'How can I track my live plant courier?',
      'answer': 'Navigate to "My Orders" from your account or drawer. You will see live delivery milestones from nursery packaging, carrier dispatch, and estimated arrival time directly on an interactive map.',
    },
    {
      'category': 'Orders & Delivery',
      'question': 'What payment methods are supported on Plantora?',
      'answer': 'We support Visa, MasterCard, Direct Bank Deposit, Koko & Mintpay 3-month interest-free installments, and Cash on Delivery (COD) for eligible municipal zones.',
    },
    {
      'category': 'AI Scanner & Care',
      'question': 'How accurate is the Plantora AI Camera Scanner?',
      'answer': 'Our deep learning vision model is trained on over 2.5 million botanical specimens and achieves over 96% accuracy across tropical house plants, succulents, herbs, and flowering trees.',
    },
    {
      'category': 'AI Scanner & Care',
      'question': 'How do automated watering reminders work?',
      'answer': 'When you save a plant to "My Garden", Plantora calculates its pot size, soil drainage, and local humidity to schedule smart water, misting, and fertilizer reminders tailored specifically to your plant.',
    },
    {
      'category': 'Returns & Refunds',
      'question': 'What is the Plantora 48-Hour Green Guarantee?',
      'answer': 'If any live plant arrives broken, wilted, or infected, simply upload a clear photo within 48 hours of delivery in "My Orders". We issue an immediate replacement from another verified nursery or a 100% full escrow refund.',
    },
    {
      'category': 'Returns & Refunds',
      'question': 'How long do refunds take to reflect in my bank?',
      'answer': 'Credit card and debit refunds are issued immediately upon claim approval and appear in your account statement within 2–4 business days depending on your issuing bank.',
    },
    {
      'category': 'Nursery Sellers',
      'question': 'How do I register as a verified Plantora Nursery Seller?',
      'answer': 'Open Settings and tap "Switch to Seller Mode". Fill out your nursery name, botanical specialty, and nursery location. Our botanical onboarding team verifies your nursery credentials within 24 hours!',
    },
    {
      'category': 'Nursery Sellers',
      'question': 'When are nursery seller payouts processed?',
      'answer': 'Payouts are automatically wired to your registered commercial bank account every Tuesday for all deliveries successfully confirmed by customers during the previous cycle.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    final query = _searchController.text.trim().toLowerCase();
    return _faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          faq['question'].toString().toLowerCase().contains(query) ||
          faq['answer'].toString().toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openTicketModal(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: AppColors.primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Submit Support Ticket',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'e.g. Question about Monstera order',
                    filled: true,
                    fillColor: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: messageCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'How can we help you?',
                    hintText: 'Provide details about your question or issue...',
                    filled: true,
                    fillColor: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in both subject and message.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Support ticket #PT-8492 submitted successfully!'),
                            ],
                          ),
                          backgroundColor: AppColors.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('SUBMIT TICKET', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Help Center',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Responsive.centered(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Search Banner
              _buildHeroSearch(context),
              const SizedBox(height: 20),

              // Quick Action Support Channels
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Category Filter Pills
              _buildCategoryChips(),
              const SizedBox(height: 18),

              // FAQ Section Header
              Row(
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filtered.length} FAQs',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // FAQs List
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No matching questions found',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching for different keywords or contact support below.',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...filtered.asMap().entries.map((entry) {
                  final index = entry.key;
                  final faq = entry.value;
                  final isExpanded = _expandedFaqIndices.contains(index);

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
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedFaqIndices.remove(index);
                                } else {
                                  _expandedFaqIndices.add(index);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isExpanded
                                          ? AppColors.primaryGreen.withOpacity(0.12)
                                          : (context.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.help_outline_rounded,
                                      size: 16,
                                      color: isExpanded ? AppColors.primaryGreen : context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      faq['question'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  faq['answer'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.55,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Bottom Support Ticket CTA
              _buildBottomSupportCta(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSearch(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F5A32),
            Color(0xFF1E8C51),
            Color(0xFF34D399),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8C51).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How can we help your garden?',
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search orders, botanical guides, delivery tracking, and returns.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search for questions or topics...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E8C51), size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF10B981),
                title: 'Plantora AI Chat',
                subtitle: '24/7 botanical assistant',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlantoraAssistantScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF3B82F6),
                title: 'Track Orders',
                subtitle: 'Live plant courier status',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: Icons.phone_in_talk_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Hotline Support',
                subtitle: '+94 11 750 8800',
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '+94 11 750 8800'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Plantora Hotline +94 11 750 8800 copied!'),
                      backgroundColor: AppColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: Icons.mail_outline_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'Email Help Desk',
                subtitle: 'support@plantora.com',
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'support@plantora.com'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Support email copied to clipboard!'),
                      backgroundColor: AppColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _expandedFaqIndices.clear();
                  _expandedFaqIndices.add(0);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : (context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomSupportCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E293B).withOpacity(0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primaryGreen, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Still need personalized assistance?',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Our Colombo customer care team is online to help you with plant care, returns, or seller inquiries.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openTicketModal(context),
              icon: const Icon(Icons.send_rounded, size: 17),
              label: Text(
                'SEND US A MESSAGE',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
