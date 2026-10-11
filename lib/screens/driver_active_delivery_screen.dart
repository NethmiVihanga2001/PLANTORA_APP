import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/socket_service.dart';
import '../../../services/order_service.dart';
import '../../../services/delivery_service.dart';
import '../../../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'driver_chat_screen.dart';

class DriverActiveDeliveryScreen extends StatefulWidget {
  final OrderModel? order;
  const DriverActiveDeliveryScreen({super.key, this.order});

  @override
  State<DriverActiveDeliveryScreen> createState() => _DriverActiveDeliveryScreenState();
}

class _DriverActiveDeliveryScreenState extends State<DriverActiveDeliveryScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Real coordinates in Colombo, Sri Lanka
  final LatLng _shopPoint = const LatLng(6.8720, 79.8860); // Plantora Shop (Maharagama)
  final LatLng _destinationPoint = const LatLng(6.9271, 79.8612); // Delivery Address (Colombo)
  
  late LatLng _currentLocation;
  double _currentHeading = 0.0;
  
  // Real road route geometry fetched from OSRM
  List<LatLng> _roadRoutePoints = [];
  // Traveled breadcrumbs (actual path driven)
  final List<LatLng> _traveledBreadcrumbs = [];
  
  // GPS Tracking
  StreamSubscription<Position>? _gpsSubscription;
  bool _isGpsLive = false;
  String _gpsStatus = 'Searching GPS...';

  // Road Route Drive (for indoor/testing)
  bool _isDrivingRoute = false;
  Timer? _driveTimer;
  int _routeStepIndex = 0;

  bool _deliveryCompleted = false;
  bool _isCompletingDelivery = false;

  String get _orderId => widget.order?.id ?? 'ORD-2026-9481';

  @override
  void initState() {
    super.initState();
    _currentLocation = _shopPoint;
    _traveledBreadcrumbs.add(_currentLocation);
    
    SocketService().joinOrderRoom(_orderId);

    // 1. Fetch real street road geometry from OSRM
    _fetchRealRoadRoute();

    // 2. Start hardware GPS tracking stream
    _initLiveGps();
  }

  Future<void> _fetchRealRoadRoute() async {
    final points = await DeliveryService.fetchRoadRoute(_shopPoint, _destinationPoint);
    if (mounted) {
      setState(() {
        _roadRoutePoints = points;
      });
      if (_roadRoutePoints.isNotEmpty) {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_currentLocation, _destinationPoint]),
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 260),
        ));
      }
    }
  }

  Future<void> _initLiveGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _gpsStatus = 'GPS Service Disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _gpsStatus = 'GPS Permission Denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _gpsStatus = 'GPS Denied Forever');
        return;
      }

      // Initial position
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _onDriverLocationUpdate(initialPos.latitude, initialPos.longitude, initialPos.heading);

      // Start continuous stream
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // meters
        ),
      ).listen((pos) {
        _onDriverLocationUpdate(pos.latitude, pos.longitude, pos.heading);
      });

      setState(() {
        _isGpsLive = true;
        _gpsStatus = 'Live GPS Streaming';
      });
    } catch (e) {
      debugPrint('Geolocator init error: $e');
      setState(() => _gpsStatus = 'Manual / Test Mode');
    }
  }

  void _onDriverLocationUpdate(double lat, double lng, double heading) {
    if (!mounted) return;
    final newPoint = LatLng(lat, lng);
    
    setState(() {
      _currentLocation = newPoint;
      _currentHeading = heading;
      if (_traveledBreadcrumbs.isEmpty || 
          const Distance().as(LengthUnit.Meter, _traveledBreadcrumbs.last, newPoint) >= 3) {
        _traveledBreadcrumbs.add(newPoint);
      }
    });

    _mapController.move(_currentLocation, 16.0);

    // Calculate real distance to destination
    final distanceMeters = const Distance().as(LengthUnit.Meter, _currentLocation, _destinationPoint);

    // Emit live location over Socket.IO to Customer and Seller maps!
    SocketService().updateLocation(
      orderId: _orderId,
      lat: lat,
      lng: lng,
      heading: heading,
      stage: 'delivering_to_customer',
      distanceToCustomer: distanceMeters.toDouble(),
    );
  }

  // Interactive road drive along the real OSRM street route
  void _toggleRoadDrive() {
    if (_isDrivingRoute) {
      _driveTimer?.cancel();
      setState(() => _isDrivingRoute = false);
      return;
    }

    final route = _roadRoutePoints.isNotEmpty 
        ? _roadRoutePoints 
        : [_shopPoint, const LatLng(6.8900, 79.8750), const LatLng(6.9100, 79.8650), _destinationPoint];

    setState(() => _isDrivingRoute = true);

    _driveTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_routeStepIndex >= route.length - 1) {
        timer.cancel();
        setState(() => _isDrivingRoute = false);
        return;
      }

      _routeStepIndex++;
      final point = route[_routeStepIndex];
      
      // Calculate heading towards next point
      double heading = 0.0;
      if (_routeStepIndex < route.length - 1) {
        final next = route[_routeStepIndex + 1];
        heading = (math.atan2(next.longitude - point.longitude, next.latitude - point.latitude) * 180 / math.pi);
      }

      _onDriverLocationUpdate(point.latitude, point.longitude, heading);
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _driveTimer?.cancel();
    SocketService().leaveOrderRoom(_orderId);
    super.dispose();
  }

  double get _distanceToDestinationMeters {
    return const Distance().as(LengthUnit.Meter, _currentLocation, _destinationPoint);
  }

  double get _overallProgress {
    final total = const Distance().as(LengthUnit.Meter, _shopPoint, _destinationPoint);
    if (total <= 0) return 1.0;
    final remaining = _distanceToDestinationMeters;
    final p = 1.0 - (remaining / total);
    return p.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      body: Stack(
        children: [
          // Flutter Map with Real Road Polyline & Driver Location
          _buildMap(isDark),
          
          // Header with Back button and Live GPS Pill
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 24),
                  ),
                ),

                // Live GPS Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isGpsLive ? const Color(0xFF10B981) : Colors.orangeAccent, 
                      width: 1.5,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isGpsLive ? const Color(0xFF10B981) : Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 800.ms),
                      const SizedBox(width: 8),
                      Text(
                        _isGpsLive ? 'Live GPS Active' : _gpsStatus,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isGpsLive ? const Color(0xFF10B981) : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    const urlTemplate = 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    final fullRoad = _roadRoutePoints.isNotEmpty 
        ? _roadRoutePoints 
        : [_shopPoint, _destinationPoint];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _shopPoint,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onTap: (tapPosition, point) {
          // Allow driver to tap to jump/test location anywhere on the street
          _onDriverLocationUpdate(point.latitude, point.longitude, _currentHeading);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: urlTemplate,
          subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
          userAgentPackageName: 'com.plantora.app',
        ),

        // 1. Full Planned Road Route (Subtle Street Geometry)
        PolylineLayer(
          polylines: [
            Polyline(
              points: fullRoad,
              strokeWidth: 5.5,
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
            // 2. Real Traveled Breadcrumbs Path (Solid Emerald Green)
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
            // Shop Pickup Marker
            Marker(
              point: _shopPoint,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF065F46),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
              ),
            ),

            // Destination Marker (Customer House)
            Marker(
              point: _destinationPoint,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 10)],
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.9, 0.9), duration: 1.seconds),
            ),

            // Driver Motorcycle Live Marker (Rotating with heading)
            Marker(
              point: _currentLocation,
              width: 60,
              height: 60,
              child: Transform.rotate(
                angle: _currentHeading * (math.pi / 180),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5), 
                        blurRadius: 15, 
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🛵', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomPanel(bool isDark) {
    final distKm = (_distanceToDestinationMeters / 1000).toStringAsFixed(1);
    final etaMins = (_distanceToDestinationMeters / 300).ceil();
    final isArrived = _distanceToDestinationMeters <= 60;
    final orderAmount = widget.order?.totalAmount ?? 2450.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5), width: 1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, -10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: context.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))]
                    ),
                    child: Icon(
                      isArrived ? Icons.check_circle_rounded : Icons.navigation_rounded, 
                      color: Colors.white, 
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArrived ? 'Arrived at Destination' : 'Delivering via Street Route',
                          style: GoogleFonts.outfit(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.order?.shippingAddress ?? 'Colombo, Sri Lanka',
                          style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavStat(isDark, '$etaMins min', 'ETA'),
                  Container(width: 1, height: 36, color: context.textSecondary.withValues(alpha: 0.2)),
                  _buildNavStat(isDark, '$distKm km', 'Distance'),
                  Container(width: 1, height: 36, color: context.textSecondary.withValues(alpha: 0.2)),
                  _buildNavStat(isDark, '${(_overallProgress * 100).round()}%', 'Progress'),
                ],
              ),
              const SizedBox(height: 18),
              
              // Order Summary strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Amount', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                        Text('Rs. ${orderAmount.toStringAsFixed(2)}', 
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                      ],
                    ),
                    const Spacer(),
                    Text('Order ID: $_orderId', 
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Live Customer Chat Action Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final ord = widget.order ?? OrderModel(
                          id: _orderId,
                          customerId: 'customer',
                          customerName: 'Customer',
                          items: [],
                          totalAmount: orderAmount,
                          status: 'Out for Delivery',
                          createdAt: DateTime.now(),
                          shippingAddress: widget.order?.shippingAddress ?? 'Colombo, Sri Lanka',
                          phone: widget.order?.phone ?? '',
                          driverId: 'driver',
                          driverName: 'Driver',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverChatScreen(order: ord),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: Text('Chat Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (widget.order?.phone != null && widget.order!.phone.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () async {
                        final url = Uri.parse('tel:${widget.order!.phone}');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                      icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons: Drive Route Test & Complete Delivery
              Row(
                children: [
                  // Test drive road button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleRoadDrive,
                      icon: Icon(_isDrivingRoute ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                      label: Text(_isDrivingRoute ? 'Pause Drive' : 'Drive Road'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Complete delivery button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (_isCompletingDelivery || _deliveryCompleted) ? null : _confirmCompleteDelivery,
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                      label: Text(
                        _deliveryCompleted ? 'Delivered!' : (_isCompletingDelivery ? 'Completing...' : 'Complete Delivery'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavStat(bool isDark, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: context.textSecondary),
        ),
      ],
    );
  }

  void _confirmCompleteDelivery() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                'Complete Delivery?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm that you have handed over the plants to the customer. This updates order status to Delivered.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade500,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _finishDelivery();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Yes, Delivered!', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finishDelivery() async {
    HapticFeedback.heavyImpact();
    setState(() => _isCompletingDelivery = true);

    // Call real-time socket and order service completion
    SocketService().completeDelivery(_orderId);
    await OrderService().updateOrderStatus(_orderId, 'Delivered');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _deliveryCompleted = true;
      _isCompletingDelivery = false;
    });
    HapticFeedback.heavyImpact();
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF065F46), Color(0xFF10B981)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 18),
                Text(
                  'Delivery Complete! 🎉',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order status has been updated to Delivered. Earnings credited to your wallet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
