import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/premium_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SellerOffersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const SellerOffersScreen({Key? key, this.onMenuTap}) : super(key: key);

  @override
  State<SellerOffersScreen> createState() => _SellerOffersScreenState();
}

class _SellerOffersScreenState extends State<SellerOffersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _validityCtrl = TextEditingController();
  
  bool _isLoading = false;
  List<dynamic> _ads = [];
  bool _isLoadingAds = true;
  
  late PageController _adPageController;
  int _currentAdPage = 0;

  String _selectedColorHex = '0xFF012E23';
  String _selectedColorHexSecondary = '0xFF10B981';

  final List<Map<String, String>> _colorOptions = [
    {'name': 'Emerald', 'color1': '0xFF012E23', 'color2': '0xFF10B981', 'icon': '🌿'},
    {'name': 'Ocean', 'color1': '0xFF1E3A8A', 'color2': '0xFF3B82F6', 'icon': '🌊'},
    {'name': 'Sunset', 'color1': '0xFFC2410C', 'color2': '0xFFF97316', 'icon': '🌅'},
    {'name': 'Berry', 'color1': '0xFF5B21B6', 'color2': '0xFF8B5CF6', 'icon': '🫐'},
    {'name': 'Crimson', 'color1': '0xFF991B1B', 'color2': '0xFFEF4444', 'icon': '🌺'},
    {'name': 'Teal', 'color1': '0xFF115E59', 'color2': '0xFF14B8A6', 'icon': '✨'},
  ];

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

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    
    _titleCtrl.addListener(() => setState(() {}));
    _discountCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
    _validityCtrl.addListener(() => setState(() {}));
    
    _fetchAds();
  }

  Future<void> _fetchAds() async {
    setState(() => _isLoadingAds = true);
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        if (mounted) setState(() => _ads = []);
        return;
      }
      
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/ads/${user.id}'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        if (mounted) {
          setState(() => _ads = decoded);
        }
      } else {
        debugPrint('Failed to load ads: ${response.statusCode}');
        if (mounted) setState(() => _ads = []);
      }
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      if (mounted) setState(() => _ads = []);
    } finally {
      if (mounted) setState(() => _isLoadingAds = false);
    }
  }

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/seller/ads'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: json.encode({
          'title': _titleCtrl.text,
          'discountPercentage': int.parse(_discountCtrl.text),
          'description': _descCtrl.text,
          'validity': _validityCtrl.text.isEmpty ? 'Limited Time Offer' : _validityCtrl.text,
          'colorHex': _selectedColorHex,
          'colorHexSecondary': _selectedColorHexSecondary,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Campaign Created Successfully!');
        _resetForm();
        _fetchAds();
      } else {
        debugPrint('Failed to create ad: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create campaign')));
      }
    } catch (e) {
      debugPrint('Error creating ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error creating campaign')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAd(String adId) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/seller/ads/$adId'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        _fetchAds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign removed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete campaign')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error deleting campaign')),
      );
    }
  }

  void _resetForm() {
    _titleCtrl.clear();
    _discountCtrl.clear();
    _descCtrl.clear();
    _validityCtrl.clear();
    setState(() {
      _selectedColorHex = '0xFF012E23';
      _selectedColorHexSecondary = '0xFF10B981';
    });
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLivePreview() {
    final title = _titleCtrl.text.isEmpty ? 'Monsoon Plant Sale' : _titleCtrl.text;
    final discount = _discountCtrl.text.isEmpty ? '20' : _discountCtrl.text;
    final desc = _descCtrl.text.isEmpty
        ? 'Get exclusive discounts on all indoor plant collections!'
        : _descCtrl.text;
    final validity = _validityCtrl.text.isEmpty ? 'Valid till 31st Oct' : _validityCtrl.text;

    final primaryColor = _parseColor(_selectedColorHex, const Color(0xFF012E23));
    final secondaryColor = _parseColor(_selectedColorHexSecondary, const Color(0xFF10B981));

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 195),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Background Decorative Shine & Circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          
          // Content Layout
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE PREVIEW BANNER',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Colors.black, size: 13),
                          Text(
                            'LIMITED OFFER',
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Main Title & Discount Badge Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.88),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Big Discount Starburst Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$discount%',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'OFF',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Footer: Expiry + CTA button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          validity,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Claim Deal',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
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
    ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97), duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_chart_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Campaign Details',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInputField(
              controller: _titleCtrl,
              label: 'Campaign Title',
              hint: 'e.g., Monsoon Botanical Sale',
              icon: Icons.campaign_rounded,
              validator: (v) => v!.isEmpty ? 'Please enter a campaign title' : null,
            ),
            const SizedBox(height: 14),

            _buildInputField(
              controller: _discountCtrl,
              label: 'Discount Percentage (%)',
              hint: 'e.g., 20',
              icon: Icons.percent_rounded,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter discount %';
                final n = int.tryParse(v);
                if (n == null || n < 1 || n > 99) return 'Enter a valid % (1-99)';
                return null;
              },
            ),
            const SizedBox(height: 14),

            _buildInputField(
              controller: _descCtrl,
              label: 'Offer Summary (Optional)',
              hint: 'e.g., 20% off all indoor plants this week!',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 14),

            _buildInputField(
              controller: _validityCtrl,
              label: 'Expiry / Validity Text',
              hint: 'e.g., Valid till 31st Oct 2026',
              icon: Icons.event_available_rounded,
            ),
            const SizedBox(height: 24),

            Text(
              'Banner Color Theme',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Color Theme Pills Bar
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (context, index) {
                  final option = _colorOptions[index];
                  final isSelected = _selectedColorHex == option['color1'];
                  final c1 = Color(int.parse(option['color1']!));
                  final c2 = Color(int.parse(option['color2']!));

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorHex = option['color1']!;
                        _selectedColorHexSecondary = option['color2']!;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c1, c2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? context.textPrimary : Colors.transparent,
                          width: isSelected ? 2.5 : 0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: c2.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(option['icon']!, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            option['name']!,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Publish Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createAd,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isLoading ? 'Publishing Campaign...' : 'Publish Promotion Banner',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 4,
                  shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: context.textSecondary.withOpacity(0.5), fontSize: 12.5),
        prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildActiveAds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Campaigns',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_ads.length} Running',
                style: GoogleFonts.inter(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _isLoadingAds
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ads.length,
                itemBuilder: (context, index) {
                  final ad = _ads[index];
                  final pColor = _parseColor(ad['colorHex'], const Color(0xFF012E23));
                  final sColor = _parseColor(ad['colorHexSecondary'], const Color(0xFF10B981));
                  final views = ad['views'] ?? 180;
                  final redemptions = ad['redemptions'] ?? 24;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(
                      children: [
                        // Ad Preview Badge
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [pColor, sColor],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${ad['discountPercentage'] ?? 10}%',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Campaign Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad['title'] ?? 'Special Offer',
                                style: GoogleFonts.outfit(
                                  color: context.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ad['validity'] ?? 'Active Promotion',
                                style: GoogleFonts.inter(
                                  color: context.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$views views',
                                    style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.local_offer_outlined, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$redemptions claims',
                                    style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            _deleteAd(ad['id']);
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
                },
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: isDesktop
          ? null
          : PremiumAppBar(
              title: 'Offers & Promotions',
              subtitle: 'Manage Store Discounts & Ads',
              showBackButton: widget.onMenuTap == null,
              leading: widget.onMenuTap != null
                  ? PremiumAppBar.buildEmblemButton(
                      icon: Icons.menu_rounded,
                      onTap: widget.onMenuTap!,
                    )
                  : null,
            ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Campaign',
                  style: GoogleFonts.outfit(
                      fontSize: 28, fontWeight: FontWeight.w900, color: context.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Design a stunning banner to promote your store discounts.',
                  style: TextStyle(color: context.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 32),
                _buildForm(),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Preview',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildLivePreview(),
                const SizedBox(height: 48),
                _buildActiveAds().animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Preview',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: context.textSecondary),
              ),
              const SizedBox(height: 10),
              _buildLivePreview(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 32),
              _buildActiveAds(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _discountCtrl.dispose();
    _descCtrl.dispose();
    _validityCtrl.dispose();
    _adPageController.dispose();
    super.dispose();
  }
}
