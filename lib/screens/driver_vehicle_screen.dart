import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class DriverVehicleScreen extends StatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen>
    with TickerProviderStateMixin {
  String _vehicleName = 'Honda Dio';
  String _licensePlate = 'WP BFE-1234';
  String _vehicleType = 'Motorcycle';
  String _vehicleColor = 'Matte Black';
  String _vehicleYear = '2022';
  bool _isActive = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Vehicle Registration',
      'subtitle': 'Valid until Dec 2026',
      'icon': Icons.description_rounded,
      'color': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFEFF6FF),
      'darkBgColor': const Color(0xFF1E3A5F),
      'isValid': true,
      'fileName': null,
      'status': 'Verified',
    },
    {
      'title': 'Insurance Policy',
      'subtitle': 'Valid until Jun 2026',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFFECFDF5),
      'darkBgColor': const Color(0xFF064E3B),
      'isValid': true,
      'fileName': null,
      'status': 'Verified',
    },
    {
      'title': "Driver's License",
      'subtitle': 'Valid until Mar 2027',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFFBEB),
      'darkBgColor': const Color(0xFF451A03),
      'isValid': true,
      'fileName': null,
      'status': 'Verified',
    },
  ];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'name': 'Motorcycle', 'icon': Icons.two_wheeler_rounded, 'emoji': '🏍️'},
    {'name': 'Car', 'icon': Icons.directions_car_rounded, 'emoji': '🚗'},
    {'name': 'Van', 'icon': Icons.airport_shuttle_rounded, 'emoji': '🚐'},
    {'name': 'Truck', 'icon': Icons.local_shipping_rounded, 'emoji': '🚚'},
    {'name': 'Tuk Tuk', 'icon': Icons.electric_rickshaw_rounded, 'emoji': '🛺'},
    {'name': 'Bicycle', 'icon': Icons.pedal_bike_rounded, 'emoji': '🚴'},
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.vehicleType != null && user.vehicleType!.isNotEmpty) {
      _vehicleType = user.vehicleType!;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData get _vehicleIcon {
    switch (_vehicleType) {
      case 'Car':
        return Icons.directions_car_rounded;
      case 'Van':
        return Icons.airport_shuttle_rounded;
      case 'Truck':
        return Icons.local_shipping_rounded;
      case 'Tuk Tuk':
        return Icons.electric_rickshaw_rounded;
      case 'Bicycle':
        return Icons.pedal_bike_rounded;
      default:
        return Icons.two_wheeler_rounded;
    }
  }

  String get _vehicleEmoji {
    switch (_vehicleType) {
      case 'Car':
        return '🚗';
      case 'Van':
        return '🚐';
      case 'Truck':
        return '🚚';
      case 'Tuk Tuk':
        return '🛺';
      case 'Bicycle':
        return '🚴';
      default:
        return '🏍️';
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(message,
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
    ));
  }

  void _showEditVehicleSheet() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final nameController = TextEditingController(text: _vehicleName);
    final plateController = TextEditingController(text: _licensePlate);
    final colorController = TextEditingController(text: _vehicleColor);
    final yearController = TextEditingController(text: _vehicleYear);
    String selectedType = _vehicleType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Vehicle Info',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Type Grid
                        Text(
                          'VEHICLE TYPE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.1,
                          children: _vehicleTypes.map((type) {
                            final isSelected = selectedType == type['name'];
                            return GestureDetector(
                              onTap: () =>
                                  setModal(() => selectedType = type['name'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : Colors.grey.withOpacity(0.15),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981)
                                                .withOpacity(0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      type['emoji'] as String,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Input fields
                        _buildSheetField(
                          controller: nameController,
                          label: 'Vehicle Name',
                          hint: 'e.g. Honda Dio 125',
                          icon: Icons.directions_car_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildSheetField(
                          controller: plateController,
                          label: 'License Plate',
                          hint: 'e.g. WP BFE-1234',
                          icon: Icons.badge_rounded,
                          isDark: isDark,
                          isUppercase: true,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSheetField(
                                controller: colorController,
                                label: 'Vehicle Color',
                                hint: 'e.g. Matte Black',
                                icon: Icons.color_lens_rounded,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSheetField(
                                controller: yearController,
                                label: 'Year',
                                hint: 'e.g. 2022',
                                icon: Icons.calendar_today_rounded,
                                isDark: isDark,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _vehicleType = selectedType;
                                if (nameController.text.trim().isNotEmpty) {
                                  _vehicleName = nameController.text.trim();
                                }
                                if (plateController.text.trim().isNotEmpty) {
                                  _licensePlate =
                                      plateController.text.trim().toUpperCase();
                                }
                                if (colorController.text.trim().isNotEmpty) {
                                  _vehicleColor = colorController.text.trim();
                                }
                                if (yearController.text.trim().isNotEmpty) {
                                  _vehicleYear = yearController.text.trim();
                                }
                              });
                              final auth = context.read<AuthProvider>();
                              if (auth.user != null) {
                                auth.updateProfile(auth.user!.copyWith(vehicleType: selectedType));
                              }
                              Navigator.pop(context);
                              _showSuccess('Vehicle updated successfully!');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isUppercase = false,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: isUppercase
              ? TextCapitalization.characters
              : TextCapitalization.words,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            prefixIcon: Icon(icon,
                color: const Color(0xFF10B981), size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadDocument(int docIndex) async {
    final picker = ImagePicker();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Upload Document',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 20),
            _buildSourceTile(
              ctx,
              Icons.photo_library_rounded,
              'Choose from Gallery',
              'Select a photo from your gallery',
              const Color(0xFF10B981),
              ImageSource.gallery,
              isDark,
            ),
            const SizedBox(height: 8),
            _buildSourceTile(
              ctx,
              Icons.camera_alt_rounded,
              'Take a Photo',
              'Capture with your camera',
              const Color(0xFF3B82F6),
              ImageSource.camera,
              isDark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? file =
        await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      final fileName =
          file.name.isNotEmpty ? file.name : file.path.split('/').last;
      setState(() {
        _documents[docIndex] = {
          ..._documents[docIndex],
          'fileName': fileName,
          'subtitle': 'Uploaded: $fileName',
          'isValid': true,
          'status': 'Uploaded',
        };
      });
      _showSuccess('"${_documents[docIndex]['title']}" uploaded!');
    }
  }

  Widget _buildSourceTile(BuildContext ctx, IconData icon, String title,
      String subtitle, Color color, ImageSource source, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, source),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    )),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F7F4);
    final cardColor = isDark ? const Color(0xFF1A2332) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ──────────────── SLIVER APP BAR ────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: textPrimary),
              ),
            ),
            title: Text(
              'Vehicle Profile',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: textPrimary,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _showEditVehicleSheet,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 5),
                      Text('Edit',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ──────────────── HERO VEHICLE CARD ────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.45),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 30,
                          bottom: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Big vehicle emoji
                        Positioned(
                          right: 20,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              _vehicleEmoji,
                              style: const TextStyle(fontSize: 90),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge
                              Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnim,
                                    builder: (_, __) => Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withOpacity(_pulseAnim.value),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isActive
                                        ? 'Available for Delivery'
                                        : 'Offline',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Toggle
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _isActive = !_isActive),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isActive
                                                ? Icons.toggle_on_rounded
                                                : Icons.toggle_off_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isActive ? 'ON' : 'OFF',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Vehicle name
                              Text(
                                _vehicleName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_vehicleYear · $_vehicleColor · $_vehicleType',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // License plate
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.numbers_rounded,
                                        color: Colors.white70, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _licensePlate,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(
                      begin: const Offset(0.95, 0.95),
                      duration: 500.ms,
                      curve: Curves.easeOutBack),

                  const SizedBox(height: 28),

                  // ──────────────── QUICK STATS ────────────────
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.local_shipping_rounded,
                        label: 'Total Trips',
                        value: '248',
                        color: const Color(0xFF3B82F6),
                        bgColor: isDark
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFFEFF6FF),
                        cardColor: cardColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.star_rounded,
                        label: 'Driver Rating',
                        value: '4.9★',
                        color: const Color(0xFFF59E0B),
                        bgColor: isDark
                            ? const Color(0xFF451A03)
                            : const Color(0xFFFFFBEB),
                        cardColor: cardColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.timeline_rounded,
                        label: 'This Month',
                        value: '32',
                        color: const Color(0xFF10B981),
                        bgColor: isDark
                            ? const Color(0xFF064E3B)
                            : const Color(0xFFECFDF5),
                        cardColor: cardColor,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ──────────────── VEHICLE DETAILS SECTION ────────────────
                  _buildSectionHeader('Vehicle Details', textPrimary),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.directions_car_rounded,
                            'Vehicle Name', _vehicleName, const Color(0xFF10B981), isDark, textPrimary, textSecondary, isFirst: true),
                        _buildDetailDivider(isDark),
                        _buildDetailRow(Icons.category_rounded,
                            'Vehicle Type', _vehicleType, const Color(0xFF3B82F6), isDark, textPrimary, textSecondary),
                        _buildDetailDivider(isDark),
                        _buildDetailRow(Icons.color_lens_rounded,
                            'Color', _vehicleColor, const Color(0xFFF59E0B), isDark, textPrimary, textSecondary),
                        _buildDetailDivider(isDark),
                        _buildDetailRow(Icons.calendar_month_rounded,
                            'Year', _vehicleYear, const Color(0xFF8B5CF6), isDark, textPrimary, textSecondary),
                        _buildDetailDivider(isDark),
                        _buildDetailRow(Icons.badge_rounded,
                            'License Plate', _licensePlate, const Color(0xFFEF4444), isDark, textPrimary, textSecondary, isLast: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                  const SizedBox(height: 28),

                  // ──────────────── DOCUMENTS SECTION ────────────────
                  Row(
                    children: [
                      _buildSectionHeader('Documents & Verification', textPrimary),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _addNewDocument(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _documents.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildDocumentCard(
                          _documents[i], i, cardColor, isDark, textPrimary),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ──────────────── UPDATE BUTTON ────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _showEditVehicleSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        shadowColor:
                            const Color(0xFF10B981).withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Update Vehicle Information',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color cardColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
    Color textPrimary,
    Color textSecondary, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, int index,
      Color cardColor, bool isDark, Color textPrimary) {
    final bool hasFile = doc['fileName'] != null;
    final bool isVerified = doc['status'] == 'Verified';
    final Color accentColor = doc['color'] as Color;

    return GestureDetector(
      onTap: () => _uploadDocument(index),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF10B981).withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? (doc['darkBgColor'] as Color)
                    : (doc['bgColor'] as Color),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(doc['icon'] as IconData,
                  color: accentColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['title'] as String,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc['subtitle'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Status badge
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified_rounded
                            : Icons.upload_rounded,
                        size: 13,
                        color: isVerified
                            ? const Color(0xFF10B981)
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doc['status'] as String,
                        style: GoogleFonts.inter(
                          color: isVerified
                              ? const Color(0xFF10B981)
                              : Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to update',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 80)).slideX(begin: 0.05),
    );
  }

  void _addNewDocument() {
    final newIndex = _documents.length;
    setState(() {
      _documents.add({
        'title': 'New Document',
        'subtitle': 'Not yet uploaded',
        'icon': Icons.upload_file_rounded,
        'color': const Color(0xFF8B5CF6),
        'bgColor': const Color(0xFFF5F3FF),
        'darkBgColor': const Color(0xFF2D1B69),
        'isValid': false,
        'fileName': null,
        'status': 'Upload',
      });
    });
    _uploadDocument(newIndex);
  }
}
