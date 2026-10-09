import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) _buildAvatar(),
          if (!_isUser) const SizedBox(width: 10),
          Flexible(
            child: _isUser ? _buildUserBubble(context) : _buildAssistantBubble(context),
          ),
        ],
      ),
    );
  }

  // ── User bubble: premium gradient pill ────────────────────────────────────
  Widget _buildUserBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4ADE80),
            Color(0xFF15803D),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Assistant bubble: dark glassmorphic card ──────────────────────────────
  Widget _buildAssistantBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: MarkdownBody(
        data: message.text,
        styleSheet: _markdownStyle(context),
        shrinkWrap: true,
        softLineBreak: true,
      ),
    );
  }

  // ── Markdown style sheet ──────────────────────────────────────────────────
  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    return MarkdownStyleSheet(
      p: GoogleFonts.inter(
        fontSize: 14.5,
        color: context.textPrimary.withOpacity(0.9),
        height: 1.6,
      ),
      strong: GoogleFonts.inter(
        fontSize: 14.5,
        color: const Color(0xFF4ADE80),
        fontWeight: FontWeight.w700,
      ),
      em: GoogleFonts.inter(
        fontSize: 14.5,
        color: const Color(0xFF86EFAC),
        fontStyle: FontStyle.italic,
      ),
      h1: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
        height: 1.3,
      ),
      h2: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4ADE80),
        height: 1.3,
      ),
      h3: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF86EFAC),
        height: 1.3,
      ),
      code: GoogleFonts.sourceCodePro(
        fontSize: 13,
        color: const Color(0xFF4ADE80),
        backgroundColor: context.scaffoldBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      blockquote: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF86EFAC),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: context.scaffoldBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFF22C55E), width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFF22C55E).withOpacity(0.2), width: 1),
        ),
      ),
      tableHead: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        color: const Color(0xFF4ADE80),
      ),
      tableBody: GoogleFonts.inter(
        fontSize: 13.5,
        color: context.textPrimary.withOpacity(0.8),
      ),
      tableBorder: TableBorder.all(
        color: const Color(0xFF22C55E).withOpacity(0.2),
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      tableHeadAlign: TextAlign.left,
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      listBullet: GoogleFonts.inter(
        fontSize: 14.5,
        color: const Color(0xFF4ADE80),
      ),
      listIndent: 18,
      listBulletPadding: const EdgeInsets.only(right: 6),
      blockSpacing: 10,
      h1Padding: const EdgeInsets.only(bottom: 4),
      h2Padding: const EdgeInsets.only(bottom: 2),
      h3Padding: EdgeInsets.zero,
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF22C55E),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/images/plant_assistant_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
