import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/localization_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';
import '../services/plant_identification_service.dart';
import '../models/plant_model.dart';
import 'ai_chat_screen.dart';
import 'chat_history_screen.dart';
import 'market_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  bool _hasPermissionError = false;
  bool _isPermissionPermanentlyDenied = false;

  Uint8List? _capturedImageBytes;
  String? _capturedImagePath;
  PlantModel? _scannedPlant;

  late AnimationController _pulseController;
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _hasPermissionError = false;
        _isPermissionPermanentlyDenied = false;
      });
    }
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS)) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
        }
        if (status.isPermanentlyDenied) {
          if (mounted) {
            setState(() {
              _hasPermissionError = true;
              _isPermissionPermanentlyDenied = true;
            });
          }
          return;
        } else if (!status.isGranted) {
          if (mounted) {
            setState(() {
              _hasPermissionError = true;
              _isPermissionPermanentlyDenied = false;
            });
          }
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _initControllerWithIndex(_selectedCameraIndex);
      } else {
        if (mounted) setState(() => _hasPermissionError = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) setState(() => _hasPermissionError = true);
    }
  }

  Future<void> _initControllerWithIndex(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;
    final controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraReady = true;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize camera at index $index: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _isFlashOn = !_isFlashOn;
        await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
        HapticFeedback.selectionClick();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Flash toggle error: $e');
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      HapticFeedback.lightImpact();
      setState(() => _isCameraReady = false);
      await _cameraController?.dispose();
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      await _initControllerWithIndex(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    if (_isCapturing || _isAnalyzing) return;
    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();
        if (mounted) setState(() => _isCapturing = false);
        _processAndIdentifyImage(image.path);
        return;
      } catch (e) {
        debugPrint('Camera capture failed: $e');
      }
    }

    // Fallback to ImagePicker
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (mounted) setState(() => _isCapturing = false);
      if (image != null) {
        _processAndIdentifyImage(image.path);
      }
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
      _showError('Error opening camera: $e');
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isAnalyzing) return;
    HapticFeedback.lightImpact();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        _processAndIdentifyImage(image.path);
      }
    } catch (e) {
      _showError('Error opening gallery: $e');
    }
  }

  Future<void> _processAndIdentifyImage(String imagePath) async {
    final XFile imageFile = XFile(imagePath);
    final bytes = await imageFile.readAsBytes();

    if (!mounted) return;

    setState(() {
      _isAnalyzing = true;
      _capturedImageBytes = bytes;
      _capturedImagePath = imagePath;
      _scannedPlant = null;
    });

    try {
      final res = await PlantIdentificationService.identifyPlant(bytes, imageFile.name);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        if (res['success'] == true && res['plant'] != null) {
          setState(() {
            _scannedPlant = res['plant'] as PlantModel;
          });
          _openGoogleLensSheet();
        } else {
          _showError(res['message'] ?? 'Failed to identify plant. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showError('Identification error: $e');
      }
    }
  }

  void _openGoogleLensSheet() {
    if (_scannedPlant == null || _capturedImageBytes == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _GoogleLensResultsSheet(
        plant: _scannedPlant!,
        imageBytes: _capturedImageBytes!,
        imagePath: _capturedImagePath ?? '',
        onScanAnother: () {
          Navigator.pop(ctx);
          setState(() {
            _scannedPlant = null;
            _capturedImageBytes = null;
          });
        },
        onOpenChat: (initialQuestion) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiChatScreen(
                imageFile: _capturedImagePath != null ? XFile(_capturedImagePath!) : null,
                imageBytes: _capturedImageBytes,
                initialQuestion: initialQuestion,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Fullscreen Camera Viewfinder ──────────────────────────────
          if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            _buildCameraFallback(),

          // ── 2. Center Google Lens Framing Reticle ────────────────────────
          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(270, 270),
                    painter: _LensBracketPainter(isScanning: _isAnalyzing),
                  ),
                  // Animated Scanning Laser Beam when AI is identifying
                  if (_isAnalyzing)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, _) {
                        final yOffset = (_laserController.value * 240) + 15;
                        return Positioned(
                          top: yOffset,
                          left: 15,
                          right: 15,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF38BDF8),
                                  Color(0xFF34D399),
                                  Color(0xFF38BDF8),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF34D399).withOpacity(0.8),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    // Subtle pulsing target indicator
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Opacity(
                          opacity: 0.35 + (_pulseController.value * 0.35),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // ── 3. Top Mode Hint Floating Chip ───────────────────────────────
          Positioned(
            top: topPadding + 64,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAnalyzing ? Icons.auto_awesome_rounded : Icons.search_rounded,
                      size: 15,
                      color: _isAnalyzing ? const Color(0xFF38BDF8) : const Color(0xFF34D399),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _isAnalyzing ? '✦ Analyzing Plant with AI...' : loc.translate('scan_description'),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 4. Top Navigation Header Bar ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(8, topPadding + 4, 8, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? Colors.amberAccent : Colors.white,
                      size: 22,
                    ),
                    onPressed: _toggleFlash,
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.center_focus_strong_rounded, color: Color(0xFF34D399), size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Plantora Lens',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                    tooltip: 'Scan History',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
                    tooltip: 'Guidelines',
                    onPressed: () => _showGuidelinesModal(context, loc),
                  ),
                ],
              ),
            ),
          ),

          // ── 5. Bottom Controls & Mode Bar ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.92),
                    Colors.black.withOpacity(0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Gallery Picker
                      GestureDetector(
                        onTap: _scanFromGallery,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Center: Big Google Lens Shutter Button
                      GestureDetector(
                        onTap: _scanFromCamera,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: (_isCapturing || _isAnalyzing)
                                  ? const Center(
                                      child: SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Right: Flip Camera
                      GestureDetector(
                        onTap: _flipCamera,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.flip_camera_ios_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF061A14),
            Color(0xFF03221A),
            Color(0xFF021611),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasPermissionError 
                      ? Colors.amber.withOpacity(0.15) 
                      : const Color(0xFF10B981).withOpacity(0.15),
                ),
                child: Icon(
                  _hasPermissionError ? Icons.camera_enhance_rounded : Icons.camera_alt_outlined,
                  size: 48,
                  color: _hasPermissionError ? Colors.amberAccent : const Color(0xFF34D399),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasPermissionError 
                    ? (_isPermissionPermanentlyDenied ? 'Camera Access Denied' : 'Camera Permission Required')
                    : 'Initializing Camera...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _hasPermissionError
                    ? (_isPermissionPermanentlyDenied
                        ? 'Please enable camera permission in App Settings to scan plants'
                        : 'Grant camera access to scan plants directly')
                    : 'Or tap gallery below to pick an image',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
              if (_hasPermissionError) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_isPermissionPermanentlyDenied) {
                      openAppSettings();
                    } else {
                      _initializeCamera();
                    }
                  },
                  icon: Icon(
                    _isPermissionPermanentlyDenied ? Icons.settings_rounded : Icons.lock_open_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isPermissionPermanentlyDenied ? 'Open Settings' : 'Enable Camera',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGuidelinesModal(BuildContext context, LocalizationProvider loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF34D399), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Plant Lens Guidelines',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGuidelineStep(
                icon: Icons.filter_center_focus_rounded,
                title: 'Center the Leaf or Bloom',
                desc: 'Keep the subject inside the rounded brackets with good natural lighting.',
              ),
              const SizedBox(height: 12),
              _buildGuidelineStep(
                icon: Icons.wb_sunny_outlined,
                title: 'Avoid Blurry Images',
                desc: 'Hold your device steady. If it is too dark, toggle the flash icon above.',
              ),
              const SizedBox(height: 12),
              _buildGuidelineStep(
                icon: Icons.auto_awesome_rounded,
                title: 'Instant Botanical AI',
                desc: 'Get identification, health diagnosis, and tailored care recommendations.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuidelineStep({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF34D399), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.5, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Google Lens Curved Bracket Corner Reticle Painter ──────────────────────
class _LensBracketPainter extends CustomPainter {
  final bool isScanning;
  _LensBracketPainter({this.isScanning = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isScanning ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isScanning ? 3.8 : 3.2
      ..strokeCap = StrokeCap.round;

    const cornerRadius = 32.0;
    const cornerLength = 46.0;

    // Top Left
    final tlPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius)
      ..arcToPoint(const Offset(cornerRadius, 0), radius: const Radius.circular(cornerRadius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tlPath, paint);

    // Top Right
    final trPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..arcToPoint(Offset(size.width, cornerRadius), radius: const Radius.circular(cornerRadius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(trPath, paint);

    // Bottom Right
    final brPath = Path()
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - cornerRadius)
      ..arcToPoint(Offset(size.width - cornerRadius, size.height), radius: const Radius.circular(cornerRadius))
      ..lineTo(size.width - cornerLength, size.height);
    canvas.drawPath(brPath, paint);

    // Bottom Left
    final blPath = Path()
      ..moveTo(cornerLength, size.height)
      ..lineTo(cornerRadius, size.height)
      ..arcToPoint(Offset(0, size.height - cornerRadius), radius: const Radius.circular(cornerRadius))
      ..lineTo(0, size.height - cornerLength);
    canvas.drawPath(blPath, paint);
  }

  @override
  bool shouldRepaint(covariant _LensBracketPainter oldDelegate) {
    return oldDelegate.isScanning != isScanning;
  }
}

// ============================================================================
// ── Google Lens Style Bottom Sheet Results Modal (Light/Dark Adaptive) ──────
// ============================================================================
class _GoogleLensResultsSheet extends StatefulWidget {
  final PlantModel plant;
  final Uint8List imageBytes;
  final String imagePath;
  final VoidCallback onScanAnother;
  final Function(String initialQuestion) onOpenChat;

  const _GoogleLensResultsSheet({
    required this.plant,
    required this.imageBytes,
    required this.imagePath,
    required this.onScanAnother,
    required this.onOpenChat,
  });

  @override
  State<_GoogleLensResultsSheet> createState() => _GoogleLensResultsSheetState();
}

class _GoogleLensResultsSheetState extends State<_GoogleLensResultsSheet> {
  int _selectedTabIndex = 1; // Default: 1 -> 'All'

  final List<String> _tabs = [
    'AI Mode',
    'All',
    'Care Specs',
    'Diseases',
    'Buy Plant',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Theme Adaptive Color Tokens
    final sheetBg = isDark ? const Color(0xFF072418) : Colors.white; // Dark Green in dark mode, White in light mode
    final dragPillColor = isDark ? Colors.white38 : const Color(0xFFCBD5E1);
    final searchPillBg = isDark ? const Color(0xFF0F3D2A) : const Color(0xFFF1F5F9);
    final searchPillBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final searchTextColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final searchIconColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    final tabDividerColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final tabActiveText = isDark ? Colors.white : const Color(0xFF0F172A);
    final tabInactiveText = isDark ? Colors.white54 : const Color(0xFF64748B);
    final tabActiveUnderline = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            children: [
              // 1. Sheet Drag Handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: dragPillColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Google Lens Search Pill Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: searchPillBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                    side: BorderSide(color: searchPillBorder, width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => widget.onOpenChat('Tell me more about this ${widget.plant.name} (${widget.plant.scientificName})'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Google / Plantora Multi-color AI Icon
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 10),
                          // Image Thumbnail Preview
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              widget.imageBytes,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Search Input Text Placeholder
                          Expanded(
                            child: Text(
                              'Ask about this image',
                              style: GoogleFonts.inter(
                                color: searchTextColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.search_rounded, color: searchIconColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Tab Filter Bar (AI Mode | All | Care Specs | Diseases | Buy Plant)
              Container(
                height: 38,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tabDividerColor, width: 1)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedTabIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTabIndex = index);
                        if (index == 0) {
                          // Tap on 'AI Mode' opens chat
                          widget.onOpenChat('I have questions about this ${widget.plant.name}');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? tabActiveUnderline : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          style: GoogleFonts.inter(
                            color: isSelected ? tabActiveText : tabInactiveText,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. Tab Body Content (Scrollable)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (_selectedTabIndex == 1) _buildAllOverviewTab(context, isDark),
                    if (_selectedTabIndex == 2) _buildCareSpecsTab(context, isDark),
                    if (_selectedTabIndex == 3) _buildDiseasesTab(context, isDark),
                    if (_selectedTabIndex == 4) _buildBuyPlantTab(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 1: All Overview (Google Lens AI Overview Style) ───────────────────
  Widget _buildAllOverviewTab(BuildContext context, bool isDark) {
    final confidencePct = (widget.plant.confidenceScore * 100).toInt();

    final overviewBg = isDark ? const Color(0xFF0E3D28) : const Color(0xFFF8FAFC);
    final overviewBorder = isDark ? const Color(0xFF34D399).withOpacity(0.35) : const Color(0xFFCBD5E1);
    final headerTitleColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyTextColor = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final scientificColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final matchBadgeBg = isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFDCFCE7);
    final matchBadgeText = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);

    final tagPillBg = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final tagPillText = isDark ? Colors.white70 : const Color(0xFF475569);

    final cardBg = isDark ? const Color(0xFF0A2B1B) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✦ AI Overview Card (Matching Google Lens Screenshot)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: overviewBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: overviewBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: headerTitleColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI Overview',
                    style: GoogleFonts.outfit(
                      color: headerTitleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: matchBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$confidencePct% Match',
                      style: GoogleFonts.inter(
                        color: matchBadgeText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(color: bodyTextColor, fontSize: 14, height: 1.45),
                  children: [
                    const TextSpan(text: 'The plant in your image appears to be an '),
                    TextSpan(
                      text: widget.plant.name,
                      style: TextStyle(fontWeight: FontWeight.w700, color: primaryTextColor, textBaseline: TextBaseline.alphabetic),
                    ),
                    TextSpan(
                      text: ' (${widget.plant.scientificName})',
                      style: TextStyle(fontStyle: FontStyle.italic, color: scientificColor),
                    ),
                    TextSpan(
                      text: widget.plant.uses.isNotEmpty 
                          ? ', widely recognized for ${widget.plant.uses.first.toLowerCase()}.'
                          : '.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.plant.description,
                style: GoogleFonts.inter(color: subTextColor, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagPillBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined, color: headerTitleColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Plantora AI +1',
                          style: GoogleFonts.inter(color: tagPillText, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Botanical Identity Specs Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Botanical Taxonomy',
                style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _buildSpecRow('Common Name', widget.plant.name, isDark: isDark),
              _buildSpecRow('Scientific Name', widget.plant.scientificName, isItalic: true, isDark: isDark),
              _buildSpecRow('Botanical Family', widget.plant.family, isDark: isDark),
              _buildSpecRow('Category', widget.plant.category.toUpperCase(), isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Care Guide Cards Grid
        Text(
          'Care Requirements',
          style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildCareQuickCard(Icons.wb_sunny_outlined, 'Sunlight', widget.plant.careInfo.sunlightRequirement, const Color(0xFFF59E0B), isDark),
            _buildCareQuickCard(Icons.water_drop_outlined, 'Watering', widget.plant.careInfo.wateringFrequency, const Color(0xFF3B82F6), isDark),
            _buildCareQuickCard(Icons.grass_outlined, 'Soil Mix', widget.plant.careInfo.soilType, const Color(0xFF10B981), isDark),
            _buildCareQuickCard(Icons.thermostat_outlined, 'Temperature', widget.plant.careInfo.temperature, const Color(0xFFEC4899), isDark),
          ],
        ),
        const SizedBox(height: 20),

        // Action Buttons Row (Buy on Marketplace | Ask AI Chatbot | Scan Another)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketScreen()),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text('Find in Shop', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onOpenChat('How do I take care of ${widget.plant.name}?'),
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: headerTitleColor),
                label: Text('Ask Chatbot', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: headerTitleColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: headerTitleColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: widget.onScanAnother,
            icon: Icon(Icons.camera_alt_outlined, color: subTextColor, size: 16),
            label: Text('Scan Another Plant', style: GoogleFonts.inter(color: subTextColor, fontSize: 12.5)),
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Care Specs Detailed View ───────────────────────────────────────
  Widget _buildCareSpecsTab(BuildContext context, bool isDark) {
    final c = widget.plant.careInfo;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Care Requirements', style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _buildCareDetailTile(Icons.wb_sunny_outlined, 'Sunlight & Lighting', c.sunlightRequirement, 'Keep in bright position according to requirement.', isDark),
        _buildCareDetailTile(Icons.water_drop_outlined, 'Watering Schedule', c.wateringFrequency, 'Water thoroughly when soil surface feels dry.', isDark),
        _buildCareDetailTile(Icons.grass_outlined, 'Soil & Potting Mix', c.soilType, 'Ensure good drainage to avoid root rot.', isDark),
        _buildCareDetailTile(Icons.thermostat_outlined, 'Ideal Temperature', c.temperature, 'Protect from extreme heat or freezing drafts.', isDark),
        _buildCareDetailTile(Icons.opacity_outlined, 'Humidity Level', c.humidity, 'Mist leaves during dry seasons.', isDark),
        _buildCareDetailTile(Icons.eco_outlined, 'Fertilization', c.fertilizer, 'Feed with organic liquid fertilizer during growing period.', isDark),
        _buildCareDetailTile(Icons.content_cut_rounded, 'Pruning', c.pruning, 'Remove yellowed or dead leaves regularly.', isDark),
      ],
    );
  }

  // ── Tab 3: Diseases & Health Diagnostic View ─────────────────────────────
  Widget _buildDiseasesTab(BuildContext context, bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF0E3D28) : const Color(0xFFF8FAFC);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plant Disease & Health Diagnostic', style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('General Health Check', style: GoogleFonts.inter(color: primaryTextColor, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('No severe visible leaf blights or fungal lesions detected on foliage.', style: GoogleFonts.inter(color: subTextColor, fontSize: 12.5, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Common Issues & Prevention', style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _buildDiseaseItem('Yellowing Leaves', 'Overwatering or poor drainage. Let top soil dry out before watering.', isDark),
        _buildDiseaseItem('Brown Leaf Tips', 'Low ambient humidity or tap water mineral buildup. Use filtered water.', isDark),
        _buildDiseaseItem('Aphids & Mites', 'Spray organic Neem oil solution (1 tsp neem oil + liquid soap in 1L water).', isDark),
      ],
    );
  }

  // ── Tab 4: Buy Plant / Shop Products View ─────────────────────────────────
  Widget _buildBuyPlantTab(BuildContext context, bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plantora Store Essentials', style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Supplies recommended for ${widget.plant.name}:', style: GoogleFonts.inter(color: subTextColor, fontSize: 13)),
        const SizedBox(height: 16),
        _buildStoreProductTile('Organic Potting Soil Mix (5kg)', 'Rs. 850', Icons.grass_outlined, isDark),
        _buildStoreProductTile('Seaweed Liquid Fertilizer (500ml)', 'Rs. 1,200', Icons.eco_outlined, isDark),
        _buildStoreProductTile('Self-Watering Terracotta Pot', 'Rs. 1,450', Icons.grid_view_rounded, isDark),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketScreen()),
              );
            },
            icon: const Icon(Icons.storefront_rounded),
            label: Text('Explore Plantora Marketplace', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildSpecRow(String label, String value, {bool isItalic = false, required bool isDark}) {
    final labelColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: labelColor, fontSize: 12.5)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareQuickCard(IconData icon, String title, String val, Color iconColor, bool isDark) {
    final bg = isDark ? const Color(0xFF0A2B1B) : const Color(0xFFF1F5F9);
    final border = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final valColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.inter(color: titleColor, fontSize: 11, fontWeight: FontWeight.w500)),
                Text(val, style: GoogleFonts.inter(color: valColor, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareDetailTile(IconData icon, String title, String val, String tip, bool isDark) {
    final bg = isDark ? const Color(0xFF0A2B1B) : const Color(0xFFF8FAFC);
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final tipColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(color: titleColor, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        val,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tip, style: GoogleFonts.inter(color: tipColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseItem(String title, String desc, bool isDark) {
    final bg = isDark ? const Color(0xFF0A2B1B) : const Color(0xFFF8FAFC);
    final border = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final descColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(desc, style: GoogleFonts.inter(color: descColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStoreProductTile(String title, String price, IconData icon, bool isDark) {
    final bg = isDark ? const Color(0xFF0A2B1B) : const Color(0xFFF8FAFC);
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: titleColor, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(price, style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 14),
        ],
      ),
    );
  }
}