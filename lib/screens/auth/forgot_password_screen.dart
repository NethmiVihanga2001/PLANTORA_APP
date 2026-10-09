import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _step = 1; // 1 = Email, 2 = Code, 3 = Reset
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendTimer = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        timer.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  bool _hasMinLength(String p) => p.length >= 7;
  bool _hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
  bool _hasDigits(String p) => p.contains(RegExp(r'[0-9]'));
  bool _hasSpecialChar(String p) => p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  int _rulesMetCount(String p) {
    int count = 0;
    if (_hasMinLength(p)) count++;
    if (_hasUppercase(p)) count++;
    if (_hasDigits(p)) count++;
    if (_hasSpecialChar(p)) count++;
    return count;
  }

  Widget _buildPasswordStrengthIndicator() {
    final p = _passwordController.text;
    if (p.isEmpty) return const SizedBox.shrink();
    
    final count = _rulesMetCount(p);
    final progress = count / 4.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.mediumGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightGreen),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please provide an email address');
      return;
    }
    
    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(email);
    
    if (mounted) {
      if (success) {
        setState(() => _step = 2);
        _startTimer();
      } else {
        _showError(auth.error ?? 'Failed to send reset email');
      }
    }
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    final auth = context.read<AuthProvider>();
    final success = await auth.resendResetCode(email);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent!'), backgroundColor: AppColors.success),
        );
        _startTimer();
      } else {
        _showError(auth.error ?? 'Failed to resend code');
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('Please enter the 6-digit code');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyResetCode(_emailController.text.trim(), code);

    if (mounted) {
      if (success) {
        setState(() => _step = 3);
      } else {
        _showError(auth.error ?? 'Invalid code');
      }
    }
  }

  Future<void> _resetPassword() async {
    final pass = _passwordController.text;
    if (pass != _confirmController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{7,}$').hasMatch(pass)) {
      _showError('Password must be >6 chars, with a capital letter, number & symbol');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(_emailController.text.trim(), _codeController.text.trim(), pass);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(auth.error ?? 'Failed to reset password');
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
  }) {
    bool obscure = isPassword 
        ? (isConfirm ? _obscureConfirm : _obscurePassword) 
        : false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textAlign: textAlign,
          style: style ?? const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF4ADE80), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      if (isConfirm) {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      } else {
                        setState(() => _obscurePassword = !_obscurePassword);
                      }
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed, bool isLoading) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: onPressed == null ? null : const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: onPressed == null ? Colors.white.withOpacity(0.1) : null,
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // ── Layer 1: Realistic Full-Screen Plant Background ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/plantora_full_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF041C10), Color(0xFF0B3A22), Color(0xFF041C10)],
                  ),
                ),
              ),
            ),
          ),
          
          // ── Layer 2: Deep Dark Green Vignette Overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF08150C).withOpacity(0.68),
                    const Color(0xFF030A05).withOpacity(0.93),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Ambient Sunlight Ray Beam ──
          Positioned(
            top: 0,
            left: size.width * 0.5 - 2,
            child: Container(
              width: 4,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4ADE80).withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // ── Layer 4: Main Content (Frosted Glassmorphic Form Card) ──
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Form Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2113).withOpacity(0.78),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3), width: 1.2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 28, offset: const Offset(0, 12))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _step == 1 ? 'Forgot Password?'
                                  : _step == 2 ? 'Verification Code'
                                  : 'New Password',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                                
                                const SizedBox(height: 8),
                                
                                Text(
                                  _step == 1 ? 'Provide your account email to receive a 6-digit verification code.'
                                  : _step == 2 ? '6-digit code sent to ${_emailController.text}'
                                  : 'Create a new secure password for your account.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                                
                                const SizedBox(height: 28),
                                
                                if (_step == 1) ...[
                                  _buildField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    hint: 'youremail@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                                  
                                  const SizedBox(height: 28),
                                  
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) => _buildButton(
                                      'Send Code',
                                      auth.isLoading ? null : _sendReset,
                                      auth.isLoading,
                                    ),
                                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                                  
                                ] else if (_step == 2) ...[
                                  _buildField(
                                    controller: _codeController,
                                    label: '',
                                    icon: Icons.pin_outlined,
                                    hint: '000000',
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 24, letterSpacing: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                                  
                                  const SizedBox(height: 28),
                                  
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) => Column(
                                      children: [
                                        _buildButton(
                                          'Verify Code',
                                          auth.isLoading ? null : _verifyCode,
                                          auth.isLoading,
                                        ),
                                        const SizedBox(height: 20),
                                        Center(
                                          child: TextButton(
                                            onPressed: (_resendTimer > 0 || auth.isLoading) ? null : _resendCode,
                                            child: Text(
                                              _resendTimer > 0 
                                                ? 'Resend Code in ${_resendTimer}s' 
                                                : 'Resend Code',
                                              style: TextStyle(
                                                color: _resendTimer > 0 ? Colors.white.withOpacity(0.5) : const Color(0xFF4ADE80),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                                  
                                ] else if (_step == 3) ...[
                                  _buildField(
                                    controller: _passwordController,
                                    label: 'New Password',
                                    icon: Icons.lock_outline,
                                    hint: '••••••••',
                                    isPassword: true,
                                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                                  
                                  _buildPasswordStrengthIndicator(),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildField(
                                    controller: _confirmController,
                                    label: 'Confirm Password',
                                    icon: Icons.lock_outline,
                                    hint: '••••••••',
                                    isPassword: true,
                                    isConfirm: true,
                                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                                  
                                  const SizedBox(height: 28),
                                  
                                  Consumer<AuthProvider>(
                                    builder: (_, auth, __) => _buildButton(
                                      'Update Password',
                                      auth.isLoading ? null : _resetPassword,
                                      auth.isLoading,
                                    ),
                                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ).animate().slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}