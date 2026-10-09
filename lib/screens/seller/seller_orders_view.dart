import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';
import '../../../widgets/premium_app_bar.dart';

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
  late AnimationController _pulseController;

  final List<String> _filters = ['All', 'Pending', 'Preparing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadOrders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<OrderModel> _getSampleOrders() {
    return [
      OrderModel(
        id: 'ORD-2026-9481',
        customerId: 'c1',
        customerName: 'Amal Perera',
        totalAmount: 5450.0,
        subtotalAmount: 4950.0,
        deliveryFee: 500.0,
        shippingAddress: 'No. 45, Flower Road, Colombo 07',
        phone: '+94 77 482 9102',
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        items: [
          OrderItem(productId: 'p1', title: 'Monstera Deliciosa (Swiss Cheese)', price: 3500.0, quantity: 1, sellerId: 's1', emoji: '🪴'),
          OrderItem(productId: 'p2', title: 'Organic Botanical Fertilizer 500g', price: 1950.0, quantity: 1, sellerId: 's1', emoji: '🌱'),
        ],
      ),
      OrderModel(
        id: 'ORD-2026-8812',
        customerId: 'c2',
        customerName: 'Dinusha Wickramasinghe',
        totalAmount: 8200.0,
        subtotalAmount: 7600.0,
        deliveryFee: 600.0,
        shippingAddress: '12/A, Kandy Road, Kiribathgoda',
        phone: '+94 71 883 2049',
        status: 'Preparing',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        items: [
          OrderItem(productId: 'p3', title: 'Fiddle Leaf Fig Tree (Ficus Lyrata)', price: 6800.0, quantity: 1, sellerId: 's1', emoji: '🌿'),
          OrderItem(productId: 'p4', title: 'Terracotta Clay Pot (Large)', price: 1400.0, quantity: 1, sellerId: 's1', emoji: '🏺'),
        ],
      ),
      OrderModel(
        id: 'ORD-2026-7530',
        customerId: 'c3',
        customerName: 'Kasun Rajapaksha',
        totalAmount: 3850.0,
        subtotalAmount: 3400.0,
        deliveryFee: 450.0,
        shippingAddress: '88, Beach Road, Mount Lavinia',
        phone: '+94 75 991 4028',
        status: 'Shipped',
        driverName: 'Kamal Silva (Rider #2)',
        driverPhone: '+94 77 882 1199',
        vehicleType: 'Motorcycle',
        vehiclePlate: 'WP BIZ-8492',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        items: [
          OrderItem(productId: 'p5', title: 'Golden Pothos Hanging Vine', price: 1450.0, quantity: 2, sellerId: 's1', emoji: '🍃'),
          OrderItem(productId: 'p6', title: 'Plant Moisture Meter Sensor', price: 950.0, quantity: 1, sellerId: 's1', emoji: '⚡'),
        ],
      ),
      OrderModel(
        id: 'ORD-2026-6194',
        customerId: 'c4',
        customerName: 'Nipuni Fernando',
        totalAmount: 4200.0,
        subtotalAmount: 3750.0,
        deliveryFee: 450.0,
        shippingAddress: '24, Galle Road, Panadura',
        phone: '+94 70 334 1180',
        status: 'Delivered',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        items: [
          OrderItem(productId: 'p7', title: 'Sansevieria Snake Plant', price: 2200.0, quantity: 1, sellerId: 's1', emoji: '🪴'),
          OrderItem(productId: 'p8', title: 'Peace Lily (Spathiphyllum)', price: 2000.0, quantity: 1, sellerId: 's1', emoji: '🌸'),
        ],
      ),
      OrderModel(
        id: 'ORD-2026-4105',
        customerId: 'c5',
        customerName: 'Nethmi Vihanga',
        totalAmount: 4105.0,
        subtotalAmount: 3705.0,
        deliveryFee: 400.0,
        shippingAddress: 'Peradeniya Road, Kandy',
        phone: '+94 77 012 4960',
        status: 'Cancelled',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          OrderItem(productId: 'p9', title: 'Variegated Monstera Albo', price: 4105.0, quantity: 1, sellerId: 's1', emoji: '✨'),
        ],
      ),
    ];
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final fetched = await _orderService.getOrders();
    final samples = _getSampleOrders();

    final List<OrderModel> combined = List.from(fetched);
    for (final s in samples) {
      if (!combined.any((o) => o.id == s.id)) {
        combined.add(s);
      }
    }

    if (mounted) {
      setState(() {
        _orders = combined;
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

    await _orderService.updateOrderStatus(orderId, status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
                          onDismissed: (direction) {
                            final removedOrder = order;
                            final originalIndex = _orders.indexOf(order);
                            setState(() {
                              _orders.removeAt(originalIndex);
                            });

                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
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
                                  onPressed: () {
                                    setState(() {
                                      _orders.insert(originalIndex, removedOrder);
                                    });
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
          tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Icon(order.orderStatus.icon, color: statusColor, size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName,
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.inter(color: Colors.orange, fontSize: 9.5, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '  •  ${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 16))),
                  ),
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
