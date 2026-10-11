import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../screens/chat_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Unread', 'Orders', 'Promos', 'Care Tips'];

  List<AppNotification> _getFilteredNotifications(List<AppNotification> all) {
    if (_selectedFilter == 'Unread') {
      return all.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'Orders') {
      return all.where((n) => n.type == 'order').toList();
    } else if (_selectedFilter == 'Promos') {
      return all.where((n) => n.type == 'promo').toList();
    } else if (_selectedFilter == 'Care Tips') {
      return all.where((n) => n.type == 'care').toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final loc = context.watch<LocalizationProvider>();
    
    final allNotifications = notificationProvider.notifications;
    final unreadCount = notificationProvider.unreadCount;
    final filtered = _getFilteredNotifications(allNotifications);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      appBar: PremiumAppBar(
        title: loc.translate('notifications'),
        subtitle: unreadCount > 0 ? '$unreadCount ${loc.translate('unread_alerts')}' : loc.translate('all_caught_up'),
        showMenuButton: true,
        actions: [
          // Refresh button
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
              onPressed: () => context.read<NotificationProvider>().fetchNotifications(),
            ),
          ),
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399).withOpacity(0.18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () {
                  context.read<NotificationProvider>().markAllAsRead();
                },
                icon: const Icon(Icons.done_all_rounded, color: Color(0xFF34D399), size: 16),
                label: Text(
                  loc.translate('mark_all_read'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    int count = 0;
                    if (filter == 'All') {
                      count = allNotifications.length;
                    } else if (filter == 'Unread') {
                      count = unreadCount;
                    } else if (filter == 'Orders') {
                      count = allNotifications.where((n) => n.type == 'order').length;
                    } else if (filter == 'Promos') {
                      count = allNotifications.where((n) => n.type == 'promo').length;
                    } else if (filter == 'Care Tips') {
                      count = allNotifications.where((n) => n.type == 'care').length;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF065F46), Color(0xFF10B981)],
                                  )
                                : null,
                            color: isSelected ? null : context.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF34D399)
                                  : context.border.withOpacity(0.6),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text(
                                loc.translate(filter.toLowerCase()),
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : context.textPrimary,
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.25)
                                        : (filter == 'Unread' && count > 0
                                            ? const Color(0xFFEF4444)
                                            : context.textSecondary.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (filter == 'Unread' && count > 0
                                              ? Colors.white
                                              : context.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Notifications List
            Expanded(
              child: notificationProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : filtered.isEmpty
                      ? _buildEmptyState(context)
                      : RefreshIndicator(
                          color: const Color(0xFF10B981),
                          onRefresh: () => context.read<NotificationProvider>().fetchNotifications(),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final notification = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildNotificationCard(context, notification)
                                    .animate()
                                    .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
                                    .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF044E39).withOpacity(0.2),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF34D399).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Color(0xFF34D399),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.95, end: 1.05, duration: 2.seconds),
          const SizedBox(height: 20),
          Text(
            loc.translate('all_caught_up'),
            style: GoogleFonts.outfit(
              color: context.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              loc.translate('no_notifications'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: context.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final meta = _getCategoryMeta(notification.type);

    return GestureDetector(
      onTap: () {
        context.read<NotificationProvider>().markAsRead(notification);
        if (notification.type == 'chat' && notification.data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatId: notification.data!['chatId'],
                otherParticipantName: notification.data!['senderName'] ?? 'Customer',
              ),
            ),
          );
        } else if (notification.type == 'order') {
          Navigator.pushNamed(context, '/orders');
        } else if (notification.type == 'promo') {
          Navigator.pushNamed(context, '/loyalty');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: notification.isRead
              ? context.cardBg
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF042B20)
                  : const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? context.border
                : const Color(0xFF34D399).withOpacity(0.4),
            width: notification.isRead ? 0.8 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Small icon badge
            Container(
              width: 36,
              height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: meta.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta.icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),

                // Content Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: timestamp + close
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(notification.timestamp),
                      style: GoogleFonts.inter(
                        color: context.textSecondary.withOpacity(0.7),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        context.read<NotificationProvider>().removeNotification(notification);
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: context.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }

  _CategoryMeta _getCategoryMeta(String? type) {
    switch (type) {
      case 'order':
        return _CategoryMeta(
          categoryLabel: 'ORDER UPDATE',
          icon: Icons.local_shipping_rounded,
          gradientColors: [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
          badgeBgColor: const Color(0xFFE0F2FE),
          badgeTextColor: const Color(0xFF0369A1),
          actionLabel: 'Track Delivery',
        );
      case 'promo':
        return _CategoryMeta(
          categoryLabel: 'SPECIAL OFFER',
          icon: Icons.local_offer_rounded,
          gradientColors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
          badgeBgColor: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFB45309),
          actionLabel: 'Claim Reward',
        );
      case 'care':
        return _CategoryMeta(
          categoryLabel: 'PLANT CARE',
          icon: Icons.eco_rounded,
          gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
          badgeBgColor: const Color(0xFFD1FAE5),
          badgeTextColor: const Color(0xFF047857),
          actionLabel: 'View Care Guide',
        );
      case 'chat':
        return _CategoryMeta(
          categoryLabel: 'DIRECT MESSAGE',
          icon: Icons.forum_rounded,
          gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
          badgeBgColor: const Color(0xFFEDE9FE),
          badgeTextColor: const Color(0xFF6D28D9),
          actionLabel: 'Open Chat',
        );
      default:
        return _CategoryMeta(
          categoryLabel: 'SYSTEM ALERT',
          icon: Icons.notifications_active_rounded,
          gradientColors: [const Color(0xFF044E39), const Color(0xFF065F46)],
          badgeBgColor: const Color(0xFFE6F4EA),
          badgeTextColor: const Color(0xFF044E39),
          actionLabel: null,
        );
    }
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localTime);
    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      final hour12 = localTime.hour == 0 ? 12 : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
      final ampm = localTime.hour >= 12 ? 'PM' : 'AM';
      final min = localTime.minute.toString().padLeft(2, '0');
      return '${localTime.day}/${localTime.month} $hour12:$min $ampm';
    }
  }
}

class _CategoryMeta {
  final String categoryLabel;
  final IconData icon;
  final List<Color> gradientColors;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String? actionLabel;

  _CategoryMeta({
    required this.categoryLabel,
    required this.icon,
    required this.gradientColors,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.actionLabel,
  });
}
