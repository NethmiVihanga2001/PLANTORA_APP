import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../services/assistant_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../theme/app_theme.dart';

class PlantoraAssistantScreen extends StatefulWidget {
  const PlantoraAssistantScreen({super.key});

  @override
  State<PlantoraAssistantScreen> createState() =>
      _PlantoraAssistantScreenState();
}

class _PlantoraAssistantScreenState extends State<PlantoraAssistantScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AssistantService _assistantService = AssistantService();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;

  // Animation controllers
  late AnimationController _orbController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _orbAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _orbAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_orbController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

  }


  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _floatController.dispose();

    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(ChatMessage(text: trimmed, role: MessageRole.user));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _assistantService.sendMessage(_messages);
      setState(() {
        _messages.add(ChatMessage(text: reply, role: MessageRole.assistant));
      });
    } catch (e) {
      String errorMsg;
      if (e is AssistantException) {
        if (e.statusCode == 401) {
          errorMsg = '⚠️ Connectivity issue. Please check the system configuration.';
        } else if (e.statusCode == 429) {
          errorMsg = '⚠️ System busy. Please wait a moment and try again.';
        } else {
          errorMsg = '⚠️ System Error ${e.statusCode}: ${e.message}';
        }
      } else {
        errorMsg = '⚠️ Network error. Please check your internet connection.\n\nDetails: $e';
      }
      setState(() {
        _messages.add(ChatMessage(text: errorMsg, role: MessageRole.assistant));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Conversation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will delete the entire conversation history.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                setState(() => _messages.clear());
                Navigator.pop(ctx);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated dark forest background
          _buildAnimatedBackground(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _buildMessageList(),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (_, __) {
        return Stack(
          children: [
            // Deep dark gradient base
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.5),
                  radius: 1.2,
                  colors: [
                    context.scaffoldBg,
                    context.scaffoldBg,
                    context.scaffoldBg,
                  ],
                ),
              ),
            ),
            // Orbiting glow orb 1
            Positioned(
              left: MediaQuery.of(context).size.width * 0.5 +
                  math.cos(_orbAnimation.value) * 120,
              top: 200 + math.sin(_orbAnimation.value) * 80,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Orbiting glow orb 2
            Positioned(
              left: 30 + math.cos(_orbAnimation.value + math.pi) * 60,
              top: MediaQuery.of(context).size.height * 0.6 +
                  math.sin(_orbAnimation.value + math.pi) * 50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4ADE80).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle grid lines overlay
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              painter: _GridPainter(),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: _PremiumAppBar(
        floatAnimation: _floatAnimation,
        pulseAnimation: _pulseAnimation,
        onClear: _messages.isEmpty ? null : _clearChat,
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      itemCount: _messages.isEmpty
          ? 1
          : _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_messages.isEmpty) {
          return _buildWelcomeCard();
        }
        if (_isLoading && index == _messages.length) {
          return const TypingIndicator();
        }
        return _AnimatedMessageBubble(
          message: _messages[index],
          index: index,
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value * 0.3),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.cardBg.withOpacity(0.85),
              context.cardBg.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.35),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Animated 3D avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF334155), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.6),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Image.asset(
                        'assets/images/plant_assistant_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello! I\'m Plantora AI',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, __) => Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  const Color(0xFF4ADE80),
                                  const Color(0xFF22C55E),
                                  _pulseAnimation.value,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4ADE80).withOpacity(0.8 * _pulseAnimation.value),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Always online for you',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF4ADE80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: Text(
                "Your premium botanical companion. Ask me anything about plant care, disease identification, gardening tips, and more!",
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PremiumBadge(icon: Icons.local_florist, label: 'Plant Expert', color: Color(0xFF22C55E)),
                _PremiumBadge(icon: Icons.healing, label: 'Disease Detector', color: Color(0xFFFBBF24)),
                _PremiumBadge(icon: Icons.water_drop, label: 'Care Advisor', color: Color(0xFF60A5FA)),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInputBar() {
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
              // Middle Multi-line Text Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _sendMessage,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask anything...',
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

              // Bottom Action Row: (+) Attachment | Spacer | (🎙️) Voice | (↑) Up Arrow Send
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left (+) Attachment Plus Button
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
                        onTap: () => _sendMessage(_controller.text),
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

// ── Premium AppBar ────────────────────────────────────────────────────────────
class _PremiumAppBar extends StatelessWidget {
  final Animation<double> floatAnimation;
  final Animation<double> pulseAnimation;
  final VoidCallback? onClear;

  const _PremiumAppBar({
    required this.floatAnimation,
    required this.pulseAnimation,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, topPadding + 10, 12, 14),
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
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF34D399).withOpacity(0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF34D399).withOpacity(0.3),
                  const Color(0xFF059669).withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF34D399).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plantora AI Assistant',
                  style: GoogleFonts.outfit(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (_, __) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF34D399),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34D399).withOpacity(pulseAnimation.value),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Botanical Expert • Online',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFA7F3D0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 22),
            tooltip: 'Clear history',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ── Animated Message Bubble Wrapper ──────────────────────────────────────────
class _AnimatedMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final int index;
  const _AnimatedMessageBubble({required this.message, required this.index});

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(
      begin: widget.message.role == MessageRole.user
          ? const Offset(0.3, 0)
          : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MessageBubble(message: widget.message),
      ),
    );
  }
}



// ── Premium Badge ─────────────────────────────────────────────────────────────
class _PremiumBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PremiumBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Background Painter ────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.025)
      ..strokeWidth = 1;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
