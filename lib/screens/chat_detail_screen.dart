import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_animate/flutter_animate.dart';

import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String? chatId;
  final String? otherParticipantName;
  final bool isEmbedded;
  final String? otherParticipantRole; // 'Seller', 'Driver', 'Customer'
  final String? plantTitle;
  final String? plantPrice;
  final String? plantImageUrl;

  const ChatDetailScreen({
    Key? key,
    this.chatId,
    this.otherParticipantName,
    this.isEmbedded = false,
    this.otherParticipantRole,
    this.plantTitle,
    this.plantPrice,
    this.plantImageUrl,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isOtherTyping = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _chatSub;
  bool _isEmojiVisible = false;
  final ImagePicker _picker = ImagePicker();

  late final String _role;
  bool _showProductContextBanner = true;

  String get _chatId => (widget.chatId != null && widget.chatId!.isNotEmpty) ? widget.chatId! : 'chat_generic';
  String get _participantName => (widget.otherParticipantName != null && widget.otherParticipantName!.isNotEmpty) ? widget.otherParticipantName! : 'Plantora User';

  @override
  void initState() {
    super.initState();
    _role = _determineRole();
    _loadMessages();
    _setupSocket();
  }

  String _determineRole() {
    if (widget.otherParticipantRole != null && widget.otherParticipantRole!.isNotEmpty) {
      return widget.otherParticipantRole!;
    }
    final nameLower = _participantName.toLowerCase();
    if (nameLower.contains('rider') ||
        nameLower.contains('courier') ||
        nameLower.contains('delivery') ||
        nameLower.contains('driver')) {
      return 'Rider';
    }
    if (nameLower.contains('nursery') ||
        nameLower.contains('flora') ||
        nameLower.contains('oasis') ||
        nameLower.contains('garden') ||
        nameLower.contains('seller') ||
        nameLower.contains('greenery')) {
      return 'Seller';
    }
    return 'Customer';
  }

  void _setupSocket() {
    _socketService.joinChatRoom(_chatId);
    _chatSub = _socketService.chatStream.listen((data) {
      final incomingChatId = (data['chatId'] ?? data['id'])?.toString();
      if (incomingChatId == _chatId || _chatId == 'chat_generic') {
        if (data['senderId'] != _currentUser?.id) {
          final content = (data['text'] ?? data['message'] ?? '').toString();
          if (content.isNotEmpty) {
            final exists = _messages.any((m) =>
                m is Map &&
                m['timestamp'] == data['timestamp'] &&
                (m['text'] ?? m['message']) == content);
            if (!exists && mounted) {
              setState(() {
                _messages.add(data);
              });
              _scrollToBottom();
            }
          }
        }
      }
    });
  }

  Future<void> _loadMessages() async {
    _currentUser = await _authService.getCurrentUser();
    _currentUser ??= UserModel(
      id: 'customer_guest',
      name: 'Customer',
      email: 'customer@plantora.com',
      joinedAt: DateTime.now(),
      role: 'Customer',
    );

    try {
      final msgs = await _chatService.getChatMessages(_chatId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
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

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _currentUser == null) return;

    if (presetText == null) _textController.clear();
    HapticFeedback.lightImpact();

    final userMsg = {
      'chatId': _chatId,
      'senderId': _currentUser!.id,
      'senderName': _currentUser!.name,
      'text': text,
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'sent',
    };

    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();

    // Broadcast to real backend services (socket + REST fallback)
    _socketService.sendChatMessage(_chatId, text, _currentUser!.id, senderName: _currentUser!.name);
    _chatService.sendMessage(_chatId, _currentUser!.id, text, senderName: _currentUser!.name);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null && _currentUser != null) {
      final bytes = await image.readAsBytes();
      final msg = {
        'senderId': _currentUser!.id,
        'imageBytes': bytes,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sent',
      };

      setState(() {
        _messages.add(msg);
      });
      _scrollToBottom();
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '+94771234567',
    );
    try {
      final bool launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
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
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Center(
              child: imageSource is foundation.Uint8List
                  ? Image.memory(imageSource)
                  : Image.network(imageSource.toString()),
            ),
          ),
        );
      },
    );
  }

  List<String> _getQuickReplies() {
    if (_role == 'Rider') {
      return [
        '📍 Where are you now?',
        '⏰ When will you arrive?',
        '📞 Please call on arrival',
        '🏡 Leave at front gate',
      ];
    }
    if (_role == 'Customer') {
      return [
        '🪴 Is this in stock?',
        '📦 Please pack carefully',
        '🚚 How fast is delivery?',
        '🌿 Can you send care tips?',
      ];
    }
    return [
      '🌿 Is this plant in stock?',
      '🚚 When can you deliver?',
      '💧 How often to water?',
      '📸 Can you share real photos?',
    ];
  }

  @override
  void dispose() {
    _chatSub?.cancel();
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
                    icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),

                // Avatar with Role Indicator Badge
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
                          _role == 'Rider'
                              ? Icons.two_wheeler_rounded
                              : (_role == 'Seller' ? Icons.storefront_rounded : Icons.person_rounded),
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
                          border: Border.all(color: isDark ? const Color(0xFF06231A) : Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name and Status
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

                // Call Action Button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 19),
                  ),
                  onPressed: _makePhoneCall,
                  tooltip: 'Call ${_role}',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Botanical Leaf Canvas Background ─────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.03 : 0.05,
              child: Image.asset(
                'assets/images/plantora_full_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Chat Flow ───────────────────────────────────────────────────
          Column(
            children: [
              // Product context card banner if applicable
              if (_showProductContextBanner && widget.plantTitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.7),
                    border: Border(bottom: BorderSide(color: context.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inquiring about: ${widget.plantTitle} ${widget.plantPrice != null ? "· Rs. ${widget.plantPrice}" : ""}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showProductContextBanner = false),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              // Messages List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                    : _messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 40,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Send a message to $_participantName to start the conversation.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                            itemCount: _messages.length + (_isOtherTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                          // Typing Indicator Bubble at bottom
                          if (index == _messages.length) {
                            return _buildTypingBubble(isDark);
                          }

                          final dynamic rawMsg = _messages[index];
                          final Map<dynamic, dynamic> msg = rawMsg is Map ? rawMsg : {'text': rawMsg.toString()};
                          final isMe = (msg['senderId']?.toString() ?? '') == _currentUser?.id;
                          final text = (msg['text'] ?? msg['message'] ?? msg['content'] ?? '').toString();

                          String timeStr = '';
                          try {
                            final ts = msg['timestamp'] ?? msg['createdAt'] ?? msg['time'];
                            if (ts != null) {
                              final dt = DateTime.tryParse(ts.toString())?.toLocal();
                              if (dt != null) {
                                final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
                                final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                                final min = dt.minute.toString().padLeft(2, '0');
                                timeStr = '$hour12:$min $ampm';
                              }
                            }
                          } catch (_) {}

                          return _buildMessageBubble(msg, text, timeStr, isMe, isDark);
                        },
                      ),
              ),

              // Quick Action Chips Row
              _buildQuickReplyChips(isDark),

              // Bottom Input Bar
              _buildInputArea(context),

              if (_isEmojiVisible) _buildEmojiPicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<dynamic, dynamic> msg,
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
          color: isMe
              ? null
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
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
            // Image Content
            if (msg.containsKey('imageBytes'))
              GestureDetector(
                onTap: () => _showImagePreview(msg['imageBytes']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    msg['imageBytes'],
                    width: 220,
                    fit: BoxFit.cover,
                  ),
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

            // Time and Checkmark
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr.isNotEmpty ? timeStr : 'Just now',
                  style: GoogleFonts.inter(
                    color: isMe ? Colors.white70 : Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: Color(0xFF67E8F9),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildTypingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_participantName is typing',
              style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF10B981)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChips(bool isDark) {
    final replies = _getQuickReplies();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(reply),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                  ],
                ),
                child: Center(
                  child: Text(
                    reply,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final isDark = context.isDark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        color: isDark ? const Color(0xFF06231A) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isEmojiVisible ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _isEmojiVisible = !_isEmojiVisible);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onTap: () {
                          if (_isEmojiVisible) setState(() => _isEmojiVisible = false);
                        },
                        style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                        maxLines: 5,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message to ${_role}...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 21,
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 21,
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send Floating Circle
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: emoji.EmojiPicker(
        onEmojiSelected: (category, emj) {
          _textController.text = _textController.text + emj.emoji;
        },
        config: emoji.Config(
          emojiViewConfig: emoji.EmojiViewConfig(
            columns: 8,
            emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
          ),
          bottomActionBarConfig: const emoji.BottomActionBarConfig(
            showBackspaceButton: true,
            showSearchViewButton: true,
          ),
        ),
      ),
    );
  }
}