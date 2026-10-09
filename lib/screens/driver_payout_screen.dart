import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class DriverPayoutScreen extends StatefulWidget {
  const DriverPayoutScreen({super.key});

  @override
  State<DriverPayoutScreen> createState() => _DriverPayoutScreenState();
}

class _DriverPayoutScreenState extends State<DriverPayoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  double _todayEarnings(FinanceService finance) {
    return finance.driverTransactions
        .where((t) => t.isCredit && _isToday(t.date))
        .fold(0.0, (s, t) => s + t.amount);
  }

  int _todayDeliveries(FinanceService finance) {
    return finance.driverTransactions
        .where((t) => t.isCredit && _isToday(t.date))
        .length;
  }

  /// Group credit-only transactions by day, excluding today.
  Map<String, List<Transaction>> _pastDailyGroups(FinanceService finance) {
    final Map<String, List<Transaction>> groups = {};
    for (final tx in finance.driverTransactions) {
      if (!tx.isCredit) continue; // skip bank-transfer rows
      if (_isToday(tx.date)) continue; // today is shown in the green box
      final key = _dayKey(tx.date);
      groups.putIfAbsent(key, () => []).add(tx);
    }
    return groups;
  }

  String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _dayLabel(String key) {
    final dt = DateTime.parse(key);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finance = context.watch<FinanceService>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(isDark, finance),
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEarningsTab(isDark, finance),
                _buildBankDetailsTab(isDark, finance),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, FinanceService finance) {
    final today = _todayEarnings(finance);
    final deliveries = _todayDeliveries(finance);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF022C22), Color(0xFF065F46), Color(0xFF047857)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Nav row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Earnings',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('Delivery charges go directly to your bank',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFA7F3D0), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TODAY'S EARNINGS green card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Earnings",
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${today.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFA7F3D0), size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Resets at midnight · sent to your bank daily',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFFA7F3D0),
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        _statBadge("Today's\nDeliveries", '$deliveries'),
                        const SizedBox(height: 10),
                        _statBadge('Total\nEarned',
                            'Rs.${finance.totalDriverEarnings.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF122218) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        tabs: [
          _tab('Earnings', Icons.receipt_long_rounded, _tabController.index == 0),
          _tab('Bank Details', Icons.account_balance_rounded, _tabController.index == 1),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, bool active) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : context.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── EARNINGS TAB ──────────────────────────────────────────────────────────

  Widget _buildEarningsTab(bool isDark, FinanceService finance) {
    final todayTxns = finance.driverTransactions
        .where((t) => t.isCredit && _isToday(t.date))
        .toList();
    final pastGroups = _pastDailyGroups(finance);
    final sortedDays = pastGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto Bank Transfer',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimary)),
                    Text(
                      'Your delivery earnings are automatically transferred to your linked bank account at the end of each day.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 20),

        // TODAY'S DELIVERIES
        if (todayTxns.isNotEmpty) ...[
          _sectionHeader("Today's Deliveries"),
          const SizedBox(height: 10),
          ...todayTxns.asMap().entries.map((e) => _txCard(e.value, isDark)
              .animate()
              .fadeIn(duration: 200.ms, delay: (e.key * 40).ms)
              .slideY(begin: 0.05)),
          const SizedBox(height: 20),
        ],

        // PAST DAYS
        if (sortedDays.isNotEmpty) ...[
          _sectionHeader('Daily Payment History'),
          const SizedBox(height: 10),
          ...sortedDays.map((dayKey) {
            final txns = pastGroups[dayKey]!;
            final dayTotal =
                txns.fold(0.0, (s, t) => s + t.amount);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dayGroupHeader(dayKey, dayTotal, txns.length, isDark),
                const SizedBox(height: 8),
                ...txns
                    .asMap()
                    .entries
                    .map((e) => _txCard(e.value, isDark)
                        .animate()
                        .fadeIn(duration: 200.ms, delay: (e.key * 40).ms)
                        .slideY(begin: 0.05)),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],

        if (todayTxns.isEmpty && sortedDays.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 56,
                      color: context.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No earnings yet',
                      style: GoogleFonts.outfit(
                          color: context.textSecondary, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Complete deliveries to start earning!',
                      style: GoogleFonts.inter(
                          color: context.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.textSecondary,
          letterSpacing: 1.5),
    );
  }

  Widget _dayGroupHeader(
      String dayKey, double total, int count, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E16) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(_dayLabel(dayKey),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: context.textPrimary)),
              const SizedBox(width: 8),
              Text('$count delivery${count != 1 ? 'ies' : 'y'}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: context.textSecondary)),
            ],
          ),
          Text(
            'Rs. ${total.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: const Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }

  Widget _txCard(Transaction tx, bool isDark) {
    final color = const Color(0xFF10B981);
    final timeStr = _formatTime(tx.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E16) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward_rounded,
                color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (tx.customerName.isNotEmpty) ...[
                      Icon(Icons.storefront_outlined,
                          size: 11, color: context.textSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(tx.customerName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                                color: context.textSecondary, fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.access_time_rounded,
                        size: 11, color: context.textSecondary),
                    const SizedBox(width: 3),
                    Text(timeStr,
                        style: GoogleFonts.inter(
                            color: context.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ Rs. ${tx.amount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RECEIVED',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BANK DETAILS TAB ──────────────────────────────────────────────────────

  Widget _buildBankDetailsTab(bool isDark, FinanceService finance) {
    final bank = finance.driverBankAccount;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1D4ED8).withOpacity(isDark ? 0.3 : 0.07),
                const Color(0xFF3B82F6).withOpacity(isDark ? 0.15 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: Color(0xFF3B82F6), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure Bank Transfer',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimary)),
                    Text(
                      'Your delivery charges are automatically transferred to this account at the end of each day. No manual withdrawal needed.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 0.08, duration: 300.ms).fadeIn(),
        const SizedBox(height: 20),

        if (bank != null) ...[
          _buildLinkedBankCard(bank, isDark),
          const SizedBox(height: 16),
          _buildChangeButton(isDark),
        ] else ...[
          _buildNoBankCard(isDark),
          const SizedBox(height: 16),
          _buildAddBankButton(isDark),
        ],
      ],
    );
  }

  Widget _buildLinkedBankCard(DriverBankAccount bank, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bank.bankName,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(bank.branch,
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              if (bank.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text('Verified',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Account Holder',
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 11)),
                Text(bank.accountHolderName,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Account Number',
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 11)),
                Text(bank.maskedAccount,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ]),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildChangeButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: () => _showAddBankSheet(context),
      icon: const Icon(Icons.edit_rounded, size: 16),
      label: const Text('Change Bank Account'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF10B981),
        side: const BorderSide(color: Color(0xFF10B981)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 0),
      ),
    );
  }

  Widget _buildNoBankCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E16) : const Color(0xFFF8FFFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
            width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_outlined,
              size: 48, color: context.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No bank account linked',
              style: GoogleFonts.outfit(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Add your bank account so earnings can be transferred automatically at the end of each day.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: context.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBankButton(bool isDark) {
    return ElevatedButton.icon(
      onPressed: () => _showAddBankSheet(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Bank Account'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 0),
        textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── ADD BANK BOTTOM SHEET ─────────────────────────────────────────────────

  void _showAddBankSheet(BuildContext context) {
    final finance = context.read<FinanceService>();
    final existing = finance.driverBankAccount;
    final nameCtrl = TextEditingController(text: existing?.accountHolderName ?? '');
    final accCtrl = TextEditingController(text: existing?.accountNumber ?? '');
    final branchCtrl = TextEditingController(text: existing?.branch ?? '');
    String selectedBank = existing?.bankName ?? FinanceService.sriLankanBanks.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 30),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1E16) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(existing != null ? 'Update Bank Account' : 'Add Bank Account',
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary)),
                  const SizedBox(height: 20),

                  // Bank picker
                  Text('Bank Name',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration: _inputDecoration('Select bank', isDark),
                    items: FinanceService.sriLankanBanks
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.inter(fontSize: 14))))
                        .toList(),
                    onChanged: (v) => setLocal(() => selectedBank = v!),
                  ),
                  const SizedBox(height: 16),
                  _formField('Account Holder Name', nameCtrl, isDark, 'Full name as per bank'),
                  const SizedBox(height: 16),
                  _formField('Account Number', accCtrl, isDark, 'e.g. 1234567890', numeric: true),
                  const SizedBox(height: 16),
                  _formField('Branch', branchCtrl, isDark, 'e.g. Colombo 03'),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || accCtrl.text.trim().isEmpty) return;
                      finance.saveDriverBankAccount(DriverBankAccount(
                        bankName: selectedBank,
                        accountNumber: accCtrl.text.trim(),
                        accountHolderName: nameCtrl.text.trim(),
                        branch: branchCtrl.text.trim(),
                        bankCode: '',
                      ));
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Save Bank Account'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: isDark ? const Color(0xFF1A2E22) : const Color(0xFFF8FFFE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, bool isDark, String hint,
      {bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
                fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
          decoration: _inputDecoration(hint, isDark),
        ),
      ],
    );
  }
}
