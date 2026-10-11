import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';

class AppOverlay {
  static final GlobalKey<NotificationOverlayState> overlayKey = GlobalKey<NotificationOverlayState>();
  static void show(AppNotification notif) {
    overlayKey.currentState?.show(notif);
  }
}

/// Wraps any child widget and shows a slide-down banner whenever
/// NotificationProvider fires [onInAppNotification].
class NotificationOverlay extends StatefulWidget {
  final Widget child;
  const NotificationOverlay({super.key, required this.child});

  @override
  State<NotificationOverlay> createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  AppNotification? _current;
  Timer? _dismissTimer;
  final List<AppNotification> _queue = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.findAncestorWidgetOfExactType<_ProviderAccessor>();
    if (provider != null) return;
  }

  void show(AppNotification notif) {
    _queue.add(notif);
    if (_current == null) _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    setState(() => _current = _queue.removeAt(0));
    _controller.forward(from: 0);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() => _current = null);
        if (_queue.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 150), _showNext);
        }
      }
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'delivery':
        return Icons.two_wheeler_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'care':
        return Icons.eco_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF10B981);
      case 'delivery':
        return const Color(0xFFF59E0B);
      case 'chat':
        return const Color(0xFF6366F1);
      case 'promo':
        return const Color(0xFFF59E0B);
      case 'care':
        return const Color(0xFF34D399);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _BannerCard(
                  notification: _current!,
                  accent: _colorFor(_current!.type),
                  icon: _iconFor(_current!.type),
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProviderAccessor extends InheritedWidget {
  const _ProviderAccessor({required super.child});
  @override
  bool updateShouldNotify(_ProviderAccessor old) => false;
}

class _BannerCard extends StatelessWidget {
  final AppNotification notification;
  final Color accent;
  final IconData icon;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.notification,
    required this.accent,
    required this.icon,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 14,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF1A2330) : Colors.white,
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
