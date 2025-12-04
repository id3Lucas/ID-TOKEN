import 'package:flutter/material.dart';
import '../services/github_service.dart';
import '../services/auth_service.dart';
import '../models/repository.dart';

class RepoListScreen extends StatefulWidget {
  const RepoListScreen({super.key});

  @override
  State<RepoListScreen> createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  final GitHubService _githubService = GitHubService();
  final AuthService _authService = AuthService();
  late Future<List<Repository>> _repositoriesFuture;

  @override
  void initState() {
    super.initState();
    _repositoriesFuture = _githubService.getRepositories();
  }

  void _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Repositories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<Repository>>(
        future: _repositoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}\n\nThis could be due to an invalid or expired Personal Access Token. Please try logging out and logging back in with a valid token.'),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No repositories found.'));
          } else {
            final repos = snapshot.data!;
            return ListView.builder(
              itemCount: repos.length,
              itemBuilder: (context, index) {
                final repo = repos[index];
                return ListTile(
                  title: Text(repo.name),
                  subtitle: Text(repo.owner),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/file_browser',
                      arguments: {'owner': repo.owner, 'repoName': repo.name},
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
