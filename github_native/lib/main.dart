import 'package:flutter/material.dart';
import 'package:github_native/screens/file_browser_screen.dart';
import 'package:github_native/screens/login_screen.dart';
import 'package:github_native/screens/repo_list_screen.dart';
import 'package:github_native/screens/webview_screen.dart';
import 'package:github_native/services/auth_service.dart';

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
  late Future<bool> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    _authCheckFuture = _authService.isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub HTML Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<bool>(
        future: _authCheckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasData && snapshot.data == true) {
            return const RepoListScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
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
