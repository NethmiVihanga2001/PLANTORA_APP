import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/finance_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_invoice_service.dart';
import '../models/order_model.dart';
import '../widgets/responsive_layout.dart';
import 'order_tracking_screen.dart';
import 'settings/payment_methods_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String deliveryAddress;
  final double deliveryFee;
  
  const PaymentScreen({
    super.key, 
    required this.deliveryAddress,
    this.deliveryFee = 0.0,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  String _selectedCardHolder = 'NETHMI VIHANGA';
  String _selectedCardNumber = '9469 7643 1610 3431';
  String _selectedCardExpiry = '12/24';
  String _selectedCardBrand = 'VISA / DEBIT';
  String _selectedBankName = 'Commercial Bank';

  @override
  void initState() {
    super.initState();
    _loadSavedCard();
  }

  Future<void> _loadSavedCard() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = context.read<AuthProvider>();
    final defaultUserName = auth.user?.name ?? 'NETHMI VIHANGA';

    // 1. Try loading from saved_payment_cards_v2
    final cardsJson = prefs.getString('saved_payment_cards_v2');
    if (cardsJson != null && cardsJson.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cardsJson);
        final list = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        if (list.isNotEmpty) {
          final card = list.firstWhere(
            (c) => c['isDefault'] == true,
            orElse: () => list.first,
          );
          if (mounted) {
            setState(() {
              _selectedCardHolder = (card['holderName'] ?? defaultUserName).toString().toUpperCase();
              _selectedCardNumber = (card['cardNumber'] ?? '9469 7643 1610 3431').toString();
              _selectedCardExpiry = (card['expiry'] ?? '12/24').toString();
              _selectedCardBrand = (card['type'] ?? 'VISA').toString().toUpperCase();
              _selectedBankName = (card['bankName'] ?? 'Commercial Bank').toString();
            });
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Legacy fallback
    final legacyNumber = prefs.getString('saved_card_number');
    final legacyName = prefs.getString('saved_card_name');
    final legacyExpiry = prefs.getString('saved_card_expiry');

    if (legacyNumber != null && legacyNumber.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedCardHolder = (legacyName ?? defaultUserName).toUpperCase();
          _selectedCardNumber = legacyNumber;
          _selectedCardExpiry = legacyExpiry ?? '12/24';
          _selectedCardBrand = legacyNumber.startsWith('5') ? 'MASTERCARD' : 'VISA / DEBIT';
          _selectedBankName = 'Commercial Bank';
        });
        return;
      }
    }

    // 3. Default fallback
    if (mounted) {
      setState(() {
        _selectedCardHolder = defaultUserName.toUpperCase();
        _selectedCardNumber = '9469 7643 1610 3431';
        _selectedCardExpiry = '12/24';
        _selectedCardBrand = 'VISA / DEBIT';
        _selectedBankName = 'Commercial Bank';
      });
    }
  }

  Future<void> _navigateToPaymentMethods() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
    if (mounted) {
      await _loadSavedCard();
    }
  }

  void _processPayment(BuildContext ctx, CartProvider cart) async {
    setState(() => _isLoading = true);

    // Update real bank & card details in backend database
    final authService = AuthService();
    await authService.updateBankDetails(
      cardHolderName: _selectedCardHolder,
      cardNumber: _selectedCardNumber,
      expiryDate: _selectedCardExpiry,
      bankName: _selectedBankName.isNotEmpty ? _selectedBankName : _selectedCardBrand,
    );

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    final orderService = OrderService();
    
    final orderItems = cart.items.map((i) => OrderItem(
      productId: i.productId,
      title: i.title,
      quantity: i.quantity,
      price: i.price,
      sellerId: i.sellerId,
      emoji: i.emoji,
      imageUrl: i.imageUrl,
    )).toList();

    final auth = context.read<AuthProvider>();
    final penalty = auth.user?.cancellationPenalty ?? 0.0;
    final effectiveDeliveryFee = cart.hasFreeDeliveryReward ? 0.0 : widget.deliveryFee;
    final itemsSubtotal = cart.totalPrice;
    final discountAmt = cart.discountAmount;
    final rewardTitle = cart.activeRewardTitle ?? (cart.discountPercentage > 0 ? '${cart.discountPercentage.toInt()}% OFF Loyalty Reward' : null);
    final customerAvatar = auth.user?.avatarUrl;
    final customerName = auth.user?.name ?? 'Customer';
    final totalOrderAmount = cart.finalSubtotal + effectiveDeliveryFee + penalty;

    final result = await orderService.placeOrder(
      items: orderItems,
      totalAmount: totalOrderAmount,
      subtotalAmount: itemsSubtotal,
      discountAmount: discountAmt,
      discountTitle: rewardTitle,
      deliveryFee: effectiveDeliveryFee,
      shippingAddress: widget.deliveryAddress.isEmpty ? 'Colombo, Sri Lanka' : widget.deliveryAddress,
      phone: '+94 77 123 4567',
      customerName: customerName,
      customerAvatar: customerAvatar,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final orderId = result['orderId'] ?? 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      final createdOrder = OrderModel(
        id: orderId,
        customerId: auth.user?.id ?? '',
        customerName: customerName,
        customerAvatar: customerAvatar,
        items: orderItems,
        totalAmount: totalOrderAmount,
        subtotalAmount: itemsSubtotal,
        discountAmount: discountAmt,
        discountTitle: rewardTitle,
        deliveryFee: effectiveDeliveryFee,
        shippingAddress: widget.deliveryAddress.isEmpty ? 'Colombo, Sri Lanka' : widget.deliveryAddress,
        phone: '+94 77 123 4567',
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.clearCancellationPenalty();
      
      final financeService = context.read<FinanceService>();
      financeService.processCustomerPayment(totalOrderAmount, orderId);
      
      cart.clearCart();
      cart.clearReward();
      if (mounted) _showSuccessDialog(context, createdOrder);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment failed', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext ctx, OrderModel order) {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.displayName ?? 'Valued Customer';

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: context.cardBg,
        elevation: 16,
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Header Banner with Emerald Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF012E23),
                      Color(0xFF044E39),
                      Color(0xFF065F46),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Glowing Checkmark Outer Circle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 20),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 14),
                    Text(
                      'Payment Successful!',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Order #${order.id.length > 12 ? order.id.substring(0, 12).toUpperCase() : order.id.toUpperCase()}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA7F3D0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Thank You, $userName!',
                      style: GoogleFonts.outfit(
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your order has been confirmed and sent to the nursery seller for preparation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Payment & Transaction Receipt Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Transaction Date', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Builder(
                                    builder: (context) {
                                      final createdLocal = order.createdAt.toLocal();
                                      final hour12 = createdLocal.hour == 0 ? 12 : (createdLocal.hour > 12 ? createdLocal.hour - 12 : createdLocal.hour);
                                      final ampm = createdLocal.hour >= 12 ? "PM" : "AM";
                                      final min = createdLocal.minute.toString().padLeft(2, '0');
                                      return Text(
                                        '${createdLocal.day.toString().padLeft(2, '0')}/${createdLocal.month.toString().padLeft(2, '0')}/${createdLocal.year} $hour12:$min $ampm',
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Method', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Online Bank Card',
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount Paid', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Action: Track Order Live Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B3A22), Color(0xFF10B981)],
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(ctx);
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                            );
                          },
                          icon: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
                          label: Text('Track Order Live', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary Action: Download PDF Slip Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => PdfInvoiceService.generateAndDownloadInvoice(
                          order: order,
                          customerName: userName,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Download PDF Payment Slip',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10B981)),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tertiary Action: View All Orders Text Button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(ctx, '/orders');
                      },
                      child: Text('View All Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'Valued Customer';
    final penalty = auth.user?.cancellationPenalty ?? 0.0;
    final effectiveDeliveryFee = cart.hasFreeDeliveryReward ? 0.0 : widget.deliveryFee;
    final totalAmount = cart.finalSubtotal + effectiveDeliveryFee + penalty;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Responsive.centered(
                maxWidth: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order & Shipping Summary Box
                    _buildOrderSummaryCard(userName, totalAmount, cart.totalPrice, penalty, cart),
                    const SizedBox(height: 20),

                    // Payment Header & Change Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment & Bank Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Encrypted online card payment processing',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _navigateToPaymentMethods,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'Change',
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
                    const SizedBox(height: 14),

                    // Interactive Live 3D Bank Credit Card - Touch to manage/switch
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: _navigateToPaymentMethods,
                        borderRadius: BorderRadius.circular(22),
                        child: _buildInteractiveCreditCard(userName),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Helper label prompting user that tapping the card switches payment method
                    InkWell(
                      onTap: _navigateToPaymentMethods,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.touch_app_rounded, size: 15, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              'Tap card to manage, edit or select another card',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF10B981)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Pay Now Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B3A22), Color(0xFF10B981)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _processPayment(context, cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pay Rs. ${totalAmount.toStringAsFixed(2)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Checkout & Payment',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '🔒 Encrypted Online Banking Payment',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA7F3D0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCreditCard(String userName) {
    final displayNum = _selectedCardNumber.isEmpty
        ? '•••• •••• •••• ••••'
        : _selectedCardNumber;
    final displayName = _selectedCardHolder.isEmpty
        ? userName.toUpperCase()
        : _selectedCardHolder.toUpperCase();
    final displayExpiry = _selectedCardExpiry.isEmpty ? '12/24' : _selectedCardExpiry;

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF047857),
            Color(0xFF022C22),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Chip + Bank + Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.nfc_rounded, color: Colors.black45, size: 18),
                  ),
                  if (_selectedBankName.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text(
                      _selectedBankName.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA7F3D0).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _selectedCardBrand,
                style: GoogleFonts.inter(
                  color: const Color(0xFFA7F3D0),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Card Number
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayNum,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
          ),

          // Bottom Row: Holder Name & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARDHOLDER NAME',
                      style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFFA7F3D0), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES',
                    style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFFA7F3D0), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayExpiry,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(String userName, double totalAmount, double subtotal, double penalty, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13.5)),
              Text('Rs. ${subtotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
            ],
          ),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loyalty Reward (${cart.discountPercentage.toInt()}% OFF)', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text('- Rs. ${cart.discountAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981))),
              ],
            ),
          ],
          if (widget.deliveryFee > 0 || cart.hasFreeDeliveryReward) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Fee', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13.5)),
                if (cart.hasFreeDeliveryReward)
                  Row(
                    children: [
                      Text('Rs. ${widget.deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.inter(decoration: TextDecoration.lineThrough, color: context.textSecondary, fontSize: 12)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                        child: Text('FREE (REWARD)', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  Text('Rs. ${widget.deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
              ],
            ),
          ],
          if (penalty > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cancellation Fee', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13.5)),
                Text('Rs. ${penalty.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.redAccent)),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 15.5, fontWeight: FontWeight.bold)),
              Text(
                'Rs. ${totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 21, color: const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.deliveryAddress.isEmpty ? 'Colombo, Sri Lanka' : widget.deliveryAddress,
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
