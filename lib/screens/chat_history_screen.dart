import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'ai_chat_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _chatSessions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _dbService.getChatHistory();
    if (mounted) {
      setState(() {
        _chatSessions = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession(String sessionId, Map<String, dynamic> session, int index) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _chatSessions.removeWhere((s) => s['sessionId'] == sessionId);
    });
    await _dbService.deleteChatSession(sessionId);

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
                  'Consultation deleted',
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
            onPressed: () async {
              // Restore in database
              Uint8List? imgBytes;
              if (session['imageBase64'] != null) {
                try {
                  imgBytes = base64Decode(session['imageBase64']);
                } catch (_) {}
              }
              final List rawMsgs = session['messages'] as List<dynamic>? ?? [];
              final List<Map<String, String>> messages = rawMsgs.map((msg) {
                final map = msg as Map<String, dynamic>;
                return map.map((k, v) => MapEntry(k, v.toString()));
              }).toList();

              await _dbService.saveChatSession(
                session['sessionId'],
                session['title'] ?? 'Restored Chat',
                messages,
                session['imagePath'],
                imgBytes,
              );
              _loadHistory();
            },
          ),
        ),
      );
    }
  }

  void _confirmDeleteSession(String sessionId, Map<String, dynamic> session, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Chat?',
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
          'Are you sure you want to remove this consultation from your chat history?',
          style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSession(sessionId, session, index);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Clear All History?',
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
          'This will permanently delete all your plant consultations and chat history. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _dbService.clearChatHistory();
              _loadHistory();
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

  void _openChat(Map<String, dynamic> session) {
    HapticFeedback.lightImpact();
    Uint8List? imageBytes;
    if (session['imageBase64'] != null) {
      try {
        imageBytes = base64Decode(session['imageBase64']);
      } catch (_) {}
    }

    final rawMessages = session['messages'] as List<dynamic>? ?? [];
    final List<Map<String, String>> messages = rawMessages.map((msg) {
      final map = msg as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          sessionId: session['sessionId'],
          initialMessages: messages,
          imageBytes: imageBytes,
        ),
      ),
    ).then((_) => _loadHistory());
  }

  void _startNewChat() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiChatScreen(),
      ),
    ).then((_) => _loadHistory());
  }

  List<Map<String, dynamic>> get _filteredSessions {
    return _chatSessions.where((session) {
      final title = (session['title'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'With Image') {
        return session['imageBase64'] != null && (session['imageBase64'] as String).isNotEmpty;
      }
      return true;
    }).toList();
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
        return 'Today, ${DateFormat('h:mm a').format(dt)}';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day) {
        return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
      } else if (diff.inDays < 7 && !diff.isNegative) {
        return DateFormat('EEEE, h:mm a').format(dt);
      } else {
        return DateFormat('MMM d, yyyy • h:mm a').format(dt);
      }
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSessions;
    final hasSessions = _chatSessions.isNotEmpty;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: const Color(0xFF10B981),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasSessions) ...[
                            _buildStatsCard(),
                            const SizedBox(height: 16),
                            _buildSearchAndFilters(),
                            const SizedBox(height: 16),
                          ],
                          if (filtered.isEmpty)
                            _buildEmptyState(hasSessions)
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final session = filtered[index];
                                return _buildChatCard(session, index);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'New Diagnosis',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chat History',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Plantora AI Assistant consultations',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA7F3D0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_chatSessions.isNotEmpty)
            IconButton(
              onPressed: _confirmClearAll,
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFCA5A5), size: 24),
              tooltip: 'Clear History',
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final withImagesCount = _chatSessions.where((s) => s['imageBase64'] != null).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.chat_bubble_outline_rounded,
            value: '${_chatSessions.length}',
            label: 'Consultations',
            color: const Color(0xFF10B981),
          ),
          Container(width: 1, height: 32, color: context.border),
          _buildStatItem(
            icon: Icons.center_focus_strong_rounded,
            value: '$withImagesCount',
            label: 'Photo Scans',
            color: const Color(0xFF3B82F6),
          ),
          Container(width: 1, height: 32, color: context.border),
          _buildStatItem(
            icon: Icons.bolt_rounded,
            value: 'Real-time',
            label: 'AI Sync',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search TextField
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search consultations...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('With Image'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : context.border,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> session, int index) {
    final sessionId = (session['sessionId'] ?? '').toString();
    final title = (session['title'] ?? 'Plant Consultation').toString();
    final timestamp = (session['timestamp'] ?? '').toString();
    final formattedDate = _formatDate(timestamp);
    final rawMessages = session['messages'] as List<dynamic>? ?? [];
    final messageCount = rawMessages.length;

    Uint8List? imageBytes;
    if (session['imageBase64'] != null) {
      try {
        imageBytes = base64Decode(session['imageBase64']);
      } catch (_) {}
    }

    return Dismissible(
      key: Key(sessionId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _confirmDeleteSession(sessionId, session, index);
        return false; // Let confirmation handle deletion
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => _openChat(session),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image Thumbnail or Styled Icon
                  Stack(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF044E39), Color(0xFF10B981)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                  width: 54,
                                  height: 54,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Session Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 13, color: context.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$messageCount ${messageCount == 1 ? 'message' : 'messages'}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                    onPressed: () => _confirmDeleteSession(sessionId, session, index),
                    tooltip: 'Delete Chat',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideX(
          begin: 0.05,
          delay: Duration(milliseconds: 30 * index),
          duration: 220.ms,
        );
  }

  Widget _buildEmptyState(bool hasSessions) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌿🤖', style: TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasSessions ? 'No matching consultations' : 'No Chat History Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSessions
                  ? 'Try searching for a different keyword or prompt.'
                  : 'Start a conversation with Plantora AI Assistant for plant diagnosis, care advice, or herbal insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                'Start AI Diagnosis',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
