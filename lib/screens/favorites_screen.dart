import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/localization_provider.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final loc = context.watch<LocalizationProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      appBar: PremiumAppBar(
        title: loc.translate('my_favourites'),
        subtitle: favorites.count > 0 ? '${favorites.count} plants saved' : null,
        showMenuButton: true,
      ),
      body: favorites.items.isEmpty
          ? _buildEmpty(context)
          : _buildList(context, favorites),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded, size: 52, color: Colors.redAccent),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'No favourites yet',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Tap the ♥ heart on any plant\nto save it here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14, height: 1.5),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/market'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            icon: const Icon(Icons.storefront_rounded, color: Colors.white),
            label: Text('Browse Marketplace', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, FavoritesProvider favorites) {
    return Responsive.centered(
      maxWidth: 1200,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.productGridColumns(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 250,
        ),
        itemCount: favorites.items.length,
        itemBuilder: (context, i) {
          final product = favorites.items[i];
          final cart = context.watch<CartProvider>();
          final inCart = cart.isInCart(product.id);
          final fullImgUrl = product.imageUrl.isNotEmpty
              ? (product.imageUrl.startsWith('http') ? product.imageUrl : '${AppConfig.baseUrl}${product.imageUrl}')
              : '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: fullImgUrl.isNotEmpty
                          ? Image.network(fullImgUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: context.scaffoldBg,
                                child: Center(child: Icon(Icons.local_florist_rounded, size: 40, color: Colors.grey)),
                              ))
                          : Container(
                              color: context.scaffoldBg,
                              child: Center(child: Icon(Icons.local_florist_rounded, size: 40, color: Colors.grey)),
                            ),
                    ),
                  ),

                  // Remove fav button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => favorites.remove(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.cardBg.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.favorite_rounded, size: 18, color: Colors.redAccent),
                      ),
                    ),
                  ),

                  // Bottom info gradient overlay
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
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.title,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rs. ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4ADE80)),
                              ),
                              GestureDetector(
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
                                        content: Row(children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                          const SizedBox(width: 8),
                                          Text('Added to cart', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                        ]),
                                        backgroundColor: AppColors.primaryGreen,
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: inCart ? const Color(0xFF22C55E) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    inCart ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                                    color: inCart ? Colors.white : Colors.black87,
                                    size: 15,
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
            ),
          ).animate()
          .slideY(begin: 0.2, delay: Duration(milliseconds: 60 * i), duration: 350.ms, curve: Curves.easeOutCubic)
          .fadeIn(delay: Duration(milliseconds: 60 * i), duration: 350.ms);
        },
      ),
    );
  }
}
