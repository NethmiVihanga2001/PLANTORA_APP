import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/driver_drawer.dart';
import 'seller/seller_drawer.dart';
import 'chat_list_screen.dart';
import 'driver_vehicle_screen.dart';
import 'driver_payout_screen.dart';
import 'driver_history_screen.dart';
import '../widgets/product_image.dart';


// ── Premium Color Accents ────────────────────────────────────────────────────
const _gold = Color(0xFFD4AF37);
const _goldLight = Color(0xFFF3E5AB);
const _emeraldAccent = Color(0xFF10B981);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _rotateCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _rotate;
  late Animation<double> _float;
  late Animation<double> _shimmer;

  bool _isUploadingAvatar = false;
  bool _isUploadingShopCover = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2500, milliseconds: 0))..repeat();

    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateCtrl);
    _float = Tween<double>(begin: -6.0, end: 6.0).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String? _getAvatarUrl(String? path) {
    if (path == null || path.trim().isEmpty || path == 'null') return null;
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:image')) return path;
    return '${AppConfig.baseUrl}$path';
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 800);
      if (file == null) return;

      setState(() => _isUploadingAvatar = true);

      final Uint8List bytes = await file.readAsBytes();
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.updateProfileImage(bytes, file.name);

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Profile photo updated successfully!'),
                ],
              ),
              backgroundColor: _emeraldAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to upload photo. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadShopCover(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
      if (file == null) return;

      setState(() => _isUploadingShopCover = true);

      final Uint8List bytes = await file.readAsBytes();
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.updateShopImage(bytes, file.name);

      if (mounted) {
        setState(() => _isUploadingShopCover = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Shop cover photo updated successfully!'),
                ],
              ),
              backgroundColor: _emeraldAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to upload cover photo. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingShopCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting cover photo: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCoverOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: context.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Shop Cover Options',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how you want to update your shop cover image',
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _emeraldAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: _emeraldAccent),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              subtitle: Text('Pick a cover photo from your device', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadShopCover(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.blueAccent),
              ),
              title: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              subtitle: Text('Use camera to capture cover photo', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadShopCover(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAvatarOptionsSheet() {
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: context.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Profile Photo Options',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how you want to update your profile photo',
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _emeraldAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: _emeraldAccent),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              subtitle: Text('Pick an existing photo from your device', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.blueAccent),
              ),
              title: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
              subtitle: Text('Use your camera to capture a new photo', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            if (user?.isSeller == true) ...[
              const Divider(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded, color: _gold),
                ),
                title: Text('Change Shop Cover Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                subtitle: Text('Upload or change banner photo for your shop', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCoverOptionsSheet();
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final loc = context.watch<LocalizationProvider>();
    final avatarFullUrl = _getAvatarUrl(user?.avatarUrl ?? (user?.isSeller == true ? null : user?.shopImage));
    final initials = (user?.name.isNotEmpty == true) ? user!.name.trim().substring(0, 1).toUpperCase() : 'P';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.scaffoldBg,
        drawer: user?.role == 'Driver'
            ? const DriverDrawer(currentIndex: 2)
            : (user?.role == 'Seller'
                ? SellerDrawer(
                    currentIndex: 98,
                    onNavigate: (i) {
                      if (i == 0) Navigator.pushNamed(context, '/seller-dashboard');
                    },
                  )
                : const AppDrawer()),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── TOP HERO APP BAR & AVATAR ───────────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Shop Cover Image Background Header (Seller only) or Gradient Header
                  Container(
                    height: 380,
                    width: double.infinity,
                    child: user?.isSeller == true
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              if (user?.shopImage != null && user!.shopImage!.trim().isNotEmpty)
                                ProductImage(
                                  imageUrl: user.shopImage,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 380,
                                  borderRadius: BorderRadius.zero,
                                )
                              else
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF064E3B),
                                        Color(0xFF047857),
                                        Color(0xFF059669),
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: -20,
                                        bottom: 20,
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          size: 200,
                                          color: Colors.white.withOpacity(0.08),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Dark overlay for legibility of icons and text
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.65),
                                      Colors.black.withOpacity(0.35),
                                      context.scaffoldBg.withOpacity(0.85),
                                      context.scaffoldBg,
                                    ],
                                    stops: const [0.0, 0.45, 0.85, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  context.primary.withOpacity(0.9),
                                  context.primary.withOpacity(0.3),
                                  context.scaffoldBg,
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                            ),
                          ),
                  ),

                  // Floating Ambient Circles (shown when no shop cover image)
                  if (user?.isSeller != true || user?.shopImage == null || user!.shopImage!.trim().isEmpty) ...[
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emeraldAccent.withOpacity(0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 100,
                      left: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],

                  SafeArea(
                    child: Column(
                      children: [
                        // Top Nav Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Builder(
                                builder: (btnCtx) => IconButton(
                                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                                  onPressed: () {
                                    if (_scaffoldKey.currentState != null) {
                                      _scaffoldKey.currentState!.openDrawer();
                                    } else {
                                      Scaffold.of(btnCtx).openDrawer();
                                    }
                                  },
                                ),
                              ),
                              const Spacer(),
                              Text(
                                loc.translate('my_profile'),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              if (user?.isSeller == true) ...[
                                IconButton(
                                  tooltip: 'Change Shop Cover',
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                                    ),
                                    child: _isUploadingShopCover
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 18),
                                  ),
                                  onPressed: _showCoverOptionsSheet,
                                ),
                                const SizedBox(width: 4),
                              ],
                              IconButton(
                                tooltip: 'Edit Profile',
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.cardBg.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.border.withOpacity(0.5)),
                                  ),
                                  child: Icon(Icons.edit_rounded, color: _emeraldAccent, size: 20),
                                ),
                                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Animated Avatar with Camera Upload Badge
                        AnimatedBuilder(
                          animation: Listenable.merge([_rotateCtrl, _floatCtrl]),
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, _float.value),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Rotating Gradient Halo Outer Ring
                                  Transform.rotate(
                                    angle: _rotate.value,
                                    child: CustomPaint(
                                      size: const Size(140, 140),
                                      painter: _ArcRingPainter(
                                        colors: [_emeraldAccent, _gold, _emeraldAccent.withOpacity(0.3), _goldLight],
                                      ),
                                    ),
                                  ),

                                  // Avatar Image Circle
                                  Container(
                                    width: 124,
                                    height: 124,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.cardBg,
                                      border: Border.all(color: Colors.white, width: 3.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _isUploadingAvatar
                                          ? const Center(
                                              child: CircularProgressIndicator(color: _emeraldAccent, strokeWidth: 3),
                                            )
                                          : (avatarFullUrl != null
                                              ? (avatarFullUrl.startsWith('data:image')
                                                  ? Image.memory(
                                                      base64Decode(avatarFullUrl.split(',').last),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : CachedNetworkImage(
                                                      imageUrl: avatarFullUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => Container(
                                                        color: context.cardBg,
                                                        child: const Center(
                                                          child: CircularProgressIndicator(color: _emeraldAccent, strokeWidth: 2),
                                                        ),
                                                      ),
                                                      errorWidget: (context, url, error) {
                                                        return _buildAvatarInitials(initials);
                                                      },
                                                    ))
                                              : _buildAvatarInitials(initials)),
                                    ),
                                  ),

                                  // Camera Upload Button Overlay Badge
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Material(
                                      elevation: 6,
                                      shape: const CircleBorder(),
                                      color: _emeraldAccent,
                                      child: InkWell(
                                        onTap: _showAvatarOptionsSheet,
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 14),

                        // Name
                        Text(
                          user?.displayName ?? 'Plant Enthusiast',
                          style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),

                        if (user?.businessName != null && user!.businessName!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: _emeraldAccent),
                              const SizedBox(width: 4),
                              Text(
                                user.businessName!,
                                style: GoogleFonts.inter(
                                  color: _emeraldAccent,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 4),

                        // Email
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Role & Status Badge
                        AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (_, __) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  _gold.withOpacity(0.2),
                                  _goldLight.withOpacity(0.4),
                                  _gold.withOpacity(0.2),
                                ],
                                begin: Alignment(_shimmer.value - 1, 0),
                                end: Alignment(_shimmer.value + 1, 0),
                              ),
                              border: Border.all(color: _gold.withOpacity(0.5), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user?.isSeller == true
                                      ? Icons.storefront_rounded
                                      : (user?.isDriver == true ? Icons.local_shipping_rounded : Icons.verified_user_rounded),
                                  color: _gold,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  loc.translate((user?.role ?? 'Customer').toLowerCase()),
                                  style: GoogleFonts.inter(
                                    color: _gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── QUICK STATS & ACTIONS ROW ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildRoleStatCards(context, user, loc)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.1),
              ),
            ),

            // ── ACCOUNT DETAILS SECTION ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('personal_details'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            icon: Icons.person_rounded,
                            iconBg: _emeraldAccent.withValues(alpha: 0.1),
                            iconColor: _emeraldAccent,
                            label: loc.translate('full_name'),
                            value: user?.name ?? 'Not set',
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withValues(alpha: 0.5)),
                          if (user?.isSeller == true || (user?.businessName != null && user!.businessName!.trim().isNotEmpty)) ...[
                            _buildDetailRow(
                              context,
                              icon: Icons.storefront_rounded,
                              iconBg: Colors.teal.withValues(alpha: 0.1),
                              iconColor: Colors.teal,
                              label: loc.translate('shop_name'),
                              value: (user?.businessName != null && user!.businessName!.trim().isNotEmpty)
                                  ? user.businessName!
                                  : 'Not set',
                            ),
                            Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withValues(alpha: 0.5)),
                          ],
                          _buildDetailRow(
                            context,
                            icon: Icons.email_rounded,
                            iconBg: Colors.blueAccent.withValues(alpha: 0.1),
                            iconColor: Colors.blueAccent,
                            label: loc.translate('email_label'),
                            value: user?.email ?? 'Not set',
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withValues(alpha: 0.5)),
                          _buildDetailRow(
                            context,
                            icon: Icons.phone_rounded,
                            iconBg: Colors.amber.withValues(alpha: 0.1),
                            iconColor: Colors.amber.shade800,
                            label: loc.translate('phone_number'),
                            value: (user?.phone != null && user!.phone!.trim().isNotEmpty && user.phone != 'null')
                                ? user.phone!
                                : 'Not set',
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withValues(alpha: 0.5)),
                          _buildDetailRow(
                            context,
                            icon: Icons.badge_rounded,
                            iconBg: Colors.purple.withValues(alpha: 0.1),
                            iconColor: Colors.purple,
                            label: loc.translate('account_role'),
                            value: loc.translate((user?.role ?? 'Customer').toLowerCase()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── DASHBOARDS & PREFERENCES ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('app_and_dashboards'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          if (user?.isSeller == true) ...[
                            _buildMenuTile(
                              context,
                              icon: Icons.storefront_rounded,
                              iconColor: _emeraldAccent,
                              title: loc.translate('seller_dashboard'),
                              subtitle: loc.translate('manage_notifications_desc'),
                              onTap: () => Navigator.pushNamed(context, '/seller-dashboard'),
                            ),
                            Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withOpacity(0.5)),
                          ],
                          if (user?.isDriver == true) ...[
                            _buildMenuTile(
                              context,
                              icon: Icons.local_shipping_rounded,
                              iconColor: Colors.deepOrangeAccent,
                              title: loc.translate('driver_navigation_hub'),
                              subtitle: loc.translate('active_deliveries_route'),
                              onTap: () => Navigator.pushNamed(context, '/driver-dashboard'),
                            ),
                            Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withOpacity(0.5)),
                          ],
                          _buildMenuTile(
                            context,
                            icon: Icons.edit_note_rounded,
                            iconColor: Colors.indigoAccent,
                            title: loc.translate('edit_profile_info'),
                            subtitle: loc.translate('update_profile_desc'),
                            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withOpacity(0.5)),
                          _buildMenuTile(
                            context,
                            icon: Icons.notifications_none_rounded,
                            iconColor: Colors.amber.shade700,
                            title: loc.translate('notifications_and_alerts'),
                            subtitle: loc.translate('manage_notifications_desc'),
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                          ),
                          Divider(height: 1, indent: 64, endIndent: 16, color: context.border.withOpacity(0.5)),
                          _buildMenuTile(
                            context,
                            icon: Icons.language_rounded,
                            iconColor: Colors.teal,
                            title: loc.translate('app_language'),
                            subtitle: loc.translate('switch_language_desc'),
                            onTap: () => Navigator.pushNamed(context, '/language'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── ACTION BUTTONS: LOGOUT & DELETE ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 48),
                child: Column(
                  children: [
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          loc.translate('sign_out'),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: context.cardBg,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(loc.translate('sign_out'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
                              content: Text(loc.translate('sign_out_confirm'), style: GoogleFonts.inter(color: context.textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(loc.translate('cancel'), style: GoogleFonts.inter(color: context.textSecondary)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await context.read<AuthProvider>().logout();
                                    if (context.mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                    }
                                  },
                                  child: Text(loc.translate('sign_out')),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Delete Account Link
                    TextButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.grey),
                      label: Text(
                        loc.translate('delete_account'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            final isDark = Theme.of(ctx).brightness == Brightness.dark;
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 420),
                                padding: const EdgeInsets.all(26),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF131F18) : Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                                      blurRadius: 32,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFFECACA), width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 32),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      loc.translate('delete_account'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: -0.3,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This action is permanent and cannot be reversed. Are you sure you want to proceed?',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: context.textSecondary,
                                        fontSize: 13.5,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFEE2E8),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.eco_outlined, size: 16, color: Color(0xFFEF4444)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Saved plant collection & scans will be erased',
                                                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFEF4444)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Cheer Points & loyalty tiers will be forfeited',
                                                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                                                  width: 1.2,
                                                ),
                                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                              child: Text(
                                                loc.translate('cancel'),
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                final success = await context.read<AuthProvider>().deleteAccount();
                                                if (success && context.mounted) {
                                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                                }
                                              },
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                              label: Text(loc.translate('delete'), style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFEF4444),
                                                foregroundColor: Colors.white,
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          },
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarInitials(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _emeraldAccent,
            _emeraldAccent.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleStatCards(BuildContext context, UserModel? user, LocalizationProvider loc) {
    if (user?.isDriver == true || user?.role.toLowerCase() == 'driver') {
      return Row(
        children: [
          _buildStatCard(
            context,
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF3B82F6),
            title: '142',
            subtitle: loc.translate('deliveries'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverHistoryScreen())),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            title: '4.9 ★',
            subtitle: loc.translate('ratings'),
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.account_balance_wallet_outlined,
            color: _gold,
            title: 'Rs. 45k',
            subtitle: loc.translate('earnings'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPayoutScreen())),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.two_wheeler_rounded,
            color: _emeraldAccent,
            title: 'Active',
            subtitle: loc.translate('vehicle'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverVehicleScreen())),
          ),
        ],
      );
    } else if (user?.isSeller == true || user?.role.toLowerCase() == 'seller') {
      return Row(
        children: [
          _buildStatCard(
            context,
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF3B82F6),
            title: '12',
            subtitle: loc.translate('listings'),
            onTap: () => Navigator.pushNamed(context, '/seller-dashboard'),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.point_of_sale_rounded,
            color: _emeraldAccent,
            title: '48',
            subtitle: loc.translate('sales'),
            onTap: () => Navigator.pushNamed(context, '/seller-dashboard'),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.account_balance_wallet_outlined,
            color: _gold,
            title: 'Rs. 85k',
            subtitle: loc.translate('earnings'),
            onTap: () => Navigator.pushNamed(context, '/seller-dashboard'),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            title: '4.9 ★',
            subtitle: loc.translate('ratings'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
        ],
      );
    } else {
      // Customer side (default)
      return Row(
        children: [
          _buildStatCard(
            context,
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF3B82F6),
            title: '${user?.myOrders.length ?? 0}',
            subtitle: loc.translate('my_orders'),
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.military_tech_rounded,
            color: _gold,
            title: '${user?.points ?? 10}',
            subtitle: loc.translate('pts'),
            onTap: () => Navigator.pushNamed(context, '/loyalty'),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFFEF4444),
            title: '${user?.wishlist.length ?? 0}',
            subtitle: loc.translate('favorites'),
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            color: _emeraldAccent,
            title: 'Chat',
            subtitle: loc.translate('messages'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: context.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

// ── Rotating Arc Ring Painter ─────────────────────────────────────────────
class _ArcRingPainter extends CustomPainter {
  final List<Color> colors;
  _ArcRingPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        stops: const [0.0, 0.33, 0.66, 1.0],
      ).createShader(rect);

    for (int i = 0; i < 3; i++) {
      final start = (i * 2 * math.pi / 3);
      canvas.drawArc(rect, start, math.pi / 3 * 1.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => false;
}
