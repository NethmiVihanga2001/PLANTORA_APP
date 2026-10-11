import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/product_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/socket_service.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../widgets/product_image.dart';

class SellerProductsView extends StatefulWidget {
  final VoidCallback onMenuTap;
  const SellerProductsView({super.key, required this.onMenuTap});

  @override
  State<SellerProductsView> createState() => _SellerProductsViewState();
}

class _SellerProductsViewState extends State<SellerProductsView>
    with SingleTickerProviderStateMixin {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  late AnimationController _fabController;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Products', 'icon': '🪴'},
    {'id': 'indoor', 'label': 'Indoor Plants', 'icon': '🌿'},
    {'id': 'outdoor', 'label': 'Outdoor', 'icon': '🌳'},
    {'id': 'rare', 'label': 'Rare Collectibles', 'icon': '✨'},
    {'id': 'low_stock', 'label': 'Low Stock Alert', 'icon': '⚠️'},
  ];

  StreamSubscription? _stockSub;
  StreamSubscription? _marketSub;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadProducts();

    // Live real-time stock sync
    SocketService().connect();
    _stockSub = SocketService().stockStream.listen((data) {
      final pId = data['productId'];
      final newStk = data['stock'];
      final isAvail = data['isAvailable'] ?? ((newStk is num) ? newStk > 0 : true);
      if (pId != null && newStk != null && mounted) {
        setState(() {
          final idx = _products.indexWhere((p) => p.id == pId);
          if (idx != -1) {
            _products[idx] = _products[idx].copyWith(
              stock: (newStk as num).toInt(),
              isAvailable: isAvail == true,
            );
          }
        });
      }
    });

    _marketSub = SocketService().marketplaceStream.listen((data) {
      if (data['type'] == 'delete' || data['type'] == 'new_product') {
        _loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _stockSub?.cancel();
    _marketSub?.cancel();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().user ?? await AuthService().getCurrentUser();
    final sellerId = user?.id ?? 's_demo';
    final sellerName = user?.businessName ?? user?.name ?? 'My Green Shop';
    final sellerLocation = user?.location ?? 'Colombo, Sri Lanka';

    final allProducts = await _marketplaceService.getProductsByCategory('all');
    
    List<ProductModel> sellerProds = [];
    if (user != null) {
      sellerProds = allProducts.where((p) =>
        p.sellerId == user.id ||
        p.sellerId == sellerId ||
        p.sellerId == 's_demo' ||
        p.sellerId.isEmpty ||
        p.sellerName.toLowerCase().trim() == sellerName.toLowerCase().trim()
      ).toList();
    } else {
      sellerProds = allProducts;
    }

    if (sellerProds.isEmpty) {
      sellerProds = _getSampleProductsForSeller(sellerId, sellerName, sellerLocation);
    }

    _products = sellerProds;
    if (mounted) setState(() => _isLoading = false);
  }

  List<ProductModel> _getSampleProductsForSeller(String sellerId, String sellerName, String sellerLocation) {
    final now = DateTime.now();
    return [
      ProductModel(
        id: 'sample_${sellerId}_01',
        title: 'Monstera Deliciosa (Swiss Cheese)',
        description: 'Stunning Swiss Cheese plant with glossy split leaves. Perfect indoor accent for living rooms.',
        price: 3500.0,
        originalPrice: 4200.0,
        category: 'indoor',
        imageUrl: 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=800&q=80',
        emoji: '🪴',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.9,
        reviewCount: 32,
        stock: 14,
        isAvailable: true,
        tags: ['indoor', 'popular', 'top-rated'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_02',
        title: 'Fiddle Leaf Fig (Ficus Lyrata)',
        description: 'Tall Fiddle Leaf Fig tree in woven rattan basket. Premium interior decor plant.',
        price: 6800.0,
        originalPrice: 7500.0,
        category: 'indoor',
        imageUrl: 'https://images.unsplash.com/photo-1545241047-6083a3684587?auto=format&fit=crop&w=800&q=80',
        emoji: '🌿',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.8,
        reviewCount: 19,
        stock: 4,
        isAvailable: true,
        tags: ['indoor', 'decor', 'rare'],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_03',
        title: 'Golden Pothos Hanging Vine',
        description: 'Cascading Golden Pothos vine in hanging basket. Fast grower with variegated golden leaves.',
        price: 1450.0,
        originalPrice: 1800.0,
        category: 'indoor',
        imageUrl: 'https://images.unsplash.com/photo-1604762524889-3e2fcc145683?auto=format&fit=crop&w=800&q=80',
        emoji: '🍃',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.7,
        reviewCount: 45,
        stock: 25,
        isAvailable: true,
        tags: ['indoor', 'hanging', 'easy-care'],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_04',
        title: 'Sansevieria Snake Plant (Lauren)',
        description: 'Air-purifying Snake Plant in 8-inch ceramic pot. Extremely low maintenance and hardy.',
        price: 2200.0,
        originalPrice: 2600.0,
        category: 'indoor',
        imageUrl: 'https://images.unsplash.com/photo-1599598425947-52028682855b?auto=format&fit=crop&w=800&q=80',
        emoji: '🪴',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.9,
        reviewCount: 58,
        stock: 18,
        isAvailable: true,
        tags: ['indoor', 'air-purifier'],
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_05',
        title: 'Calathea Orbifolia (Silver Stripes)',
        description: 'Round patterned leaves with striking silver stripes. Loves humid indoor spots.',
        price: 2950.0,
        originalPrice: 3400.0,
        category: 'indoor',
        imageUrl: 'https://images.unsplash.com/photo-1592150621744-aca64f48394a?auto=format&fit=crop&w=800&q=80',
        emoji: '🌿',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.6,
        reviewCount: 22,
        stock: 3,
        isAvailable: true,
        tags: ['indoor', 'humidity-lover'],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_06',
        title: 'Red Tropical Hibiscus Bush',
        description: 'Vibrant crimson red blooms all year round. Thrives in full sun outdoor garden.',
        price: 1800.0,
        originalPrice: 2100.0,
        category: 'outdoor',
        imageUrl: 'https://images.unsplash.com/photo-1550950158-d0d960dff51b?auto=format&fit=crop&w=800&q=80',
        emoji: '🌺',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.8,
        reviewCount: 14,
        stock: 12,
        isAvailable: true,
        tags: ['outdoor', 'flowering'],
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_07',
        title: 'Peace Lily (Spathiphyllum)',
        description: 'Elegant Peace Lily with snowy white blooms. Air purifying champion for office desk.',
        price: 1850.0,
        originalPrice: 2300.0,
        category: 'indoor',
        imageUrl: 'https://images.unsplash.com/photo-1593691509543-c55fb32e7355?auto=format&fit=crop&w=800&q=80',
        emoji: '🌸',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 4.7,
        reviewCount: 36,
        stock: 9,
        isAvailable: true,
        tags: ['indoor', 'air-purifier'],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      ProductModel(
        id: 'sample_${sellerId}_08',
        title: 'Monstera Thai Constellation',
        description: 'Ultra rare Monstera with celestial cream speckles on giant split leaves.',
        price: 24500.0,
        originalPrice: 28000.0,
        category: 'rare',
        imageUrl: 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=800&q=80',
        emoji: '✨',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerLocation: sellerLocation,
        rating: 5.0,
        reviewCount: 8,
        stock: 2,
        isAvailable: true,
        tags: ['rare', 'collector', 'premium'],
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  void _adjustStock(ProductModel product, int delta) async {
    final newStock = math.max(0, product.stock + delta);
    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(
          stock: newStock,
          isAvailable: newStock > 0,
        );
      }
    });

    final token = await AuthService().getToken();
    if (token != null) {
      await _marketplaceService.updateStock(product.id, newStock, token);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newStock == 0 ? Icons.warning_amber_rounded : (delta > 0 ? Icons.add_circle : Icons.remove_circle),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                newStock == 0
                    ? '⚠️ ${product.title} is now OUT OF STOCK'
                    : 'Stock for ${product.title} updated to $newStock',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: newStock == 0 ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final token = await AuthService().getToken();
    if (token != null) {
      await _marketplaceService.deleteProduct(productId, token);
    }
    setState(() {
      _products.removeWhere((p) => p.id == productId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: context.textPrimary),
            const SizedBox(width: 8),
            const Text('Product removed from shop'),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesCat = true;
      if (_selectedCategory == 'low_stock') {
        matchesCat = p.stock <= 5;
      } else if (_selectedCategory != 'all') {
        matchesCat = p.category.toLowerCase() == _selectedCategory.toLowerCase();
      }

      return matchesSearch && matchesCat;
    }).toList();
  }

  double get _totalStockValue {
    return _products.fold(0.0, (sum, p) => sum + (p.price * p.stock));
  }

  int get _lowStockCount {
    return _products.where((p) => p.stock <= 5).length;
  }

  double get _averageRating {
    if (_products.isEmpty) return 0.0;
    return _products.fold(0.0, (sum, p) => sum + p.rating) / _products.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildCategoryFilterBar()),
        ],
        body: RefreshIndicator(
          onRefresh: _loadProducts,
          color: const Color(0xFF10B981),
          backgroundColor: Theme.of(context).cardColor,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                )
              : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(_filteredProducts[index], index),
                    ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 18),
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
            color: const Color(0xFF34D399).withOpacity(0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Emblem menu button + Title
              Row(
                children: [
                  PremiumAppBar.buildEmblemButton(
                    icon: Icons.menu_rounded,
                    onTap: widget.onMenuTap,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Products',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
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
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF34D399),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live Storefront Inventory',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA7F3D0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: Color(0xFF34D399), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${_products.length} items',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Inventory Analytics Metric Cards Bar
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  label: 'Stock Value',
                  value: 'Rs. ${(_totalStockValue / 1000).toStringAsFixed(1)}k',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  label: 'Low Stock',
                  value: '$_lowStockCount items',
                  icon: Icons.warning_amber_rounded,
                  color: _lowStockCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  label: 'Store Rating',
                  value: '${_averageRating.toStringAsFixed(1)} ★',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 14),

          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search plant products by title or category...',
                hintStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 19),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

  Widget _buildCategoryFilterBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: const Color(0xFF10B981),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : context.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              label: Text(
                '${cat['icon']} ${cat['label']}',
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : context.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = cat['id']!);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, int index) {
    final bool isLowStock = product.stock <= 3 && product.stock > 0;
    final bool isOutOfStock = product.stock <= 0;

    Color badgeColor = const Color(0xFF10B981);
    String badgeText = '${product.stock} in stock';
    if (isOutOfStock) {
      badgeColor = Colors.redAccent;
      badgeText = 'OUT OF STOCK';
    } else if (isLowStock) {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = '⚠️ Low: ${product.stock} left';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLowStock
              ? const Color(0xFFF59E0B).withOpacity(0.35)
              : const Color(0xFF10B981).withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF10B981).withOpacity(0.08),
          onTap: () async {
            await Navigator.pushNamed(context, '/edit-listing', arguments: product);
            _loadProducts();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image Container with Stock Overlay Badge
                Stack(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.15),
                            const Color(0xFF059669).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                        ),
                      ),
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        emoji: product.emoji,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        emojiSize: 34,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Title
                      Text(
                        product.title,
                        style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Price Row
                      Row(
                        children: [
                          Text(
                            'Rs. ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF10B981),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Rs. ${product.originalPrice!.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: context.textSecondary.withOpacity(0.5),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Quick Stock Adjuster Controls
                      Row(
                        children: [
                          Text(
                            'Stock:',
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStockButton(
                            icon: Icons.remove,
                            onTap: product.stock > 0 ? () => _adjustStock(product, -1) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${product.stock}',
                              style: GoogleFonts.outfit(
                                color: isOutOfStock ? Colors.redAccent : context.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _buildStockButton(
                            icon: Icons.add,
                            onTap: () => _adjustStock(product, 1),
                          ),
                          if (isOutOfStock) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _adjustStock(product, 10),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                ),
                                child: Text(
                                  '+10 Restock',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF10B981),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action Icons (Edit & Delete)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconAction(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () async {
                        await Navigator.pushNamed(context, '/edit-listing', arguments: product);
                        _loadProducts();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildIconAction(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      onTap: () => _confirmDelete(product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
     .fadeIn(delay: Duration(milliseconds: 60 + index * 50), duration: 350.ms)
     .slideX(begin: 0.06, delay: Duration(milliseconds: 60 + index * 50));
  }

  Widget _buildStockButton({required IconData icon, VoidCallback? onTap}) {
    final bool isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFF10B981).withOpacity(0.14)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF10B981).withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? const Color(0xFF10B981) : Colors.grey,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildIconAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Products Found',
              style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'all'
                  ? 'No items match your filter settings.'
                  : 'Add your plant inventory to start selling!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/add-listing');
                    _loadProducts();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: context.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF10B981)),
                  label: const Text('Load Sample Items', style: TextStyle(color: Color(0xFF10B981))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _fabController.value * -4),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4 + _fabController.value * 0.15),
                  blurRadius: 16 + _fabController.value * 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () async {
                await Navigator.pushNamed(context, '/add-listing');
                _loadProducts();
              },
              icon: Icon(Icons.add_rounded, color: context.textPrimary),
              label: Text(
                'Add Product',
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Product?', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${product.title}" from your shop? This cannot be undone.',
          style: TextStyle(color: context.textPrimary.withOpacity(0.65), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: context.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
