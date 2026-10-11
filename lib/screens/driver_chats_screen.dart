import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/driver_drawer.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'driver_chat_screen.dart';

class DriverChatsScreen extends StatefulWidget {
  final bool showMenuButton;
  const DriverChatsScreen({super.key, this.showMenuButton = false});

  @override
  State<DriverChatsScreen> createState() => _DriverChatsScreenState();
}

class _DriverChatsScreenState extends State<DriverChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Driver's own chats — with Customers & Sellers
  final List<Map<String, dynamic>> _customerChats = [];
  final List<Map<String, dynamic>> _sellerChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadLiveOrders();
  }

  Future<void> _loadLiveOrders() async {
    try {
      final orders = await OrderService().getMyDeliveries();
      if (orders.isEmpty) {
        final all = await OrderService().getOrders();
        orders.addAll(all.where((o) => o.status == 'Out for Delivery' || o.status == 'Shipped' || o.status == 'Preparing'));
      }
      if (orders.isNotEmpty && mounted) {
        setState(() {
          for (final ord in orders) {
            final custExists = _customerChats.any((c) => c['orderId'] == ord.id);
            if (!custExists) {
              _customerChats.insert(0, {
                'id': ord.customerId.isNotEmpty ? ord.customerId : 'cust_${ord.id}',
                'name': ord.customerName.isNotEmpty ? ord.customerName : 'Customer',
                'role': 'Customer',
                'lastMessage': 'Order #${ord.id.length > 6 ? ord.id.substring(0, 6) : ord.id} • ${ord.status}',
                'time': 'Active',
                'unread': 0,
                'isOnline': true,
                'orderId': ord.id,
                'orderContext': ord.items.isNotEmpty ? ord.items.first.title : 'Order Items',
                'avatar': ord.customerAvatar,
                'isRead': true,
                'order': ord,
              });
            }

            final sellExists = _sellerChats.any((c) => c['orderId'] == ord.id);
            if (!sellExists) {
              _sellerChats.insert(0, {
                'id': 'seller_${ord.id}',
                'name': 'Green Haven Nursery',
                'role': 'Seller',
                'lastMessage': 'Order #${ord.id.length > 6 ? ord.id.substring(0, 6) : ord.id} ready for pickup',
                'time': 'Active',
                'unread': 0,
                'isOnline': true,
                'orderId': ord.id,
                'orderContext': ord.items.isNotEmpty ? ord.items.first.title : 'Pickup Confirmation',
                'avatar': null,
                'isRead': true,
                'order': ord,
              });
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    var list = _customerChats;
    if (_selectedFilter == 'Unread') {
      list = list.where((c) => (c['unread'] as int) > 0).toList();
    } else if (_selectedFilter == 'Online') {
      list = list.where((c) => c['isOnline'] == true).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c['name'].toString().toLowerCase().contains(q) ||
          c['lastMessage'].toString().toLowerCase().contains(q) ||
          c['orderId'].toString().toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get _filteredSellers {
    var list = _sellerChats;
    if (_selectedFilter == 'Unread') {
      list = list.where((c) => (c['unread'] as int) > 0).toList();
    } else if (_selectedFilter == 'Online') {
      list = list.where((c) => c['isOnline'] == true).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c['name'].toString().toLowerCase().contains(q) ||
          c['lastMessage'].toString().toLowerCase().contains(q) ||
          c['orderId'].toString().toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int get _totalUnread {
    return [
      ..._customerChats,
      ..._sellerChats,
    ].fold(0, (sum, c) => sum + ((c['unread'] as int?) ?? 0));
  }

  List<Color> _getGradient(String name, String role) {
    if (role == 'Customer') {
      int hash = name.codeUnits.fold(0, (p, e) => p + e);
      final palettes = [
        [const Color(0xFF6366F1), const Color(0xFF4338CA)],
        [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        [const Color(0xFFEC4899), const Color(0xFFBE185D)],
        [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      ];
      return palettes[hash % palettes.length];
    }
    // Seller
    return [const Color(0xFF059669), const Color(0xFF064E3B)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: context.scaffoldBg,
      drawer: widget.showMenuButton ? const DriverDrawer() : null,
      body: Column(
        children: [
          // ─── PREMIUM HEADER ───
          _buildHeader(isDark, scaffoldKey),

          // ─── FILTER CHIPS (above search) ───
          _buildFilterChips(isDark),

          // ─── TABS ───
          _buildTabBar(isDark),

          // ─── SEARCH ───
          _buildSearchBar(isDark),

          // ─── TAB VIEWS ───
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(_filteredCustomers, isDark, 'Customer'),
                _buildChatList(_filteredSellers, isDark, 'Seller'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ──────────── HEADER ────────────
  Widget _buildHeader(bool isDark, GlobalKey<ScaffoldState> scaffoldKey) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.headerGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Hamburger / Back
              GestureDetector(
                onTap: () {
                  if (widget.showMenuButton) {
                    scaffoldKey.currentState?.openDrawer();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.showMenuButton
                        ? Icons.menu_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Driver Chats',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_totalUnread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_totalUnread',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Chat with customers & sellers',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA7F3D0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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

  // ──────────── SEARCH BAR ────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF122218) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search name, order, message...',
            hintStyle: GoogleFonts.inter(
              color: context.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Color(0xFF10B981), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ──────────── FILTER CHIPS ────────────
  Widget _buildFilterChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(child: _filterChip('All', Icons.chat_bubble_outline_rounded, isDark)),
          const SizedBox(width: 8),
          Expanded(child: _filterChip('Unread', Icons.mark_chat_unread_rounded, isDark)),
          const SizedBox(width: 8),
          Expanded(child: _filterChip('Online', Icons.circle, isDark)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, IconData icon, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── TAB BAR ────────────
  Widget _buildTabBar(bool isDark) {
    final customerUnread = _customerChats.fold<int>(
        0, (s, c) => s + ((c['unread'] as int?) ?? 0));
    final sellerUnread =
        _sellerChats.fold<int>(0, (s, c) => s + ((c['unread'] as int?) ?? 0));

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
          _buildTab('Customers', Icons.person_rounded, customerUnread,
              _tabController.index == 0),
          _buildTab('Sellers', Icons.storefront_rounded, sellerUnread,
              _tabController.index == 1),
        ],
      ),
    );
  }

  Widget _buildTab(
      String label, IconData icon, int unread, bool isActive) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : context.textSecondary,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────── CHAT LIST ────────────
  Widget _buildChatList(
      List<Map<String, dynamic>> chats, bool isDark, String role) {
    if (chats.isEmpty) {
      return _buildEmptyState(role);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatCard(chat, isDark)
            .animate()
            .fadeIn(duration: 200.ms, delay: (index * 50).ms)
            .slideY(begin: 0.05, end: 0, duration: 250.ms);
      },
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, bool isDark) {
    final unread = (chat['unread'] as int?) ?? 0;
    final isUnread = unread > 0;
    final isOnline = chat['isOnline'] == true;
    final role = chat['role'] as String;
    final gradientColors = _getGradient(chat['name'] as String, role);
    final name = chat['name'] as String;

    return Dismissible(
      key: Key(chat['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text('Delete',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onDismissed: (_) {
        setState(() {
          if (role == 'Customer') {
            _customerChats.removeWhere((c) => c['id'] == chat['id']);
          } else {
            _sellerChats.removeWhere((c) => c['id'] == chat['id']);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1E16) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF10B981).withOpacity(0.45)
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0)),
            width: isUnread ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              // Open real live order chat with participants (Customer / Rider / Seller)
              OrderModel targetOrder;
              if (chat['order'] != null) {
                targetOrder = chat['order'] as OrderModel;
              } else {
                targetOrder = OrderModel(
                  id: chat['orderId']?.toString() ?? 'ORD-9982',
                  customerId: chat['id']?.toString() ?? 'cust_1',
                  customerName: chat['name']?.toString() ?? (role == 'Customer' ? 'Customer' : 'Store'),
                  items: [],
                  totalAmount: 1500,
                  status: 'Out for Delivery',
                  createdAt: DateTime.now(),
                  shippingAddress: 'Colombo, Sri Lanka',
                  phone: '+94 77 123 4567',
                  driverId: 'driver',
                  driverName: 'Driver',
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverChatScreen(order: targetOrder),
                ),
              );
              // Mark as read
              setState(() {
                if (role == 'Customer') {
                  final i = _customerChats
                      .indexWhere((c) => c['id'] == chat['id']);
                  if (i != -1) {
                    _customerChats[i] = {
                      ..._customerChats[i],
                      'unread': 0,
                      'isRead': true,
                    };
                  }
                } else {
                  final i =
                      _sellerChats.indexWhere((c) => c['id'] == chat['id']);
                  if (i != -1) {
                    _sellerChats[i] = {
                      ..._sellerChats[i],
                      'unread': 0,
                      'isRead': true,
                    };
                  }
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── AVATAR ──
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: gradientColors.first,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      // Online dot
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF0F1E16)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // ── CONTENT ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.outfit(
                                        fontWeight: isUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 15.5,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Role badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _roleColor(role).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: _roleColor(role),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Time
                            Text(
                              chat['time'] as String,
                              style: GoogleFonts.inter(
                                color: isUnread
                                    ? const Color(0xFF10B981)
                                    : context.textSecondary.withOpacity(0.7),
                                fontSize: 11.5,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Order context badge
                        if (chat['orderContext'] != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  role == 'Customer'
                                      ? Icons.eco_rounded
                                      : Icons.storefront_rounded,
                                  size: 11,
                                  color: _roleColor(role),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${chat['orderId']} · ${chat['orderContext']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Last message + unread badge
                        Row(
                          children: [
                            const Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                chat['lastMessage'] as String,
                                style: GoogleFonts.inter(
                                  color: isUnread
                                      ? context.textPrimary
                                      : context.textSecondary.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$unread',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Customer':
        return const Color(0xFF6366F1);
      case 'Seller':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF10B981);
    }
  }

  // ──────────── EMPTY STATE ────────────
  Widget _buildEmptyState(String role) {
    final isCustomer = role == 'Customer';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isCustomer
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF059669))
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCustomer
                    ? Icons.person_search_rounded
                    : Icons.storefront_rounded,
                size: 56,
                color: isCustomer
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isCustomer ? 'No Customer Chats' : 'No Seller Chats',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCustomer
                  ? 'Conversations with customers about their deliveries will appear here.'
                  : 'Chat with sellers to coordinate pickups and confirm order details.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── FAB ────────────
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Start new chat — coming soon!',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
        icon: const Icon(Icons.chat_bubble_rounded,
            color: Colors.white, size: 20),
        label: Text(
          'New Chat',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms, duration: 300.ms);
  }
}
