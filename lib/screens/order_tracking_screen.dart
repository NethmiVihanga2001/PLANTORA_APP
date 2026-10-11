import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../models/order_model.dart';
import '../providers/notification_provider.dart';
import 'driver_chat_screen.dart';
import '../config/app_config.dart';
import '../services/socket_service.dart';
import '../services/delivery_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _currentOrder;

  late IO.Socket _socket;
  final MapController _mapController = MapController();
  
  // Real-time coordinates in Colombo
  final LatLng _shopLocation = const LatLng(6.8720, 79.8860); // Plantora Shop (Maharagama)
  final LatLng _customerLocation = const LatLng(6.9271, 79.8612); // Customer House (Colombo Fort)
  LatLng _driverLocation = const LatLng(6.8890, 79.8720); // Driver position
  double _driverHeading = 0.0;

  List<LatLng> _roadPoints = [];
  final List<LatLng> _traveledBreadcrumbs = [];

  bool _hasNotifiedNearby = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _fetchRoadRoute();
    _initSocket();
  }

  Future<void> _fetchRoadRoute() async {
    // 1. Fetch real street road geometry from OSRM
    final points = await DeliveryService.fetchRoadRoute(_shopLocation, _customerLocation);
    if (mounted) {
      setState(() {
        _roadPoints = points;
      });
      if (_roadPoints.isNotEmpty) {
        _recenterMap();
      }
    }

    // 2. Fetch existing active location & breadcrumbs from backend
    final activeLoc = await DeliveryService().getActiveDeliveryLocation(_currentOrder.id);
    if (activeLoc != null && mounted) {
      final lat = (activeLoc['lat'] as num?)?.toDouble();
      final lng = (activeLoc['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        setState(() {
          _driverLocation = LatLng(lat, lng);
          _driverHeading = (activeLoc['heading'] as num?)?.toDouble() ?? 0.0;
          if (activeLoc['path'] is List) {
            _traveledBreadcrumbs.clear();
            for (final p in activeLoc['path']) {
              if (p is Map && p['lat'] != null && p['lng'] != null) {
                _traveledBreadcrumbs.add(LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()));
              }
            }
          }
        });
      }
    }
  }


  void _checkProximityAlert(int distanceMeters) {
    if (distanceMeters <= 500 && !_hasNotifiedNearby) {
      _hasNotifiedNearby = true;
      
      // 1. Add to App Notifications
      try {
        final notifications = Provider.of<NotificationProvider>(context, listen: false);
        notifications.addNotification(
          '🚨 Rider is Nearby!',
          'Your delivery driver ${_currentOrder.driverName ?? "Rider"} is arriving at your location (${distanceMeters}m away)!',
          type: 'delivery',
        );
      } catch (e) {
        debugPrint('Notification error: $e');
      }

      // 2. Pop-Up Banner Dialog
      if (mounted) {
        _showNearbyRiderDialog(distanceMeters);
      }
    }
  }

  void _showNearbyRiderDialog(int meters) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.cardBg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF10B981), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rider is Arriving!',
                    style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  Text(
                    'Get ready to collect your plant',
                    style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your delivery driver is right outside your address (${meters > 0 ? "$meters meters away" : "Arrived"})!',
              style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentOrder.driverName ?? 'Assigned Rider',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                        ),
                        Text(
                          '${_currentOrder.vehicleType ?? "Motorcycle"} ${_currentOrder.vehiclePlate != null ? "• ${_currentOrder.vehiclePlate}" : ""}',
                          style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Got It', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _initSocket() {
    SocketService().joinOrderRoom(_currentOrder.id);

    _socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'extraHeaders': AppConfig.defaultHeaders,
      'autoConnect': false,
    });
    
    _socket.connect();
    
    _socket.onConnect((_) {
      _socket.emit('joinOrderRoom', _currentOrder.id);
    });

    _socket.on('rider_arriving_near', (data) {
      if (mounted) {
        final meters = (data['distanceMeters'] as num?)?.toInt() ?? 300;
        _checkProximityAlert(meters);
      }
    });

    _socket.on('order_status_updated', (data) {
      if (mounted && data != null && data['orderId'] != null && data['orderId'].toString() == _currentOrder.id.toString()) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(
            status: data['status'] ?? _currentOrder.status,
            driverName: data['driverName'] ?? _currentOrder.driverName,
            driverPhone: data['driverPhone'] ?? _currentOrder.driverPhone,
            vehicleType: data['vehicleType'] ?? _currentOrder.vehicleType,
            vehiclePlate: data['vehiclePlate'] ?? _currentOrder.vehiclePlate,
          );
        });
      }
    });
    
    _socket.on('order_status_${_currentOrder.customerId}', (data) {
      if (mounted && data != null && data['orderId'] != null && data['orderId'].toString() == _currentOrder.id.toString()) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(
            status: data['status'] ?? _currentOrder.status,
            driverName: data['driverName'] ?? _currentOrder.driverName,
          );
        });
      }
    });
    
    _socket.on('locationUpdated', (data) {
      if (mounted && data != null && data['orderId'] != null && data['orderId'].toString() == _currentOrder.id.toString()) {
        if (data['lat'] != null && data['lng'] != null) {
          final lat = (data['lat'] as num).toDouble();
          final lng = (data['lng'] as num).toDouble();
          final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
          final newLoc = LatLng(lat, lng);

          setState(() {
            _driverLocation = newLoc;
            _driverHeading = heading;
            if (data['path'] is List) {
              _traveledBreadcrumbs.clear();
              for (final p in data['path']) {
                if (p is Map && p['lat'] != null && p['lng'] != null) {
                  _traveledBreadcrumbs.add(LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()));
                }
              }
            } else {
              if (_traveledBreadcrumbs.isEmpty || const Distance().as(LengthUnit.Meter, _traveledBreadcrumbs.last, newLoc) >= 3) {
                _traveledBreadcrumbs.add(newLoc);
              }
            }
          });

          final distanceMeters = (data['distanceToCustomer'] as num?)?.toInt() ?? 
              const Distance().as(LengthUnit.Meter, _driverLocation, _customerLocation).toInt();
          if (distanceMeters <= 500) {
            _checkProximityAlert(distanceMeters);
          }
          
          if (_currentOrder.orderStatus == OrderStatus.outForDelivery) {
            final bounds = LatLngBounds.fromPoints([_customerLocation, _driverLocation]);
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService().leaveOrderRoom(_currentOrder.id);
    _socket.disconnect();
    super.dispose();
  }


  void _recenterMap() {
    final bounds = LatLngBounds.fromPoints([_shopLocation, _driverLocation, _customerLocation]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentOrder.orderStatus;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.54;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. FULL SCREEN MAP CANVAS (Uber Eats Style)
            Positioned.fill(
              child: _buildFullBleedMap(),
            ),

            // 2. FLOATING TOP GLASS CONTROLS
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Floating Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 26),
                  ),

                  // Floating Live Telemetry Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: context.cardBg.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
                        const SizedBox(width: 8),
                        Text(
                          _telemetryText,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. FLOATING RECENTER BUTTON
            Positioned(
              right: 14,
              bottom: bottomSheetHeight + 14,
              child: FloatingActionButton.small(
                onPressed: _recenterMap,
                backgroundColor: context.cardBg.withValues(alpha: 0.95),
                foregroundColor: const Color(0xFF10B981),
                elevation: 4,
                child: const Icon(Icons.my_location_rounded, size: 20),
              ),
            ),

            // 4. UBER EATS UNIFIED SLIDING BOTTOM SHEET
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: bottomSheetHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle Bar Pill
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // ETA Header Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _headerTitle,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Delivering to ${widget.order.shippingAddress}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: status.color, width: 1.2),
                            ),
                            child: Text(
                              status.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: status.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Divider(height: 1, color: context.border),
                    ),

                    // Unified Continuous Surface Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: Responsive.formContainer(
                          context: context,
                          maxWidth: 800,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDriverSection(),
                              Divider(height: 28, color: context.border),
                              _buildStatusTimelineSection(status),
                              Divider(height: 28, color: context.border),
                              _buildOrderItemsSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _telemetryText {
    final status = _currentOrder.orderStatus;
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed • Waiting for Seller';
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return 'Seller Preparing Plants';
      case OrderStatus.shipped:
        return 'Ready for Pickup • Assigning Rider';
      case OrderStatus.outForDelivery:
        final distanceMeters = const Distance().as(LengthUnit.Meter, _driverLocation, _customerLocation);
        final distanceKm = (distanceMeters / 1000).toStringAsFixed(1);
        final estimatedMins = (distanceMeters / 250).ceil();
        return distanceMeters > 50 ? '$estimatedMins mins away ($distanceKm km)' : 'Rider Arrived!';
      case OrderStatus.delivered:
        return 'Order Delivered Successfully!';
      case OrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }

  String get _headerTitle {
    final status = _currentOrder.orderStatus;
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Accepted by Seller';
      case OrderStatus.preparing:
        return 'Preparing your Plants';
      case OrderStatus.shipped:
        return 'Waiting for Delivery Rider';
      case OrderStatus.outForDelivery:
        final distanceMeters = const Distance().as(LengthUnit.Meter, _driverLocation, _customerLocation);
        final estimatedMins = (distanceMeters / 250).ceil();
        return distanceMeters <= 50 ? 'Driver Has Arrived!' : 'Arriving in $estimatedMins Mins';
      case OrderStatus.delivered:
        return 'Order Delivered!';
      case OrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }

  Widget _buildFullBleedMap() {
    final hasActiveRider = (_currentOrder.orderStatus == OrderStatus.outForDelivery || _currentOrder.orderStatus == OrderStatus.delivered) &&
        (_currentOrder.driverName != null && _currentOrder.driverName!.trim().isNotEmpty);

    final road = _roadPoints.isNotEmpty ? _roadPoints : [_shopLocation, _customerLocation];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(road),
          padding: const EdgeInsets.fromLTRB(50, 80, 50, 270),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
          subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
          userAgentPackageName: 'com.plantora.app',
        ),
        // Real Road & Traveled Breadcrumbs Polylines
        PolylineLayer(
          polylines: [
            // Planned street road route
            Polyline(
              points: road,
              strokeWidth: 5.5,
              color: const Color(0xFF10B981).withValues(alpha: hasActiveRider ? 0.35 : 0.6),
            ),
            // Real driver breadcrumbs path traveled
            if (_traveledBreadcrumbs.length >= 2)
              Polyline(
                points: _traveledBreadcrumbs,
                strokeWidth: 6.0,
                color: const Color(0xFF10B981),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _shopLocation,
              width: 42,
              height: 42,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5A32),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF34D399), size: 20),
              ),
            ),
            Marker(
              point: _customerLocation,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3A22),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.5), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.home_work_rounded, color: Color(0xFF10B981), size: 22),
              ),
            ),
            if (hasActiveRider)
              Marker(
                point: _driverLocation,
                width: 56,
                height: 56,
                child: Transform.rotate(
                  angle: _driverHeading * (3.141592653589793 / 180),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.25, 1.25), duration: 1200.ms),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
                          ],
                        ),
                        child: const Center(
                          child: Text('🛵', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Unified Driver Profile Section
  Widget _buildDriverSection() {
    final hasDriver = (_currentOrder.orderStatus == OrderStatus.outForDelivery || _currentOrder.orderStatus == OrderStatus.delivered) &&
        (_currentOrder.driverName != null && _currentOrder.driverName!.trim().isNotEmpty);

    final driverName = hasDriver
        ? _currentOrder.driverName!
        : (_currentOrder.orderStatus == OrderStatus.shipped ? 'Assigning Rider...' : 'Seller Preparing Plant');
    final vehicle = hasDriver ? (_currentOrder.vehicleType ?? 'Motorcycle') : 'Awaiting delivery partner';
    final plate = hasDriver ? (_currentOrder.vehiclePlate ?? '') : '';

    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: (hasDriver && _currentOrder.driverAvatar != null && _currentOrder.driverAvatar!.isNotEmpty) ? NetworkImage(_currentOrder.driverAvatar!) : null,
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
              child: (!hasDriver || _currentOrder.driverAvatar == null)
                  ? Icon(hasDriver ? Icons.person_rounded : Icons.storefront_rounded, color: const Color(0xFF10B981), size: 26)
                  : null,
            ),
            if (hasDriver)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      driverName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasDriver) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                plate.isNotEmpty ? '$vehicle • $plate' : vehicle,
                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        if (hasDriver)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DriverChatScreen(order: _currentOrder)),
                  );
                },
                icon: const Icon(Icons.message_rounded, color: Color(0xFF10B981), size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  minimumSize: const Size(44, 44),
                  shape: const CircleBorder(),
                ),
                tooltip: 'Chat with Driver',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final phone = _currentOrder.driverPhone ?? '+94771234567';
                  final url = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(44, 44),
                  shape: const CircleBorder(),
                  elevation: 2,
                ),
                tooltip: 'Call Driver',
              ),
            ],
          ),
      ],
    ).animate().fadeIn().slideY(begin: 0.08);
  }


  // Unified Timeline Section (No Heavy Outer Box)
  Widget _buildStatusTimelineSection(OrderStatus currentStatus) {
    final stages = [
      {'status': OrderStatus.pending, 'label': 'Order Placed', 'time': '10:30 AM'},
      {'status': OrderStatus.accepted, 'label': 'Accepted by Seller', 'time': '10:35 AM'},
      {'status': OrderStatus.preparing, 'label': 'Preparing your Plants', 'time': '11:00 AM'},
      {'status': OrderStatus.shipped, 'label': 'Handed to Courier', 'time': '11:45 AM'},
      {'status': OrderStatus.outForDelivery, 'label': 'Out for Delivery', 'time': 'On the way'},
      {'status': OrderStatus.delivered, 'label': 'Delivered', 'time': 'Pending'},
    ];

    int currentIndex = stages.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Timeline', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
        const SizedBox(height: 16),
        ...List.generate(stages.length, (index) {
          final stage = stages[index];
          final isCompleted = index <= currentIndex;
          final isLast = index == stages.length - 1;

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFF10B981) : context.border,
                        shape: BoxShape.circle,
                        border: isCompleted ? Border.all(color: const Color(0xFFA7F3D0), width: 2.5) : null,
                      ),
                      child: isCompleted ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted ? const Color(0xFF10B981) : context.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['label'] as String,
                          style: GoogleFonts.inter(
                            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13.5,
                            color: isCompleted ? context.textPrimary : context.textSecondary,
                          ),
                        ),
                        Text(
                          isCompleted ? (stage['time'] as String) : 'Waiting...',
                          style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Unified Order Summary Section (No Heavy Outer Box)
  Widget _buildOrderItemsSection() {
    final shopToCustKm = (const Distance().as(LengthUnit.Meter, _shopLocation, _customerLocation) / 1000);
    final deliveryFee = shopToCustKm * 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
        const SizedBox(height: 14),
        ..._currentOrder.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildItemImage(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                    Text('Quantity: ${item.quantity}', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text('Rs. ${(item.price * item.quantity).toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
            ],
          ),
        )),
        Divider(height: 20, color: context.border),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Delivery Charge (${shopToCustKm.toStringAsFixed(1)} km @ Rs. 20/km)',
                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('Rs. ${deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Amount Paid', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 14)),
            Text('Rs. ${_currentOrder.totalAmount.toStringAsFixed(2)}', 
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF10B981), fontSize: 19)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemImage(OrderItem item) {
    String? imgUrl = item.imageUrl;
    
    if (imgUrl == null || imgUrl.isEmpty || imgUrl == 'null') {
      final title = item.title.toLowerCase();
      if (title.contains('aloe')) {
        imgUrl = 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&w=400&q=80';
      } else if (title.contains('basil')) {
        imgUrl = 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?auto=format&fit=crop&w=400&q=80';
      } else if (title.contains('snake')) {
        imgUrl = 'https://images.unsplash.com/photo-1593482892290-f54927ae1bac?auto=format&fit=crop&w=400&q=80';
      } else {
        imgUrl = 'https://images.unsplash.com/photo-1545241047-6083a3684587?auto=format&fit=crop&w=400&q=80';
      }
    } else if (imgUrl.startsWith('/')) {
      imgUrl = '${AppConfig.baseUrl}$imgUrl';
    }

    if (imgUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imgUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackPlantIcon(item),
        ),
      );
    }

    return _buildFallbackPlantIcon(item);
  }

  Widget _buildFallbackPlantIcon(OrderItem item) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(item.emoji.isNotEmpty ? item.emoji : '🌿', style: const TextStyle(fontSize: 22)),
    );
  }
}
