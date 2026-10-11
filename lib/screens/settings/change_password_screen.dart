import 'package:flutter/material.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    final current = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    if (newPass != confirm) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{7,}$');
    if (!passwordRegex.hasMatch(newPass)) {
      _showSnackBar('Password must be >6 chars, with a capital letter, number & symbol', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService().changePassword(current, newPass);

    if (mounted) {
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        _showSnackBar('Password updated successfully in database!');
        Navigator.pop(context);
      } else {
        _showSnackBar(res['error'] ?? 'Failed to update password', isError: true);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Change Password',
        subtitle: 'Update your login credentials',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Responsive.formContainer(
          context: context,
          maxWidth: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ensure your account is using a long, random password to stay secure.',
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
              const SizedBox(height: 28),
              _buildPasswordField(
                label: 'Current Password',
                controller: _currentController,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                label: 'New Password',
                controller: _newController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                label: 'Confirm New Password',
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: context.textTertiary, fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF10B981), size: 20),
            filled: true,
            fillColor: context.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8),
            ),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
              onPressed: onToggle,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
