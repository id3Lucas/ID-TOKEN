import 'package:flutter/material.dart';
import 'package:github_html_viewer/screens/file_browser_screen.dart';
import 'package:github_html_viewer/screens/login_screen.dart';
import 'package:github_html_viewer/screens/repo_list_screen.dart';
import 'package:github_html_viewer/screens/webview_screen.dart';
import 'package:github_html_viewer/services/auth_service.dart'; // Import AuthService

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    _isAuthenticated = await _authService.isAuthenticated();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub HTML Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_isAuthenticated ? const RepoListScreen() : const LoginScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/repo_list': (context) => const RepoListScreen(),
        '/file_browser': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return FileBrowserScreen(owner: args['owner']!, repoName: args['repoName']!);
        },
        '/webview': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return WebViewScreen(fileUrl: args['fileUrl']!, fileName: args['fileName']!);
        },
      },
    );
  }
}
