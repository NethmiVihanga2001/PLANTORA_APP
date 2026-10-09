import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../services/marketplace_service.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/cart_item_model.dart';
import '../services/socket_service.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'shop_screen.dart';
import 'chat_detail_screen.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'dart:async';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceService _marketService = MarketplaceService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  List<ProductModel> _products = [];
  bool _isLoading = true;
  late StreamSubscription _socketSub;

  // Category scroll controller for indicator
  final ScrollController _catScrollCtrl = ScrollController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all',      'label': 'All',       'icon': Icons.apps_rounded,              'color': const Color(0xFF22C55E)},
    {'id': 'herbal',   'label': 'Herbal',    'icon': Icons.spa_rounded,               'color': const Color(0xFF10B981)},
    {'id': 'indoor',   'label': 'Indoor',    'icon': Icons.home_rounded,              'color': const Color(0xFF60A5FA)},
    {'id': 'outdoor',  'label': 'Outdoor',   'icon': Icons.park_rounded,              'color': const Color(0xFF34D399)},
    {'id': 'medicinal','label': 'Medicinal', 'icon': Icons.medical_services_rounded,  'color': const Color(0xFFF97316)},
    {'id': 'culinary', 'label': 'Culinary',  'icon': Icons.restaurant_menu_rounded,   'color': const Color(0xFFFBBF24)},
    {'id': 'rare',     'label': 'Rare',      'icon': Icons.auto_awesome_rounded,      'color': const Color(0xFFA78BFA)},
    {'id': 'aromatic', 'label': 'Aromatic',  'icon': Icons.air_rounded,               'color': const Color(0xFF818CF8)},
    {'id': 'tea',      'label': 'Teas',      'icon': Icons.emoji_food_beverage_rounded,'color': const Color(0xFF6EE7B7)},
    {'id': 'seed',     'label': 'Seeds',     'icon': Icons.grain_rounded,             'color': const Color(0xFFF59E0B)},
    {'id': 'tool',     'label': 'Tools',     'icon': Icons.build_rounded,             'color': const Color(0xFF9CA3AF)},
  ];

  bool _initializedCategory = false;

  @override
  void initState() {
    super.initState();
    _loadUser();

    SocketService().connect();
    _socketSub = SocketService().marketplaceStream.listen((event) {
      _loadProducts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedCategory) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        final catLower = args;
        if (_categories.any((c) => c['id'] == catLower)) {
          _selectedCategory = catLower;
        }
      }
      _loadProducts();
      _initializedCategory = true;
    }
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _marketService.getProductsByCategory(_selectedCategory);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _socketSub.cancel();
    _searchController.dispose();
    _catScrollCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> get _filteredProducts {
    if (_searchQuery.isNotEmpty) {
      return _products.where((p) =>
        p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return _products;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildUltraMarketHeader(cart),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildSearchBar(),
                _buildCategoryTabs(),
                Expanded(child: _buildProductGrid(cart, favorites)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentUser?.role == 'Seller'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/add-listing'),
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                context.watch<LocalizationProvider>().translate('sell_plant'),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().scale(duration: 400.ms, delay: 300.ms, curve: Curves.elasticOut)
          : null,
    );
  }

  Widget _buildUltraMarketHeader(CartProvider cart) {
    final topPadding = MediaQuery.of(context).padding.top;
    final loc = context.watch<LocalizationProvider>();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 14, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF012E23),
            Color(0xFF044E39),
            Color(0xFF065F46),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF34D399).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Store Emblem Menu Circle
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF34D399).withValues(alpha: 0.3),
                    const Color(0xFF059669).withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF34D399),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title & Subtitle in 1 Line layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.translate('marketplace_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isLoading
                            ? loc.translate('loading_products')
                            : '${_filteredProducts.length} ${loc.translate('items_available')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA7F3D0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Shopping Cart Action Button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: context.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.primaryGreen.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(fontSize: 14.5, color: context.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: context.watch<LocalizationProvider>().translate('search_hint'),
            hintStyle: GoogleFonts.inter(color: context.textTertiary, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: context.iconSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : Container(
                    margin: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primaryGreen, size: 18),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final loc = context.watch<LocalizationProvider>();
    return Container(
      color: context.cardBg,
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          controller: _catScrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (ctx, i) {
            final cat = _categories[i];
            final isSelected = _selectedCategory == cat['id'];
            final color = cat['color'] as Color;

            final unselectedBg = Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9);
            final unselectedBorder = Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['id'] as String;
                  _searchQuery = '';
                  _searchController.clear();
                });
                _loadProducts();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : unselectedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: unselectedBorder, width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : context.iconSecondary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      loc.translate(cat['id'] as String),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(CartProvider cart, FavoritesProvider favorites) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1200 ? 4 : (screenWidth >= 900 ? 3 : 2);

    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 252,
            ),
            itemCount: 6,
            itemBuilder: (_, i) => _buildProductSkeleton(),
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_florist_rounded, size: 40, color: AppColors.primaryGreen.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text('No products found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: context.textSecondary)),
            const SizedBox(height: 6),
            Text('Try a different category or search term', style: GoogleFonts.inter(color: context.textTertiary, fontSize: 13)),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.builder(
          padding: const EdgeInsets.all(14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 252,
          ),
          itemCount: _filteredProducts.length,
          itemBuilder: (ctx, i) {
            final product = _filteredProducts[i];
            return _buildProductCard(product, i, cart, favorites);
          },
        ),
      ),
    );
  }

  Widget _buildProductSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(duration: 1200.ms, color: Colors.grey.shade100);
  }

  Widget _buildProductCard(ProductModel product, int index, CartProvider cart, FavoritesProvider favorites) {
    final inCart = cart.isInCart(product.id);
    final isFav = favorites.isFavorite(product.id);
    final sellerDisplayName = product.sellerName.isNotEmpty ? product.sellerName : 'Plantora Verified';

    return GestureDetector(
      onTap: () => _showProductPopup(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Product image full size
              Positioned.fill(
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl.startsWith('http')
                            ? product.imageUrl
                            : '${AppConfig.baseUrl}${product.imageUrl}',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF0F291E)
                                : const Color(0xFFE8F5E9),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF0F291E)
                              : const Color(0xFFE8F5E9),
                          child: const Center(
                            child: Icon(Icons.eco_rounded, size: 44, color: Color(0xFF10B981)),
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0F291E)
                            : const Color(0xFFE8F5E9),
                        child: const Center(
                          child: Icon(Icons.eco_rounded, size: 44, color: Color(0xFF10B981)),
                        ),
                      ),
              ),

              // Top Left: Category Badge Pill
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded, color: Color(0xFF34D399), size: 10),
                      const SizedBox(width: 4),
                      Text(
                        context.watch<LocalizationProvider>().translate(product.category).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right: Favorite Button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => favorites.toggle(product),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: isFav ? const Color(0xFFEF4444) : Colors.black54,
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
                  padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seller tag with icon
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF34D399)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sellerDisplayName,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Rating Badge
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 2),
                              Text(
                                product.rating > 0 ? product.rating.toStringAsFixed(1) : '4.8',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Title & Price & Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rs. ${product.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Add to cart button with bounce animation
                          _CartButton(
                            inCart: inCart,
                            onTap: () {
                              if (inCart) {
                                cart.removeItem(product.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.remove_shopping_cart_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text('${product.title} removed from cart',
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
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
      ),
    )
    .animate()
    .slideY(begin: 0.12, delay: Duration(milliseconds: 40 * (index % 6)), duration: 300.ms, curve: Curves.easeOutCubic)
    .fadeIn(delay: Duration(milliseconds: 40 * (index % 6)), duration: 300.ms);
  }

  Future<void> _openChatWithSeller(BuildContext sheetCtx, ProductModel product) async {
    final auth = context.read<AuthProvider>();
    final user = _currentUser ?? auth.user;

    final effectiveUser = user ?? UserModel(
      id: 'customer_guest',
      name: 'Customer',
      email: 'customer@plantora.com',
      joinedAt: DateTime.now(),
      role: 'Customer',
    );

    final targetSellerId = product.sellerId.isNotEmpty ? product.sellerId : 'seller_island_greenery';
    final targetSellerName = product.sellerName.isNotEmpty ? product.sellerName : 'Island Greenery';

    if (effectiveUser.id == targetSellerId && targetSellerId != 'seller_island_greenery') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are the seller of this product', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.pop(sheetCtx);

    try {
      final chatData = await ChatService().initiateChat(
        effectiveUser.id,
        targetSellerId,
        effectiveUser.name,
        targetSellerName,
        product.sellerAvatar,
      );

      final chatId = chatData?['id'] ?? 'chat_${effectiveUser.id}_$targetSellerId';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chatId,
              otherParticipantName: targetSellerName,
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
              chatId: 'chat_${effectiveUser.id}_$targetSellerId',
              otherParticipantName: targetSellerName,
            ),
          ),
        );
      }
    }
  }

  void _showProductPopup(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cart = context.watch<CartProvider>();
        final inCart = cart.isInCart(product.id);
        final isOwner = _currentUser?.id == product.sellerId;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header image with overlay buttons
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                            child: SizedBox(
                              height: 270,
                              width: double.infinity,
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl.startsWith('http')
                                          ? product.imageUrl
                                          : '${AppConfig.baseUrl}${product.imageUrl}',
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          color: context.isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: context.isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                                        child: const Center(
                                          child: Icon(Icons.eco_rounded, size: 70, color: Color(0xFF10B981)),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: context.isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                                      child: const Center(
                                        child: Icon(Icons.eco_rounded, size: 70, color: Color(0xFF10B981)),
                                      ),
                                    ),
                            ),
                          ),

                          // Top drag handle bar
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
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Close button
                          Positioned(
                            top: 14,
                            right: 14,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),

                          // Category pill on top left
                          if (product.category.isNotEmpty)
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco_rounded, color: Color(0xFF34D399), size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.category.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Plant information body
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Title
                            Text(
                              product.title,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Meta Pills Row (Rating & Guarantee)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.rating > 0 ? product.rating.toStringAsFixed(1) : '4.8',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${product.reviewCount} reviews)',
                                        style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.25), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Healthy Plant',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Description Section
                            Text(
                              'Description',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description.isNotEmpty
                                  ? product.description
                                  : 'Fresh, vibrant indoor plant carefully nurtured for optimum growth and beauty.',
                              style: GoogleFonts.inter(
                                color: context.textSecondary,
                                fontSize: 14,
                                height: 1.55,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Seller Information Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.isDark ? const Color(0xFF1E293B).withOpacity(0.6) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryGreen,
                                    backgroundImage: product.sellerAvatar != null
                                        ? NetworkImage(
                                            product.sellerAvatar!.startsWith('http')
                                                ? product.sellerAvatar!
                                                : '${AppConfig.baseUrl}${product.sellerAvatar}')
                                        : null,
                                    child: product.sellerAvatar == null
                                        ? Text(
                                            product.sellerName.isNotEmpty
                                                ? product.sellerName.substring(0, 1).toUpperCase()
                                                : 'S',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.sellerName.isNotEmpty ? product.sellerName : 'Verified Seller',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: context.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.verified, color: Colors.blue, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Verified Seller',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: context.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ShopScreen(
                                            sellerId: product.sellerId,
                                            sellerName: product.sellerName,
                                            sellerLocation: product.sellerLocation,
                                            sellerAvatar: product.sellerAvatar,
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
                                      foregroundColor: AppColors.primaryGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      'View Shop',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
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
                ),
              ),

              // Fixed Sticky Bottom Action Bar
              Container(
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).padding.bottom + 14),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: isOwner
                    ? Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(context, '/edit-listing', arguments: product);
                                },
                                icon: const Icon(Icons.edit_rounded, color: AppColors.primaryGreen, size: 18),
                                label: Text(
                                  'EDIT',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _confirmDelete(product);
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: Text(
                                  'DELETE',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Price',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Rs. ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (!isOwner) ...[
                            Tooltip(
                              message: 'Chat with seller',
                              child: SizedBox(
                                width: 52,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _openChatWithSeller(ctx, product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
                                    foregroundColor: AppColors.primaryGreen,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.35)),
                                    ),
                                  ),
                                  child: const Icon(Icons.forum_rounded, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Tooltip(
                            message: inCart ? 'Remove from Cart' : 'Add to Cart',
                            child: SizedBox(
                              width: 56,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (inCart) {
                                    cart.removeItem(product.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Removed from cart!'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  } else {
                                    cart.addItem(CartItem(
                                      productId: product.id,
                                      title: product.title,
                                      price: product.price,
                                      sellerId: product.sellerId,
                                      imageUrl: product.imageUrl,
                                      emoji: '',
                                    ));
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${product.title} added to cart!',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.primaryGreen,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: inCart ? Colors.red.shade600 : AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Icon(
                                  inCart ? Icons.remove_shopping_cart_rounded : Icons.add_shopping_cart_rounded,
                                  size: 22,
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
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Listing?'),
        content: Text('Are you sure you want to remove "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final token = await _authService.getToken();
              if (token != null) {
                final success = await _marketService.deleteProduct(product.id, token);
                if (success) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing deleted'), backgroundColor: AppColors.success),
                    );
                    _loadProducts();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('DELETE'),
          ),
        ],
      ),
    );
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
                    ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.1),
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