import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'help_center_screen.dart';

class InfoScreen extends StatelessWidget {
  final String title;
  final String content;

  const InfoScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Route directly to specialized rich screens
    if (title.toLowerCase().contains('privacy')) {
      return const PrivacyPolicyScreen();
    } else if (title.toLowerCase().contains('terms')) {
      return const TermsOfServiceScreen();
    } else if (title.toLowerCase().contains('help')) {
      return const HelpCenterScreen();
    }

    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: PremiumAppBar(
        title: title,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Responsive.centered(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFormattedContent(_getActualContent(title, content), theme, context),
          ),
        ),
      ),
    );
  }

  String _getActualContent(String title, String content) {
    if (content != '...') return content;
    return 'Detailed information coming soon.';
  }

  List<Widget> _buildFormattedContent(String content, ThemeData theme, BuildContext context) {
    List<Widget> widgets = [];
    final lines = content.split('\n');
    
    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 16));
      } else if (line.startsWith(RegExp(r'\d\.\s')) || 
                 line.startsWith('Q:') || 
                 line.trim() == 'Frequently Asked Questions' || 
                 line.trim() == 'Contact Support') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: context.textSecondary,
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
}
