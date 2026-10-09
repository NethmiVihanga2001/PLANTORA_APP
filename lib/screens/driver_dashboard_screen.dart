import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';
import 'dart:math' as math;
import 'driver_chat_screen.dart';
import 'driver_active_delivery_screen.dart';
import 'driver_main_screen.dart'; // for driverScaffoldKey

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  
  List<OrderModel> _availableOrders = [];
  bool _isLoading = true;
  bool _isOnline = true;
  UserModel? _currentUser;
  
  // Subtle 3D tilt variables for card
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = await _authService.getCurrentUser();
    
    // Fetch available deliveries from backend
    _availableOrders = await _orderService.getAvailableDeliveries();
    
    // Create dummy orders if empty for demonstration of the premium UI
    if (_availableOrders.isEmpty) {
      _availableOrders = [
        OrderModel(
          id: 'DEL-839210',
          customerId: 'b1',
          customerName: 'Vihanga Nethmi',
          phone: '+94 77 123 4567',
          items: [],
          totalAmount: 250.0,
          status: 'Available',
          shippingAddress: '123 Main St, Colombo',
          createdAt: DateTime.now(),
        ),
        OrderModel(
          id: 'DEL-839211',
          customerId: 'b2',
          customerName: 'Jane Smith',
          phone: '+94 77 234 5678',
          items: [],
          totalAmount: 350.0,
          status: 'Available',
          shippingAddress: '45 Park Ave, Colombo',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        OrderModel(
          id: 'DEL-839212',
          customerId: 'b3',
          customerName: 'Michael Brown',
          phone: '+94 77 345 6789',
          items: [],
          totalAmount: 150.0,
          status: 'Available',
          shippingAddress: '78 Lake Drive, Colombo',
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
      ];
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  String _getGreeting(LocalizationProvider loc) {
    var hour = DateTime.now().hour;
    if (hour < 12) return loc.translate('good_morning');
    if (hour < 17) return loc.translate('good_afternoon');
    return loc.translate('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Background Map Simulation
          Positioned.fill(
            child: _buildMapBackground(),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(loc),
                const SizedBox(height: 12),
                _buildStatusPill(loc),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                          : !_isOnline
                              ? _buildOfflineState()
                              : _availableOrders.isEmpty
                                  ? _buildSearchingState()
                                  : _buildOrderList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Stack(
        children: [
          // Grid lines for map feel
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
          ),
          // Radar if online and searching
          if (_isOnline && _availableOrders.isEmpty)
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(1.1),
                child: AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.15), width: 1),
                          ),
                        ),
                        Container(
                          width: 320 * _radarController.value,
                          height: 320 * _radarController.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(alpha: 1 - _radarController.value),
                              width: 3,
                            ),
                            color: AppColors.primaryGreen.withValues(alpha: (1 - _radarController.value) * 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(alpha: 0.3 * (1 - _radarController.value)),
                                blurRadius: 30,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(LocalizationProvider loc) {
    final userName = _currentUser?.name ?? 'Vihanga Nethmi';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.headerGradient[0],
            context.headerGradient.last,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => driverScaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_getGreeting(loc)},',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: -0.5, curve: Curves.easeOutBack, duration: 600.ms).fadeIn();
  }

  Widget _buildStatusPill(LocalizationProvider loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1.seconds),
              const SizedBox(width: 10),
              Text(
                _isOnline ? loc.translate('you_are_online') : loc.translate('you_are_offline'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary),
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _isOnline = val);
            },
            activeThumbColor: AppColors.primaryGreen,
            activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.4),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2, curve: Curves.easeOutBack, duration: 600.ms).fadeIn();
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_rounded, size: 72, color: context.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Text(
            'Go online to receive deliveries',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Shops in your area are looking for drivers.',
            style: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondary),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 140),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 32),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.15, duration: 1.seconds),
          const SizedBox(height: 28),
          Text(
            'Finding deliveries nearby...',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: context.textPrimary, letterSpacing: -0.5),
          ),
        ],
      ).animate().fadeIn(duration: 800.ms),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 90),
      physics: const BouncingScrollPhysics(),
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        return _buildDeliveryOfferCard(order);
      },
    );
  }

  Widget _buildDeliveryOfferCard(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onPanUpdate: (d) {
        setState(() {
          _tiltY = (_tiltY + d.delta.dx * 0.15).clamp(-5.0, 5.0);
          _tiltX = (_tiltX - d.delta.dy * 0.15).clamp(-5.0, 5.0);
        });
      },
      onPanEnd: (_) {
        setState(() { _tiltX = 0; _tiltY = 0; });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tiltX * math.pi / 180)
          ..rotateY(_tiltY * math.pi / 180),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFF10B981).withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Header: Emerald Gradient Accent + Earnings + Timer & Chat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                      : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: Colors.white, size: 11),
                                const SizedBox(width: 2),
                                Text(
                                  'EXPRESS',
                                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Delivery Pay',
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontSize: 25, fontWeight: FontWeight.w900, color: const Color(0xFF047857)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DriverChatScreen(order: order)),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF047857), size: 18),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              '15 min',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5, color: context.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Locations: Pickup & Dropoff
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _buildLocationRow(
                    icon: Icons.storefront_rounded,
                    iconBgColor: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: 'Pickup at GreenRoots Shop',
                    subtitle: '45 Lotus Road, Colombo',
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 17),
                    height: 16,
                    alignment: Alignment.centerLeft,
                    child: CustomPaint(painter: DashedLinePainter(color: context.textSecondary.withValues(alpha: 0.3))),
                  ),
                  _buildLocationRow(
                    icon: Icons.location_on_rounded,
                    iconBgColor: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    title: 'Dropoff',
                    subtitle: order.shippingAddress.isNotEmpty ? order.shippingAddress : '123 Main St, Colombo',
                  ),
                ],
              ),
            ),
            
            // Action Button: Swipe to Accept
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _InteractiveSwipeButton(
                  onAccept: () async {
                    await _orderService.acceptDelivery(order.id);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.96, 0.96), duration: 300.ms, curve: Curves.easeOutCubic).fadeIn();
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark ? iconColor.withValues(alpha: 0.2) : iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5, color: context.textPrimary),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InteractiveSwipeButton extends StatefulWidget {
  final Future<void> Function()? onAccept;
  const _InteractiveSwipeButton({this.onAccept});

  @override
  State<_InteractiveSwipeButton> createState() => _InteractiveSwipeButtonState();
}

class _InteractiveSwipeButtonState extends State<_InteractiveSwipeButton> {
  double _dragPosition = 0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 50;
        return Stack(
          children: [
            Center(
              child: Text(
                _isCompleted ? 'Accepted!' : 'Swipe to Accept',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            Positioned(
              left: 4 + _dragPosition,
              top: 4,
              bottom: 4,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (_isCompleted) return;
                  setState(() {
                    _dragPosition += details.delta.dx;
                    if (_dragPosition < 0) _dragPosition = 0;
                    if (_dragPosition > maxDrag) {
                      _dragPosition = maxDrag;
                      _isCompleted = true;
                      HapticFeedback.heavyImpact();

                      if (widget.onAccept != null) {
                        widget.onAccept!();
                      }
                      
                      // Navigate to Active Delivery Screen
                      Future.delayed(const Duration(milliseconds: 250), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverActiveDeliveryScreen()),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _dragPosition = 0;
                              _isCompleted = false;
                            });
                          }
                        });
                      });
                    }
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (!_isCompleted) {
                    setState(() {
                      _dragPosition = 0; // Snap back
                    });
                  }
                },
                child: Container(
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Icon(
                    _isCompleted ? Icons.check_rounded : Icons.keyboard_double_arrow_right_rounded, 
                    color: const Color(0xFF022C22), 
                    size: 24
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
      
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double i = 0; i < size.height; i += 5) {
      canvas.drawLine(Offset(0, i), Offset(0, i + 2.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
