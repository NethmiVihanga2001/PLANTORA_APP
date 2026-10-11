import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../config/app_config.dart';
import '../../../widgets/product_image.dart';

import 'dart:async';
import '../../../services/socket_service.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../chat_detail_screen.dart';
import '../driver_chat_screen.dart';

class SellerOrdersView extends StatefulWidget {
  final VoidCallback onMenuTap;
  const SellerOrdersView({super.key, required this.onMenuTap});

  @override
  State<SellerOrdersView> createState() => _SellerOrdersViewState();
}

class _SellerOrdersViewState extends State<SellerOrdersView>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  UserModel? _currentUser;
  late AnimationController _pulseController;
  StreamSubscription? _socketSub;
  StreamSubscription? _notifSub;

  final List<String> _filters = ['All', 'Pending', 'Preparing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _socketSub = SocketService().orderStatusStream.listen((data) {
      if (mounted) {
        final deletedId = data['orderId'];
        if (data['status'] == 'Deleted' && deletedId != null) {
          setState(() {
            _orders.removeWhere((o) => o.id == deletedId);
          });
        } else {
          _loadOrders();
        }
      }
    });

    _notifSub = SocketService().notificationStream.listen((data) {
      if (mounted) _loadOrders();
    });

    AuthService().getCurrentUser().then((u) {
      if (mounted) setState(() => _currentUser = u);
    });

    _loadOrders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _socketSub?.cancel();
    _notifSub?.cancel();
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }


  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final fetched = await _orderService.getOrders();

    if (mounted) {
      setState(() {
        _orders = fetched;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status);
      }
    });

    final success = await _orderService.updateOrderStatus(orderId, status);
    if (status == 'Shipped') {
      await _orderService.ringForDelivery(orderId, 500.0);
      SocketService().ringForDelivery(orderId, 500.0);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Order status updated to "$status"'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Failed to update order status. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((o) => o.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader(context)),
        ],
        body: RefreshIndicator(
          onRefresh: _loadOrders,
          color: const Color(0xFF10B981),
          backgroundColor: Theme.of(context).cardColor,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : _filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return Dismissible(
                          key: Key('order_hist_${order.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Clear History',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                          onDismissed: (direction) async {
                            final removedOrder = order;
                            final originalIndex = _orders.indexOf(order);
                            setState(() {
                              _orders.removeAt(originalIndex);
                            });

                            await _orderService.deleteOrder(removedOrder.id);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Cleared ${removedOrder.id} from history',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: const Color(0xFF34D399),
                                  onPressed: () async {
                                    setState(() {
                                      _orders.insert(originalIndex, removedOrder);
                                    });
                                    await _orderService.restoreOrder(removedOrder.id);
                                  },
                                ),
                                backgroundColor: const Color(0xFF111827),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          },
                          child: _buildOrderCard(order, index),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PremiumAppBar.buildEmblemButton(
                    icon: Icons.menu_rounded,
                    onTap: widget.onMenuTap,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orders',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
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
                          Text(
                            'Manage & Fulfill Customer Orders',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA7F3D0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              PremiumAppBar.buildEmblemButton(
                icon: Icons.refresh_rounded,
                onTap: _loadOrders,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                final count = filter == 'All'
                    ? _orders.length
                    : _orders.where((o) => o.status == filter).length;

                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF34D399) : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF34D399) : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filter,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlantImageUrl(String title, String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      if (imageUrl.startsWith('/uploads')) {
        return '${AppConfig.baseUrl}$imageUrl';
      }
      return imageUrl;
    }

    final t = title.trim().toLowerCase();
    if (t.contains('karapincha') || t.contains('curry')) {
      return 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('kumarika') || t.contains('aloe')) {
      return 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('kohomba') || t.contains('neem')) {
      return 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('monstera')) {
      return 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('lavender')) {
      return 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('rosemary')) {
      return 'https://images.unsplash.com/photo-1515542706656-c30e16a65529?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('mint')) {
      return 'https://images.unsplash.com/photo-1628556270448-4d4e4148e1b1?auto=format&fit=crop&w=400&q=80';
    } else if (t.contains('snake') || t.contains('sansevieria')) {
      return 'https://images.unsplash.com/photo-1593482892290-f54927ae1bf6?auto=format&fit=crop&w=400&q=80';
    }
    return 'https://images.unsplash.com/photo-1545241047-6083a3684587?auto=format&fit=crop&w=400&q=80';
  }

  Widget _buildPlantImage(String title, String? imageUrl, {double size = 38}) {
    return ProductImage(
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : _getPlantImageUrl(title, imageUrl),
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(10),
    );
  }

  String _getCustomerAvatarUrl(String customerName, String? avatar) {
    if (avatar != null && avatar.trim().isNotEmpty && avatar != 'null' && !avatar.contains('unsplash.com')) {
      if (avatar.startsWith('http://') || avatar.startsWith('https://') || avatar.startsWith('data:image')) return avatar;
      if (avatar.startsWith('/uploads') || avatar.startsWith('/avatars')) return '${AppConfig.baseUrl}$avatar';
      return avatar;
    }
    return '';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour12 = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour12:$min $ampm';
  }

  Widget _buildCustomerAvatar(OrderModel order) {
    final statusColor = order.orderStatus.color;
    final avatar = order.customerAvatar;
    final initial = order.customerName.trim().isNotEmpty
        ? order.customerName.trim()[0].toUpperCase()
        : 'C';

    final bool hasCustomPhoto = avatar != null &&
        avatar.trim().isNotEmpty &&
        avatar != 'null' &&
        !avatar.contains('unsplash.com');

    String? photoUrl;
    if (hasCustomPhoto) {
      if (avatar.startsWith('http://') || avatar.startsWith('https://') || avatar.startsWith('data:image')) {
        photoUrl = avatar;
      } else if (avatar.startsWith('/uploads') || avatar.startsWith('/avatars')) {
        photoUrl = '${AppConfig.baseUrl}$avatar';
      }
    }

    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF10B981), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitialBadge(initial),
                  )
                : _buildInitialBadge(initial),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialBadge(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, int index) {
    final statusColor = order.orderStatus.color;
    final isUrgent = order.status == 'Pending';
    final isCancelled = order.status == 'Cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUrgent
              ? Colors.orange.withOpacity(0.4)
              : (isCancelled ? Colors.redAccent.withOpacity(0.3) : context.border),
          width: isUrgent ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: _buildCustomerAvatar(order),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: GoogleFonts.outfit(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.inter(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF10B981),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      ' • ${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 10, color: context.textSecondary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      _formatDate(order.createdAt),
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              order.status,
              style: GoogleFonts.inter(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          iconColor: context.textPrimary,
          collapsedIconColor: context.textPrimary,
          children: [
            const Divider(height: 16),
            // Order items
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _buildPlantImage(item.title, item.imageUrl, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.title} × ${item.quantity}',
                      style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),

            // Shipping Address & Phone
            if (order.shippingAddress.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.shippingAddress,
                            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (order.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          Text(
                            order.phone,
                            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Live Chat Action Buttons (Customer <-> Seller / Seller <-> Rider)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFF10B981),
                      elevation: 0,
                      side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(
                      'Chat Customer',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final myId = _currentUser?.id ?? 'seller';
                      final myName = _currentUser?.name ?? 'Seller';
                      final myAvatar = _currentUser?.avatarUrl;
                      final targetName = order.customerName.isNotEmpty ? order.customerName : 'Customer';
                      final targetId = order.customerId.isNotEmpty ? order.customerId : 'customer';

                      final chatData = await ChatService().initiateChat(
                        targetId,
                        myId,
                        targetName,
                        myName,
                        myAvatar,
                      );
                      if (context.mounted) {
                        final chatId = (chatData?['chatId'] ?? chatData?['id'] ?? 'chat_${targetId}_$myId').toString();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chatId,
                              otherParticipantName: targetName,
                              otherParticipantRole: 'Customer',
                              plantTitle: order.items.isNotEmpty ? order.items.first.title : 'Order #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                              plantPrice: order.totalAmount.toStringAsFixed(0),
                              plantImageUrl: order.items.isNotEmpty ? order.items.first.imageUrl : null,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                if (order.driverName != null || order.driverId != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.12),
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                      label: Text(
                        'Chat Rider',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverChatScreen(order: order),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Status dropdown update row
            Row(
              children: [
                Text(
                  'Change Status:',
                  style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: order.status,
                        dropdownColor: context.cardBg,
                        style: GoogleFonts.inter(color: context.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF10B981), size: 20),
                        items: ['Pending', 'Accepted', 'Preparing', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, style: GoogleFonts.inter(fontSize: 12.5)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null && val != order.status) {
                            _updateStatus(order.id, val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (order.status == 'Pending' || order.status == 'Accepted' || order.status == 'Preparing') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                  label: Text(
                    'Ring Nearby Drivers for Delivery',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    await _orderService.ringForDelivery(order.id, 500.0);
                    SocketService().ringForDelivery(order.id, 500.0);
                    _loadOrders();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(child: Text('🚨 Ring dispatched to all nearby drivers!')),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate()
     .fadeIn(delay: Duration(milliseconds: 80 + index * 60), duration: 350.ms)
     .slideY(begin: 0.06);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Colors.orange.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Orders Found',
            style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Your store hasn\'t received any orders yet.'
                : 'No $_selectedFilter orders right now.',
            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
