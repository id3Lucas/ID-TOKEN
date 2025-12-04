import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _githubPatKey = 'github_pat';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_githubPatKey, token);
  }

  Future<String?>getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_githubPatKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_githubPatKey);
  }
}
