import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/marketplace_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/responsive_layout.dart';

class EditListingScreen extends StatefulWidget {
  final ProductModel product;

  const EditListingScreen({super.key, required this.product});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late String _selectedCategory;
  bool _isSubmitting = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final MarketplaceService _marketService = MarketplaceService();
  final AuthService _authService = AuthService();

  final List<Map<String, dynamic>> _categories = [
    {'value': 'indoor',    'label': 'Indoor',    'emoji': '🪴'},
    {'value': 'outdoor',   'label': 'Outdoor',   'emoji': '🌲'},
    {'value': 'rare',      'label': 'Rare',      'emoji': '✨'},
    {'value': 'medicinal', 'label': 'Medicinal', 'emoji': '💊'},
    {'value': 'culinary',  'label': 'Culinary',  'emoji': '🍳'},
    {'value': 'aromatic',  'label': 'Aromatic',  'emoji': '🌸'},
    {'value': 'tea',       'label': 'Teas',      'emoji': '🍵'},
    {'value': 'seed',      'label': 'Seeds',     'emoji': '🌱'},
    {'value': 'fertilizer','label': 'Care',      'emoji': '🧪'},
    {'value': 'tool',      'label': 'Tools',     'emoji': '✂️'},
    {'value': 'pot',       'label': 'Pots',      'emoji': '🏺'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _originalPriceController = TextEditingController(
      text: widget.product.originalPrice != null ? widget.product.originalPrice!.toStringAsFixed(0) : ''
    );
    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  Future<void> _updateListing() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all required fields'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid price'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final double? originalPrice = _originalPriceController.text.trim().isNotEmpty
        ? double.tryParse(_originalPriceController.text.trim())
        : null;

    setState(() => _isSubmitting = true);

    try {
      final token = await _authService.getToken() ?? '';
      Uint8List? imageBytes;
      String? fileName;
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
        fileName = _selectedImage!.name;
      }

      final success = await _marketService.updateProduct(
        widget.product.id,
        {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'price': price,
          'category': _selectedCategory,
          'emoji': _categories.firstWhere((c) => c['value'] == _selectedCategory, orElse: () => {'emoji': '🌿'})['emoji'],
        },
        token,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Listing updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to update listing'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Edit Listing',
        subtitle: 'Update plant details & pricing',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Responsive.formContainer(
          context: context,
          maxWidth: 650,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: context.cardBg,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                            title: Text('Choose from Gallery', style: TextStyle(color: context.textPrimary)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                              if (image != null) setState(() => _selectedImage = image);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981)),
                            title: Text('Take a Photo', style: TextStyle(color: context.textPrimary)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                              if (image != null) setState(() => _selectedImage = image);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.textPrimary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    image: _selectedImage != null 
                      ? DecorationImage(
                          image: kIsWeb 
                            ? NetworkImage(_selectedImage!.path) as ImageProvider
                            : FileImage(File(_selectedImage!.path)), 
                          fit: BoxFit.cover
                        )
                      : null,
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: _selectedImage == null ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.product.emoji, style: const TextStyle(fontSize: 50)),
                      const SizedBox(height: 10),
                      const Text('Tap to change photo',
                          style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    ],
                  ) : null,
                ),
              ),

              const SizedBox(height: 24),
              _buildLabel('Title *'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: _inputDecoration('Plant or item title'),
              ),

              const SizedBox(height: 16),
              _buildLabel('Category *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: context.cardBg,
                decoration: _inputDecoration('Category'),
                items: _categories.map((cat) => DropdownMenuItem<String>(
                  value: cat['value'] as String,
                  child: Text('${cat['emoji']}  ${cat['label']}', style: TextStyle(color: context.textPrimary)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Price (Rs.) *'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('1500', prefix: 'Rs. '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Original Price (Optional)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('2000', prefix: 'Rs. '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildLabel('Description *'),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputDecoration('Plant care tips, size, and details...'),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _updateListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
      filled: true,
      fillColor: context.textPrimary.withOpacity(0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8)),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary));
  }
}
