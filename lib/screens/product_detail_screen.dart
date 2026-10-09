import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import 'plantora_assistant_screen.dart';
import '../services/auth_service.dart';
import '../services/marketplace_service.dart';
import '../models/user_model.dart';
import 'edit_listing_screen.dart';
import '../config/app_config.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  int _quantity = 1;
  UserModel? _currentUser;
  final AuthService _authService = AuthService();
  final MarketplaceService _marketService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Fixed Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl.startsWith('http')
                        ? product.imageUrl
                        : '${AppConfig.baseUrl}${product.imageUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(gradient: AppColors.cardGradient),
                      child: Center(
                        child: Text(product.emoji, style: const TextStyle(fontSize: 110))
                            .animate().scale(duration: 500.ms),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(gradient: AppColors.cardGradient),
                    child: Center(
                      child: Text(product.emoji, style: const TextStyle(fontSize: 110))
                          .animate().scale(duration: 500.ms),
                    ),
                  ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 320), // Transparent space for image
                Container(
                  constraints: BoxConstraints(minHeight: size.height - 320),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 120), // Bottom padding for floating bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title, Category, Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF15803D)]),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                    ]
                                  ),
                                  child: Text(product.category.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                Text(product.title,
                                    style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${product.rating}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
                                    const SizedBox(width: 6),
                                    Text('(${product.reviewCount} reviews)', style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                              ]
                            ),
                            child: Text(
                              'Rs. ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),

                      const SizedBox(height: 28),

                      // Seller info card (3D)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
                                boxShadow: [
                                  BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                                ]
                              ),
                              child: const Center(child: Text('🧑‍🌾', style: TextStyle(fontSize: 26))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.sellerName,
                                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: AppColors.primaryGreen, size: 14),
                                      const SizedBox(width: 4),
                                      Text(product.sellerLocation, style: const TextStyle(color: AppColors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF166534)]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    if (_currentUser == null) return;
                                    final chatData = await ChatService().initiateChat(
                                      _currentUser!.id,
                                      product.sellerId,
                                      _currentUser!.name,
                                      product.sellerName,
                                      null,
                                    );
                                    if (chatData != null && mounted) {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => ChatDetailScreen(
                                          chatId: chatData['id'],
                                          otherParticipantName: product.sellerName,
                                        ),
                                      ));
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Icon(Icons.forum_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: 0.1, delay: 100.ms, duration: 400.ms).fadeIn(delay: 100.ms),

                      const SizedBox(height: 28),

                      // Description
                      Text('Description', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w900, fontSize: 20)),
                      const SizedBox(height: 12),
                      Text(product.description,
                          style: TextStyle(color: context.textSecondary, fontSize: 15, height: 1.7, fontWeight: FontWeight.w500)),

                      const SizedBox(height: 24),

                      // Tags
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: product.tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.border, width: 1.5),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))]
                                  ),
                                  child: Text('#$tag', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 28),

                      // Stock info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: product.stock > 10 ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: product.stock > 10 ? const Color(0xFFBBF7D0) : const Color(0xFFFEF3C7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_rounded,
                                color: product.stock > 10 ? const Color(0xFF16A34A) : const Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${product.stock} in stock ready to ship',
                              style: TextStyle(
                                color: product.stock > 10 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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

          // Custom Top Bar (Floating Glassmorphism)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 26),
                ),
                Row(
                  children: [
                    if (_currentUser != null && _currentUser!.id == product.sellerId) ...[
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditListingScreen(product: product))),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.black87, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorite ? Colors.redAccent : Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          // TODO: Implement share functionality
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: const Icon(Icons.share_rounded, color: Colors.black87, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating Bottom Bar (3D Premium)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity control (Pill shape)
                  Container(
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          onTap: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                          child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.remove_rounded, size: 20)),
                        ),
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        InkWell(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                          onTap: () => setState(() => _quantity++),
                          child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.add_rounded, size: 20)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add to Cart Button (Gradient + Shadow)
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            for (var i = 0; i < _quantity; i++) {
                              cart.addItem(CartItem(
                                productId: product.id,
                                title: product.title,
                                price: product.price,
                                sellerId: product.sellerId,
                                imageUrl: product.imageUrl,
                                emoji: product.emoji,
                              ));
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Added $_quantity item(s) to cart!',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.primaryGreen,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(inCart ? Icons.shopping_bag_rounded : Icons.add_shopping_cart_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                inCart ? 'Add More' : 'Add to Cart',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.5, delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          ),
        ],
      ),
    );
  }
}
