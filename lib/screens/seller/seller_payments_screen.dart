import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/finance_service.dart';
import '../../widgets/premium_app_bar.dart';

class SellerPaymentsScreen extends StatefulWidget {
  const SellerPaymentsScreen({super.key});

  @override
  State<SellerPaymentsScreen> createState() => _SellerPaymentsScreenState();
}

class _SellerPaymentsScreenState extends State<SellerPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceService>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Payments & Ledger',
        subtitle: 'Track customer payments & driver fee cuts',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Balance & Summary Header Cards (100% Overflow Free)
            _buildFinancialOverviewHeader(context, finance, isDark),

            const SizedBox(height: 20),

            // 2. Bank Payout Banner
            _buildPayoutBanner(context, finance, isDark),

            const SizedBox(height: 20),

            // 3. Search & Filter Tabs
            _buildSearchAndFilters(context, isDark),

            const SizedBox(height: 16),

            // 4. Financial Ledger Transactions List
            _buildTransactionsSection(context, finance, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverviewHeader(BuildContext context, FinanceService finance, bool isDark) {
    final netRevenue = finance.sellerBalance;
    final grossPayments = finance.totalGrossCustomerPayments;
    final driverCuts = finance.totalDeliveryFeesDeducted;

    return Column(
      children: [
        // Main Total Net Revenue Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Title + Live Badge (Strictly Constrained)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total Available Balance',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Live Wallet',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rs. ${netRevenue.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Net earnings after automatic driver delivery fee deductions',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

        const SizedBox(height: 12),

        // Sub-Metrics Grid: Customer Paid vs Driver Fee Cuts
        Row(
          children: [
            // Customer Paid Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Customer Paid',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rs. ${grossPayments.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF10B981),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Items + Delivery',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 10.5),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Driver Fee Cuts Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler_rounded, color: Color(0xFFF97316), size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Driver Auto-Cuts',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '- Rs. ${driverCuts.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFF97316),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${finance.driverFee.toStringAsFixed(0)} / pickup',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 10.5),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      ],
    );
  }

  Widget _buildPayoutBanner(BuildContext context, FinanceService finance, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_rounded, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Payouts',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Cashout directly to your bank account',
                  style: TextStyle(color: context.textSecondary, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            onPressed: () => _showWithdrawDialog(context, finance),
            child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Search Input Bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: TextStyle(color: context.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search Order ID or Customer...',
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: context.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Tabs: All, Customer Paid, Driver Fee Cuts, Withdrawals
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12.5),
          tabs: const [
            Tab(text: 'All Transactions'),
            Tab(text: 'Customer Paid (+)'),
            Tab(text: 'Driver Fee Cuts (-)'),
            Tab(text: 'Withdrawals'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(BuildContext context, FinanceService finance, bool isDark) {
    List<Transaction> transactions = List.from(finance.sellerTransactions);

    // Apply Filter Tab Selection
    if (_tabController.index == 1) {
      transactions = transactions.where((t) => t.type == TransactionType.customerPayment).toList();
    } else if (_tabController.index == 2) {
      transactions = transactions.where((t) => t.type == TransactionType.deliveryDeduction).toList();
    } else if (_tabController.index == 3) {
      transactions = transactions.where((t) => t.type == TransactionType.withdrawal).toList();
    }

    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      transactions = transactions.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.orderId.toLowerCase().contains(q) ||
            t.customerName.toLowerCase().contains(q);
      }).toList();
    }

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 42, color: context.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text(
              'No Transactions Found',
              style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'No records match your filter criteria.',
              style: TextStyle(color: context.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionCard(context, tx, isDark);
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction tx, bool isDark) {
    final isCredit = tx.isCredit;
    final isDriverCut = tx.type == TransactionType.deliveryDeduction;

    Color iconBg;
    Color iconColor;
    IconData icon;
    String tagLabel;

    if (tx.type == TransactionType.customerPayment) {
      iconBg = const Color(0xFF10B981).withOpacity(0.12);
      iconColor = const Color(0xFF10B981);
      icon = Icons.add_circle_outline_rounded;
      tagLabel = '+ Received';
    } else if (isDriverCut) {
      iconBg = const Color(0xFFF97316).withOpacity(0.12);
      iconColor = const Color(0xFFF97316);
      icon = Icons.two_wheeler_rounded;
      tagLabel = '- Driver Cut';
    } else {
      iconBg = Colors.blue.withOpacity(0.12);
      iconColor = Colors.blue;
      icon = Icons.account_balance_outlined;
      tagLabel = '- Cashout';
    }

    final formattedDate = '${tx.date.day}/${tx.date.month}/${tx.date.year} at ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Avatar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Amount (strictly bounded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.title,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${isCredit ? '+' : '-'} Rs. ${tx.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Bottom Row: Party Name + Short Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Party: ${tx.customerName}',
                        style: TextStyle(color: context.textSecondary, fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tagLabel,
                        style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  formattedDate,
                  style: TextStyle(color: context.textSecondary.withOpacity(0.6), fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, FinanceService finance) {
    final amountController = TextEditingController();
    String selectedBank = 'Commercial Bank of Ceylon';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        titlePadding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_rounded, color: AppColors.primaryGreen, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Withdraw Seller Earnings',
                style: TextStyle(color: context.textPrimary, fontSize: 14.5, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Balance: Rs. ${finance.sellerBalance.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text('Enter Amount (Rs.):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: context.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'e.g. 5000',
                prefixText: 'Rs. ',
                filled: true,
                fillColor: context.scaffoldBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Select Bank Account:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedBank,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Commercial Bank of Ceylon', child: Text('Commercial Bank (Acc: **** 8842)', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 'Sampath Bank PLC', child: Text('Sampath Bank (Acc: **** 1093)', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 'Hatton National Bank (HNB)', child: Text('HNB Bank (Acc: **** 5521)', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
              onChanged: (val) {
                if (val != null) selectedBank = val;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: context.scaffoldBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final amt = double.tryParse(amountController.text.trim()) ?? 0;
              if (amt <= 0 || amt > finance.sellerBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid withdrawal amount!'), backgroundColor: Colors.red),
                );
                return;
              }

              final success = finance.withdrawSellerFunds(amt, bankName: selectedBank);
              Navigator.pop(ctx);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payout request of Rs. ${amt.toStringAsFixed(0)} submitted successfully!'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Confirm Cashout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
