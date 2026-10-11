import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class DriverChatScreen extends StatefulWidget {
  final OrderModel order;
  const DriverChatScreen({super.key, required this.order});

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  late IO.Socket _socket;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;
  late String _currentUserName;
  late String _currentUserRole;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _currentUserId = user?.id ?? 'customer_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = user?.name ?? widget.order.customerName;
    _currentUserRole = user?.role ?? 'Customer';

    _loadMessageHistory();
    _initSocket();
  }

  Future<void> _loadMessageHistory() async {
    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/orders/${widget.order.id}/messages'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(data.map((m) => {
              'message': m['text'] ?? m['message'] ?? '',
              'senderId': m['senderId'],
              'senderName': m['senderName'],
              'timestamp': m['timestamp'],
            }));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error loading order chat history: $e');
    }
  }

  void _initSocket() {
    _socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'extraHeaders': AppConfig.defaultHeaders,
      'autoConnect': false,
      'forceNew': true,
    });

    _socket.onConnect((_) {
      print('Connected to Chat Socket');
      _socket.emit('joinOrderRoom', widget.order.id);
      _socket.emit('join_order', widget.order.id);
    });

    void handleIncomingMessage(dynamic data) {
      if (mounted && data is Map) {
        final msgText = (data['message'] ?? data['text'] ?? '').toString();
        if (msgText.isNotEmpty && data['senderId'] != _currentUserId) {
          final exists = _messages.any((m) =>
              m['senderId'] == data['senderId'] &&
              m['timestamp'] == data['timestamp'] &&
              (m['message'] ?? m['text']) == msgText);
          if (!exists) {
            setState(() {
              _messages.add({
                'message': msgText,
                'text': msgText,
                'senderId': data['senderId'],
                'senderName': data['senderName'],
                'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
              });
            });
            _scrollToBottom();
          }
        }
      }
    }

    _socket.on('receiveMessage', handleIncomingMessage);
    _socket.on('order_message_${widget.order.id}', handleIncomingMessage);
    _socket.on('order_message_$_currentUserId', handleIncomingMessage);

    _socket.connect();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    final newMsg = {
      'message': message,
      'text': message,
      'senderId': _currentUserId,
      'senderName': _currentUserName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(newMsg);
    });
    _scrollToBottom();

    // 1. Emit live via Socket.IO
    _socket.emit('sendMessage', {
      'orderId': widget.order.id,
      'message': message,
      'text': message,
      'senderId': _currentUserId,
      'senderName': _currentUserName,
    });

    // 2. Persist with HTTP fallback
    ChatService().sendOrderMessage(
      widget.order.id,
      _currentUserId,
      message,
      senderName: _currentUserName,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _makePhoneCall() async {
    final phone = widget.order.phone;
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      try {
        final bool launched = await launchUrl(
          uri,
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided')),
      );
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B141A) : const Color(0xFFE5DDD5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202C33) : const Color(0xFFF0F2F5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF54656F)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen,
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentUserRole == 'Driver'
                            ? widget.order.customerName
                            : (widget.order.driverName ?? 'Driver'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111B21),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Order #${widget.order.id}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                // Simulated voice call button (Video Call explicitly removed)
                IconButton(
                  icon: Icon(Icons.call, color: isDark ? Colors.white : const Color(0xFF54656F)),
                  onPressed: _makePhoneCall,
                  tooltip: 'Voice Call',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
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
                            'Send a message regarding this order to start the conversation.',
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['senderId'] == _currentUserId;
                final text = msg['message'] ?? '';

                // Parse time nicely
                String timeStr = '';
                try {
                  if (msg['timestamp'] != null) {
                    final dt = DateTime.parse(msg['timestamp'].toString()).toLocal();
                    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
                    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                    final min = dt.minute.toString().padLeft(2, '0');
                    timeStr = '$hour12:$min $ampm';
                  }
                } catch (_) {}

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe
                          ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3))
                          : (isDark ? const Color(0xFF202C33) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && (msg['senderName'] != null && msg['senderName'].toString().isNotEmpty)) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              msg['senderName'].toString(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(right: 36.0, bottom: 4.0),
                          child: Text(
                            text,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : const Color(0xFF111B21),
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: GoogleFonts.inter(
                                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                                  fontSize: 10,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 14,
                                  color: Color(0xFF53BDEB),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(duration: 200.ms).slideY(begin: 0.1, end: 0, duration: 250.ms);
              },
            ),
          ),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    final quickReplies = _currentUserRole == 'Driver'
        ? ["I'm on my way!", "I've arrived.", "Can you come outside?"]
        : ["Where are you?", "I'm waiting here.", "Leave it at the door."];

    return Container(
      color: isDark ? const Color(0xFF111B21) : const Color(0xFFF0F2F5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: quickReplies.map((reply) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    reply,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF00A884) : const Color(0xFF008069),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isDark ? const Color(0xFF005C4B).withOpacity(0.3) : const Color(0xFFD9FDD3),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF00A884).withOpacity(0.5) : const Color(0xFFD9FDD3),
                  ),
                  onPressed: () {
                    _messageController.text = reply;
                    _sendMessage();
                  },
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A3942) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A884),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
