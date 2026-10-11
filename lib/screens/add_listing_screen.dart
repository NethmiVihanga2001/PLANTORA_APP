import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/marketplace_service.dart';
import '../services/auth_service.dart';
import '../widgets/premium_app_bar.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = 'indoor';
  bool _isSubmitting = false;
  bool _hasDiscount = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final MarketplaceService _marketService = MarketplaceService();
  final AuthService _authService = AuthService();

  late AnimationController _pulseController;
  late AnimationController _submitController;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'indoor',    'label': 'Indoor',    'icon': Icons.home_rounded,              'emoji': '🪴', 'desc': 'Indoor plants'},
    {'value': 'outdoor',   'label': 'Outdoor',   'icon': Icons.park_rounded,              'emoji': '🌲', 'desc': 'Outdoor plants'},
    {'value': 'rare',      'label': 'Rare',      'icon': Icons.auto_awesome_rounded,      'emoji': '✨', 'desc': 'Rare & exotic'},
    {'value': 'medicinal', 'label': 'Medicinal', 'icon': Icons.medical_services_rounded,  'emoji': '💊', 'desc': 'Herbs & remedies'},
    {'value': 'culinary',  'label': 'Culinary',  'icon': Icons.restaurant_menu_rounded,   'emoji': '🍳', 'desc': 'Kitchen herbs'},
    {'value': 'aromatic',  'label': 'Aromatic',  'icon': Icons.air_rounded,               'emoji': '🌸', 'desc': 'Fragrant plants'},
    {'value': 'tea',       'label': 'Teas',      'icon': Icons.emoji_food_beverage_rounded,'emoji': '🍵', 'desc': 'Tea varieties'},
    {'value': 'seed',      'label': 'Seeds',     'icon': Icons.grain_rounded,             'emoji': '🌱', 'desc': 'Plant seeds'},
    {'value': 'tool',      'label': 'Tools',     'icon': Icons.build_rounded,             'emoji': '🛠️', 'desc': 'Gardening tools'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _submitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Listen to price changes to dynamically update discount UI
    _priceController.addListener(() => setState(() {}));
    _originalPriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _pulseController.dispose();
    _submitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
  }

  Future<void> _submitListing() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _priceController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isSubmitting = true);

    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('You must be logged in to post listings');
      }
      return;
    }

    Uint8List? imageBytes;
    String? fileName;
    if (_selectedImage != null) {
      imageBytes = await _selectedImage!.readAsBytes();
      fileName = _selectedImage!.name;
    }

    final currentUser = await _authService.getCurrentUser();
    final errorStr = await _marketService.addProduct({
      'title': _titleController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'originalPrice': double.tryParse(_originalPriceController.text),
      'category': _selectedCategory,
      'stock': int.tryParse(_stockController.text) ?? 10,
      'emoji': _categories.firstWhere((c) => c['value'] == _selectedCategory)['emoji'],
      'sellerId': currentUser?.id ?? 's_demo',
      'sellerName': currentUser?.businessName ?? currentUser?.name ?? 'My Green Shop',
      'sellerLocation': currentUser?.location ?? 'Colombo, Sri Lanka',
    }, token, imageBytes: imageBytes, fileName: fileName);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (errorStr == null) {
        _showSuccessDialog();
      } else {
        _showError('Failed: $errorStr');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Listing Posted! 🎉',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your plant listing is now live on the marketplace!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const PremiumAppBar(
        title: 'Add New Listing',
        subtitle: 'List your plant for marketplace buyers',
      ),
      body: Stack(
        children: [
          // Animated background orbs
          Positioned(
            top: -60,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 200 + _pulseController.value * 20,
                height: 200 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.06),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withOpacity(0.05),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoSection(),
                        const SizedBox(height: 24),
                        _buildFormCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky submit button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Add New Listing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Text(
              '🌿 New',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: _selectedImage == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.12),
                        const Color(0xFF059669).withOpacity(0.06),
                      ],
                    )
                  : null,
              border: Border.all(
                color: _selectedImage != null
                    ? const Color(0xFF10B981).withOpacity(0.5)
                    : const Color(0xFF10B981).withOpacity(0.2 + _pulseController.value * 0.1),
                width: 1.5,
              ),
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3 + _pulseController.value * 0.15),
                          ),
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF10B981), size: 30),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tap to add photos',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG • Max 5MB',
                        style: TextStyle(
                          color: context.textPrimary.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb 
                          ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                                  SizedBox(width: 4),
                                  Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95), delay: 100.ms);
  }

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.textPrimary.withOpacity(0.05),
                context.textPrimary.withOpacity(0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.textPrimary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Product Details', Icons.info_outline_rounded),
              const SizedBox(height: 16),

              // Title
              _buildFieldLabel('Product Title *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Fresh Aloe Vera Plant',
                icon: Icons.label_rounded,
              ),
              const SizedBox(height: 16),

              // Category
              _buildFieldLabel('Category *'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Interactive Pricing Section
              _buildPricingSection(),
              const SizedBox(height: 16),

              // Stock
              _buildFieldLabel('Stock Quantity'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _stockController,
                hint: 'e.g. 50',
                icon: Icons.inventory_rounded,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Description
              _buildFieldLabel('Description *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descController,
                hint: 'Describe your product — care instructions, benefits, size...',
                icon: Icons.description_rounded,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.08, delay: 200.ms);
  }

  Widget _buildPricingSection() {
    final double? origPrice = double.tryParse(_originalPriceController.text);
    final double? currentPrice = double.tryParse(_priceController.text);
    
    int discountPercent = 0;
    if (origPrice != null && currentPrice != null && origPrice > currentPrice) {
      discountPercent = ((origPrice - currentPrice) / origPrice * 100).round();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scaffoldBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasDiscount ? const Color(0xFF10B981) : context.border,
          width: _hasDiscount ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildFieldLabel('Pricing Setup')),
              Row(
                children: [
                  Text('Offer Discount', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _hasDiscount,
                    onChanged: (val) {
                      setState(() {
                        _hasDiscount = val;
                        if (!val) {
                          _originalPriceController.clear();
                        }
                      });
                    },
                    activeColor: const Color(0xFF10B981),
                    inactiveTrackColor: Colors.grey.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_hasDiscount) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Original Price', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _originalPriceController,
                        hint: 'e.g. 2000',
                        icon: Icons.money_off_csred_rounded,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Final Price (Rs.) *', style: TextStyle(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _priceController,
                        hint: 'e.g. 1500',
                        icon: Icons.local_offer_rounded,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (discountPercent > 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.celebration_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Buyers will see a $discountPercent% OFF badge!',
                        style: const TextStyle(color: Color(0xFF044E39), fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Regular Price (Rs.) *', style: TextStyle(color: context.textPrimary, fontSize: 12)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _priceController,
                  hint: 'e.g. 1500',
                  icon: Icons.sell_rounded,
                  prefixText: 'Rs. ',
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: context.textPrimary.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.textPrimary.withOpacity(0.35), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF10B981).withOpacity(0.7), size: 18),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: maxLines > 1 ? 14 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: context.cardBg,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF10B981)),
          items: _categories.map((cat) => DropdownMenuItem<String>(
            value: cat['value'] as String,
            child: Row(
              children: [
                Icon(cat['icon'] as IconData, color: const Color(0xFF10B981), size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat['label'] as String,
                      style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      cat['desc'] as String,
                      style: TextStyle(color: context.textPrimary.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          )).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.scaffoldBg.withOpacity(0.8),
                context.scaffoldBg,
              ],
            ),
            border: Border(
              top: BorderSide(color: context.border),
            ),
          ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              return GestureDetector(
                onTap: _isSubmitting ? null : _submitListing,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: _isSubmitting
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withOpacity(0.4),
                              const Color(0xFF059669).withOpacity(0.4),
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _isSubmitting
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.35 + _pulseController.value * 0.1),
                              blurRadius: 20 + _pulseController.value * 6,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(Icons.publish_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _isSubmitting ? 'Posting Listing...' : 'Post Listing',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
