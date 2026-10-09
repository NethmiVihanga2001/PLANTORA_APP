import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  String _selectedBank = 'Commercial Bank of Ceylon';
  bool _setAsDefault = true;
  bool _isSaving = false;

  final List<String> _banks = [
    'Commercial Bank of Ceylon',
    'Sampath Bank PLC',
    'Hatton National Bank (HNB)',
    'Bank of Ceylon (BOC)',
    'People\'s Bank',
    'Nations Trust Bank (NTB)',
    'HSBC Sri Lanka',
    'Standard Chartered Bank',
    'Other Bank / International',
  ];

  @override
  void initState() {
    super.initState();
    _numberController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _detectBrand(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith('5') || clean.startsWith('2')) return 'Mastercard';
    if (clean.startsWith('34') || clean.startsWith('37')) return 'Amex';
    return 'Visa';
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final cleanNumber = _numberController.text.replaceAll(' ', '');
    final last4 = cleanNumber.length >= 4 ? cleanNumber.substring(cleanNumber.length - 4) : cleanNumber;
    final brand = _detectBrand(cleanNumber);
    final holder = _nameController.text.trim().isEmpty ? 'CARDHOLDER' : _nameController.text.trim().toUpperCase();
    final expiry = _expiryController.text.trim();

    final newCard = {
      'id': 'card_${DateTime.now().millisecondsSinceEpoch}',
      'holderName': holder,
      'type': brand,
      'cardNumber': '•••• •••• •••• $last4',
      'last4': last4,
      'expiry': expiry,
      'bankName': '$_selectedBank $brand',
      'isDefault': _setAsDefault,
      'gradient': brand == 'Visa' ? 'emerald' : 'obsidian',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString('saved_payment_cards_v2');
      List<Map<String, dynamic>> existingCards = [];

      if (cardsJson != null && cardsJson.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cardsJson);
          existingCards = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (_) {}
      }

      if (_setAsDefault) {
        for (var c in existingCards) {
          c['isDefault'] = false;
        }
      }

      existingCards.add(newCard);
      await prefs.setString('saved_payment_cards_v2', jsonEncode(existingCards));

      // Also sync bank details with user backend profile
      final authService = AuthService();
      await authService.updateBankDetails(
        cardHolderName: holder,
        cardNumber: cleanNumber,
        expiryDate: expiry,
        bankName: _selectedBank,
      );

      // Save for quick checkout
      await prefs.setString('saved_card_name', holder);
      await prefs.setString('saved_card_number', _numberController.text);
      await prefs.setString('saved_card_expiry', expiry);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('$brand ending in •••• $last4 added successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save card: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final brand = _detectBrand(_numberController.text);
    final isVisa = brand == 'Visa';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Add Payment Card',
        subtitle: 'Debit or credit card details',
        showMenuButton: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Responsive.centered(
          maxWidth: 680,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Live Interactive Card Preview ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isVisa
                            ? [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF10B981)]
                            : [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isVisa ? const Color(0xFF10B981) : const Color(0xFF0F172A)).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bank Name & Brand
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedBank.split(' ').take(3).join(' '),
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isVisa)
                              Text(
                                'VISA',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              )
                            else
                              SizedBox(
                                width: 36,
                                height: 22,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEB001B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Positioned(
                                      left: 12,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Gold EMV Chip
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFDF79), Color(0xFFD4AF37), Color(0xFFA67C1E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF8C6615), width: 0.8),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.contactless_rounded, color: Colors.white70, size: 22),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Live Card Number Display
                        Text(
                          _numberController.text.isEmpty
                              ? '••••  ••••  ••••  ••••'
                              : _numberController.text,
                          style: GoogleFonts.spaceMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Live Cardholder & Expiry
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARDHOLDER',
                                  style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 1),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nameController.text.isEmpty ? 'YOUR NAME' : _nameController.text.toUpperCase(),
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'EXPIRES',
                                  style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 1),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text,
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Issuing Bank Selector ──
                  _buildSectionTitle('ISSUING BANK'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBank,
                        isExpanded: true,
                        dropdownColor: context.cardBg,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF10B981)),
                        items: _banks.map((b) {
                          return DropdownMenuItem<String>(
                            value: b,
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF10B981)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBank = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Cardholder Name ──
                  _buildSectionTitle('CARDHOLDER NAME'),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. NETHMI VIHANGA',
                      hintStyle: GoogleFonts.inter(fontSize: 13.5, color: context.textTertiary),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF10B981), size: 20),
                      filled: true,
                      fillColor: context.inputFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Cardholder name is required' : null,
                  ),

                  const SizedBox(height: 18),

                  // ── Card Number ──
                  _buildSectionTitle('CARD NUMBER'),
                  TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    style: GoogleFonts.spaceMono(fontSize: 14.5, color: context.textPrimary, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      hintText: '4242 •••• •••• 4242',
                      hintStyle: GoogleFonts.spaceMono(fontSize: 13.5, color: context.textTertiary, letterSpacing: 1.5),
                      prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF10B981), size: 20),
                      filled: true,
                      fillColor: context.inputFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Card number is required';
                      final clean = val.replaceAll(' ', '');
                      if (clean.length < 15) return 'Enter full 16-digit card number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ── Expiry & CVV Row ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('EXPIRY DATE'),
                            TextFormField(
                              controller: _expiryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _CardExpiryFormatter(),
                              ],
                              style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                hintStyle: GoogleFonts.inter(fontSize: 13.5, color: context.textTertiary),
                                prefixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF10B981), size: 20),
                                filled: true,
                                fillColor: context.inputFill,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Required';
                                if (!val.contains('/') || val.length < 5) return 'Invalid MM/YY';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('CVV / CVC'),
                            TextFormField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                              decoration: InputDecoration(
                                hintText: '3 or 4 digits',
                                hintStyle: GoogleFonts.inter(fontSize: 13.5, color: context.textTertiary),
                                prefixIcon: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
                                filled: true,
                                fillColor: context.inputFill,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Required';
                                if (val.length < 3) return 'Invalid CVV';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Set as Default Toggle ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1E16) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _setAsDefault,
                      onChanged: (val) => setState(() => _setAsDefault = val),
                      activeColor: const Color(0xFF10B981),
                      title: Text(
                        'Set as primary payment card',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
                      ),
                      subtitle: Text(
                        'Will be selected by default at plant checkout',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Save Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveCard,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Encrypting & Saving...' : 'Save Payment Card',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 1.1,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

// Format card number with spaces every 4 digits
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Format expiry with slash MM/YY
class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
