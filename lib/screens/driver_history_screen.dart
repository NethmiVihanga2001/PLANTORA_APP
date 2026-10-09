import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  List<Map<String, dynamic>> _history = [
    {'id': 'ORD-20261007-00142', 'date': 'Today, 2:30 PM', 'amount': '350.00', 'status': 'Completed', 'from': 'GreenRoots Shop', 'to': 'No. 45 Lotus Rd', 'distance': '3.2 km', 'duration': '15 min'},
    {'id': 'ORD-20261007-00141', 'date': 'Today, 11:15 AM', 'amount': '280.00', 'status': 'Completed', 'from': 'Green Thumb Nursery', 'to': 'No. 12 Temple Ave', 'distance': '2.8 km', 'duration': '12 min'},
    {'id': 'ORD-20261006-00138', 'date': 'Yesterday, 4:45 PM', 'amount': '420.00', 'status': 'Completed', 'from': 'Flora Lanka', 'to': 'No. 7 Marine Drive', 'distance': '4.1 km', 'duration': '18 min'},
    {'id': 'ORD-20261006-00135', 'date': 'Yesterday, 1:20 PM', 'amount': '310.00', 'status': 'Completed', 'from': 'GreenRoots Shop', 'to': 'No. 88 Galle Rd', 'distance': '3.5 km', 'duration': '16 min'},
    {'id': 'ORD-20261005-00130', 'date': '2 days ago, 3:00 PM', 'amount': '450.00', 'status': 'Completed', 'from': 'Green Thumb Nursery', 'to': 'No. 22 High Level Rd', 'distance': '5.0 km', 'duration': '22 min'},
    {'id': 'ORD-20261005-00128', 'date': '2 days ago, 10:45 AM', 'amount': '190.00', 'status': 'Cancelled', 'from': 'Flora Lanka', 'to': 'No. 3 Park St', 'distance': '1.9 km', 'duration': '—'},
  ];

  void _deleteOrder(Map<String, dynamic> order, int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _history.removeWhere((item) => item['id'] == order['id']);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Order #${order['id']} removed from history',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1F2937),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFF34D399),
            onPressed: () {
              setState(() {
                if (index <= _history.length) {
                  _history.insert(index, order);
                } else {
                  _history.add(order);
                }
              });
            },
          ),
        ),
      );
    }
  }

  void _confirmDeleteOrder(Map<String, dynamic> order, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF122218) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Record?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete Order #${order['id']} from your delivery history?',
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOrder(order, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backupHistory = List<Map<String, dynamic>>.from(_history);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF122218) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Clear Delivery History?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will delete all delivery history records. Are you sure you want to clear your history?',
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              setState(() {
                _history.clear();
              });

              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All delivery history cleared',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFF1F2937),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'UNDO',
                      textColor: const Color(0xFF34D399),
                      onPressed: () {
                        setState(() {
                          _history = backupHistory;
                        });
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Clear All', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsSheet(Map<String, dynamic> order, int originalIndex) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = order['status'] == 'Completed';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF122218) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order['status'],
                    style: GoogleFonts.inter(
                      color: isCompleted ? const Color(0xFF065F46) : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today_rounded, 'Date & Time', order['date'], isDark),
            const SizedBox(height: 10),
            _detailRow(Icons.store_rounded, 'Pickup Location', order['from'], isDark),
            const SizedBox(height: 10),
            _detailRow(Icons.location_on_rounded, 'Delivery Address', order['to'], isDark),
            const SizedBox(height: 10),
            _detailRow(Icons.directions_car_rounded, 'Distance & Duration', '${order['distance']} • ${order['duration']}', isDark),
            const SizedBox(height: 10),
            _detailRow(Icons.payments_rounded, 'Earnings', 'Rs. ${order['amount']}', isDark, isHighlight: true),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteOrder(order, originalIndex);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                    label: Text(
                      'Delete Record',
                      style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065F46),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val, bool isDark, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isHighlight ? const Color(0xFF065F46) : Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
        const Spacer(),
        Text(
          val,
          style: GoogleFonts.inter(
            color: isHighlight ? const Color(0xFF065F46) : (isDark ? Colors.white : Colors.black),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int completedCount = _history.where((o) => o['status'] == 'Completed').length;
    int cancelledCount = _history.where((o) => o['status'] == 'Cancelled').length;
    double totalEarned = _history
        .where((o) => o['status'] == 'Completed')
        .fold(0.0, (sum, o) => sum + double.parse(o['amount']));

    final filteredList = _history.where((order) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Today') return order['date'].toString().contains('Today');
      if (_selectedFilter == 'This Week') return order['date'].toString().contains('Today') || order['date'].toString().contains('Yesterday');
      if (_selectedFilter == 'This Month') return true;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1F17) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── HEADER ──
          _buildHeader(),

          // ── STATS CARD ──
          _buildStatsCard(completedCount, cancelledCount, totalEarned),

          // ── FILTERS ──
          _buildFilters(),

          // ── LIST / EMPTY STATE ──
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 30),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, i) {
                      final order = filteredList[i];
                      return _buildHistoryCard(order, isDark, i);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF022C22), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery History', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Completed rides & earnings', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _confirmClearAll,
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFCA5A5), size: 24),
              tooltip: 'Clear History',
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int completed, int cancelled, double earned) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF065F46).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(completed.toString(), 'Completed'),
            Container(width: 1, height: 40, color: Colors.white24),
            _statItem(cancelled.toString(), 'Cancelled'),
            Container(width: 1, height: 40, color: Colors.white24),
            _statItem('Rs. ${earned.toStringAsFixed(0)}', 'Total Earned'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final active = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = filter);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF065F46) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: active ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: active ? [BoxShadow(color: const Color(0xFF065F46).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Text(
                filter,
                style: GoogleFonts.inter(
                  color: active ? Colors.white : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF065F46).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 40,
                color: Color(0xFF065F46),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.95, end: 1.05, duration: 2.seconds),
            const SizedBox(height: 20),
            Text(
              'No Delivery History',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _history.isEmpty
                  ? 'Your delivery history has been cleared.'
                  : 'No orders match the selected filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order, bool isDark, int index) {
    final isCompleted = order['status'] == 'Completed';
    final orderId = order['id'].toString();

    return Dismissible(
      key: Key(orderId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _confirmDeleteOrder(order, index);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF122218) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _showOrderDetailsSheet(order, index),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isCompleted ? Icons.check_rounded : Icons.close_rounded,
                        color: isCompleted ? const Color(0xFF065F46) : Colors.red, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(text: 'Order #${order['id']} '),
                              TextSpan(text: 'Rs. ${order['amount']}', style: const TextStyle(color: Color(0xFF065F46))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(order['date'], style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDeleteOrder(order, index),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Delete',
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1),
    );
  }
}
