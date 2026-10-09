import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  UserModel? _temp2faUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> loadUser() async {
    _isLoading = true;
    _user = await _authService.getCurrentUser();
    if (_user != null) {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
    
    // Refresh user details from database online if available
    final latest = await _authService.fetchLatestUser();
    if (latest != null) {
      _user = latest;
    }
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool isSeller = false,
    bool isDriver = false,
    String? businessName,
    String? vehicleType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      isSeller: isSeller,
      isDriver: isDriver,
      businessName: businessName,
      vehicleType: vehicleType,
    );

    _isLoading = false;
    if (result['success']) {
      _user = result['user'] as UserModel;
      notifyListeners();
      return true;
    } else {
      _error = result['message'] as String;
      notifyListeners();
      return false;
    }
  }

  Future<String> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password, rememberMe: rememberMe);

    _isLoading = false;
    if (result['success']) {
      if (result['requires2fa'] == true) {
        _temp2faUser = result['tempUser'] as UserModel;
        notifyListeners();
        return '2fa_required';
      }
      _user = result['user'] as UserModel;
      notifyListeners();
      return 'success';
    } else {
      _error = result['message'] as String;
      notifyListeners();
      return 'error';
    }
  }

  Future<String> socialLogin({
    required String provider,
    required String email,
    required String name,
    required String id,
    String? role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.socialLogin(
      provider: provider,
      email: email,
      name: name,
      id: id,
      role: role,
    );

    _isLoading = false;
    if (result['success']) {
      if (result['requires2fa'] == true) {
        _temp2faUser = result['tempUser'] as UserModel;
        notifyListeners();
        return '2fa_required';
      }
      _user = result['user'] as UserModel;
      notifyListeners();
      return 'success';
    } else {
      _error = result['message'] as String;
      notifyListeners();
      return 'error';
    }
  }

  Future<bool> verify2fa(String code) async {
    if (_temp2faUser == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _authService.verify2fa(_temp2faUser!.id, code);

    _isLoading = false;
    if (success['success'] == true) {
      _user = _temp2faUser;
      _temp2faUser = null;
      notifyListeners();
      return true;
    } else {
      _error = 'Invalid 2FA code';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile(UserModel updated) async {
    final success = await _authService.updateProfile(updated);
    if (success) {
      final latest = await _authService.getCurrentUser();
      _user = latest ?? updated;
      notifyListeners();
    }
    return success;
  }

  Future<void> updatePoints(int newPoints) async {
    if (_user != null) {
      _user!.points = newPoints;
      await _authService.updatePoints(newPoints);
      notifyListeners();
    }
  }
  
  Future<void> addCancellationPenalty(double amount) async {
    if (_user != null) {
      _user!.cancellationPenalty += amount;
      // We don't need to hit backend since backend already added it, just sync local prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_user!.toMap()));
      notifyListeners();
    }
  }

  Future<void> clearCancellationPenalty() async {
    if (_user != null) {
      _user!.cancellationPenalty = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_user!.toMap()));
      notifyListeners();
    }
  }
  
  Future<void> addPoints(int amount) async {
    if (_user != null) {
      updatePoints(_user!.points + amount);
    }
  }

  Future<void> deductPoints(int amount) async {
    if (_user != null) {
      updatePoints(_user!.points - amount);
    }
  }

  Future<bool> deleteAccount() async {
    final success = await _authService.deleteAccount();
    if (success) {
      _user = null;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateProfileImage(List<int> bytes, String filename) async {
    final avatarUrl = await _authService.uploadProfileImage(bytes, filename);
    if (avatarUrl != null && _user != null) {
      _user!.avatarUrl = avatarUrl;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateShopImage(List<int> bytes, String filename) async {
    final shopImage = await _authService.uploadShopImage(bytes, filename);
    if (shopImage != null && _user != null) {
      _user!.shopImage = shopImage;
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.forgotPassword(email);

    _isLoading = false;
    if (!result['success']) {
      _error = result['message'] as String;
    }
    notifyListeners();
    return result['success'];
  }

  Future<bool> verifyResetCode(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _authService.verifyResetCode(email, code);

    _isLoading = false;
    if (!success) {
      _error = 'Invalid or expired code';
    }
    notifyListeners();
    return success;
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _authService.resetPassword(email, code, newPassword);

    _isLoading = false;
    if (!success) {
      _error = 'Failed to reset password. Check requirements.';
    }
    notifyListeners();
    return success;
  }
  Future<bool> resendResetCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.resendResetCode(email);

    _isLoading = false;
    if (!result['success']) {
      _error = result['message'] as String;
    }
    notifyListeners();
    return result['success'];
  }
}
