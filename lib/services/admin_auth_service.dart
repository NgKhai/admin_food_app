import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  Future<void> login(String username, String password) async {
    // Simulating authentication logic (replace with actual API call)
    if (username == "crunchanddash" && password == "gagionvuive") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }
}