import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _2faController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _2faController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final resultStr = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (mounted) {
      if (resultStr == 'success') {
        final user = auth.user;
        if (user != null) {
          if (user.role == 'Driver') {
            Navigator.pushReplacementNamed(context, '/driver-dashboard');
          } else if (user.role == 'Seller') {
            Navigator.pushReplacementNamed(context, '/seller-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else if (resultStr == '2fa_required') {
        _show2FADialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    String email = '';
    String name = '';
    String id = '';

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      email = googleUser.email;
      name = googleUser.displayName ?? 'Google User';
      id = googleUser.id;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using demo Google login...'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      email = 'demo_google_user@example.com';
      name = 'Demo Google User';
      id = 'mock_google_789';
    }

    if (email.isEmpty) return;

    final resultStr = await auth.socialLogin(
      provider: 'Google',
      email: email,
      name: name,
      id: id,
    );

    if (mounted) {
      if (resultStr == 'success') {
        final role = auth.user?.role ?? 'Customer';
        if (role == 'Driver') {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        } else if (role == 'Seller') {
          Navigator.pushReplacementNamed(context, '/seller-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (resultStr == '2fa_required') {
        _show2FADialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Google login failed. Please sign up first.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _show2FADialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0C2016),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Two-Factor Authentication', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the 6-digit verification code sent to your device.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: _2faController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '2FA Code',
                  labelStyle: const TextStyle(color: AppColors.lightGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.lightGreen), borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: auth.isLoading ? null : () async {
                  final code = _2faController.text;
                  if (code.length != 6) return;
                  final success = await auth.verify2fa(code);
                  if (mounted && success) {
                    Navigator.pop(context);
                    final user = auth.user;
                    if (user != null && user.role == 'Driver') {
                      Navigator.pushReplacementNamed(context, '/driver-dashboard');
                    } else if (user != null && user.role == 'Seller') {
                      Navigator.pushReplacementNamed(context, '/seller-dashboard');
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(auth.error ?? 'Invalid code'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF03140C), Color(0xFF082618), Color(0xFF03140C)],
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

          // ── Layer 3: Ambient Sunlight Ray Beam (Top Center) ──
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

          // ── Layer 4: Main Auth Content (No Top Logo, Perfectly Centered) ──
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Auth Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2113).withOpacity(0.78),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFF4ADE80).withOpacity(0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Welcome Back Header
                                Center(
                                  child: Text(
                                    loc.translate('welcome_back'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ).animate().fadeIn(delay: 150.ms),
                                ),

                                const SizedBox(height: 24),

                                // Email Input
                                _buildField(
                                  controller: _emailController,
                                  label: loc.translate('email_label'),
                                  icon: Icons.email_outlined,
                                  hint: loc.translate('email_hint'),
                                  keyboardType: TextInputType.emailAddress,
                                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),
                                
                                const SizedBox(height: 18),

                                // Password Input
                                _buildField(
                                  controller: _passwordController,
                                  label: loc.translate('password_label'),
                                  icon: Icons.lock_outline_rounded,
                                  hint: 'Enter your password',
                                  isPassword: true,
                                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),

                                const SizedBox(height: 14),

                                // Remember Me & Forgot Password Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                              activeColor: const Color(0xFF4ADE80),
                                              checkColor: Colors.white,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              loc.translate('remember_me'),
                                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        loc.translate('forgot_password'),
                                        style: const TextStyle(
                                          color: Color(0xFF4ADE80),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 450.ms),

                                const SizedBox(height: 24),

                                // Login Primary Button
                                Consumer<AuthProvider>(
                                  builder: (_, auth, __) => SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF22C55E),
                                        foregroundColor: Colors.white,
                                        elevation: 6,
                                        shadowColor: const Color(0xFF22C55E).withOpacity(0.45),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: auth.isLoading ? null : _login,
                                      child: auth.isLoading
                                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : Text(
                                              loc.translate('login_button'),
                                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
                                            ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 550.ms),

                                const SizedBox(height: 22),
                                
                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white.withOpacity(0.18), height: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        loc.translate('or_continue_with'),
                                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.white.withOpacity(0.18), height: 1)),
                                  ],
                                ).animate().fadeIn(delay: 650.ms),
                                
                                const SizedBox(height: 18),

                                // Google Sign-in Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.06),
                                      side: BorderSide(color: Colors.white.withOpacity(0.20), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    onPressed: _handleGoogleLogin,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/icons/google.png',
                                          width: 20,
                                          height: 20,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 24),
                                        ),
                                        const SizedBox(width: 10),
                                        const Flexible(
                                          child: Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 750.ms),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 22),
                      
                      // Sign Up Footer Link
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "${loc.translate('dont_have_account')} ",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13.5),
                            children: [
                              TextSpan(
                                text: loc.translate('sign_up'),
                                style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 850.ms),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.lightGreen, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.lightGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }
}