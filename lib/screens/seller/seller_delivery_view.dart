import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/order_model.dart';
import '../../../services/order_service.dart';
import '../../../services/delivery_service.dart';
import '../../../services/finance_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_app_bar.dart';
import 'package:provider/provider.dart';

class _LiveRider {
  final String id;
  final String name;
  final String phone;
  final String vehiclePlate;
  final String vehicleType;
  final double rating;
  final LatLng position;
  final double distanceKm;
  final bool isAvailable;
  final int completedToday;

  const _LiveRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.rating,
    required this.position,
    required this.distanceKm,
    required this.isAvailable,
    required this.completedToday,
  });
}

// Plantora Store HQ Location (Colombo 07, Cinnamon Gardens)
const _storeLocation = LatLng(6.9147, 79.8530);

// Customer sample locations in Colombo
const Map<String, LatLng> _customerLocations = {
  'ORD-2026-9481': LatLng(6.9080, 79.8580), // Flower Road
  'ORD-2026-8812': LatLng(6.9350, 79.8700), // Kandy Road
  'ORD-2026-7530': LatLng(6.8380, 79.8650), // Mount Lavinia Beach Rd
};

final List<_LiveRider> _initialRiders = [
  const _LiveRider(
    id: 'd1',
    name: 'Nimal Perera',
    phone: '+94 77 410 9921',
    vehiclePlate: 'WP CAB-1122',
    vehicleType: 'Motorcycle (Honda CD110)',
    rating: 4.9,
    position: LatLng(6.9205, 79.8495),
    distanceKm: 0.8,
    isAvailable: true,
    completedToday: 9,
  ),
  const _LiveRider(
    id: 'd2',
    name: 'Kamal Silva',
    phone: '+94 77 882 1199',
    vehiclePlate: 'WP BIZ-8492',
    vehicleType: 'Motorcycle (Bajaj Pulsar)',
    rating: 4.8,
    position: LatLng(6.9090, 79.8560),
    distanceKm: 0.4,
    isAvailable: true,
    completedToday: 14,
  ),
  const _LiveRider(
    id: 'd3',
    name: 'Sahan Kumara',
    phone: '+94 71 550 4432',
    vehiclePlate: 'WP DMS-3301',
    vehicleType: 'Motorcycle (TVS Raider)',
    rating: 4.7,
    position: LatLng(6.9160, 79.8450),
    distanceKm: 1.1,
    isAvailable: false,
    completedToday: 11,
  ),
  const _LiveRider(
    id: 'd4',
    name: 'Ruvini Fernando',
    phone: '+94 76 990 1284',
    vehiclePlate: 'WP GAB-7741',
    vehicleType: 'Scooter (Yamaha RayZR)',
    rating: 5.0,
    position: LatLng(6.9250, 79.8580),
    distanceKm: 1.5,
    isAvailable: true,
    completedToday: 8,
  ),
];

class _BroadcastState {
  final String orderId;
  DateTime broadcastAt;
  Timer? countdownTimer;
  Timer? autoAcceptTimer;
  int secondsRemaining; // 3600 seconds = 1 hour
  bool needsRebroadcast;
  bool isSearching;

  _BroadcastState({
    required this.orderId,
    required this.broadcastAt,
    this.secondsRemaining = 3600,
    this.needsRebroadcast = false,
    this.isSearching = true,
  });
}

class SellerDeliveryView extends StatefulWidget {
  final VoidCallback onMenuTap;
  const SellerDeliveryView({super.key, required this.onMenuTap});

  @override
  State<SellerDeliveryView> createState() => _SellerDeliveryViewState();
}

class _SellerDeliveryViewState extends State<SellerDeliveryView>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final DeliveryService _deliveryService = DeliveryService();
  final MapController _mapController = MapController();

  List<OrderModel> _readyOrders = [];
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _deliveredOrders = [];
  bool _isLoading = true;

  // Real Google Maps Layer Style: 'm' = Standard Road, 'y' = Hybrid Satellite, 'p' = Terrain
  String _mapLayerStyle = 'm';
  bool _isMapExpanded = false;

  late AnimationController _pulseController;
  final Map<String, _BroadcastState> _broadcastStates = {};
  List<_LiveRider> _riders = List.from(_initialRiders);
  // Tracks which orders have already had delivery charge transferred
  final Set<String> _transferredOrders = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final s in _broadcastStates.values) {
      s.countdownTimer?.cancel();
      s.autoAcceptTimer?.cancel();
    }
    super.dispose();
  }

  List<OrderModel> _getSampleOrders() => [
    OrderModel(
      id: 'ORD-2026-9481',
      customerId: 'c1',
      customerName: 'Amal Perera',
      totalAmount: 5450.0,
      subtotalAmount: 4950.0,
      deliveryFee: 500.0,
      shippingAddress: 'No. 45, Flower Road, Colombo 07',
      phone: '+94 77 482 9102',
      status: 'Preparing',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      items: [
        OrderItem(productId: 'p1', title: 'Monstera Deliciosa', price: 3500.0, quantity: 1, sellerId: 's1', emoji: '🪴', imageUrl: 'https://images.unsplash.com/photo-1614594975525-e45190c55d40?w=100'),
        OrderItem(productId: 'p2', title: 'Organic Botanical Fertilizer', price: 1950.0, quantity: 1, sellerId: 's1', emoji: '🌱', imageUrl: 'https://images.unsplash.com/photo-1592982537447-6f296d19f074?w=100'),
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
        OrderItem(productId: 'p3', title: 'Fiddle Leaf Fig Tree', price: 6800.0, quantity: 1, sellerId: 's1', emoji: '🌿', imageUrl: 'https://images.unsplash.com/photo-1606228399580-c117eb8a892b?w=100'),
        OrderItem(productId: 'p4', title: 'Terracotta Clay Pot', price: 1400.0, quantity: 1, sellerId: 's1', emoji: '🏺', imageUrl: 'https://images.unsplash.com/photo-1456930722108-e7a9b0e271eb?w=100'),
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
      status: 'Out for Delivery',
      driverName: 'Kamal Silva',
      driverPhone: '+94 77 882 1199',
      vehicleType: 'Motorcycle',
      vehiclePlate: 'WP BIZ-8492',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      items: [
        OrderItem(productId: 'p5', title: 'Golden Pothos Hanging Vine', price: 1450.0, quantity: 2, sellerId: 's1', emoji: '🍃', imageUrl: 'https://images.unsplash.com/photo-1645802111494-b2fc45bcf6f1?w=100'),
        OrderItem(productId: 'p6', title: 'Plant Moisture Meter', price: 950.0, quantity: 1, sellerId: 's1', emoji: '⚡', imageUrl: 'https://images.unsplash.com/photo-1634626159516-79c29cc3697e?w=100'),
      ],
    ),
  ];

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final all = await _orderService.getOrders();
    final samples = _getSampleOrders();
    for (final s in samples) {
      if (!all.any((o) => o.id == s.id)) all.add(s);
    }
    _readyOrders = all.where((o) => o.status == 'Accepted' || o.status == 'Preparing').toList();
    _activeOrders = all.where((o) => o.status == 'Shipped' || o.status == 'Out for Delivery').toList();
    _deliveredOrders = all.where((o) => o.status == 'Delivered').toList();
    if (mounted) setState(() => _isLoading = false);
  }

  // 1-HOUR COUNTDOWN & BROADCAST TO RIDERS
  void _broadcastToRiders(OrderModel order, {bool isRebroadcast = false}) {
    _broadcastStates[order.id]?.countdownTimer?.cancel();
    _broadcastStates[order.id]?.autoAcceptTimer?.cancel();

    final bs = _BroadcastState(
      orderId: order.id,
      broadcastAt: DateTime.now(),
      secondsRemaining: 3600, // Exactly 1 hour
      needsRebroadcast: false,
      isSearching: true,
    );
    _broadcastStates[order.id] = bs;

    // Start 1-hour pickup window countdown
    bs.countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        bs.secondsRemaining--;
        if (bs.secondsRemaining <= 0) {
          bs.needsRebroadcast = true;
          bs.isSearching = false;
          t.cancel();
        }
      });
    });

    setState(() {});

    _showSnack(
      isRebroadcast
          ? '🔔 Re-ringing all nearby riders! 1-hour pickup timer reset.'
          : '📡 Order broadcasted to 4 nearby riders! Awaiting rider acceptance.',
      const Color(0xFF10B981),
    );

    // Show Broadcast Modal Sheet with live radar
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BroadcastWaitingSheet(
        order: order,
        ridersCount: _riders.where((r) => r.isAvailable).length,
        onRiderAccepted: (rider) async {
          Navigator.pop(ctx);
          await _onRiderAcceptedOrder(order, rider);
        },
      ),
    );
  }

  Future<void> _onRiderAcceptedOrder(OrderModel order, _LiveRider rider) async {
    final bs = _broadcastStates[order.id];
    bs?.countdownTimer?.cancel();
    bs?.autoAcceptTimer?.cancel();
    _broadcastStates.remove(order.id);

    // Update status in orderService to 'Shipped' (Rider heading to shop)
    await _orderService.updateOrderStatus(order.id, 'Shipped');
    await _deliveryService.assignDriver(order.id, rider.id);

    // Update the local list
    setState(() {
      final index = _readyOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        final removed = _readyOrders.removeAt(index);
        final updated = OrderModel(
          id: removed.id,
          customerId: removed.customerId,
          customerName: removed.customerName,
          totalAmount: removed.totalAmount,
          subtotalAmount: removed.subtotalAmount,
          deliveryFee: removed.deliveryFee,
          shippingAddress: removed.shippingAddress,
          phone: removed.phone,
          status: 'Shipped',
          driverName: rider.name,
          driverPhone: rider.phone,
          vehicleType: rider.vehicleType,
          vehiclePlate: rider.vehiclePlate,
          createdAt: removed.createdAt,
          items: removed.items,
        );
        _activeOrders.insert(0, updated);
      }
    });

    // Animate map camera towards rider
    _mapController.move(rider.position, 15.0);

    if (mounted) {
      _showSnack(
        '🏍️ ${rider.name} accepted Order #${order.id}! Heading to your store for pickup (~3 min ETA).',
        const Color(0xFF10B981),
      );
    }
  }

  // TEST HELPER: Simulate 1-hour expiration instantly
  void _simulateOneHourTimeout(String orderId) {
    final bs = _broadcastStates[orderId];
    if (bs != null) {
      bs.countdownTimer?.cancel();
      bs.autoAcceptTimer?.cancel();
      setState(() {
        bs.secondsRemaining = 0;
        bs.needsRebroadcast = true;
        bs.isSearching = false;
      });
      _showSnack(
        '⚠️ Simulated: 1 hour passed! Order not picked up by riders. Rings expired.',
        Colors.redAccent,
      );
    }
  }

  Future<void> _advanceDelivery(OrderModel order) async {
    final isShipped = order.status == 'Shipped';
    final nextStatus = isShipped ? 'Out for Delivery' : 'Delivered';

    await _orderService.updateOrderStatus(order.id, nextStatus);

    setState(() {
      final idx = _activeOrders.indexWhere((o) => o.id == order.id);
      if (idx != -1) {
        if (nextStatus == 'Delivered') {
          final done = _activeOrders.removeAt(idx);
          _deliveredOrders.insert(
            0,
            OrderModel(
              id: done.id,
              customerId: done.customerId,
              customerName: done.customerName,
              totalAmount: done.totalAmount,
              subtotalAmount: done.subtotalAmount,
              deliveryFee: done.deliveryFee,
              shippingAddress: done.shippingAddress,
              phone: done.phone,
              status: 'Delivered',
              driverName: done.driverName,
              driverPhone: done.driverPhone,
              vehicleType: done.vehicleType,
              vehiclePlate: done.vehiclePlate,
              createdAt: done.createdAt,
              items: done.items,
            ),
          );
        } else {
          final cur = _activeOrders[idx];
          _activeOrders[idx] = OrderModel(
            id: cur.id,
            customerId: cur.customerId,
            customerName: cur.customerName,
            totalAmount: cur.totalAmount,
            subtotalAmount: cur.subtotalAmount,
            deliveryFee: cur.deliveryFee,
            shippingAddress: cur.shippingAddress,
            phone: cur.phone,
            status: 'Out for Delivery',
            driverName: cur.driverName,
            driverPhone: cur.driverPhone,
            vehicleType: cur.vehicleType,
            vehiclePlate: cur.vehiclePlate,
            createdAt: cur.createdAt,
            items: cur.items,
          );
        }
      }
    });

    if (mounted) {
      _showSnack(
        nextStatus == 'Delivered'
            ? '✅ Order #${order.id} marked Delivered to customer!'
            : '📦 Package handed to ${order.driverName ?? 'rider'}! On the way to customer.',
        nextStatus == 'Delivered' ? const Color(0xFF10B981) : Colors.blueAccent,
      );
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  String _fmtCountdown(int s) {
    if (s <= 0) return '00:00';
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))));
    }

    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: _riders.isEmpty
          ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Sticky header ───────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Google Map (scrolls away when user scrolls down) ────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: screenH * 0.44,
                      child: _buildGoogleMapCard(),
                    ),
                  ),

                  // ── Stat tiles ──────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildStats()),

                  // ── Section divider ─────────────────────────────────────
                  if (_readyOrders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _sectionHeader(
                        '📦 Awaiting Rider Pickup',
                        '${_readyOrders.length} order(s) ready',
                        Colors.orange.shade700,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildReadyCard(_readyOrders[i], i),
                        childCount: _readyOrders.length,
                      ),
                    ),
                  ],

                  if (_activeOrders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _sectionHeader(
                        '🏍️ Active Deliveries',
                        '${_activeOrders.length} rider(s) on the road',
                        const Color(0xFF10B981),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildActiveCard(_activeOrders[i], i),
                        childCount: _activeOrders.length,
                      ),
                    ),
                  ],

                  if (_deliveredOrders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _sectionHeader(
                        '✅ Delivered',
                        'Recent completed deliveries',
                        const Color(0xFF10B981),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildDeliveredCard(_deliveredOrders[i], i),
                        childCount: _deliveredOrders.length,
                      ),
                    ),
                  ],

                  if (_readyOrders.isEmpty && _activeOrders.isEmpty && _deliveredOrders.isEmpty)
                    SliverFillRemaining(child: _buildEmpty()),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
    );
  }

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF012E23), Color(0xFF044E39), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                PremiumAppBar.buildEmblemButton(icon: Icons.menu_rounded, onTap: widget.onMenuTap),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Dispatch Hub',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399).withValues(
                                  alpha: 0.5 + _pulseController.value * 0.5,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Color(0xFF34D399), blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_riders.where((r) => r.isAvailable).length} Riders Online • Google Maps Live',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFA7F3D0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PremiumAppBar.buildEmblemButton(icon: Icons.refresh_rounded, onTap: _loadData),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final availableCount = _riders.where((r) => r.isAvailable).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          _statTile('${_readyOrders.length}', 'Awaiting Rider', Icons.pending_actions_rounded, Colors.orange, 0),
          const SizedBox(width: 10),
          _statTile('${_activeOrders.length}', 'On the Road', Icons.two_wheeler_rounded, const Color(0xFF10B981), 1),
          const SizedBox(width: 10),
          _statTile('$availableCount', 'Riders Nearby', Icons.radar_rounded, const Color(0xFF6366F1), 2),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label, IconData icon, Color color, int i) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, i.isEven ? _pulseController.value * -2 : _pulseController.value * 2),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1.0),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // GOOGLE MAP — fills its Expanded parent completely; controls overlaid
  Widget _buildGoogleMapCard() {
    final onlineCount = _riders.where((r) => r.isAvailable).length;

    final List<Polyline> polylines = [];
    final activeRider = _riders.firstWhere((r) => r.id == 'd2');
    polylines.add(Polyline(
      points: [_storeLocation, activeRider.position],
      strokeWidth: 4.5,
      color: const Color(0xFF10B981),
      strokeCap: StrokeCap.round,
    ));
    final customerPos = _customerLocations['ORD-2026-9481'] ?? const LatLng(6.9080, 79.8580);
    polylines.add(Polyline(
      points: [_storeLocation, customerPos],
      strokeWidth: 3.5,
      color: Colors.blueAccent.withValues(alpha: 0.8),
      strokeCap: StrokeCap.round,
    ));

    return Stack(
      children: [
        // Full-size map
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _storeLocation,
              initialZoom: 14.5,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.google.com/vt/lyrs=$_mapLayerStyle&x={x}&y={y}&z={z}',
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                userAgentPackageName: 'com.plantora.app',
                maxZoom: 20,
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: [
                Marker(
                  point: _storeLocation, width: 56, height: 56,
                  child: GestureDetector(
                    onTap: () => _showStoreHQInfo(),
                    child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 50 + _pulseController.value * 6,
                          height: 50 + _pulseController.value * 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35 - _pulseController.value * 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF044E39),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                      ),
                    ]),
                  ),
                ),
                ..._riders.map((rider) => Marker(
                  point: rider.position, width: 48, height: 48,
                  child: GestureDetector(
                    onTap: () => _showRiderInfo(rider),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: rider.isAvailable ? const Color(0xFF10B981) : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(
                          color: (rider.isAvailable ? const Color(0xFF10B981) : Colors.orange).withValues(alpha: 0.5),
                          blurRadius: 8,
                        )],
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                )),
                Marker(
                  point: customerPos, width: 40, height: 40,
                  child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 38),
                ),
              ]),
            ],
          ),
        ),

        // Top-left: Google Maps badge
        Positioned(
          top: 10, left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Google', style: GoogleFonts.outfit(color: const Color(0xFF4285F4), fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 3),
              Text('Maps', style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),

        // Top-right: Satellite toggle
        Positioned(
          top: 10, right: 10,
          child: GestureDetector(
            onTap: () => setState(() => _mapLayerStyle = (_mapLayerStyle == 'm') ? 'y' : 'm'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_mapLayerStyle == 'm' ? Icons.satellite_alt_rounded : Icons.map_rounded, size: 14, color: const Color(0xFF10B981)),
                const SizedBox(width: 5),
                Text(_mapLayerStyle == 'm' ? 'Satellite' : 'Roadmap',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
              ]),
            ),
          ),
        ),

        // Bottom-left: Legend
        Positioned(
          bottom: 10, left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
            ),
            child: Wrap(spacing: 10, runSpacing: 4, children: [
              _dot(const Color(0xFF044E39), 'Shop HQ'),
              _dot(const Color(0xFF10B981), 'Available ($onlineCount)'),
              _dot(Colors.orange, 'Busy'),
            ]),
          ),
        ),

        // Bottom-right: Zoom & recenter controls
        Positioned(
          bottom: 10, right: 10,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _mapFloatingBtn(Icons.my_location_rounded, () => _mapController.move(_storeLocation, 14.5)),
            const SizedBox(height: 6),
            _mapFloatingBtn(Icons.add_rounded, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
            const SizedBox(height: 6),
            _mapFloatingBtn(Icons.remove_rounded, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
          ]),
        ),
      ],
    );
  }


  Widget _mapFloatingBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.cardBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
          ],
          border: Border.all(color: context.border),
        ),
        child: Icon(icon, color: context.textPrimary, size: 16),
      ),
    );
  }

  Widget _dot(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(
        label,
        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
    ],
  );

  void _showStoreHQInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plantora Dispatch HQ',
                        style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Cinnamon Gardens, Colombo 07, Sri Lanka',
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This is your central fulfillment station. When you broadcast orders, all delivery riders within 5km receive the notification and can choose to accept the pickup.',
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiderInfo(_LiveRider rider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: (rider.isAvailable ? const Color(0xFF10B981) : Colors.orange).withValues(alpha: 0.15),
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: rider.isAvailable ? const Color(0xFF10B981) : Colors.orange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.name,
                        style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${rider.vehiclePlate} • ${rider.vehicleType}',
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (rider.isAvailable ? const Color(0xFF10B981) : Colors.orange).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rider.isAvailable ? '✅ Available' : '🟠 On Delivery',
                    style: GoogleFonts.inter(
                      color: rider.isAvailable ? const Color(0xFF10B981) : Colors.orange,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _infoTile(Icons.location_on_rounded, '${rider.distanceKm} km away', Colors.blue)),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoTile(
                    Icons.access_time_rounded,
                    'ETA ~${(rider.distanceKm * 3.5).round()} min',
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _infoTile(Icons.star_rounded, '${rider.rating} ★', Colors.amber)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sellers cannot select riders. Riders independently view incoming broadcast orders and choose whether to accept.',
                      style: GoogleFonts.inter(color: context.textPrimary, fontSize: 11.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title, String sub, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 16.5, fontWeight: FontWeight.w800)),
        Text(sub, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildOrderItemsList(List<OrderItem> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4, left: 4),
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item.imageUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 12))),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 12))),
                  ),
                const SizedBox(width: 6),
                Text(
                  item.title,
                  style: GoogleFonts.inter(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'x${item.quantity}',
                    style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // PREPARED ORDER CARD
  Widget _buildReadyCard(OrderModel order, int index) {
    final bs = _broadcastStates[order.id];
    final isBroadcasting = bs?.isSearching ?? false;
    final isExpired = bs?.needsRebroadcast ?? false;
    final countdownStr = bs != null ? '${(bs.secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(bs.secondsRemaining % 60).toString().padLeft(2, '0')}' : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired 
              ? Colors.redAccent.withValues(alpha: 0.5) 
              : isBroadcasting 
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : context.border.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.shippingAddress,
                              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Prepared',
                        style: GoogleFonts.inter(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),
            
            // Items
            _buildOrderItemsList(order.items),
            const SizedBox(height: 16),

            // BROADCAST IN PROGRESS BAR (1 HOUR PICKUP WINDOW)
            if (isBroadcasting) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(
                                alpha: 0.4 + _pulseController.value * 0.6,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Broadcasting • Awaiting pickup',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            countdownStr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 1-HOUR EXPIRED ALERT (RE-BROADCAST NEEDED)
            if (isExpired) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1 Hour Passed — No Pickup!',
                            style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Please re-ring nearby riders.',
                            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ACTION BUTTON: RING RIDERS / RE-BROADCAST
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _broadcastToRiders(order, isRebroadcast: isExpired),
                icon: Icon(
                  isExpired ? Icons.notifications_active_rounded : Icons.campaign_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  isExpired
                      ? 'Re-Broadcast Order'
                      : isBroadcasting
                          ? 'Re-Ring Nearby Riders'
                          : 'Inform Riders (Broadcast)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpired ? Colors.redAccent : context.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 70 * index), duration: 350.ms).slideY(begin: 0.08);
  }
  // ACTIVE ON-THE-ROAD ORDER CARD
  Widget _buildActiveCard(OrderModel order, int index) {
    final isOnWay = order.status == 'Out for Delivery';
    final color = isOnWay ? const Color(0xFF10B981) : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOrderItemsList(order.items),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 1),
            ),
            
            _buildProgress(order.status),
            const SizedBox(height: 16),
            
            if (order.driverName != null) _buildDriverCard(order),
            
            const SizedBox(height: 12),

            // ── TRANSFER DELIVERY CHARGE BUTTON ──
            _buildTransferButton(order),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _advanceDelivery(order),
                icon: Icon(
                  isOnWay ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  isOnWay ? 'Confirm Delivery Completed' : 'Hand Package to Rider',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 70 * index), duration: 350.ms).slideX(begin: 0.06);
  }

  Widget _buildTransferButton(OrderModel order) {
    if (order.status != 'Shipped') return const SizedBox.shrink();

    final isTransferred = _transferredOrders.contains(order.id);

    return SizedBox(
      width: double.infinity,
      child: isTransferred
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Charge Transferred',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            )
          : ElevatedButton.icon(
              onPressed: () {
                final finance = context.read<FinanceService>();
                final success = finance.transferDeliveryChargeToDriver(
                  order.id,
                  driverName: order.driverName ?? 'Driver',
                  sellerName: 'Your Store',
                );
                
                if (success) {
                  setState(() {
                    _transferredOrders.add(order.id);
                  });
                  _showSnack('Rs. ${finance.driverFee.toStringAsFixed(0)} transferred to driver', const Color(0xFF10B981));
                } else {
                  _showSnack('Insufficient balance to transfer charge', Colors.redAccent);
                }
              },
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.white),
              label: Text(
                'Transfer Delivery Charge (Rs. 350)',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
    );
  }
  // DELIVERED CARD WITH SWIPE-TO-CLEAR HISTORY (DISMISSIBLE)
  Widget _buildDeliveredCard(OrderModel order, int index) {
    return Dismissible(
      key: Key('deliv_hist_${order.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Clear History',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      onDismissed: (_) {
        setState(() {
          _deliveredOrders.removeWhere((o) => o.id == order.id);
        });
        _orderService.deleteOrder(order.id);
        _showSnack('Delivered order #${order.id} cleared from history', const Color(0xFF10B981));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: GoogleFonts.outfit(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Text(
                      '${order.customerName} • Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'Swipe to clear ⇦',
                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(String status) {
    final steps = ['Preparing', 'Shipped', 'Out for Delivery', 'Delivered'];
    final active = steps.indexOf(status == 'Accepted' ? 'Preparing' : status);

    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final done = i <= active;
        final isAct = i == active;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isAct ? 22 : 16,
                    height: isAct ? 22 : 16,
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF10B981) : context.border,
                      shape: BoxShape.circle,
                      border: Border.all(color: isAct ? const Color(0xFF10B981) : context.border, width: isAct ? 2 : 1),
                      boxShadow: isAct
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: done ? const Icon(Icons.check, color: Colors.white, size: 10) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.value.replaceAll(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: done ? const Color(0xFF10B981) : context.textSecondary,
                      fontSize: 8.5,
                      fontWeight: isAct ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: i < active
                            ? [const Color(0xFF10B981), const Color(0xFF10B981)]
                            : [context.border, context.textPrimary.withValues(alpha: 0.04)],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDriverCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                order.driverName!.isNotEmpty ? order.driverName![0].toUpperCase() : 'D',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName!,
                  style: GoogleFonts.outfit(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                Row(
                  children: [
                    Icon(
                      order.vehicleType?.toLowerCase() == 'car'
                          ? Icons.directions_car_rounded
                          : Icons.two_wheeler_rounded,
                      size: 12,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.vehicleType ?? 'Bike'} ${order.vehiclePlate != null ? '• ${order.vehiclePlate}' : ''}',
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order.driverPhone != null)
            GestureDetector(
              onTap: () => _showContactDialog(order.driverName!, order.driverPhone!),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 17),
              ),
            ),
        ],
      ),
    );
  }

  void _showContactDialog(String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(name, style: GoogleFonts.outfit(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 12),
              Text(phone, style: GoogleFonts.inter(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: context.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 90 + _pulseController.value * 6,
              height: 90 + _pulseController.value * 6,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08 + _pulseController.value * 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2), width: 1.5),
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF10B981), size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text('All Clear!', style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'No orders awaiting dispatch.\nNew orders will appear here automatically.',
            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

// BOTTOM SHEET: BROADCASTING IN REAL TIME TO NEARBY RIDERS
class _BroadcastWaitingSheet extends StatefulWidget {
  final OrderModel order;
  final int ridersCount;
  final Function(_LiveRider rider) onRiderAccepted;

  const _BroadcastWaitingSheet({
    required this.order,
    required this.ridersCount,
    required this.onRiderAccepted,
  });

  @override
  State<_BroadcastWaitingSheet> createState() => _BroadcastWaitingSheetState();
}

class _BroadcastWaitingSheetState extends State<_BroadcastWaitingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  bool _riderFound = false;
  _LiveRider? _acceptedRider;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Rider Kamal Silva simulates receiving and deciding to accept the delivery after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _riderFound = true;
          _acceptedRider = _initialRiders[1]; // Kamal Silva
        });
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_riderFound) ...[
            // Live Radar Rings Animation
            AnimatedBuilder(
              animation: _radarController,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76 + _radarController.value * 26,
                    height: 76 + _radarController.value * 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(
                          alpha: 0.4 - _radarController.value * 0.35,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 2),
                    ),
                    child: const Icon(Icons.radar_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ringing Nearby Delivery Riders',
              style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Informing ${widget.ridersCount} available riders nearby.\nEach rider can review the store location and customer address to accept.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: Color(0xFF10B981), backgroundColor: Color(0x2210B981)),
            const SizedBox(height: 10),
            Text(
              'Riders choose to accept • 1-hour window active',
              style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary, fontStyle: FontStyle.italic),
            ),
          ] else ...[
            // RIDER ACCEPTED CARD
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Rider Accepted Delivery!',
              style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 18.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_acceptedRider!.name} accepted and is riding to your store.',
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _acceptedRider!.name[0],
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _acceptedRider!.name,
                          style: GoogleFonts.outfit(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          '${_acceptedRider!.vehiclePlate} • ~3 min ETA (0.4 km away)',
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_acceptedRider!.rating} ★',
                      style: GoogleFonts.inter(color: Colors.amber.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onRiderAccepted(_acceptedRider!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm & Track on Google Map',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
