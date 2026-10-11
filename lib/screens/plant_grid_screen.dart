import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../data/plant_database.dart';
import '../models/plant_model.dart';
import '../data/herbal_market_data.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'plant_detail_screen.dart';
import 'cart_screen.dart';

class PlantGridScreen extends StatefulWidget {
  const PlantGridScreen({super.key});

  @override
  State<PlantGridScreen> createState() => _PlantGridScreenState();
}

class _PlantGridScreenState extends State<PlantGridScreen> {
  final List<PlantModel> _allPlants = PlantDatabase.allPlants;
  List<PlantModel> _filteredPlants = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Medicinal',
    'Culinary',
    'Aromatic',
    'Ayurvedic',
    'Easy Care',
  ];

  final Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _filteredPlants = _allPlants;
  }

  void _applyFilter() {
    setState(() {
      _filteredPlants = _allPlants.where((p) {
        final matchesSearch = _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.scientificName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

        if (!matchesSearch) return false;

        if (_selectedCategory == 'All') return true;
        if (_selectedCategory == 'Medicinal') {
          return p.tags.any((t) => t.contains('medicinal') || t.contains('ayurvedic') || t.contains('immune'));
        }
        if (_selectedCategory == 'Culinary') {
          return p.tags.any((t) => t.contains('culinary') || t.contains('spice') || t.contains('tea'));
        }
        if (_selectedCategory == 'Aromatic') {
          return p.tags.any((t) => t.contains('aromatic') || t.contains('fragrant') || t.contains('aromatherapy'));
        }
        if (_selectedCategory == 'Ayurvedic') {
          return p.tags.any((t) => t.contains('ayurvedic') || t.contains('sri-lankan'));
        }
        if (_selectedCategory == 'Easy Care') {
          return p.careInfo.difficulty.toLowerCase().contains('easy');
        }
        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String val) {
    _searchQuery = val.trim();
    _applyFilter();
  }

  void _onCategorySelected(String category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
    _applyFilter();
  }

  void _toggleFavorite(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  void _addToCart(PlantModel plant, HerbalPlantInfo info, {int quantity = 1}) {
    HapticFeedback.mediumImpact();
    final cart = context.read<CartProvider>();

    for (int i = 0; i < quantity; i++) {
      cart.addItem(
        CartItem(
          productId: plant.id,
          title: plant.name,
          price: info.price,
          sellerId: 'seller_herbal_oasis',
          imageUrl: info.imageUrl,
          emoji: plant.emoji,
        ),
      );
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added ${plant.name} to Cart! (Rs. ${info.price.toInt()})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _chatWithSeller(BuildContext modalCtx, PlantModel plant, HerbalPlantInfo info) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user ??
        UserModel(
          id: 'customer_guest',
          name: 'Customer',
          email: 'customer@plantora.com',
          joinedAt: DateTime.now(),
          role: 'Customer',
        );

    Navigator.pop(modalCtx);

    const sellerId = 'seller_herbal_oasis';
    final sellerName = info.sellerName;

    try {
      final chatData = await ChatService().initiateChat(
        user.id,
        sellerId,
        user.name,
        sellerName,
        null,
      );

      final chatId = (chatData?['chatId'] ?? chatData?['id'] ?? 'chat_${user.id}_$sellerId').toString();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chatId,
              otherParticipantName: sellerName,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: 'chat_${user.id}_$sellerId',
              otherParticipantName: sellerName,
            ),
          ),
        );
      }
    }
  }

  void _showPlantModal(PlantModel plant, HerbalPlantInfo info) {
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = context.isDark;

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.88,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Image Header with controls
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                child: SizedBox(
                                  height: 280,
                                  width: double.infinity,
                                  child: Image.network(
                                    info.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (c, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF10B981)),
                                        ),
                                      );
                                    },
                                    errorBuilder: (c, err, trace) => Container(
                                      color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                                      child: Center(
                                        child: Text(plant.emoji, style: const TextStyle(fontSize: 70)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Gradient Scrim
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.55),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.4),
                                      ],
                                      stops: const [0.0, 0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Close Button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(modalCtx),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),

                              // Drag handle
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 44,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                              // In-Stock & Difficulty badge
                              Positioned(
                                bottom: 16,
                                left: 20,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            'IN STOCK',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white24, width: 0.8),
                                      ),
                                      child: Text(
                                        plant.careInfo.difficulty.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Plant Details Body
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Scientific Name
                                Text(
                                  plant.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plant.scientificName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Ratings & Reviews
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            info.rating.toStringAsFixed(1),
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${info.reviews} reviews)',
                                            style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        '100% Organic',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Description
                                Text(
                                  'About this Herb',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plant.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    height: 1.55,
                                    color: context.textSecondary,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Medicinal & Culinary Uses
                                if (plant.uses.isNotEmpty) ...[
                                  Text(
                                    'Key Uses & Benefits',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: plant.uses.map((use) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              use,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Seller Card with Message Button
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xFF10B981),
                                        child: Text(
                                          info.sellerName.substring(0, 1),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              info.sellerName,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: context.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              info.sellerLocation,
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                color: context.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _chatWithSeller(modalCtx, plant, info),
                                        icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                                        label: Text(
                                          'Chat',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF10B981),
                                          side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                                          backgroundColor: const Color(0xFF10B981).withOpacity(0.08),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Botanical Encyclopedia Button
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(modalCtx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlantDetailScreen(plant: plant),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 18),
                                    label: Text(
                                      'View Complete Botanical & Care Guide',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF10B981),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sticky Bottom Buy / Cart Bar
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(modalCtx).padding.bottom + 14),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                      border: Border(top: BorderSide(color: context.border, width: 1)),
                    ),
                    child: Row(
                      children: [
                        // Price Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Price',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Rs. ${(info.price * quantity).toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        // Quantity Stepper
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove_rounded, size: 18),
                                onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                              ),
                              Text(
                                '$quantity',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                onPressed: () => setModalState(() => quantity++),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Add to Cart Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(modalCtx);
                                _addToCart(plant, info, quantity: quantity);
                              },
                              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                              label: Text(
                                'ADD TO CART',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // ── Ultra Premium Header ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF012E23),
                  Color(0xFF044E39),
                  Color(0xFF065F46),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Navigation Row
                Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Herbal Library & Market',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '40+ Medicinal & Culinary Herbs',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA7F3D0),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cart Badge Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text(
                                    '$cartCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Search Box
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search herbs by name or properties...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF047857), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Horizontal Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _onCategorySelected(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF34D399) : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.white24,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF064E3B) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Plants Marketplace Grid ──────────────────────────────────────
          Expanded(
            child: _filteredPlants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No herbal plants found for "$_searchQuery"',
                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            _onCategorySelected('All');
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.67,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredPlants.length,
                    itemBuilder: (context, index) {
                      final plant = _filteredPlants[index];
                      final info = HerbalMarketData.getInfo(plant.id, plant.name);
                      final isFav = _favoriteIds.contains(plant.id);

                      return _buildMarketPlantCard(plant, info, isFav, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPlantCard(
    PlantModel plant,
    HerbalPlantInfo info,
    bool isFav,
    int index,
  ) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => _showPlantModal(plant, info),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Badges
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: Image.network(
                      info.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (c, err, trace) => Container(
                        color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                        child: Center(
                          child: Text(plant.emoji, style: const TextStyle(fontSize: 44)),
                        ),
                      ),
                    ),
                  ),

                  // Difficulty Tag
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        plant.careInfo.difficulty.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Favorite Heart
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(plant.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Product Body
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant Name
                  Text(
                    plant.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Scientific Name
                  Text(
                    plant.scientificName,
                    style: GoogleFonts.inter(
                      color: context.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        info.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${info.reviews})',
                        style: GoogleFonts.inter(fontSize: 10, color: context.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price & Add to Cart Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs. ${info.price.toInt()}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            'Rs. ${info.originalPrice.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: context.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                      // Quick Add to Cart button
                      GestureDetector(
                        onTap: () => _addToCart(plant, info),
                        child: Container(
                          padding: const EdgeInsets.all(7.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index % 10 * 35).ms).slideY(begin: 0.08);
  }
}
