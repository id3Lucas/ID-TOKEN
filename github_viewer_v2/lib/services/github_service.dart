import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repository.dart';
import 'auth_service.dart';

class GitHubService {
  final AuthService _authService = AuthService();

  static const String _githubApiBaseUrl = 'https://api.github.com';

  Future<List<Repository>> getRepositories() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please provide a Personal Access Token.');
    }

    final response = await http.get(
      Uri.parse('$_githubApiBaseUrl/user/repos?type=all&sort=updated'),
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Repository>.from(l.map((model) => Repository.fromJson(model)));
    } else {
      throw Exception('Failed to load repositories: ${response.body}');
    }
  }

  Future<List<RepositoryContent>> getRepositoryContents(String owner, String repoName, {String path = ''}) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please provide a Personal Access Token.');
    }

    final response = await http.get(
      Uri.parse('$_githubApiBaseUrl/repos/$owner/$repoName/contents/$path'),
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<RepositoryContent>.from(l.map((model) => RepositoryContent.fromJson(model)));
    } else {
      throw Exception('Failed to load repository contents: ${response.body}');
    }
  }
}
