import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
    // developer.log('RepoListScreen: Fetching repositories...', name: 'RepoListScreen'); // Log removed
    _repositoriesFuture = _githubService.getRepositories();
  }

  void _signOut() async {
    // developer.log('RepoListScreen: Signing out...', name: 'RepoListScreen'); // Log removed
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // Helper widget for the shimmer loading effect
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 10, // Number of shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 24,
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 16.0,
                color: Colors.white,
              ),
            ),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 14.0,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
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
            // developer.log('RepoListScreen: ConnectionState.waiting', name: 'RepoListScreen'); // Log removed
            return _buildShimmerList();
          } else if (snapshot.hasError) {
            // developer.log('RepoListScreen: Error: ${snapshot.error}', name: 'RepoListScreen'); // Log removed
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}\n\nThis could be due to an invalid or expired Personal Access Token. Please try logging out and logging back in with a valid token.'),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // developer.log('RepoListScreen: No repositories found.', name: 'RepoListScreen'); // Log removed
            return const Center(child: Text('No repositories found.'));
          } else {
            final repos = snapshot.data!;
            // developer.log('RepoListScreen: Repositories loaded (${repos.length} found).', name: 'RepoListScreen'); // Log removed
            // // Log names of loaded repositories
            // for (var repo in repos) { // Log removed
            //   developer.log('RepoListScreen: - ${repo.name} (owner: ${repo.owner})', name: 'RepoListScreen'); // Log removed
            // }
            return ListView.builder(
              itemCount: repos.length,
              itemBuilder: (context, index) {
                final repo = repos[index];
                return ListTile(
                  title: Text(repo.name),
                  subtitle: Text(repo.owner),
                  onTap: () {
                    // developer.log('RepoListScreen: Tapped on repository: ${repo.name}', name: 'RepoListScreen'); // Log removed
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
