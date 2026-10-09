import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../providers/cart_provider.dart';
import '../providers/localization_provider.dart';
import '../services/order_service.dart';
import '../config/app_config.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isFirstOrder = false;
  double _distanceKm = 0.0;
  final LatLng _shopLocation = const LatLng(6.8649, 79.8997); // Nugegoda Shop Location
  LatLng? _customerLocation;

  static const double _ratePerKm = 20.0; // Rs. 20 per 1 km

  @override
  void initState() {
    super.initState();
    _checkFirstOrder();
  }

  Future<void> _checkFirstOrder() async {
    final orders = await OrderService().getOrders();
    if (mounted) {
      setState(() {
        _isFirstOrder = orders.isEmpty;
      });
    }
  }

  double get _rawDeliveryFee {
    if (_customerLocation == null) return 0.0;
    if (_distanceKm <= 0) return 20.0;
    return (_distanceKm * _ratePerKm).clamp(20.0, double.infinity);
  }

  double get _deliveryFee {
    if (_isFirstOrder || _customerLocation == null || context.read<CartProvider>().hasFreeDeliveryReward) return 0.0;
    return _rawDeliveryFee;
  }

  Future<void> _openMapPicker() async {
    final selectedResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (selectedResult != null && selectedResult is Map) {
      setState(() {
        _addressController.text = (selectedResult['address'] ?? '').toString();
        _customerLocation = selectedResult['location'];
        if (_customerLocation != null) {
          final distanceMeters = const Distance().distance(_shopLocation, _customerLocation!);
          _distanceKm = double.parse((distanceMeters / 1000.0).toStringAsFixed(1));
        }
      });
    }
  }

  void _onProceedToCheckout(CartProvider cart) {
    if (cart.items.isEmpty) return;

    final address = _addressController.text.trim();
    if (address.isEmpty || _customerLocation == null) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: context.cardBg,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Location Required',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Selecting a delivery location is required to place your order. Please pin your location on the map before proceeding to checkout.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openMapPicker();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 2,
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(
                'Pin Location',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          deliveryAddress: address,
          deliveryFee: _deliveryFee,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final loc = context.watch<LocalizationProvider>();
    final isDesktop = !Responsive.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildHeader(cart, loc),
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text('🛒', style: TextStyle(fontSize: 48))),
                        ),
                        const SizedBox(height: 20),
                        Text(loc.translate('empty_cart'),
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Discover plants and essentials in the marketplace',
                            style: GoogleFonts.inter(color: context.textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Browse Marketplace', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : Responsive.centered(
                    maxWidth: 1100,
                    child: isDesktop ? _buildDesktopLayout(cart) : _buildMobileLayout(cart),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CartProvider cart, LocalizationProvider loc) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 16),
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
            color: const Color(0xFF34D399).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (scaffoldCtx) => IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (_scaffoldKey.currentState != null) {
                  _scaffoldKey.currentState!.openDrawer();
                } else {
                  Scaffold.of(scaffoldCtx).openDrawer();
                }
              },
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              tooltip: 'Menu',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.translate('my_cart'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (cart.items.isNotEmpty)
                  Text(
                    '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} selected',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA7F3D0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF34D399).withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF34D399), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(CartProvider cart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      physics: const BouncingScrollPhysics(),
      child: Responsive.twoColumn(
        context: context,
        flexLeft: 3,
        flexRight: 2,
        spacing: 24,
        left: _buildItemList(cart),
        right: _buildCheckoutSummary(cart),
      ),
    );
  }

  Widget _buildMobileLayout(CartProvider cart) {
    return Column(
      children: [
        Expanded(
          child: _buildItemList(cart),
        ),
        _buildCheckoutSummary(cart),
      ],
    );
  }

  Widget _buildItemList(CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: Responsive.isMobile(context) ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !Responsive.isMobile(context),
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final item = cart.items[i];
        return Dismissible(
          key: Key(item.productId),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            cart.removeItem(item.productId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('${item.title} removed from cart',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          background: const SizedBox.shrink(),
          secondaryBackground: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: context.textPrimary.withValues(alpha: 0.05),
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              '${AppConfig.baseUrl}${item.imageUrl}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Text('🌿', style: TextStyle(fontSize: 28))),
                            )
                          : const Center(child: Text('🌿', style: TextStyle(fontSize: 28))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${item.price.toStringAsFixed(2)} each',
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          _buildQtyBtn(
                            icon: Icons.remove,
                            onTap: () => cart.decreaseQuantity(item.productId),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          _buildQtyBtn(
                            icon: Icons.add,
                            onTap: () => cart.increaseQuantity(item.productId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().slideX(
                begin: 0.05,
                delay: Duration(milliseconds: 40 * i),
                duration: 250.ms,
              ),
        );
      },
    );
  }

  Widget _buildCheckoutSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delivery Details Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Delivery Details',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  if (_customerLocation != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'PINNED ✓',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        _customerLocation == null ? 'Pin Map' : 'Change',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tappable Location Card
          InkWell(
            onTap: _openMapPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.textPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _addressController.text.isNotEmpty
                              ? _addressController.text
                              : 'Tap to select delivery location on map',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _addressController.text.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                            color: _addressController.text.isNotEmpty ? context.textPrimary : context.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_customerLocation != null && _distanceKm > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '📍 ${_distanceKm.toStringAsFixed(1)} km from nursery',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active Claimed Loyalty Reward Banner
          if (cart.activeRewardTitle != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.15),
                    const Color(0xFF047857).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.activeRewardTitle!,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          cart.discountPercentage > 0
                              ? '${cart.discountPercentage.toInt()}% Loyalty Discount Applied (-Rs. ${cart.discountAmount.toStringAsFixed(0)})'
                              : 'Free Delivery Perk Applied',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => cart.clearReward(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_addressController.text.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: GoogleFonts.inter(color: context.textSecondary)),
                Text('Rs. ${cart.totalPrice.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              ],
            ),
            if (cart.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loyalty Reward (${cart.discountPercentage.toInt()}% OFF)',
                    style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '- Rs. ${cart.discountAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Fee (Rs. 20/km)', style: GoogleFonts.inter(color: context.textSecondary)),
                    if (_customerLocation != null && _distanceKm > 0)
                      Text(
                        'Distance: ${_distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                if (_isFirstOrder || cart.hasFreeDeliveryReward)
                  Row(
                    children: [
                      Text('Rs. ${_rawDeliveryFee.toStringAsFixed(0)}', 
                        style: GoogleFonts.inter(decoration: TextDecoration.lineThrough, color: context.textSecondary, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          cart.hasFreeDeliveryReward ? 'FREE (REWARD)' : 'FREE',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                else
                  Text('Rs. ${_deliveryFee.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: context.border),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: GoogleFonts.outfit(fontSize: 15, color: context.textSecondary, fontWeight: FontWeight.w600)),
              Text('Rs. ${(cart.finalSubtotal + _deliveryFee).toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _onProceedToCheckout(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              icon: const Icon(Icons.payment_rounded, size: 20),
              label: Text('Proceed to Checkout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.textPrimary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: context.textPrimary),
      ),
    );
  }
}
