import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/app_drawer.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../widgets/responsive_layout.dart';
import 'chat_detail_screen.dart';
import 'plantora_assistant_screen.dart';
import 'market_screen.dart';
import 'driver_chats_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  List<dynamic> _chats = [];
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All', 'Sellers', 'Delivery', 'AI', 'Unread'
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _chatSub;

  // Split-pane active selection
  String? _selectedChatId;
  String? _selectedOtherParticipantName;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _chatSub = SocketService().chatStream.listen((_) {
      if (mounted) _loadChats();
    });
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    _currentUser = await _authService.getCurrentUser();
    if (_currentUser != null) {
      final fetched = await _chatService.getUserChats(_currentUser!.id);
      _chats = _enrichChats(fetched);
    } else {
      _chats = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _enrichChats(List<dynamic> rawChats) {
    return rawChats.map((c) {
      final chatId = (c['id'] ?? c['chatId'] ?? c['_id'] ?? '').toString();
      final isCustomer = _currentUser?.id == c['customerId'];
      final otherName = (isCustomer ? c['sellerName'] : c['customerName']) ?? 'Plantora User';
      final otherAvatar = isCustomer ? c['sellerAvatar'] : c['customerAvatar'];
      final String otherRole = isCustomer ? 'Seller' : 'Customer';

      return {
        ...c,
        'id': chatId,
        'chatId': chatId,
        'displayName': otherName,
        'displayAvatar': otherAvatar,
        'role': c['role'] ?? otherRole,
        'unreadCount': c['unreadCount'] ?? 0,
        'isOnline': c['isOnline'] ?? true,
        'isRead': c['isRead'] ?? true,
      };
    }).toList();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredChats() {
    List<dynamic> list = _chats;

    // Filter by category
    if (_selectedCategory == 'Sellers') {
      list = list.where((c) => c['role'] == 'Seller').toList();
    } else if (_selectedCategory == 'Delivery') {
      list = list.where((c) => c['role'] == 'Delivery').toList();
    } else if (_selectedCategory == 'AI') {
      list = list.where((c) => c['role'] == 'AI').toList();
    } else if (_selectedCategory == 'Unread') {
      list = list.where((c) => (c['unreadCount'] ?? 0) > 0 || c['isRead'] == false).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((chat) {
        final isCustomer = _currentUser?.id == chat['customerId'];
        final otherName = ((isCustomer ? chat['sellerName'] : chat['customerName']) ?? '').toString().toLowerCase();
        final lastMsg = (chat['lastMessage'] ?? '').toString().toLowerCase();
        final plantCtx = (chat['plantContext'] ?? '').toString().toLowerCase();
        return otherName.contains(query) || lastMsg.contains(query) || plantCtx.contains(query);
      }).toList();
    }

    return list;
  }

  int get _totalUnreadCount {
    return _chats.fold(0, (sum, item) {
      final count = (item['unreadCount'] as int?) ?? (item['isRead'] == false ? 1 : 0);
      return sum + count;
    });
  }

  List<Color> _getAvatarGradient(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('ai') || nameLower.contains('bot')) {
      return [const Color(0xFF10B981), const Color(0xFF047857)];
    } else if (nameLower.contains('driver') || nameLower.contains('courier') || nameLower.contains('eco')) {
      return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    } else if (nameLower.contains('nursery') || nameLower.contains('meesha') || nameLower.contains('terra')) {
      return [const Color(0xFF059669), const Color(0xFF064E3B)];
    } else if (nameLower.contains('flora') || nameLower.contains('bloom')) {
      return [const Color(0xFFEC4899), const Color(0xFFBE185D)];
    }
    
    // Hash-based dynamic gradient
    int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final palettes = [
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFF6366F1), const Color(0xFF4338CA)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    ];
    return palettes[hash % palettes.length];
  }

  Widget _getRoleBadgeIcon(String role) {
    switch (role) {
      case 'AI':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 10),
        );
      case 'Delivery':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 10),
        );
      case 'Seller':
      default:
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 10),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        drawer: const AppDrawer(),
        appBar: PremiumAppBar(
          title: 'Messages',
          subtitle: _totalUnreadCount > 0 ? '$_totalUnreadCount unread conversation${_totalUnreadCount > 1 ? 's' : ''}' : 'Connected with Plantora Network',
          showMenuButton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadChats,
              tooltip: 'Refresh Chats',
            ),
          ],
        ),
        body: _buildListPane(isMobile: true),
        floatingActionButton: _buildFloatingActionButton(),
      );
    }

    // Desktop/Tablet split pane
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Row(
        children: [
          // Left Sidebar Chat List
          SizedBox(
            width: 400,
            child: Column(
              children: [
                _buildSidebarHeader(),
                Expanded(child: _buildListPane(isMobile: false)),
              ],
            ),
          ),
          // Vertical divider line
          Container(
            width: 1,
            color: context.isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
          // Right Active Chat Screen
          Expanded(
            child: _selectedChatId != null
                ? ChatDetailScreen(
                    key: ValueKey(_selectedChatId),
                    chatId: _selectedChatId!,
                    otherParticipantName: _selectedOtherParticipantName!,
                    isEmbedded: true,
                  )
                : _buildPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF0B3A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: _showNewChatOptionsModal,
        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
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

  void _showNewChatOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final isDark = context.isDark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1B12) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Start a Conversation',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with botanical experts, sellers, or support',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModalActionTile(
                  icon: Icons.smart_toy_rounded,
                  iconBg: const Color(0xFF10B981),
                  title: 'Plantora AI Assistant',
                  subtitle: 'Get instant diagnosis, care advice & plant answers 24/7',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlantoraAssistantScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildModalActionTile(
                  icon: Icons.storefront_rounded,
                  iconBg: const Color(0xFF059669),
                  title: 'Browse Sellers & Marketplace',
                  subtitle: 'Find rare plants and chat directly with verified growers',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MarketScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildModalActionTile(
                  icon: Icons.local_shipping_rounded,
                  iconBg: const Color(0xFF2563EB),
                  title: 'Driver & Delivery Support',
                  subtitle: 'Track live orders and talk to your eco-delivery driver',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverChatsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalActionTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBg, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    _currentUser?.name.isNotEmpty == true ? _currentUser!.name[0].toUpperCase() : 'U',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plantora Chats',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _totalUnreadCount > 0 ? '$_totalUnreadCount unread' : 'All conversations',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFA7F3D0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Go to Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildListPane({required bool isMobile}) {
    final isDark = context.isDark;
    final filteredChats = _getFilteredChats();

    return Container(
      color: context.scaffoldBg,
      child: Column(
        children: [
          // Search & Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Modern Glass Search Box
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF122218) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
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
                      hintText: 'Search chats, messages, sellers...',
                      hintStyle: GoogleFonts.inter(
                        color: context.textSecondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
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
                const SizedBox(height: 12),

                // Category Filter Chips Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All', Icons.chat_bubble_outline_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sellers', Icons.storefront_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Delivery', Icons.local_shipping_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('AI', Icons.smart_toy_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unread', Icons.mark_chat_unread_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Main Conversation List
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : filteredChats.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return _buildDismissibleChatCard(chat, isMobile: isMobile)
                              .animate()
                              .fadeIn(duration: 200.ms, delay: (index * 40).ms)
                              .slideY(begin: 0.05, end: 0, duration: 250.ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
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



  Widget _buildChatCard(dynamic chat, {required bool isMobile}) {
    final isDark = context.isDark;
    final isCustomer = _currentUser?.id == chat['customerId'];
    final otherName = (chat['displayName'] ?? (isCustomer ? chat['sellerName'] : chat['customerName']) ?? 'Plantora User').toString();
    final otherAvatar = chat['displayAvatar'] ?? (isCustomer ? chat['sellerAvatar'] : chat['customerAvatar']);
    final isSelected = _selectedChatId == chat['id'];
    final role = (chat['role'] ?? (isCustomer ? 'Seller' : 'Customer')).toString();
    final unreadCount = (chat['unreadCount'] as int?) ?? 0;
    final isUnread = unreadCount > 0 || (chat['isRead'] == false);
    final plantContext = chat['plantContext'] as String?;

    // Time formatting
    String timeStr = 'Just now';
    try {
      if (chat['lastMessageTime'] != null) {
        final dt = DateTime.parse(chat['lastMessageTime'].toString()).toLocal();
        final now = DateTime.now();
        final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
        final yesterday = now.subtract(const Duration(days: 1));
        final isYesterday = yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day;
        if (isToday) {
          final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
          final ampm = dt.hour >= 12 ? 'PM' : 'AM';
          final min = dt.minute.toString().padLeft(2, '0');
          timeStr = '$hour12:$min $ampm';
        } else if (isYesterday) {
          timeStr = 'Yesterday';
        } else {
          timeStr = '${dt.day}/${dt.month}';
        }
      }
    } catch (_) {}

    final gradientColors = _getAvatarGradient(otherName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected && !isMobile
            ? (isDark ? const Color(0xFF1A3326) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF0F1E16) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected && !isMobile
              ? const Color(0xFF10B981)
              : (isUnread
                  ? const Color(0xFF10B981).withOpacity(0.4)
                  : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0))),
          width: isSelected || isUnread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final chatId = (chat['id'] ?? chat['chatId'] ?? chat['_id'] ?? 'chat_generic').toString();
            if (isMobile) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    chatId: chatId,
                    otherParticipantName: otherName,
                    otherParticipantRole: role,
                  ),
                ),
              ).then((_) => _loadChats());
            } else {
              setState(() {
                _selectedChatId = chatId;
                _selectedOtherParticipantName = otherName;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with Dynamic Gradient & Role Badge
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
                        backgroundImage: (otherAvatar != null && otherAvatar.toString().trim().isNotEmpty && otherAvatar != 'null')
                            ? NetworkImage(otherAvatar.toString().startsWith('http')
                                ? otherAvatar
                                : '${AppConfig.baseUrl}$otherAvatar')
                            : null,
                        child: (otherAvatar == null || otherAvatar.toString().trim().isEmpty || otherAvatar == 'null')
                            ? _buildAvatarFallback(otherName, role)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _getRoleBadgeIcon(role),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Name + Role Tag + Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    otherName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 16,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRoleChipColor(role).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: _getRoleChipColor(role),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              color: isUnread ? const Color(0xFF10B981) : context.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Optional Plant Context Badge
                      if (plantContext != null && plantContext.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                plantContext,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Message Subtitle + Ticks + Unread Badge
                      Row(
                        children: [
                          if (chat['lastMessage'] != null && chat['lastMessage'].isNotEmpty) ...[
                            Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: isUnread ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              chat['lastMessage']?.isNotEmpty == true
                                  ? chat['lastMessage']
                                  : 'No messages yet',
                              style: GoogleFonts.inter(
                                color: isUnread
                                    ? context.textPrimary
                                    : context.textSecondary.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadCount > 0 ? '$unreadCount' : 'NEW',
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
    );
  }

  Color _getRoleChipColor(String role) {
    switch (role) {
      case 'AI':
        return const Color(0xFF10B981);
      case 'Delivery':
        return const Color(0xFF3B82F6);
      case 'Seller':
      default:
        return const Color(0xFF059669);
    }
  }

  Widget _buildShimmerList() {
    final isDark = context.isDark;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF122218) : Colors.grey[200]!,
          highlightColor: isDark ? const Color(0xFF1F382A) : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_read_rounded,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Conversations Found',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query or start a new chat with sellers or AI support.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showNewChatOptionsModal,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final isDark = context.isDark;
    return Container(
      color: isDark ? const Color(0xFF062315) : const Color(0xFFF4F8F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 72,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Plantora Workspace Chat',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                'Select a conversation on the left to chat with plant sellers, delivery drivers, or the AI Assistant in real time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'End-to-End Encrypted Botanical Network',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name, String role) {
    final nameLower = name.toLowerCase();
    if (role == 'AI' || nameLower.contains('ai') || nameLower.contains('bot') || nameLower.contains('assistant')) {
      return const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 24,
      );
    } else if (role == 'Delivery' || nameLower.contains('driver') || nameLower.contains('courier') || nameLower.contains('eco')) {
      return const Icon(
        Icons.local_shipping_rounded,
        color: Colors.white,
        size: 22,
      );
    } else {
      return Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    }
  }

  Widget _buildDismissibleChatCard(dynamic chat, {required bool isMobile}) {
    final isCustomer = _currentUser?.id == chat['customerId'];
    final otherName = (isCustomer ? chat['sellerName'] : chat['customerName']) ?? 'Plantora User';

    return Dismissible(
      key: Key('chat_${chat['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'Remove Chat',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to remove the conversation with $otherName?',
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        final removedChat = chat;
        setState(() {
          _chats.removeWhere((c) => c['id'] == chat['id']);
          if (_selectedChatId == chat['id']) {
            _selectedChatId = null;
            _selectedOtherParticipantName = null;
          }
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat with $otherName removed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _chats.add(removedChat);
                });
              },
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: _buildChatCard(chat, isMobile: isMobile),
    );
  }
}

