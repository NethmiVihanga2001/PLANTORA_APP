import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_animate/flutter_animate.dart';

import '../services/driver_chat_service.dart';
import '../theme/app_theme.dart';

class DriverChatDetailScreen extends StatefulWidget {
  final String threadId;
  final String? otherParticipantName;
  final String? otherParticipantRole; // 'Customer', 'Seller'
  final bool isEmbedded;

  const DriverChatDetailScreen({
    super.key,
    required this.threadId,
    this.otherParticipantName,
    this.otherParticipantRole,
    this.isEmbedded = false,
  });

  @override
  State<DriverChatDetailScreen> createState() => _DriverChatDetailScreenState();
}

class _DriverChatDetailScreenState extends State<DriverChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isOtherTyping = false;
  bool _isEmojiVisible = false;

  String get _participantName =>
      widget.otherParticipantName?.isNotEmpty == true
          ? widget.otherParticipantName!
          : 'Plantora User';

  String get _role => widget.otherParticipantRole ?? 'Customer';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _messages = _getStarterMessages();
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  List<Map<String, dynamic>> _getStarterMessages() {
    final now = DateTime.now();
    if (_role == 'Customer') {
      return [
        {
          'senderId': 'other_id',
          'text': 'Hello! I picked up your Monstera plant from Green Haven Nursery.',
          'timestamp': now.subtract(const Duration(minutes: 15)).toIso8601String(),
        },
        {
          'senderId': 'me',
          'text': 'Awesome! How long until you arrive?',
          'timestamp': now.subtract(const Duration(minutes: 10)).toIso8601String(),
          'status': 'read',
        },
        {
          'senderId': 'other_id',
          'text': 'I am near your location now. Arriving in 10 mins!',
          'timestamp': now.subtract(const Duration(minutes: 2)).toIso8601String(),
        },
      ];
    }
    return [
      {
        'senderId': 'other_id',
        'text': '🌿 Your order is ready for pickup. Please come to the front counter.',
        'timestamp': now.subtract(const Duration(minutes: 20)).toIso8601String(),
      },
      {
        'senderId': 'me',
        'text': 'On my way! ETA 5 minutes.',
        'timestamp': now.subtract(const Duration(minutes: 15)).toIso8601String(),
        'status': 'read',
      },
    ];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty) return;
    if (presetText == null) _textController.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add({
        'senderId': 'me',
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sent',
      });
    });
    _scrollToBottom();
    DriverChatService().sendMessage(widget.threadId, text);
    _simulateRealTimeResponse(text);
  }

  void _simulateRealTimeResponse(String query) {
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isOtherTyping = true);
      _scrollToBottom();
    });
    Timer(const Duration(milliseconds: 2100), () {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _isOtherTyping = false;
        _messages.add({
          'senderId': 'other_id',
          'text': _generateSmartReply(query),
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'delivered',
        });
      });
      _scrollToBottom();
    });
  }

  String _generateSmartReply(String query) {
    final lower = query.toLowerCase();
    if (_role == 'Customer') {
      if (lower.contains('arrive') || lower.contains('where') || lower.contains('time')) {
        return '📍 I am almost there! About 2-3 minutes away. Will call on arrival.';
      }
      if (lower.contains('call')) return '📞 Will call you right away!';
      return 'Got it! On my way with your order safely secured. 🏍️';
    }
    // Seller
    if (lower.contains('ready') || lower.contains('pick')) {
      return '✅ Order is packed and waiting at the pickup counter. Ask for order ${widget.threadId}.';
    }
    return 'Thank you! Let me know if there are any special instructions. 🌿';
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _messages.add({
          'senderId': 'me',
          'imageBytes': bytes,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'sent',
        });
      });
      _scrollToBottom();
      _simulateRealTimeResponse('Here is a photo');
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '+94771234567');
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _showImagePreview(dynamic imageSource) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          child: Center(
            child: imageSource is foundation.Uint8List
                ? Image.memory(imageSource)
                : Image.network(imageSource.toString()),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1E17) : const Color(0xFFF3F7F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF06231A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                if (!widget.isEmbedded)
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : const Color(0xFF0F172A), size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),

                // Avatar with role badge
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 1.8),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                        child: Icon(
                          _role == 'Seller'
                              ? Icons.storefront_rounded
                              : Icons.person_rounded,
                          color: const Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? const Color(0xFF06231A) : Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _participantName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _role.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isOtherTyping ? 'typing...' : '• Active & Online',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _isOtherTyping ? FontWeight.w700 : FontWeight.w500,
                          color: _isOtherTyping ? const Color(0xFF10B981) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Call button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_rounded,
                        color: Color(0xFF10B981), size: 19),
                  ),
                  onPressed: _makePhoneCall,
                  tooltip: 'Call',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                    itemCount: _messages.length + (_isOtherTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingBubble(isDark);
                      }
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == 'me';
                      final text = (msg['text'] ?? '').toString();
                      String timeStr = '';
                      try {
                        final ts = msg['timestamp'];
                        if (ts != null) {
                          final dt = DateTime.tryParse(ts.toString());
                          if (dt != null) {
                            timeStr =
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          }
                        }
                      } catch (_) {}
                      return _buildMessageBubble(msg, text, timeStr, isMe, isDark);
                    },
                  ),
          ),

          // Quick reply chips
          _buildQuickReplyChips(isDark),

          // Input bar
          _buildInputArea(context),

          if (_isEmojiVisible) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    String text,
    String timeStr,
    bool isMe,
    bool isDark,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 3),
            bottomRight: Radius.circular(isMe ? 3 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isMe ? 0.15 : (isDark ? 0.2 : 0.05)),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.containsKey('imageBytes'))
              GestureDetector(
                onTap: () => _showImagePreview(msg['imageBytes']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(msg['imageBytes'], width: 220, fit: BoxFit.cover),
                ),
              )
            else
              Text(
                text,
                style: GoogleFonts.inter(
                  color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  fontSize: 14.5,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: isMe ? Colors.white60 : Colors.grey.shade400,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg['status'] == 'read'
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 13,
                    color: msg['status'] == 'read'
                        ? const Color(0xFF93C5FD)
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildTypingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(delay: Duration(milliseconds: i * 200), duration: 400.ms);
          }),
        ),
      ),
    );
  }

  Widget _buildQuickReplyChips(bool isDark) {
    final replies = _role == 'Customer'
        ? ['📍 Where are you?', '⏰ ETA?', '📞 Call on arrival', '🏡 Leave at gate']
        : ['✅ Picked up', '📦 Order ready?', '📍 At location', '📞 Need directions'];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendMessage(replies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Text(
              replies[i],
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final bool isDark = context.isDark;
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06231A) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isEmojiVisible ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
              color: const Color(0xFF10B981),
              size: 24,
            ),
            onPressed: () => setState(() => _isEmojiVisible = !_isEmojiVisible),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 15, color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                color: Color(0xFF10B981), size: 22),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return emoji.EmojiPicker(
      textEditingController: _textController,
      config: const emoji.Config(
        height: 256,
        checkPlatformCompatibility: true,
      ),
    );
  }
}
