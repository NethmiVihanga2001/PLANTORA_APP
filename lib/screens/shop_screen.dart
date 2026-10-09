import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/premium_app_bar.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import 'product_detail_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/cart_item_model.dart';
import 'chat_detail_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShopScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerLocation;
  final String? sellerAvatar;

  const ShopScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLocation,
    this.sellerAvatar,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  bool _isLoading = true;
  List<ProductModel> _products = [];
  String? _shopImage;
  String? _sellerAvatar;
  List<dynamic> _ads = [];
  late PageController _adPageController;
  int _currentAdPage = 0;

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    _loadShopData();
  }

  @override
  void dispose() {
    _adPageController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexStr, Color defaultColor) {
    if (hexStr == null || hexStr.isEmpty) return defaultColor;
    try {
      if (hexStr.startsWith('0xFF') || hexStr.startsWith('0xff')) {
        return Color(int.parse(hexStr));
      }
      if (hexStr.startsWith('#')) {
        return Color(int.parse(hexStr.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(hexStr));
    } catch (e) {
      return defaultColor;
    }
  }

  Future<void> _loadShopData() async {
    final products = await _marketplaceService.getProductsBySeller(widget.sellerId);
    
    String? shopImage;
    String? sellerAvatar;
    List<dynamic> ads = [];
    
    try {
      final userRes = await http.get(Uri.parse('${AppConfig.baseUrl}/users/${widget.sellerId}'));
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        shopImage = userData['shopImage'];
        sellerAvatar = userData['avatarUrl'] ?? userData['shopImage'];
      }
      
      final adsRes = await http.get(Uri.parse('${AppConfig.baseUrl}/ads/${widget.sellerId}'));
      if (adsRes.statusCode == 200) {
        ads = jsonDecode(adsRes.body);
      }
    } catch (e) {
      debugPrint('Error fetching shop extra data: $e');
    }

    setState(() {
      _products = products;
      _shopImage = shopImage;
      _sellerAvatar = sellerAvatar;
      _ads = ads;
      _isLoading = false;
    });
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final effectiveAvatar = _sellerAvatar ?? _shopImage ?? widget.sellerAvatar;
    final hasAvatar = effectiveAvatar != null && effectiveAvatar.trim().isNotEmpty && effectiveAvatar != 'null';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Photo / Banner
        Container(
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _shopImage == null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F5A32),
                      Color(0xFF1E8C51),
                      Color(0xFF22C55E),
                    ],
                  )
                : null,
            image: _shopImage != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      _shopImage!.startsWith('http') ? _shopImage! : '${AppConfig.baseUrl}$_shopImage',
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),

        // Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),

        // Glassmorphism Shop Info Card
        Positioned(
          bottom: -45,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: context.isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: context.scaffoldBg,
                    backgroundImage: hasAvatar
                        ? NetworkImage(effectiveAvatar.startsWith('http') 
                            ? effectiveAvatar 
                            : '${AppConfig.baseUrl}$effectiveAvatar')
                        : null,
                    child: !hasAvatar
                        ? Text(
                            widget.sellerName.isNotEmpty ? widget.sellerName.substring(0, 1).toUpperCase() : 'S',
                            style: const TextStyle(color: Color(0xFF1E8C51), fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.sellerName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.sellerLocation,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2, curve: Curves.easeOutBack, duration: 500.ms).fadeIn(),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context, ProductModel product, int index) {
    String imageUrl = product.imageUrl;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '${AppConfig.baseUrl}$imageUrl';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black.withOpacity(0.4) : AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: context.scaffoldBg),
                          errorWidget: (context, url, error) => Container(
                            color: context.scaffoldBg,
                            child: const Center(child: Icon(Icons.local_florist, size: 40, color: Colors.grey)),
                          ),
                        )
                      : Container(color: context.scaffoldBg),
                  // Price Tag Overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Text(
                        'Rs. ${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.primaryGreen, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )).animate().scale(delay: (100 * (index % 6)).ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(duration: 500.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = await AuthService().getCurrentUser();
          if (user != null) {
            final chatData = await ChatService().initiateChat(
              user.id,
              widget.sellerId,
              user.name,
              widget.sellerName,
              widget.sellerAvatar,
            );
            if (chatData != null && context.mounted) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  chatId: chatData['id'],
                  otherParticipantName: widget.sellerName,
                ),
              ));
            }
          }
        },
        backgroundColor: const Color(0xFF166534),
        child: const Icon(Icons.forum_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
          children: [
            _buildPremiumHeader(context),
            const SizedBox(height: 60), // Balanced space for overlapping header card
            if (_ads.isNotEmpty)
              Container(
                height: 160,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: PageView.builder(
                  controller: _adPageController,
                  itemCount: _ads.length,
                  onPageChanged: (i) => setState(() => _currentAdPage = i),
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    final hasImage = ad['imageUrl'] != null && ad['imageUrl'].toString().isNotEmpty;
                    final color1 = _parseColor(ad['colorHex'], const Color(0xFF0F5A32));
                    final color2 = _parseColor(ad['colorHexSecondary'], const Color(0xFF34D399));
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: hasImage ? null : LinearGradient(
                          colors: [color1, color2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        image: hasImage ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            ad['imageUrl'].toString().startsWith('http') 
                                ? ad['imageUrl'] 
                                : '${AppConfig.baseUrl}${ad['imageUrl']}',
                          ),
                          fit: BoxFit.cover,
                        ) : null,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ad['discountPercentage'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${ad['discountPercentage']}% OFF',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    ad['title'] ?? 'Special Offer',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (ad['description'] != null && ad['description'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        ad['description'].toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else if (ad['validity'] != null && ad['validity'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        ad['validity'].toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_ads.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _ads.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentAdPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentAdPage == index ? AppColors.primaryGreen : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'All Plants',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_products.length} items',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                  )
                : _products.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'No plants found for this shop.',
                            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 15),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width >= 1100 ? 4
                              : MediaQuery.of(context).size.width >= 768 ? 3 : 2,
                          childAspectRatio: 0.74,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final cart = context.watch<CartProvider>();
                          final favorites = context.watch<FavoritesProvider>();
                          return _buildProductCard(context, _products[index], index, cart, favorites);
                        },
                      ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, int index, CartProvider cart, FavoritesProvider favorites) {
    final inCart = cart.isInCart(product.id);
    final isFav = favorites.isFavorite(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Product image full size
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl.startsWith('http')
                            ? product.imageUrl
                            : '${AppConfig.baseUrl}${product.imageUrl}',
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          child: Center(
                            child: Icon(Icons.eco_rounded, size: 40, color: AppColors.primaryGreen.withOpacity(0.5)),
                          ),
                        ),
                      )
                    : Container(
                        color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: Center(
                          child: Icon(Icons.eco_rounded, size: 40, color: AppColors.primaryGreen.withOpacity(0.5)),
                        ),
                      ),
              ),
            ),

            // Top: Fav + New Badge
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => favorites.toggle(product),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.cardBg.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 17,
                    color: isFav ? Colors.redAccent : Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            // Bottom gradient info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerName,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Rs. ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4ADE80)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add to cart button with bounce animation
                        _CartButton(
                          inCart: inCart,
                          onTap: () {
                            if (!inCart) {
                              cart.addItem(CartItem(
                                productId: product.id,
                                title: product.title,
                                price: product.price,
                                sellerId: product.sellerId,
                                imageUrl: product.imageUrl,
                                emoji: '',
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${product.title} added to cart',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .slideY(begin: 0.18, delay: Duration(milliseconds: 50 * (index % 6)), duration: 350.ms, curve: Curves.easeOutCubic)
    .fadeIn(delay: Duration(milliseconds: 50 * (index % 6)), duration: 350.ms);
  }
}

// ── Bouncy Cart Button ────────────────────────────────────────────────────────
class _CartButton extends StatefulWidget {
  final bool inCart;
  final VoidCallback onTap;
  const _CartButton({required this.inCart, required this.onTap});

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: widget.inCart ? const Color(0xFF22C55E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.inCart
                    ? const Color(0xFF22C55E).withOpacity(0.4)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            widget.inCart ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
            color: widget.inCart ? Colors.white : Colors.black87,
            size: 17,
          ),
        ),
      ),
    );
  }
}
