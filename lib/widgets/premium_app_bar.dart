import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive_layout.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottom;
  final PreferredSizeWidget? bottomWidget;
  final double height;
  final bool showBackButton;
  final bool showMenuButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;

  const PremiumAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottom,
    this.bottomWidget,
    this.height = 72.0,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.onBackPressed,
    this.onMenuPressed,
  }) : assert(title != null || titleWidget != null, 'Must provide either title or titleWidget');

  @override
  Size get preferredSize {
    double totalHeight = height;
    if (bottomWidget != null) {
      totalHeight += bottomWidget!.preferredSize.height;
    } else if (bottom != null) {
      totalHeight += 48.0;
    }
    return Size.fromHeight(totalHeight);
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    return Container(
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
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height - 1.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Leading button (Glowing Badge Circle around 3-Line Menu or Back Icon)
                        if (leading != null)
                          leading!
                        else if (showMenuButton || hasDrawer)
                          Builder(
                            builder: (barCtx) => _buildEmblemButton(
                              icon: Icons.menu_rounded,
                              onTap: onMenuPressed ?? () => Scaffold.maybeOf(barCtx)?.openDrawer(),
                            ),
                          )
                        else if (showBackButton && canPop)
                          _buildEmblemButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                          )
                        else
                          const SizedBox(width: 4),

                        const SizedBox(width: 12),

                        // Title & Subtitle with glowing mint bullet dot
                        Expanded(
                          child: titleWidget ??
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
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
                                            subtitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFFA7F3D0),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                        ),

                        // Trailing Actions
                        if (actions != null) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (bottomWidget != null) bottomWidget!
                else if (bottom != null) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildEmblemButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildEmblemButton({required IconData icon, required VoidCallback onTap}) {
    return buildEmblemButton(icon: icon, onTap: onTap);
  }
}

