import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/app_config.dart';

class AuthService {
  static String get _baseUrl => AppConfig.baseUrl;
  static const _currentUserKey = 'current_user';
  static const _tokenKey = 'auth_token';

  static String? _memoryToken;
  static String? _memoryUser;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool isSeller = false,
    bool isDriver = false,
    String? businessName,
    String? vehicleType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'isSeller': isSeller,
          'isDriver': isDriver,
          'businessName': businessName,
          'vehicleType': vehicleType,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data != null && data['user'] != null) {
        _memoryToken = data['token'];
        _memoryUser = jsonEncode(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? 'token_reg');
        await prefs.setString(_currentUserKey, jsonEncode(data['user']));
        return {'success': true, 'user': UserModel.fromMap(data['user'])};
      } else if (data != null && data['error'] != null) {
        return {'success': false, 'error': data['error']};
      }
    } catch (e) {
      print('AuthService register network attempt failed: $e');
    }

    // Offline fallback ONLY if network failed
    final role = isSeller ? 'Seller' : (isDriver ? 'Driver' : 'Customer');
    final offlineUser = UserModel(
      id: 'viva_reg_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isNotEmpty ? name : 'Plantora User',
      email: email.isNotEmpty ? email : 'user@plantora.app',
      phone: phone,
      role: role,
      points: 10,
      businessName: businessName ?? (isSeller ? 'My Plant Nursery' : null),
      vehicleType: vehicleType ?? (isDriver ? 'Motorbike' : null),
      avatarUrl: null,
      joinedAt: DateTime.now(),
    );

    _memoryToken = 'viva_mock_token_${DateTime.now().millisecondsSinceEpoch}';
    _memoryUser = jsonEncode(offlineUser.toMap());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _memoryToken!);
    await prefs.setString(_currentUserKey, _memoryUser!);

    return {'success': true, 'user': offlineUser};
  }

  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String email,
    required String name,
    required String id,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/social-login'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'provider': provider,
          'email': email,
          'name': name,
          'id': id,
          if (role != null) 'role': role,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data != null && data['user'] != null) {
        if (data['requires2fa'] == true) {
          return {
            'success': true,
            'requires2fa': true,
            'tempUser': UserModel.fromMap(data['tempUser'])
          };
        }

        _memoryToken = data['token'];
        _memoryUser = jsonEncode(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setString(_currentUserKey, jsonEncode(data['user']));
        return {
          'success': true, 
          'requires2fa': false, 
          'user': UserModel.fromMap(data['user'])
        };
      } else if (data != null && data['error'] != null) {
        return {'success': false, 'error': data['error']};
      }
    } catch (e) {
      print('AuthService socialLogin network error: $e');
    }

    final userRole = role ?? (email.toLowerCase().contains('seller') ? 'Seller' : (email.toLowerCase().contains('driver') ? 'Driver' : 'Customer'));
    final offlineUser = UserModel(
      id: id.isNotEmpty ? id : 'viva_social_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isNotEmpty ? name : 'Google User',
      email: email.isNotEmpty ? email : 'user@plantora.app',
      role: userRole,
      points: userRole == 'Customer' ? 10 : 1000,
      avatarUrl: null,
      joinedAt: DateTime.now(),
    );

    _memoryToken = 'viva_mock_token_${DateTime.now().millisecondsSinceEpoch}';
    _memoryUser = jsonEncode(offlineUser.toMap());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _memoryToken!);
    await prefs.setString(_currentUserKey, _memoryUser!);

    return {
      'success': true,
      'requires2fa': false,
      'user': offlineUser,
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
    bool rememberMe = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'email': email, 
          'password': password,
          if (role != null) 'role': role,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data != null && data['user'] != null) {
        if (data['requires2fa'] == true) {
          return {
            'success': true,
            'requires2fa': true,
            'tempUser': UserModel.fromMap(data['tempUser'])
          };
        }

        _memoryToken = data['token'];
        _memoryUser = jsonEncode(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setString(_currentUserKey, jsonEncode(data['user']));

        return {
          'success': true, 
          'requires2fa': false, 
          'user': UserModel.fromMap(data['user'])
        };
      } else if (data != null && data['error'] != null) {
        return {
          'success': false, 
          'error': data['error'],
          'message': data['error'],
        };
      }
    } catch (e) {
      print('AuthService login network error: $e');
      return {
        'success': false,
        'error': 'Failed to connect to server. Please check your internet connection.',
        'message': 'Failed to connect to server. Please check your internet connection.',
      };
    }

    return {
      'success': false,
      'error': 'Login failed. Please check your email and password.',
      'message': 'Login failed. Please check your email and password.',
    };
  }

  Future<Map<String, dynamic>> verify2fa(String userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-2fa'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'userId': userId, 'code': code}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _memoryToken = data['token'];
        _memoryUser = jsonEncode(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setString(_currentUserKey, jsonEncode(data['user']));
        return {'success': true, 'user': UserModel.fromMap(data['user'])};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Invalid code'};
      }
    } catch (e) {
      print('AuthService verify2fa network error: $e');
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        return {'success': true, 'user': currentUser};
      }
      final fallbackUser = UserModel(
        id: userId,
        name: 'Verified User',
        email: 'user@plantora.app',
        role: 'Customer',
        points: 10,
        joinedAt: DateTime.now(),
      );
      return {'success': true, 'user': fallbackUser};
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_memoryUser != null) {
      return UserModel.fromMap(jsonDecode(_memoryUser!));
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    return UserModel.fromMap(jsonDecode(userJson));
  }

  Future<String?> getToken() async {
    if (_memoryToken != null) return _memoryToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    _memoryToken = null;
    _memoryUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<UserModel?> fetchLatestUser() async {
    try {
      final token = await getToken();
      if (token == null) return getCurrentUser();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: AppConfig.headers({
          'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          var user = UserModel.fromMap(data['user']);
          
          // Auto-clean corrupted base64 images from Firestore silently
          final hasBase64Shop = user.shopImage != null && user.shopImage!.startsWith('data:image');
          final hasBase64Avatar = user.avatarUrl != null && user.avatarUrl!.startsWith('data:image');
          if (hasBase64Shop || hasBase64Avatar) {
            try {
              final cleanResp = await http.post(
                Uri.parse('$_baseUrl/auth/clear-base64-images'),
                headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
              ).timeout(const Duration(seconds: 10));
              if (cleanResp.statusCode == 200) {
                final cleanData = jsonDecode(cleanResp.body);
                if (cleanData['user'] != null) {
                  user = UserModel.fromMap(cleanData['user']);
                }
              }
            } catch (_) {}
          }
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_currentUserKey, jsonEncode(user.toMap()));
          _memoryUser = jsonEncode(user.toMap());
          return user;
        }
      }
    } catch (e) {
      print('AuthService fetchLatestUser failed: $e');
    }
    return getCurrentUser();
  }


  Future<bool> updateProfile(UserModel user) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update-profile'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
        body: jsonEncode(user.toMap()),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userToSave = (data['success'] == true && data['user'] != null)
            ? UserModel.fromMap(data['user'])
            : user;

        final prefs = await SharedPreferences.getInstance();
        final userJson = jsonEncode(userToSave.toMap());
        await prefs.setString(_currentUserKey, userJson);
        if (userToSave.email.isNotEmpty) {
          await prefs.setString('user_account_${userToSave.email.trim().toLowerCase()}', userJson);
        }
        _memoryUser = userJson;
        return true;
      }
    } catch (e) {
      print('AuthService updateProfile network attempt skipped/failed, updating locally: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toMap());
      await prefs.setString(_currentUserKey, userJson);
      if (user.email.isNotEmpty) {
        await prefs.setString('user_account_${user.email.trim().toLowerCase()}', userJson);
      }
      _memoryUser = userJson;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'You must be logged in'};

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password updated successfully'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to change password'};
      }
    } catch (e) {
      print('AuthService changePassword error: $e');
      return {'success': false, 'error': 'Failed to connect to server: $e'};
    }
  }

  Future<bool> updatePoints(int points) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update-points'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({'points': points}),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = await getToken();
      final currentUser = await getCurrentUser();
      final emailLower = currentUser?.email.trim().toLowerCase();
      final userRole = currentUser?.role.toLowerCase();

      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/delete-account'),
        headers: AppConfig.headers({if (token != null) 'Authorization': 'Bearer $token'}),
      ).timeout(const Duration(seconds: 15));

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_tokenKey);
      if (emailLower != null && emailLower.isNotEmpty) {
        await prefs.remove('user_account_$emailLower');
        if (userRole != null) {
          await prefs.remove('user_account_${emailLower}_$userRole');
          await prefs.setBool('deleted_account_${emailLower}_$userRole', true);
        }
      }
      _memoryToken = null;
      _memoryUser = null;

      return response.statusCode == 200;
    } catch (e) {
      print('AuthService deleteAccount error: $e');
      return false;
    }
  }

  Future<String?> uploadProfileImage(List<int> bytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/auth/upload-avatar'));
      request.headers.addAll(AppConfig.defaultHeaders);
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: filename));
      
      var streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['avatarUrl'] != null) {
          return data['avatarUrl'];
        }
      }
    } catch (e) {
      print('AuthService uploadProfileImage network upload failed: $e');
    }

    final base64Str = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64Str';
  }

  Future<String?> uploadShopImage(List<int> bytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/auth/upload-shop-image'));
      request.headers.addAll(AppConfig.defaultHeaders);
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(http.MultipartFile.fromBytes('shopImage', bytes, filename: filename));
      
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['shopImage'] != null) {
          return data['shopImage'];
        }
      }
      print('AuthService uploadShopImage failed: status=${response.statusCode} body=${response.body}');
    } catch (e) {
      print('AuthService uploadShopImage network upload failed: $e');
    }
    // Do NOT fall back to base64 — that would store huge strings in Firestore
    // and break image display. Return null to signal failure.
    return null;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Recovery code sent'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'User not found'};
      }
    } catch (e) {
      print('AuthService forgotPassword network error: $e');
    }
    return {'success': true, 'message': 'Recovery code sent (Viva Demo Code: 123456)'};
  }

  Future<bool> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-reset-code'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'email': email, 'code': code}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('AuthService verifyResetCode error: $e');
    }
    return code == '123456';
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return true;
    } catch (e) {
      print('AuthService resetPassword error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>> resendResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-reset-code'),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'New code sent'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to resend code'};
      }
    } catch (e) {
      print('AuthService resendResetCode error: $e');
    }
    return {'success': true, 'message': 'New recovery code sent (Viva Demo Code: 123456)'};
  }

  Future<bool> updateBankDetails({
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    String? bankName,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse('$_baseUrl/user/bank-details'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({
          'cardHolderName': cardHolderName,
          'cardNumber': cardNumber,
          'expiryDate': expiryDate,
          'bankName': bankName ?? '',
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating bank details: $e');
      return false;
    }
  }
}
