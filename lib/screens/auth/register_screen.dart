import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isSeller = false;
  bool _isDriver = false;
  final _businessNameController = TextEditingController();
  final _vehicleTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _businessNameController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
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
    final count = p.isEmpty ? 0 : _rulesMetCount(p);
    final progress = count / 4.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            'Password Strength',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
               count == 0 ? Colors.white.withOpacity(0.2) : count < 4 ? Colors.orange : AppColors.lightGreen
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      _showError('Passwords do not match');
      return;
    }

    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    final password = _passwordController.text;
    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{7,}$').hasMatch(password)) {
      _showError('Password must be >6 chars, with a capital letter, number & symbol');
      return;
    }

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms & Conditions');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
      isSeller: _isSeller,
      isDriver: _isDriver,
      businessName: _isSeller ? _businessNameController.text.trim() : null,
      vehicleType: _isDriver ? _vehicleTypeController.text.trim() : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! 🌿'),
            backgroundColor: AppColors.success,
          ),
        );
        if (auth.user?.role == 'Driver') {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        } else if (auth.user?.role == 'Seller') {
          Navigator.pushReplacementNamed(context, '/seller-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showError(auth.error ?? 'Registration failed');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  /// Google sign-up with the currently selected role (Customer/Seller/Driver).
  Future<void> _handleGoogleSignup() async {
    final auth = context.read<AuthProvider>();
    String email = '';
    String name = '';
    String id = '';

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled
      email = googleUser.email;
      name = googleUser.displayName ?? 'Google User';
      id = googleUser.id;
    } catch (e) {
      // Fallback to mock for platforms without native Google SDK
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using demo Google signup...'),
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

    String role = 'Customer';
    if (_isSeller) role = 'Seller';
    if (_isDriver) role = 'Driver';

    final resultStr = await auth.socialLogin(
      provider: 'Google',
      email: email,
      name: name,
      id: id,
      role: role,
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
        _showError(auth.error ?? 'Google signup failed');
      }
    }
  }

  void _show2FADialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final _2faController = TextEditingController();
        return AlertDialog(
          title: const Text('Two-Factor Authentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the 6-digit code sent to your device (Use 123456 for testing).'),
              const SizedBox(height: 16),
              TextField(
                controller: _2faController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '2FA Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  final Code = _2faController.text;
                  if (Code.length != 6) return;
                  final success = await auth.verify2fa(Code);
                  if (mounted && success) {
                    Navigator.pop(context); // close dialog
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
                  } else if (mounted) {
                    _showError(auth.error ?? 'Invalid code');
                  }
                },
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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

          // ── Layer 4: Main Content (No Top Logo, Perfectly Centered) ──
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  loc.translate('create_account'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ).animate().fadeIn(delay: 200.ms),
                              ),
                              const SizedBox(height: 24),
                              
                              // Roles
                              Row(
                                children: [
                                  _buildRoleOption(
                                    label: 'Customer',
                                    isActive: !_isSeller && !_isDriver,
                                    onTap: () => setState(() { _isSeller = false; _isDriver = false; }),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildRoleOption(
                                    label: 'Seller',
                                    isActive: _isSeller,
                                    onTap: () => setState(() { _isSeller = true; _isDriver = false; }),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildRoleOption(
                                    label: 'Driver',
                                    isActive: _isDriver,
                                    onTap: () => setState(() { _isSeller = false; _isDriver = true; }),
                                  ),
                                ],
                              ).animate().slideX(begin: -0.1, duration: 400.ms),
                              
                              const SizedBox(height: 24),

                              _buildField(
                                controller: _nameController,
                                label: loc.translate('full_name'),
                                icon: Icons.person_outline,
                                hint: 'Full Name',
                              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                              
                              if (_isSeller) ...[
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _businessNameController,
                                  label: 'Business Name *',
                                  icon: Icons.storefront_outlined,
                                  hint: 'Business Name',
                                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),
                              ],

                              if (_isDriver) ...[
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _vehicleTypeController,
                                  label: 'Vehicle Type *',
                                  icon: Icons.directions_car_outlined,
                                  hint: 'Vehicle Type',
                                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),
                              ],

                              const SizedBox(height: 16),

                              _buildField(
                                controller: _emailController,
                                label: loc.translate('email_label'),
                                icon: Icons.email_outlined,
                                hint: loc.translate('email_hint'),
                                keyboard: TextInputType.emailAddress,
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                              
                              const SizedBox(height: 16),
                              
                              _buildField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                hint: 'Phone Number',
                                keyboard: TextInputType.phone,
                                maxLength: 10,
                              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                              const SizedBox(height: 16),

                              _buildField(
                                controller: _passwordController,
                                label: loc.translate('password_label'),
                                icon: Icons.lock_outline,
                                hint: 'Password',
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                              
                              _buildPasswordStrengthIndicator(),

                              const SizedBox(height: 16),
                              
                              _buildField(
                                controller: _confirmController,
                                label: loc.translate('confirm_password_label'),
                                icon: Icons.lock_outline,
                                hint: 'Confirm Password',
                                obscureText: _obscureConfirm,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                                      activeColor: AppColors.lightGreen,
                                      checkColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I agree to the ',
                                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                        children: [
                                          const TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(color: AppColors.lightGreen, fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(text: ' and '),
                                          const TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(color: AppColors.lightGreen, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 500.ms),

                              const SizedBox(height: 32),

                              // Register button
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) => Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [AppColors.lightGreen, AppColors.accentGreen],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.lightGreen.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: auth.isLoading ? null : _register,
                                    child: auth.isLoading
                                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                        : Text(
                                            loc.translate('create_account'),
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                                          ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 600.ms).scale(),

                              const SizedBox(height: 32),
                              
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      loc.translate('or_continue_with'),
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                ],
                              ).animate().fadeIn(delay: 700.ms),
                              
                              const SizedBox(height: 24),

                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _handleGoogleSignup,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/icons/google.png',
                                            width: 24,
                                            height: 24,
                                          ),
                                          const SizedBox(width: 14),
                                          const Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign In Link
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: loc.translate('already_have_account') + ' ',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                          children: [
                            TextSpan(
                              text: loc.translate('login_button'),
                              style: const TextStyle(color: AppColors.lightGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),
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

  Widget _buildSocialBtn(String assetPath, VoidCallback onTap, {bool isWhite = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 28,
            height: 28,
            color: isWhite ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({required String label, required bool isActive, required VoidCallback onTap}) {
    final activeBtnColor = AppColors.lightGreen;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBtnColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? activeBtnColor : Colors.white.withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            label, 
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6), 
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            obscureText: obscureText,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              counterText: "",
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(icon, color: AppColors.lightGreen),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.lightGreen, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}