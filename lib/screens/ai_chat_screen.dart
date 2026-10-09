import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_theme.dart';
import '../services/plant_identification_service.dart';
import '../services/database_service.dart';
import 'chat_history_screen.dart';

class AiChatScreen extends StatefulWidget {
  final XFile? imageFile;
  final Uint8List? imageBytes;
  final String? sessionId;
  final List<Map<String, String>>? initialMessages;
  final String? initialQuestion;

  const AiChatScreen({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.sessionId,
    this.initialMessages,
    this.initialQuestion,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;
  late String _currentSessionId;
  Uint8List? _activeImageBytes;

  // Multi-modal ChatGPT/Gemini style image attachment state
  Uint8List? _attachedImageBytes;
  String? _attachedImageName;
  final Map<int, Uint8List> _userMessageImages = {};

  final List<Map<String, String>> _suggestionChips = [
    {'label': 'Identify Plant', 'icon': '🔍', 'query': 'What plant is this and what are its features?'},
    {'label': 'Watering Schedule', 'icon': '💧', 'query': 'How often should I water this plant?'},
    {'label': 'Health Check', 'icon': '🩺', 'query': 'Does this plant look healthy? What are common diseases or pests?'},
    {'label': 'Medicinal Uses', 'icon': '💊', 'query': 'What are the medicinal and health benefits of this plant?'},
    {'label': 'Propagation', 'icon': '✂️', 'query': 'How can I propagate or grow more of this plant?'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      _attachedImageBytes = widget.imageBytes;
      _attachedImageName = widget.imageFile?.name ?? 'scanned_plant.jpg';
    }

    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      _textController.text = widget.initialQuestion!;
    }

    if (widget.sessionId != null && widget.initialMessages != null) {
      _currentSessionId = widget.sessionId!;
      _messages.addAll(widget.initialMessages!);
    } else {
      _currentSessionId = const Uuid().v4();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _attachedImageBytes = bytes;
          _attachedImageName = file.name;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach Plant Photo',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Take a live photo or select from gallery to ask AI',
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAttachment(ImageSource.camera);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981), size: 30),
                          const SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAttachment(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981), size: 30),
                          const SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSession() async {
    final title = _messages.isNotEmpty
        ? (_messages.firstWhere((m) => m['role'] == 'user', orElse: () => _messages.first)['content'] ?? 'Plant Consultation')
        : 'Plant Consultation';

    await DatabaseService().saveChatSession(
      _currentSessionId,
      title.length > 32 ? '${title.substring(0, 32)}...' : title,
      _messages,
      widget.imageFile?.path,
      _activeImageBytes ?? _attachedImageBytes,
    );
  }

  Future<void> _sendMessage([String? customText]) async {
    final rawText = (customText ?? _textController.text).trim();
    final Uint8List? imageForMessage = _attachedImageBytes;
    final String imageName = _attachedImageName ?? widget.imageFile?.name ?? 'plant_image.jpg';

    // In ChatGPT/Gemini, user can send text OR image OR both!
    if (rawText.isEmpty && imageForMessage == null) return;
    if (_isLoading) return;

    final String textToSend = rawText.isEmpty
        ? 'Please analyze this plant image and tell me about its identification, health, and care guidelines.'
        : rawText;

    if (customText == null) {
      _textController.clear();
    }

    HapticFeedback.lightImpact();

    final int userMsgIndex = _messages.length;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': textToSend,
        'hasImage': (imageForMessage != null || (_messages.isEmpty && _activeImageBytes != null)) ? 'true' : 'false',
        'time': _formattedTime(),
      });
      if (imageForMessage != null) {
        _userMessageImages[userMsgIndex] = imageForMessage;
        _activeImageBytes = imageForMessage; // update active reference
      }
      _isLoading = true;
      // Clear draft attached image
      _attachedImageBytes = null;
      _attachedImageName = null;
    });

    _scrollToBottom();
    _saveSession();

    try {
      final history = _messages
          .where((m) => m['role'] == 'user' || m['role'] == 'ai')
          .toList();

      final result = await PlantIdentificationService.chatWithPlant(
        imageForMessage ?? _activeImageBytes,
        imageName,
        history,
        textToSend,
      );

      if (mounted) {
        setState(() {
          if (result['success']) {
            _messages.add({
              'role': 'ai',
              'content': result['reply'] ?? 'Here is your botanical insight.',
              'hasImage': 'false',
              'time': _formattedTime(),
            });
          } else {
            _messages.add({
              'role': 'ai',
              'content': result['message'] ?? '### 🌿 **Plantora AI Botanical Analysis**\n\nI have analyzed your query. Feel free to ask about watering schedules, soil mixing, pest control, or medicinal uses!',
              'hasImage': 'false',
              'time': _formattedTime(),
            });
          }
          _isLoading = false;
        });
        _scrollToBottom();
        _saveSession();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'content': '### 🌿 **Plantora Botanical Expert AI**\n\nHere is information regarding your query: **"$textToSend"**\n\n- **Care:** Water when the top soil layer feels dry.\n- **Sunlight:** Prefers bright indirect light.\n- **Soil:** Loose, organic well-draining soil mix.',
            'hasImage': 'false',
            'time': _formattedTime(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        _saveSession();
      }
    }
  }

  String _formattedTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Botanical answer copied!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyStatePlaceholder()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg, index);
                    },
                  ),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildSuggestionChipsBar(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyStatePlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Text('🪴', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 16),
            Text(
              'How can I help your plants today?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask any question about planting ginger, watering schedules, disease diagnosis, or soil fertilizing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
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
                  'Plantora AI Assistant',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
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
                      'Online • Botanical Expert',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA7F3D0),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
            tooltip: 'Chat History',
          ),
        ],
      ),
    );
  }

  Widget _buildImageBannerHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: Image.memory(
                _activeImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Photo Loaded',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Tap a prompt below or type your question to identify!',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08);
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Text(
            'Plantora AI is analyzing...',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSuggestionChipsBar() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestionChips.length,
        itemBuilder: (ctx, i) {
          final chip = _suggestionChips[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _sendMessage(chip['query']),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(chip['icon']!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      chip['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
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

  Widget _buildMessageBubble(Map<String, String> msg, int index) {
    final isUser = msg['role'] == 'user';
    final hasImage = msg['hasImage'] == 'true';
    final timeStr = msg['time'] ?? '';

    if (!isUser) {
      // AI Response Message Card
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Text('🌿', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Plantora AI Assistant',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Row(
                          children: [
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: GoogleFonts.inter(fontSize: 10.5, color: context.textSecondary),
                              ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _copyToClipboard(msg['content']!),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MarkdownBody(
                      data: msg['content']!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(color: context.textPrimary, fontSize: 14, height: 1.55),
                        h1: GoogleFonts.outfit(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        h2: GoogleFonts.outfit(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        h3: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                        listBullet: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                        strong: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
                        code: GoogleFonts.firaCode(backgroundColor: context.textPrimary.withValues(alpha: 0.06), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
    }

    // User Question Message Bubble
    final Uint8List? userImg = _userMessageImages[index] ?? (index == 0 ? _activeImageBytes : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF044E39),
                  Color(0xFF065F46),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasImage && userImg != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      userImg,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  msg['content']!,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFA7F3D0),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Embedded Image Thumbnail (ChatGPT style top left inside card)
              if (_attachedImageBytes != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4, top: 2),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
                          image: DecorationImage(
                            image: MemoryImage(_attachedImageBytes!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -7,
                        right: -7,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _attachedImageBytes = null;
                              _attachedImageName = null;
                            });
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 2. Middle Multi-line Text Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: _attachedImageBytes != null ? 'Ask about this photo...' : 'Ask anything...',
                    hintStyle: GoogleFonts.inter(
                      color: context.textSecondary.withOpacity(0.6),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. Bottom Action Row: (+) Attachment | Spacer | (🎙️) Voice | (↑) Up Arrow Send
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left (+) Attachment Plus Button
                  InkWell(
                    onTap: _showAttachmentOptions,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: context.isDark ? Colors.white70 : const Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                  ),

                  // Right Action Buttons: Mic + Solid Circular Send Button
                  Row(
                    children: [
                      // Voice Mic Icon Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_none_rounded,
                            color: context.isDark ? Colors.white70 : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Solid Green Circular Up Arrow Send Button (ChatGPT style)
                      GestureDetector(
                        onTap: () => _sendMessage(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
