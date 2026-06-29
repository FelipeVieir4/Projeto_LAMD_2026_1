import 'package:shared_preferences/shared_preferences.dart';
import '../remote/api_client.dart';
import '../../models/user.dart';
import '../../core/constants.dart';

class AuthRepository {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userEmailKey);
  }

  Future<String?> getSavedCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userCompanyNameKey);
  }

  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userPhoneKey);
  }

  Future<void> _saveSession(String token, PartnerUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.userEmailKey, user.email);
    await prefs.setString(AppConstants.userCompanyNameKey, user.companyName);
    if (user.phone != null && user.phone!.isNotEmpty) {
      await prefs.setString(AppConstants.userPhoneKey, user.phone!);
    } else {
      await prefs.remove(AppConstants.userPhoneKey);
    }
    if (user.bio != null && user.bio!.isNotEmpty) {
      await prefs.setString(AppConstants.userBioKey, user.bio!);
    } else {
      await prefs.remove(AppConstants.userBioKey);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userCompanyNameKey);
    await prefs.remove(AppConstants.userPhoneKey);
    await prefs.remove(AppConstants.userBioKey);
  }

  Future<({PartnerUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient().post('/auth/login', {
      'email': email,
      'password': password,
      'program': 'partner',
    });
    final user = PartnerUser.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await _saveSession(token, user);
    return (user: user, token: token);
  }

  Future<({PartnerUser user, String token})> register({
    required String companyName,
    required String document,
    required String email,
    required String password,
    String? phone,
    String? bio,
    List<String> specialties = const [],
  }) async {
    final data = await ApiClient().post('/auth/register', {
      'companyName': companyName,
      'document': document,
      'email': email,
      'password': password,
      'program': 'partner',
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      'specialties': specialties,
    });
    final user = PartnerUser.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await _saveSession(token, user);
    return (user: user, token: token);
  }

  Future<PartnerUser> fetchMe(String token) async {
    final data = await ApiClient(token: token).get('/auth/me');
    return PartnerUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<PartnerUser> updateProfile({
    required String token,
    required String companyName,
    String? phone,
    String? bio,
  }) async {
    final data = await ApiClient(token: token).patch('/auth/profile', {
      'companyName': companyName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
    });
    final user = PartnerUser.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userCompanyNameKey, user.companyName);
    if (user.phone != null && user.phone!.isNotEmpty) {
      await prefs.setString(AppConstants.userPhoneKey, user.phone!);
    } else {
      await prefs.remove(AppConstants.userPhoneKey);
    }
    return user;
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient(token: token).patch('/auth/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
