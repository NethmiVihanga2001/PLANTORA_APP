import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/product_image.dart';
import '../widgets/app_drawer.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_invoice_service.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'order_tracking_screen.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'driver_chat_screen.dart';

import 'dart:async';
import '../services/socket_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  StreamSubscription? _socketSub;
  
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _socketSub = SocketService().orderStatusStream.listen((data) {
      if (mounted) {
        final deletedId = data['orderId'];
        if (data['status'] == 'Deleted' && deletedId != null) {
          setState(() {
            _orders.removeWhere((o) => o.id == deletedId);
          });
        } else {
          _loadData();
        }
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socketSub?.cancel();
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = await _authService.getCurrentUser();
    _orders = await _orderService.getOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      appBar: PremiumAppBar(
        title: loc.translate('my_orders'),
        subtitle: loc.translate('track_order'),
        bottomWidget: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: loc.translate('active_orders')),
            Tab(text: loc.translate('order_history')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(active: true),
                _buildOrderList(active: false),
              ],
            ),
    );
  }

  Widget _buildOrderList({required bool active}) {
    final loc = context.watch<LocalizationProvider>();
    final filtered = _orders.where((o) {
      final isDone = o.status == 'Delivered' || o.status == 'Cancelled';
      return active ? !isDone : isDone;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? Icons.local_shipping_outlined : Icons.history_rounded,
                size: 48,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              active ? loc.translate('no_active_orders') : loc.translate('no_order_history'),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              active ? loc.translate('ongoing_deliveries_desc') : loc.translate('past_purchases_desc'),
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: filtered.map((order) {
              if (active) {
                return _buildOrderCard(order);
              }
              // Swipe left to delete order history record
              return Dismissible(
                key: Key(order.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: context.cardBg,
                      title: Row(
                        children: [
                          const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 8),
                          Text(loc.translate('delete_order'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary)),
                        ],
                      ),
                      content: Text(
                        '${loc.translate('delete_order_confirm')} (#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()})',
                        style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(loc.translate('cancel'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textSecondary)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(loc.translate('delete'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (direction) async {
                  final deletedId = order.id;
                  final originalIndex = _orders.indexOf(order);
                  final removedOrder = order;
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _orders.removeWhere((o) => o.id == deletedId);
                  });
                  await _orderService.deleteOrder(deletedId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 2),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(loc.translate('order_deleted'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        action: SnackBarAction(
                          label: loc.translate('undo'),
                          textColor: const Color(0xFF34D399),
                          onPressed: () async {
                            setState(() {
                              _orders.insert(originalIndex, removedOrder);
                            });
                            await _orderService.restoreOrder(deletedId);
                          },
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        loc.translate('swipe_to_delete'),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                ),
                child: _buildOrderCard(order),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final loc = context.watch<LocalizationProvider>();
    final status = order.orderStatus;
    final isSeller = _currentUser?.role == 'Seller';
    final customerName = _currentUser?.name ?? 'Valued Customer';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Container with 2-row clean layout (Zero Overflow)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Order ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${loc.translate('order')} #${order.id.length > 12 ? order.id.substring(0, 12).toUpperCase() : order.id.toUpperCase()}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16.5, color: context.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: status.color.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, color: status.color, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            loc.translate(status.name.toLowerCase()).toUpperCase(),
                            style: GoogleFonts.inter(color: status.color, fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2: Date/Time + ONLINE PAID Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt.toLocal()),
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.translate('online_paid'),
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items Summary Container with Enlarged Plant Photos & Full Width Spacing
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border.withValues(alpha: 0.8)),
                  ),
                  child: Column(
                    children: order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildItemImage(item),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Rs. ${item.price.toStringAsFixed(2)} per unit',
                                  style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.border),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 14),
                
                // Total Amount Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.translate('total_amount_paid'), style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 1, color: context.border),
                ),
                
                // Address Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.shippingAddress.isNotEmpty ? order.shippingAddress : 'Colombo, Sri Lanka',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),

                if (isSeller && order.status != 'Delivered' && order.status != 'Cancelled') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(order.id, 'Cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(loc.translate('reject'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showStatusPicker(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(loc.translate('update_status'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else if (!isSeller) ...[
                   const SizedBox(height: 16),
                   _buildProgressTracker(order.status),
                   const SizedBox(height: 18),
                   
                   // Action Buttons (Balanced & Fitted, Never Truncates)
                   Column(
                     children: [
                       Row(
                         children: [
                           // Download PDF Receipt Slip Button
                           Expanded(
                             child: OutlinedButton.icon(
                               onPressed: () => PdfInvoiceService.generateAndDownloadInvoice(
                                 order: order,
                                 customerName: customerName,
                               ),
                               icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 16),
                               label: FittedBox(
                                 fit: BoxFit.scaleDown,
                                 child: Text(
                                   loc.translate('download_slip'),
                                   style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF10B981)),
                                 ),
                               ),
                               style: OutlinedButton.styleFrom(
                                 side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                               ),
                             ),
                           ),

                           const SizedBox(width: 10),

                           // Live Tracking Button
                           Expanded(
                             child: Container(
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(14),
                                 gradient: const LinearGradient(
                                   colors: [Color(0xFF0B3A22), Color(0xFF10B981)],
                                 ),
                               ),
                               child: ElevatedButton.icon(
                                 onPressed: () => Navigator.push(
                                   context, 
                                   MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order))
                                 ),
                                 icon: const Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
                                 label: FittedBox(
                                   fit: BoxFit.scaleDown,
                                   child: Text(
                                     loc.translate('live_tracking'),
                                     style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                   ),
                                 ),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.transparent,
                                   shadowColor: Colors.transparent,
                                   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                 ),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 10),
                       Row(
                         children: [
                           // Chat Store / Nursery
                           Expanded(
                             child: OutlinedButton.icon(
                               onPressed: () async {
                                 final sellerId = order.items.isNotEmpty ? order.items.first.sellerId : 'seller';
                                 final plantTitle = order.items.isNotEmpty ? order.items.first.title : 'Order #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}';
                                 final plantImg = order.items.isNotEmpty ? order.items.first.imageUrl : null;
                                 final customerId = _currentUser?.id ?? order.customerId;
                                 final custName = _currentUser?.name ?? order.customerName;

                                 final chatData = await ChatService().initiateChat(
                                   customerId,
                                   sellerId,
                                   custName,
                                   'Green Life Nursery',
                                   null,
                                 );
                                 if (context.mounted) {
                                   final chatId = (chatData?['chatId'] ?? chatData?['id'] ?? 'chat_${customerId}_$sellerId').toString();
                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (_) => ChatDetailScreen(
                                         chatId: chatId,
                                         otherParticipantName: 'Nursery Store',
                                         otherParticipantRole: 'Seller',
                                         plantTitle: plantTitle,
                                         plantPrice: order.totalAmount.toStringAsFixed(0),
                                         plantImageUrl: plantImg,
                                       ),
                                     ),
                                   );
                                 }
                               },
                               icon: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF10B981)),
                               label: Text(
                                 'Chat Store',
                                 style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF10B981)),
                               ),
                               style: OutlinedButton.styleFrom(
                                 side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                               ),
                             ),
                           ),
                           if (order.driverName != null || order.driverId != null) ...[
                             const SizedBox(width: 10),
                             Expanded(
                               child: ElevatedButton.icon(
                                 onPressed: () {
                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(builder: (_) => DriverChatScreen(order: order)),
                                   );
                                 },
                                 icon: const Icon(Icons.delivery_dining_rounded, size: 18, color: Colors.white),
                                 label: Text(
                                   'Chat Rider',
                                   style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                                 ),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFF0284C7),
                                   foregroundColor: Colors.white,
                                   elevation: 0,
                                   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                 ),
                               ),
                             ),
                           ],
                         ],
                       ),
                       if (order.status == 'Pending') ...[
                         const SizedBox(height: 10),
                         SizedBox(
                           width: double.infinity,
                           child: OutlinedButton(
                             onPressed: () => _confirmCancelOrder(order),
                             style: OutlinedButton.styleFrom(
                               foregroundColor: Colors.redAccent,
                               side: BorderSide(color: Colors.red.shade200),
                               padding: const EdgeInsets.symmetric(vertical: 11),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: Text(loc.translate('cancel_order'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
                           ),
                         ),
                       ],
                     ],
                   ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _buildItemImage(OrderItem item) {
    String? imgUrl = item.imageUrl;
    
    // Dynamic fallback plant image lookup for marketplace plant visuals if imageUrl is empty/null
    if (imgUrl == null || imgUrl.isEmpty || imgUrl == 'null') {
      final title = item.title.toLowerCase();
      if (title.contains('aloe')) {
        imgUrl = 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&w=400&q=80';
      } else if (title.contains('basil')) {
        imgUrl = 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?auto=format&fit=crop&w=400&q=80';
      } else if (title.contains('snake')) {
        imgUrl = 'https://images.unsplash.com/photo-1593482892290-f54927ae1bac?auto=format&fit=crop&w=400&q=80';
      } else if (title.contains('monstera')) {
        imgUrl = 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=400&q=80';
      } else if (title.contains('succulent') || title.contains('cactus')) {
        imgUrl = 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=400&q=80';
      } else {
        imgUrl = 'https://images.unsplash.com/photo-1545241047-6083a3684587?auto=format&fit=crop&w=400&q=80';
      }
    } else if (imgUrl.startsWith('/')) {
      imgUrl = '${AppConfig.baseUrl}$imgUrl';
    }

    return ProductImage(
      imageUrl: imgUrl,
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(14),
    );
  }

  Widget _buildFallbackPlantIcon(OrderItem item) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.18),
            const Color(0xFF047857).withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Text(
        item.emoji.isNotEmpty ? item.emoji : '🌿',
        style: const TextStyle(fontSize: 26),
      ),
    );
  }

  Widget _buildProgressTracker(String currentStatus) {
    final loc = context.watch<LocalizationProvider>();
    final stages = ['Pending', 'Accepted', 'Preparing', 'Shipped', 'Delivered'];
    final currentIndex = stages.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('delivery_progress'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: context.textPrimary)),
              Text(
                loc.translate(currentStatus.toLowerCase()),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(stages.length, (index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == stages.length - 1;
              
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: isCurrent ? Border.all(color: const Color(0xFFA7F3D0), width: 3) : null,
                        boxShadow: isCompleted ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.35), blurRadius: 6)] : null,
                      ),
                      child: isCompleted 
                        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                        : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index < currentIndex ? const Color(0xFF10B981) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('placed'), style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.textSecondary)),
              Text(loc.translate('delivered'), style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(OrderModel order) {
    final loc = context.read<LocalizationProvider>();
    final statuses = ['Pending', 'Accepted', 'Preparing', 'Shipped', 'Delivered'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.translate('update_status'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...statuses.map((s) => ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(
                _getStatusIcon(s),
                color: s == order.status ? const Color(0xFF10B981) : AppColors.grey,
              ),
              title: Text(loc.translate(s.toLowerCase()), style: GoogleFonts.inter(
                fontWeight: s == order.status ? FontWeight.bold : FontWeight.normal,
                color: s == order.status ? const Color(0xFF10B981) : context.textPrimary,
              )),
              trailing: s == order.status ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)) : null,
              onTap: () {
                Navigator.pop(context);
                _updateStatus(order.id, s);
              },
            )),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Accepted': return Icons.check_circle_outline_rounded;
      case 'Preparing': return Icons.inventory_2_outlined;
      case 'Shipped': return Icons.local_shipping_outlined;
      case 'Delivered': return Icons.done_all_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  void _confirmCancelOrder(OrderModel order) {
    final loc = context.read<LocalizationProvider>();
    if (order.status != 'Pending') {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('${loc.translate('order')} ${order.id} ${loc.translate(order.status.toLowerCase())}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              loc.translate('cancel_order_dialog_title'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.translate('cancel_order_dialog_title')} (#$shortId)',
              style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('cancel_order_fee_note'),
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('keep_order'), style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(order.id, 'Cancelled');
            },
            child: Text(loc.translate('confirm_cancel'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String orderId, String status) async {
    final success = await _orderService.updateOrderStatus(orderId, status);
    if (success) {
      if (status == 'Cancelled' && _currentUser?.role == 'Customer') {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.addCancellationPenalty(200.0);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Order status updated to $status', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Could not update order status. Please try again.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

