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
    Navigator.of(context).pushReplacementNamed('/'); // Navigate back to login
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
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No repositories found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final repo = snapshot.data![index];
                return ListTile(
                  title: Text(repo.name),
                  subtitle: Text(repo.htmlUrl),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/file_browser',
                      arguments: {'owner': repo.htmlUrl.split('/')[3], 'repoName': repo.name},
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
