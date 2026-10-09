import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoyaltyCard extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  const LoyaltyCard({super.key, this.onTap, this.padding});

  static final List<Map<String, dynamic>> levels = [
    {
      'name': 'Seedling',
      'emoji': '🌱',
      'minPoints': 0,
      'maxPoints': 100,
      'gradient': [const Color(0xFF3D2E24), const Color(0xFF8D6E63)],
      'accent': const Color(0xFFA1887F),
    },
    {
      'name': 'Sprout',
      'emoji': '🌿',
      'minPoints': 100,
      'maxPoints': 200,
      'gradient': [const Color(0xFF0F432B), const Color(0xFF10B981)],
      'accent': const Color(0xFF34D399),
    },
    {
      'name': 'Bud',
      'emoji': '🌷',
      'minPoints': 200,
      'maxPoints': 300,
      'gradient': [const Color(0xFF881337), const Color(0xFFF43F5E)],
      'accent': const Color(0xFFFB7185),
    },
    {
      'name': 'Blossom',
      'emoji': '🌸',
      'minPoints': 300,
      'maxPoints': 400,
      'gradient': [const Color(0xFF581C87), const Color(0xFFA855F7)],
      'accent': const Color(0xFFC084FC),
    },
    {
      'name': 'Mighty Tree',
      'emoji': '🌳',
      'minPoints': 400,
      'maxPoints': 99999,
      'gradient': [const Color(0xFF064E3B), const Color(0xFF059669)],
      'accent': const Color(0xFF6EE7B7),
    },
  ];

  static Map<String, dynamic> getCurrentLevel(int points) {
    for (var level in levels.reversed) {
      if (points >= level['minPoints']) return level;
    }
    return levels.first;
  }

  static Map<String, dynamic>? getNextLevel(int points) {
    for (var level in levels) {
      if (points < level['maxPoints'] && level['maxPoints'] != 99999) return level;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currentPoints = user?.points ?? 250;
    final userName = user?.name ?? 'Plant Lover';
    final currentLvl = getCurrentLevel(currentPoints);
    final nextLvl = getNextLevel(currentPoints);

    double progress = 1.0;
    int pointsToNext = 0;
    if (nextLvl != null) {
      final range = (nextLvl['maxPoints'] as int) - (currentLvl['minPoints'] as int);
      final earned = currentPoints - (currentLvl['minPoints'] as int);
      progress = (earned / range).clamp(0.0, 1.0);
      pointsToNext = (nextLvl['maxPoints'] as int) - currentPoints;
    }

    final List<Color> gradColors = List<Color>.from(currentLvl['gradient'] as List);

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap ?? () {
          if (ModalRoute.of(context)?.settings.name != '/loyalty') {
            Navigator.pushNamed(context, '/loyalty');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradColors,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradColors[0].withOpacity(0.45),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative Geometric Auras
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -20,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                // Diagonal Foil Accent Lines
                Positioned(
                  top: 0,
                  right: 90,
                  bottom: 0,
                  width: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card Content Container
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row: Brand Title + Tier Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PLANTORA',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'VIP Membership',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Tier Badge Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentLvl['emoji'] as String,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentLvl['name'] as String,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Middle Row: Points Balance + Large Watermark Icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$currentPoints',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      letterSpacing: -1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PTS',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cheer Points Available',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Simulated Metallic SIM Chip Icon + Watermark
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 32,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1C40F).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.yellow.shade200, width: 1),
                                ),
                                child: CustomPaint(
                                  painter: ChipLinesPainter(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Bottom Section: Progress Bar & Cardholder Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sleek Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white.withOpacity(0.25),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (nextLvl != null)
                                  Text(
                                    '$pointsToNext pts to ${nextLvl['emoji']} ${nextLvl['name']} Tier',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  )
                                else
                                  Text(
                                    '🏆 Ultimate Plantora Tier Reached',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Cardholder Name
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CARD HOLDER',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                userName.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Metallic Chip graphic
class ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade800.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

