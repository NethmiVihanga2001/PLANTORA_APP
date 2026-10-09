import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/favorites_provider.dart';
import 'services/finance_service.dart';

import 'screens/language_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/plant_result_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/market_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/plantora_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/add_listing_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/edit_profile_screen.dart';
import 'screens/plant_grid_screen.dart';
import 'providers/localization_provider.dart';
import 'models/product_model.dart';
import 'screens/edit_listing_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/driver_main_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/loyalty_screen.dart';
import 'screens/seller/seller_payments_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/terms_of_service_screen.dart';
import 'screens/settings/help_center_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Allow all orientations (portrait + landscape/desktop)
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  runApp(const PlantOraApp());
}

class RootAuthHandler extends StatelessWidget {
  const RootAuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Show smooth dark splash while loading persistent user credentials from storage
    if (!auth.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF030904),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.4), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.eco_rounded, size: 48, color: Color(0xFF4ADE80)),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Color(0xFF4ADE80), strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Direct automatic entry to Home Page for logged-in users
    if (auth.isLoggedIn && auth.user != null) {
      if (auth.user!.role == 'Driver') {
        return const DriverMainScreen();
      } else if (auth.user!.role == 'Seller') {
        return const SellerDashboardScreen();
      } else {
        return const HomeScreen();
      }
    }

    // 3. Display WelcomeScreen ONLY when user is logged out
    return const WelcomeScreen();
  }
}

class PlantOraApp extends StatelessWidget {
  const PlantOraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => FinanceService()),
      ],
      child: Consumer3<LocalizationProvider, ThemeProvider, AuthProvider>(
        builder: (context, loc, themeProvider, auth, _) {
          // Use the theme selected in the app (toggled by the user)
          final effectiveTheme = themeProvider.themeMode;

          return MaterialApp(
            title: 'Plantora',
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: effectiveTheme,
            locale: loc.locale,
            initialRoute: '/',
            routes: {
              '/': (context) => const RootAuthHandler(),
              '/language': (context) => const LanguageScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/home': (context) => const HomeScreen(),
              '/scan': (context) => const ScanScreen(),
              '/market': (context) => const MarketScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/cart': (context) => const CartScreen(),
              '/add-listing': (context) => const AddListingScreen(),
              '/assistant': (context) => const PlantoraAssistantScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/edit-profile': (context) => const EditProfileScreen(),
              '/plant-library': (context) => const PlantGridScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/driver-dashboard': (context) => const DriverMainScreen(),
              '/seller-dashboard': (context) => const SellerDashboardScreen(),
              '/seller-payments': (context) => const SellerPaymentsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/favorites': (context) => const FavoritesScreen(),
              '/loyalty': (context) => const LoyaltyScreen(),
              '/privacy': (context) => const PrivacyPolicyScreen(),
              '/terms': (context) => const TermsOfServiceScreen(),
              '/help': (context) => const HelpCenterScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/plant-result') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  return MaterialPageRoute(
                    builder: (_) => PlantResultScreen(
                      plant: args['plant'],
                      imagePath: args['imagePath'] ?? '',
                      confidence: args['confidence'] ?? 0.0,
                      alternatives: args['alternatives'] ?? [],
                    ),
                  );
                }
              }
              if (settings.name == '/plant-detail') {
                final plant = settings.arguments;
                if (plant != null) {
                  return MaterialPageRoute(
                    builder: (_) => PlantDetailScreen(plant: plant as dynamic),
                  );
                }
              }
              if (settings.name == '/product-detail') {
                final product = settings.arguments;
                if (product != null) {
                  return MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(product: product as dynamic),
                  );
                }
              }
              if (settings.name == '/edit-listing') {
                final product = settings.arguments;
                if (product != null) {
                  return MaterialPageRoute(
                    builder: (_) =>
                        EditListingScreen(product: product as ProductModel),
                  );
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}