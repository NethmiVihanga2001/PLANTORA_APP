import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/responsive_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFileName;
  Uint8List? _shopImageBytes;
  String? _shopImageFileName;
  final _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _bioController.text = user.bio ?? '';
      _locationController.text = user.location ?? '';
      _businessNameController.text = user.businessName ?? '';
      _vehicleTypeController.text = user.vehicleType ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _businessNameController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFileName = pickedFile.name;
      });
    }
  }

  Future<void> _pickShopImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _shopImageBytes = bytes;
        _shopImageFileName = pickedFile.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    try {
      if (_imageBytes != null) {
        await auth.updateProfileImage(_imageBytes!, _imageFileName ?? 'avatar.jpg');
      }

      if (_shopImageBytes != null) {
        await auth.updateShopImage(_shopImageBytes!, _shopImageFileName ?? 'shop.jpg');
      }

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        businessName: _businessNameController.text.trim().isEmpty ? null : _businessNameController.text.trim(),
        vehicleType: user.isDriver ? (_vehicleTypeController.text.trim().isEmpty ? null : _vehicleTypeController.text.trim()) : user.vehicleType,
        avatarUrl: auth.user!.avatarUrl,
        shopImage: auth.user!.shopImage,
      );

      final success = await auth.updateProfile(updatedUser);
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.primaryGreen),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to update profile'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold();

    getAvatarUrl(String? path) {
      if (path == null) return null;
      if (path.startsWith('http')) return path;
      return '${AppConfig.baseUrl}$path';
    }

    final isWide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Edit Profile',
        subtitle: 'Update your account & public info',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Responsive.formContainer(
          context: context,
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? (user.avatarUrl!.startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(user.avatarUrl!.split(',').last),
                                        fit: BoxFit.cover,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: getAvatarUrl(user.avatarUrl)!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => Icon(Icons.person, size: 60, color: context.textSecondary),
                                      ))
                                : Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  )),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: const Color(0xFF10B981),
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          onTap: _pickImage,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
              ),

              if (user.isSeller) ...[
                const SizedBox(height: 32),
                Text('Shop Cover Image', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickShopImage,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: context.inputFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
                      image: _shopImageBytes != null
                          ? DecorationImage(image: MemoryImage(_shopImageBytes!), fit: BoxFit.cover)
                          : (user.shopImage != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(getAvatarUrl(user.shopImage)!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: _shopImageBytes == null && user.shopImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFF10B981)),
                              const SizedBox(height: 8),
                              Text('Click to upload shop cover banner', style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500)),
                            ],
                          )
                        : null,
                  ),
                ).animate().slideY(begin: 0.1, duration: 350.ms),
              ],

              const SizedBox(height: 32),

              // Inputs (responsive 2-column on wide screens, 1-column on mobile)
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Full Name',
                        controller: _nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        hintText: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildInputField(
                  label: 'Full Name',
                  controller: _nameController,
                  hintText: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
              ],

              const SizedBox(height: 20),

              // Bio Field
              _buildInputField(
                label: 'Bio / About You',
                controller: _bioController,
                hintText: 'Share a little about yourself or your plant journey...',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Location Field
              _buildInputField(
                label: 'Location / City',
                controller: _locationController,
                hintText: 'e.g. Colombo, Sri Lanka',
                icon: Icons.location_on_outlined,
              ),

              if (user.isSeller || (user.businessName != null && user.businessName!.isNotEmpty)) ...[
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Shop Name / Nursery Name',
                  controller: _businessNameController,
                  hintText: 'e.g. Green Roots Nursery',
                  icon: Icons.storefront_rounded,
                ),
              ],

              if (user.isDriver) ...[
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Vehicle Type',
                  controller: _vehicleTypeController,
                  hintText: 'e.g. Motorbike, Van, TukTuk',
                  icon: Icons.directions_bike_rounded,
                ),
              ],

              const SizedBox(height: 20),

              // Email (ReadOnly)
              _buildInputField(
                label: 'Email Address (Registered)',
                controller: TextEditingController(text: user.email),
                hintText: 'Email Address',
                icon: Icons.email_outlined,
                enabled: false,
              ),

              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(delay: 150.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: enabled ? context.textPrimary : context.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          style: TextStyle(color: enabled ? context.textPrimary : context.textSecondary, fontSize: 14),
          decoration: InputDecoration(
            counterText: "",
            hintText: hintText,
            hintStyle: TextStyle(color: context.textTertiary, fontSize: 14),
            prefixIcon: maxLines > 1
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(icon, color: enabled ? const Color(0xFF10B981) : context.textSecondary, size: 20),
                  )
                : Icon(icon, color: enabled ? const Color(0xFF10B981) : context.textSecondary, size: 20),
            filled: true,
            fillColor: enabled ? context.inputFill : context.inputFill.withOpacity(0.5),
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
          ),
        ),
      ],
    );
  }
}

