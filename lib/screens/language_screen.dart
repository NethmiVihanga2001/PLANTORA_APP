import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/premium_app_bar.dart';
import '../theme/app_theme.dart';
import '../providers/localization_provider.dart';
import '../providers/auth_provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<Map<String, String>> _languages = [
    {
      'flag': '🇬🇧',
      'name': 'English',
      'native': 'English',
      'region': 'Default',
      'code': 'en',
    },
    {
      'flag': '🇱🇰',
      'name': 'Sinhala',
      'native': 'සිංහල',
      'region': 'ශ්‍රී ලංකාව',
      'code': 'si',
    },
    {
      'flag': '🇱🇰',
      'name': 'Tamil',
      'native': 'தமிழ்',
      'region': 'இலங்கை',
      'code': 'ta',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    final currentCode = loc.locale.languageCode;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: PremiumAppBar(
        title: loc.translate('language_options'),
        subtitle: loc.translate('select_preferred_language'),
        showMenuButton: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title Header (No logo emblem as requested)
                  Text(
                    loc.translate('choose_language'),
                    style: GoogleFonts.outfit(
                      color: context.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 6),

                  Text(
                    loc.translate('select_preferred_language'),
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 28),

                  // Language Option Tiles Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(_languages.length, (i) {
                        final lang = _languages[i];
                        final isSelected = currentCode == lang['code'];

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await loc.setLocale(Locale(lang['code']!));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          loc.translate('language_updated'),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.only(bottom: i == _languages.length - 1 ? 0 : 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : context.scaffoldBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : context.border,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                // Flag emoji box
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Text(
                                    lang['flag']!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Name & Native script
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            lang['name']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? const Color(0xFF10B981)
                                                  : context.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                                  : context.textPrimary.withValues(alpha: 0.06),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              lang['region']!,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? const Color(0xFF10B981) : context.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        lang['native']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF10B981).withValues(alpha: 0.85)
                                              : context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Custom Checkmark Radio Icon
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ).animate().slideX(
                              begin: 0.08,
                              end: 0,
                              delay: Duration(milliseconds: 60 * i + 100),
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                            );
                      }),
                    ),
                  ).animate().slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 28),

                  // Continue / Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF047857), Color(0xFF10B981)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            final role = context.read<AuthProvider>().user?.role;
                            if (role == 'Driver') {
                              Navigator.pushReplacementNamed(context, '/driver-dashboard');
                            } else if (role == 'Seller') {
                              Navigator.pushReplacementNamed(context, '/seller-dashboard');
                            } else {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          loc.translate('continue_button'),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}