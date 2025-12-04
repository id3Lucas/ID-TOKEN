import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:github_html_viewer/screens/file_browser_screen.dart';
import 'package:github_html_viewer/screens/login_screen.dart';
import 'package:github_html_viewer/screens/repo_list_screen.dart';
import 'package:github_html_viewer/screens/webview_screen.dart';
import 'package:github_html_viewer/services/auth_service.dart';

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
  late final StreamSubscription<Uri> _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen((uri) async {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          final success = await _authService.exchangeCodeForToken(code);
          if (success) {
            _navigatorKey.currentState?.pushReplacementNamed('/repo_list');
          } else {
            // Optionally handle failed login
          }
        } catch (e) {
          // Handle error
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub HTML Viewer',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Always start at login, auth check is inside
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
