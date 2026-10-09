import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;

  final List<Map<String, String>> _onboardingPages = [
    {
      'title': 'AI Herbal Identification',
      'subtitle': 'Instant Plant Diagnostics & Care',
      'description':
          'Snap or upload a photo of any plant or herb to instantly discover its species, medicinal uses, watering schedule, and care guidelines with AI precision.',
      'image': 'assets/images/onboarding_plant_id.jpg',
      'badge': 'SCAN & IDENTIFY',
    },
    {
      'title': 'Herbal Marketplace',
      'subtitle': 'Verified Organic Growers & Shops',
      'description':
          'Browse and order fresh medicinal herbs, rare seeds, organic oils, and handcrafted botanical remedies directly from trusted local sellers.',
      'image': 'assets/images/onboarding_marketplace.jpg',
      'badge': 'ORGANIC SHOPPING',
    },
    {
      'title': 'AI Plant Doctor & Assistant',
      'subtitle': '24/7 Expert Botanical Guidance',
      'description':
          'Ask our AI plant assistant anything—from diagnosing plant diseases to recommending natural herbal recipes and personalized garden tips.',
      'image': 'assets/images/onboarding_ai_chat.jpg',
      'badge': 'SMART ASSISTANT',
    },
    {
      'title': 'Fast Home Delivery',
      'subtitle': 'Real-Time Package Tracking',
      'description':
          'Track your plant & product deliveries live as our verified drivers ensure fresh, safe, and speedy doorstep delivery right to your home.',
      'image': 'assets/images/onboarding_delivery.jpg',
      'badge': 'DOORSTEP DELIVERY',
    },
  ];

  // Total pages = 1 (Welcome Cover) + 4 (Onboarding Pages) = 5 total slides
  int get _totalPages => 1 + _onboardingPages.length;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.isLoggedIn && auth.user != null) {
          final role = auth.user?.role ?? 'Customer';
          if (role == 'Driver') {
            Navigator.pushReplacementNamed(context, '/driver-dashboard');
          } else if (role == 'Seller') {
            Navigator.pushReplacementNamed(context, '/seller-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onSkip() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full-Screen Enchanted Background Image ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/plantora_full_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0B1D11), Color(0xFF030904)],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 2: Deep Dark Green & Black Vignette Overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF08150C).withOpacity(0.65),
                    const Color(0xFF030A05).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Dynamic Ambient Pulsing Sunlight Ray ──
          Positioned(
            top: 0,
            left: size.width * 0.5 - 2,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 4,
                height: 200 + 40 * _pulseController.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF4ADE80).withOpacity(0.90),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80)
                          .withOpacity(0.35 + 0.20 * _pulseController.value),
                      blurRadius: 28,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 4: Main Content Container (Swipeable PageView) ──
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (Logo Badge on Onboarding & Skip Button)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Brand Mark (Visible on Pages 1-4)
                      if (_currentPage > 0)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF4ADE80).withOpacity(0.4)),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Color(0xFF4ADE80),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PLANTORA',
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),

                      // Skip Button Removed as requested
                      const SizedBox.shrink(),
                    ],
                  ),
                ),

                // Center Swipeable PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _totalPages,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // 🌟 SLIDE 0: Minimalist Luxury Welcome Cover Page
                        return _buildWelcomeCoverPage(context, size);
                      } else {
                        // 🌿 SLIDES 1 to 4: Onboarding Feature Screens
                        final item = _onboardingPages[index - 1];
                        return _buildOnboardingPage(context, size, item, index);
                      }
                    },
                  ),
                ),

                // Bottom Controls (Page Indicators & Action Button)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // Page Indicator Dots (Slide 0: Welcome, Slides 1-4: Onboarding)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_totalPages, (i) {
                          final isSelected = _currentPage == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isSelected ? 28 : 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4ADE80)
                                  : Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4ADE80)
                                            .withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Action Button (Slide 0: "GET STARTED" | Slides 1-3: "Next Feature" | Slide 4: "CONTINUE TO APP")
                      if (_currentPage == 0)
                        _buildWelcomeActionButton(context)
                      else if (_currentPage == _totalPages - 1)
                        _buildGetStartedButton(context)
                      else
                        _buildNextButton(),

                      // Secondary Link for Login on Welcome Page
                      if (_currentPage == 0) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Log In',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF4ADE80),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 SLIDE 0: Perfectly Balanced Luxury Welcome Cover Page Widget
  Widget _buildWelcomeCoverPage(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Spacer(flex: 1), // Equal top spacing for perfect vertical balance

          // 1. Glowing Hero 3D Botanical P-Emblem (plantora_emblem.jpg)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              return Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4ADE80)
                        .withOpacity(0.55 + 0.35 * _pulseController.value),
                    width: 2.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80)
                          .withOpacity(0.40 + 0.20 * _pulseController.value),
                      blurRadius: 40 + 15 * _pulseController.value,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/plantora_emblem.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_rounded,
                      size: 85,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
              );
            },
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.75, 0.75), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          // 2. Main App Title - PLANTORA (Strictly Single Line)
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFECFDF5),
                    Color(0xFF6EE7B7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  'PLANTORA',
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 5.0,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF10B981).withOpacity(0.8),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 700.ms)
              .moveY(begin: 15, end: 0),

          const SizedBox(height: 14),

          // 3. Sleek Single-Line Tagline
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Smart Plant Diagnostics & Organic Marketplace',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE2C085),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 600.ms),

          const SizedBox(height: 14),

          // 4. Clean Single-Line Feature Highlights
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'AI Plant ID  •  24/7 Botanical Doctor  •  Organic Marketplace',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms),

          const Spacer(flex: 1), // Equal bottom spacing for perfect vertical balance
        ],
      ),
    );
  }

  // 🌿 SLIDES 1 to 4: Onboarding Feature Page Widget
  Widget _buildOnboardingPage(
      BuildContext context, Size size, Map<String, String> item, int index) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Feature Image Card
          Container(
            width: size.width * 0.72,
            height: size.width * 0.72,
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFF4ADE80).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.65),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.30),
                  blurRadius: 50,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                item['image']!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF112616),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ),
            ),
          )
              .animate(key: ValueKey('img_$index'))
              .fadeIn(duration: 500.ms)
              .scale(
                  begin: const Offset(0.88, 0.88),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack),

          const SizedBox(height: 20),

          // Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4ADE80).withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Text(
              item['badge']!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4ADE80),
                letterSpacing: 1.2,
              ),
            ),
          )
              .animate(key: ValueKey('badge_$index'))
              .fadeIn(delay: 150.ms, duration: 500.ms),

          const SizedBox(height: 12),

          // Title
          Text(
            item['title']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(delay: 250.ms, duration: 500.ms)
              .moveY(begin: 12, end: 0),

          const SizedBox(height: 6),

          // Subtitle
          Text(
            item['subtitle']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE2C085),
              letterSpacing: 0.2,
            ),
          )
              .animate(key: ValueKey('sub_$index'))
              .fadeIn(delay: 350.ms, duration: 500.ms),

          const SizedBox(height: 14),

          // Glassmorphic Description Box
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2113).withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              item['description']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: Colors.white.withOpacity(0.88),
                height: 1.5,
              ),
            ),
          )
              .animate(key: ValueKey('desc_$index'))
              .fadeIn(delay: 450.ms, duration: 500.ms)
              .moveY(begin: 12, end: 0),
        ],
      ),
    );
  }

  // 🌟 Welcome Action Button (Slide 0 -> Slide 1)
  Widget _buildWelcomeActionButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return GestureDetector(
          onTap: _onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4ADE80),
                  Color(0xFF22C55E),
                  Color(0xFF15803D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E)
                      .withOpacity(0.50 + 0.15 * _pulseController.value),
                  blurRadius: 24 + 8 * _pulseController.value,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'EXPLORE PLANTORA',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🌿 Next Button (Slides 1 to 3)
  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _onNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.12),
          border: Border.all(
            color: const Color(0xFF4ADE80).withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next Feature',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF4ADE80),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 Get Started Button (Final Slide 4 -> Login)
  Widget _buildGetStartedButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4ADE80),
                  Color(0xFF22C55E),
                  Color(0xFF15803D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E)
                      .withOpacity(0.50 + 0.15 * _pulseController.value),
                  blurRadius: 26 + 10 * _pulseController.value,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'GET STARTED',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

