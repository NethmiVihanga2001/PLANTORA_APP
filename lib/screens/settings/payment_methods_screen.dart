import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Saved Payment Cards
  List<Map<String, dynamic>> _savedCards = [];

  // Saved Bank Accounts
  List<Map<String, dynamic>> _savedBankAccounts = [];

  // Recognized Sri Lankan & Global Banks
  static const List<Map<String, dynamic>> _popularBanks = [
    {
      'name': 'Commercial Bank of Ceylon',
      'code': 'COMB',
      'color': Color(0xFF003882),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'Sampath Bank PLC',
      'code': 'SAMP',
      'color': Color(0xFFF37021),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'Hatton National Bank (HNB)',
      'code': 'HNB',
      'color': Color(0xFF005696),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'Bank of Ceylon (BOC)',
      'code': 'BOC',
      'color': Color(0xFFD4AF37),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'People\'s Bank',
      'code': 'PB',
      'color': Color(0xFFB71C1C),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'Nations Trust Bank (NTB)',
      'code': 'NTB',
      'color': Color(0xFF1B5E20),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'HSBC Sri Lanka',
      'code': 'HSBC',
      'color': Color(0xFFDB0011),
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'Standard Chartered Bank',
      'code': 'SCB',
      'color': Color(0xFF007A3E),
      'icon': Icons.account_balance_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Cards
    final cardsJson = prefs.getString('saved_payment_cards_v2');
    if (cardsJson != null && cardsJson.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cardsJson);
        _savedCards = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        _savedCards = _getDefaultCards();
      }
    } else {
      _savedCards = _getDefaultCards();
      await _persistCards();
    }

    // 2. Load Bank Accounts
    final banksJson = prefs.getString('saved_bank_accounts_v2');
    if (banksJson != null && banksJson.isNotEmpty) {
      try {
        final List decoded = jsonDecode(banksJson);
        _savedBankAccounts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        _savedBankAccounts = _getDefaultBankAccounts();
      }
    } else {
      _savedBankAccounts = _getDefaultBankAccounts();
      await _persistBankAccounts();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getDefaultCards() {
    return [
      {
        'id': 'card_1',
        'holderName': 'NETHMI VIHANGA',
        'type': 'Visa',
        'cardNumber': '4242 •••• •••• 4242',
        'last4': '4242',
        'expiry': '12/28',
        'bankName': 'Commercial Bank Platinum',
        'isDefault': true,
        'gradient': 'emerald',
      },
      {
        'id': 'card_2',
        'holderName': 'NETHMI VIHANGA',
        'type': 'Mastercard',
        'cardNumber': '5412 •••• •••• 8899',
        'last4': '8899',
        'expiry': '05/27',
        'bankName': 'Sampath Bank World',
        'isDefault': false,
        'gradient': 'obsidian',
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultBankAccounts() {
    return [
      {
        'id': 'bank_1',
        'bankName': 'Commercial Bank of Ceylon',
        'bankCode': 'COMB',
        'accountNumber': '•••• •••• 8492',
        'rawAccountNumber': '8045928492',
        'holderName': 'Nethmi Vihanga',
        'branch': 'Colombo Kollupitiya',
        'accountType': 'Savings Account',
        'isDefault': true,
        'isVerified': true,
      },
      {
        'id': 'bank_2',
        'bankName': 'Hatton National Bank (HNB)',
        'bankCode': 'HNB',
        'accountNumber': '•••• •••• 3105',
        'rawAccountNumber': '01902043105',
        'holderName': 'Nethmi Vihanga',
        'branch': 'Kandy City Branch',
        'accountType': 'Savings Account',
        'isDefault': false,
        'isVerified': true,
      },
    ];
  }

  Future<void> _persistCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_payment_cards_v2', jsonEncode(_savedCards));
  }

  Future<void> _persistBankAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_bank_accounts_v2', jsonEncode(_savedBankAccounts));
  }

  void _setDefaultCard(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      for (var card in _savedCards) {
        card['isDefault'] = (card['id'] == id);
      }
    });
    _persistCards();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Default card updated successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeCard(String id, String last4) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Card',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove card ending in •••• $last4?',
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final wasDefault = _savedCards.firstWhere((c) => c['id'] == id)['isDefault'] == true;
                _savedCards.removeWhere((c) => c['id'] == id);
                if (wasDefault && _savedCards.isNotEmpty) {
                  _savedCards.first['isDefault'] = true;
                }
              });
              _persistCards();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card removed from payment options'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _setDefaultBankAccount(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      for (var b in _savedBankAccounts) {
        b['isDefault'] = (b['id'] == id);
      }
    });
    _persistBankAccounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Default bank account updated successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeBankAccount(String id, String bankName) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Bank Account',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        content: Text(
          'Are you sure you want to disconnect $bankName?',
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final wasDefault = _savedBankAccounts.firstWhere((b) => b['id'] == id)['isDefault'] == true;
                _savedBankAccounts.removeWhere((b) => b['id'] == id);
                if (wasDefault && _savedBankAccounts.isNotEmpty) {
                  _savedBankAccounts.first['isDefault'] = true;
                }
              });
              _persistBankAccounts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bank account disconnected'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _copyDetails(String title, String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Modal to Add Real Bank Account
  void _openAddBankModal() {
    String selectedBank = _popularBanks.first['name'];
    String branch = 'Colombo Main Branch';
    String accType = 'Savings Account';
    final accNumberController = TextEditingController();
    final holderController = TextEditingController(text: 'Nethmi Vihanga');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = context.isDark;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1E16) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Link Bank Account',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'Supports Sri Lankan & International Banks',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Select Bank Dropdown
                    Text(
                      'SELECT BANK',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBank,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF10B981)),
                          items: _popularBanks.map((b) {
                            return DropdownMenuItem<String>(
                              value: b['name'] as String,
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_outlined, size: 18, color: b['color'] as Color),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      b['name'] as String,
                                      style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedBank = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Holder Name
                    Text(
                      'ACCOUNT HOLDER NAME',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: holderController,
                      style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Nethmi Vihanga',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textTertiary),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF10B981), size: 20),
                        filled: true,
                        fillColor: context.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Account holder name is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Account Number
                    Text(
                      'ACCOUNT NUMBER',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: accNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'e.g. 8045928492',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textTertiary),
                        prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF10B981), size: 20),
                        filled: true,
                        fillColor: context.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Account number is required';
                        if (val.trim().length < 8) return 'Enter a valid account number (8-16 digits)';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Branch & Account Type Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BRANCH NAME',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: branch,
                                onChanged: (v) => branch = v,
                                style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Branch city',
                                  filled: true,
                                  fillColor: context.inputFill,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACCOUNT TYPE',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: context.inputFill,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: accType,
                                    isExpanded: true,
                                    dropdownColor: context.cardBg,
                                    items: ['Savings Account', 'Current Account', 'Business Account'].map((t) {
                                      return DropdownMenuItem<String>(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: GoogleFonts.inter(fontSize: 12.5, color: context.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => accType = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final rawAcc = accNumberController.text.trim();
                            final last4 = rawAcc.length >= 4 ? rawAcc.substring(rawAcc.length - 4) : rawAcc;
                            final masked = '•••• •••• $last4';

                            // Find bank code
                            final match = _popularBanks.firstWhere(
                              (b) => b['name'] == selectedBank,
                              orElse: () => _popularBanks.first,
                            );

                            final newBank = {
                              'id': 'bank_${DateTime.now().millisecondsSinceEpoch}',
                              'bankName': selectedBank,
                              'bankCode': match['code'],
                              'accountNumber': masked,
                              'rawAccountNumber': rawAcc,
                              'holderName': holderController.text.trim(),
                              'branch': branch.trim().isEmpty ? 'Main Branch' : branch.trim(),
                              'accountType': accType,
                              'isDefault': _savedBankAccounts.isEmpty,
                              'isVerified': true,
                            };

                            setState(() {
                              _savedBankAccounts.add(newBank);
                            });
                            await _persistBankAccounts();

                            // Also sync to AuthService for user database persistence
                            final authService = AuthService();
                            await authService.updateBankDetails(
                              cardHolderName: holderController.text.trim(),
                              cardNumber: rawAcc,
                              expiryDate: 'N/A',
                              bankName: selectedBank,
                            );

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text('$selectedBank linked successfully!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.lock_outline_rounded, size: 18),
                        label: Text(
                          'Save & Verify Bank Account',
                          style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Payment Methods',
        subtitle: 'Manage saved cards & payment options',
        showMenuButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Responsive.centered(
                maxWidth: 720,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Segmented Tab Switcher (Cards vs Bank Accounts) ──
                      Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F1E16) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: context.textSecondary,
                          labelStyle: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800),
                          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600),
                          dividerColor: Colors.transparent,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          onTap: (_) => setState(() {}),
                          tabs: [
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.credit_card_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    const Text('Cards'),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_savedCards.length}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.account_balance_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    const Text('Bank Accounts'),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_savedBankAccounts.length}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Tab View Content ──
                      if (_tabController.index == 0) ...[
                        // Cards View
                        if (_savedCards.isEmpty)
                          _buildEmptyCardsState()
                        else ...[
                          ..._savedCards.map((card) => _buildRealisticCard(card)),
                        ],

                        const SizedBox(height: 20),

                        // Add Card Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddCardScreen()),
                              ).then((value) {
                                if (value == true || (value is Map<String, dynamic>)) {
                                  _loadPaymentData();
                                }
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            label: Text(
                              'Add New Card',
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
                      ] else ...[
                        // Bank Accounts View
                        if (_savedBankAccounts.isEmpty)
                          _buildEmptyBankState()
                        else ...[
                          ..._savedBankAccounts.map((b) => _buildRealisticBankTile(b)),
                        ],

                        const SizedBox(height: 20),

                        // Link Bank Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _openAddBankModal,
                            icon: const Icon(Icons.account_balance_rounded, size: 20),
                            label: Text(
                              'Link New Bank Account',
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
                      ],

                      const SizedBox(height: 26),

                      // ── Bank Security & Encryption Footer ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F1E16) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank-Grade 256-Bit SSL Protection',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Encrypted under PCI-DSS Level 1 & Central Bank of Sri Lanka (CBSL) standards. Sensitive numbers are tokenized.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : const Color(0xFF047857),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Realistic Credit / Debit Card Widget
  Widget _buildRealisticCard(Map<String, dynamic> card) {
    final isDefault = card['isDefault'] == true;
    final isVisa = (card['type'] ?? '').toString().toLowerCase().contains('visa');
    final isEmerald = card['gradient'] == 'emerald' || isVisa;

    final gradientColors = isEmerald
        ? [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF059669)]
        : [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          // Visual Card Face
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDefault ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.15),
                width: isDefault ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background subtle watermark circles
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Bank name + Default badge / Brand
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          card['bankName'] ?? (isVisa ? 'Commercial Bank Visa' : 'Sampath Bank World'),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'DEFAULT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // EMV Gold Chip & Contactless Icon
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF79), Color(0xFFD4AF37), Color(0xFFA67C1E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: Center(
                            child: Container(
                              width: 26,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF8C6615), width: 0.8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Masked 16-Digit Card Number (Embossed look)
                    Text(
                      '••••  ••••  ••••  ${card['last4']}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottom Row: Cardholder & Expiry & Brand Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARDHOLDER',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white60,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (card['holderName'] ?? 'NETHMI VIHANGA').toString().toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white60,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card['expiry'] ?? '12/28',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Brand Logo
                        if (isVisa)
                          Text(
                            'VISA',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          )
                        else
                          SizedBox(
                            width: 38,
                            height: 24,
                            child: Stack(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEB001B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  child: Container(
                                    width: 22,
                                    height: 22,
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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Actions Strip (Set as Default / Copy / Remove)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefaultCard(card['id']),
                    icon: const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFF10B981)),
                    label: Text(
                      'Set as Default',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  )
                else
                  Text(
                    'Primary for checkout',
                    style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                  ),

                Row(
                  children: [
                    IconButton(
                      tooltip: 'Copy card details',
                      onPressed: () => _copyDetails('Card number', '•••• •••• •••• ${card['last4']}'),
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      color: context.textSecondary,
                    ),
                    IconButton(
                      tooltip: 'Remove card',
                      onPressed: () => _removeCard(card['id'], card['last4']),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Realistic Bank Account Card Widget
  Widget _buildRealisticBankTile(Map<String, dynamic> bank) {
    final isDefault = bank['isDefault'] == true;
    final isDark = context.isDark;

    // Pick brand color
    final match = _popularBanks.firstWhere(
      (b) => b['name'] == bank['bankName'] || b['code'] == bank['bankCode'],
      orElse: () => _popularBanks.first,
    );
    final bankColor = match['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E16) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault ? const Color(0xFF10B981) : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          width: isDefault ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Bank Badge, Name, Default Chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bankColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bankColor.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.account_balance_rounded, color: bankColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              bank['bankName'] ?? 'Bank Account',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bank['branch']} • ${bank['accountType']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Default',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Middle: Account Number & Beneficiary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCOUNT NUMBER',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bank['accountNumber'] ?? '•••• •••• 8492',
                      style: GoogleFonts.spaceMono(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ACCOUNT HOLDER',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bank['holderName'] ?? 'Nethmi Vihanga',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions row: Set Default / Copy / Remove
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefaultBankAccount(bank['id']),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                    label: Text(
                      'Set as Primary',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  )
                else
                  Text(
                    'Primary bank for payouts & debits',
                    style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                  ),

                Row(
                  children: [
                    IconButton(
                      tooltip: 'Copy account number',
                      onPressed: () => _copyDetails('Account number', bank['rawAccountNumber'] ?? bank['accountNumber']),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: context.textSecondary,
                    ),
                    IconButton(
                      tooltip: 'Disconnect bank',
                      onPressed: () => _removeBankAccount(bank['id'], bank['bankName']),
                      icon: const Icon(Icons.delete_outline_rounded, size: 17),
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCardsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.credit_card_off_rounded, size: 64, color: context.textTertiary),
            const SizedBox(height: 14),
            Text(
              'No Saved Cards',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a Visa, Mastercard, or Amex for quick plant checkout.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBankState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.account_balance_outlined, size: 64, color: context.textTertiary),
            const SizedBox(height: 14),
            Text(
              'No Bank Accounts Linked',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Link your bank account for secure direct debits and nursery seller payouts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
