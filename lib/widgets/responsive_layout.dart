import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Responsive {
  static const double _mobileMax = 768;
  static const double _tabletMax = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= _mobileMax && w < _tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tabletMax;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mobileMax;

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1400) return 4;
    if (w >= _tabletMax) return 3;
    if (w >= _mobileMax) return 2;
    return 2;
  }

  static int productGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1400) return 5;
    if (w >= _tabletMax) return 4;
    if (w >= _mobileMax) return 3;
    return 2;
  }

  static double maxContentWidth = 1200;

  static Widget centered({required Widget child, double maxWidth = 1200}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Wraps form screens (Edit Profile, Settings, etc.) in a styled, centered card on Desktop/Tablet
  /// while keeping clean edge-to-edge padding on mobile.
  static Widget formContainer({
    required BuildContext context,
    required Widget child,
    double maxWidth = 760,
    EdgeInsets? padding,
  }) {
    final isDesktop = !Responsive.isMobile(context);
    if (!isDesktop) {
      return Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: child,
      );
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        padding: padding ?? const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF10B981).withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.35 : 0.06),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  /// Two-column layout on Desktop/Tablet, single column on Mobile
  static Widget twoColumn({
    required BuildContext context,
    required Widget left,
    required Widget right,
    int flexLeft = 3,
    int flexRight = 2,
    double spacing = 28,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    final isDesktop = Responsive.isDesktop(context) || MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(flex: flexLeft, child: left),
          SizedBox(width: spacing),
          Expanded(flex: flexRight, child: right),
        ],
      );
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        left,
        SizedBox(height: spacing),
        right,
      ],
    );
  }
}
