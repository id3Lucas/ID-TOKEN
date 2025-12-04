import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class AuthService {
  static const String _githubAccessTokenKey = 'github_access_token';

  Future<void> signInWithGitHub() async {
    if (await canLaunchUrl(Uri.parse(githubAuthUrl))) {
      await launchUrl(Uri.parse(githubAuthUrl), mode: LaunchMode.inAppWebView);
    } else {
      throw 'Could not launch $githubAuthUrl';
    }
  }

  Future<bool> exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(githubTokenUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'client_id': githubClientId,
        'client_secret': githubClientSecret,
        'code': code,
        'redirect_uri': githubRedirectUri,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String? accessToken = data['access_token'];
      if (accessToken != null) {
        await _saveAccessToken(accessToken);
        return true;
      } else {
        throw 'Access token not found in response';
      }
    } else {
      throw 'Failed to exchange code for token: ${response.body}';
    }
  }

  Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_githubAccessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_githubAccessTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_githubAccessTokenKey);
  }
}
