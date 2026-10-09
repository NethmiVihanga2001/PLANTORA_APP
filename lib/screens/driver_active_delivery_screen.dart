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
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';

class DriverActiveDeliveryScreen extends StatefulWidget {
  const DriverActiveDeliveryScreen({super.key});

  @override
  State<DriverActiveDeliveryScreen> createState() => _DriverActiveDeliveryScreenState();
}

class _DriverActiveDeliveryScreenState extends State<DriverActiveDeliveryScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Real coordinates in Colombo, Sri Lanka
  final List<LatLng> _routePoints = const [
    LatLng(6.9110, 79.8660), // Start (Nelum Pokuna area)
    LatLng(6.9140, 79.8640),
    LatLng(6.9160, 79.8610),
    LatLng(6.9190, 79.8580),
    LatLng(6.9230, 79.8520),
    LatLng(6.9271, 79.8450), // End (Galle Face)
  ];

  late LatLng _currentLocation;
  bool _isSimulating = false;
  bool _deliveryCompleted = false;
  bool _isCompletingDelivery = false;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentSegment = 0;

  @override
  void initState() {
    super.initState();
    _currentLocation = _routePoints.first;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Duration per segment
    );
  }

  void _startSimulation() {
    if (_isSimulating || _currentSegment >= _routePoints.length - 1) return;
    
    setState(() => _isSimulating = true);
    _animateNextSegment();
  }

  void _animateNextSegment() {
    if (_currentSegment >= _routePoints.length - 1) {
      setState(() => _isSimulating = false);
      return;
    }

    final startPoint = _routePoints[_currentSegment];
    final endPoint = _routePoints[_currentSegment + 1];

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {
          final lat = lerpDouble(startPoint.latitude, endPoint.latitude, _animation.value)!;
          final lng = lerpDouble(startPoint.longitude, endPoint.longitude, _animation.value)!;
          _currentLocation = LatLng(lat, lng);
          _mapController.move(_currentLocation, 15.5);
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _currentSegment++;
          _animationController.reset();
          
          if (_currentSegment < _routePoints.length - 1) {
            _animateNextSegment(); // Move to next segment
          } else {
            // Reached destination
            setState(() => _isSimulating = false);
          }
        }
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to check progress (0.0 to 1.0) for UI stats
  double get _overallProgress {
    if (_routePoints.isEmpty) return 0;
    if (_currentSegment >= _routePoints.length - 1) return 1.0;
    
    final segmentProgress = _animationController.isAnimating ? _animationController.value : 0.0;
    return (_currentSegment + segmentProgress) / (_routePoints.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      body: Stack(
        children: [
          // Flutter Map with OpenStreetMap
          _buildMap(isDark),
          
          // Header with Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 26),
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _routePoints.first,
        initialZoom: 15.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: urlTemplate,
          subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
          userAgentPackageName: 'com.plantora.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              strokeWidth: 6.0,
              color: AppColors.primaryGreen.withOpacity(0.3),
            ),
            // The drawn path behind the driver
            Polyline(
              points: [
                ..._routePoints.sublist(0, math.min(_currentSegment + 1, _routePoints.length)),
                _currentLocation,
              ],
              strokeWidth: 6.0,
              color: AppColors.primaryGreen,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Destination Marker
            Marker(
              point: _routePoints.last,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10)],
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 30),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), duration: 1.seconds),
            ),
            // Driver Marker
            Marker(
              point: _currentLocation,
              width: 60,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomPanel(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.9) : Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(isDark ? 0.05 : 0.5), width: 1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, -10))
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: context.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                    ),
                    child: Icon(
                      _overallProgress >= 1.0 ? Icons.check_rounded : Icons.turn_right_rounded, 
                      color: Colors.white, 
                      size: 32
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _overallProgress >= 1.0 ? 'Arrived at Destination' : 'Proceed to Galle Face',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _overallProgress >= 1.0 ? 'Delivery Completed' : 'Driving on real streets',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavStat(isDark, '${(15 * (1 - _overallProgress)).ceil()} min', 'Time'),
                  Container(width: 1, height: 40, color: context.textSecondary.withOpacity(0.2)),
                  _buildNavStat(isDark, '${(3.2 * (1 - _overallProgress)).toStringAsFixed(1)} km', 'Distance'),
                  Container(width: 1, height: 40, color: context.textSecondary.withOpacity(0.2)),
                  _buildNavStat(isDark, '12:45 PM', 'ETA'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Order Amount and Chat Icons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Amount', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                        const SizedBox(height: 2),
                        Text('Rs. 2,450', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.person_rounded, size: 20, color: AppColors.primaryGreen),
                        onPressed: () {},
                        tooltip: 'Chat with Customer',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primaryGreen),
                        onPressed: () {},
                        tooltip: 'Chat with Seller',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // ── ARRIVED: End Ride Button ──────────────────────────
              if (_overallProgress >= 1.0 && !_deliveryCompleted)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    // Pulsing arrived banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'You have arrived at the destination',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms, begin: 0.7),
                    const SizedBox(height: 16),

                    // Complete Delivery button
                    GestureDetector(
                      onTap: _isCompletingDelivery ? null : _confirmCompleteDelivery,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF065F46), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: _isCompletingDelivery
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Complete Delivery',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.02, duration: 900.ms, curve: Curves.easeInOut),
                    ),
                  ],
                ),

              // ── IN PROGRESS: Simulate Drive Button ──────────────────
              if (_overallProgress < 1.0)
                GestureDetector(
                  onTap: _startSimulation,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: _isSimulating
                          ? [Colors.grey, Colors.grey.shade600]
                          : [AppColors.primaryGreen, const Color(0xFF34D399)]),
                      boxShadow: [
                        BoxShadow(
                          color: _isSimulating
                              ? Colors.transparent
                              : AppColors.primaryGreen.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isSimulating ? 'Simulating Drive...' : 'Simulate Drive',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutBack);
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 52),
              ),
              const SizedBox(height: 20),
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
                'Confirm that you have handed over the order to the customer. This will mark the delivery as done.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade500,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 15)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Yes, Delivered!',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700, fontSize: 15)),
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
    // Brief loading to feel reliable
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _deliveryCompleted = true;
      _isCompletingDelivery = false;
    });
    HapticFeedback.heavyImpact();
    // Show success then pop
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
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
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF10B981)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 48),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
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
                  'Rs. 350 has been added to your earnings for today.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Back to Dashboard',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavStat(bool isDark, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.textPrimary)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary)),
      ],
    );
  }
}
