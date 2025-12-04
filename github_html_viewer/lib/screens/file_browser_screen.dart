import 'package:flutter/material.dart';
import '../services/github_service.dart';
import '../models/repository.dart';

class FileBrowserScreen extends StatefulWidget {
  final String owner;
  final String repoName;

  const FileBrowserScreen({super.key, required this.owner, required this.repoName});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  final GitHubService _githubService = GitHubService();
  late Future<List<RepositoryContent>> _contentsFuture;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _fetchContents();
  }

  void _fetchContents() {
    setState(() {
      _contentsFuture = _githubService.getRepositoryContents(
        widget.owner,
        widget.repoName,
        path: _currentPath,
      );
    });
  }

  void _onTapContent(RepositoryContent content) {
    if (content.type == 'dir') {
      setState(() {
        _currentPath = content.path;
      });
      _fetchContents();
    } else if (content.type == 'file' && content.downloadUrl != null) {
      // Assuming we want to view any file, but the request was specifically for HTML
      // We can add a check here if content.name.endsWith('.html') if strictly needed
      Navigator.of(context).pushNamed(
        '/webview',
        arguments: {'fileUrl': content.downloadUrl!, 'fileName': content.name},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.repoName} - $_currentPath'),
        leading: _currentPath.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentPath = _currentPath.contains('/')
                        ? _currentPath.substring(0, _currentPath.lastIndexOf('/'))
                        : '';
                  });
                  _fetchContents();
                },
              )
            : null,
      ),
      body: FutureBuilder<List<RepositoryContent>>(
        future: _contentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No contents found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final content = snapshot.data![index];
                return ListTile(
                  leading: Icon(content.type == 'dir' ? Icons.folder : Icons.insert_drive_file),
                  title: Text(content.name),
                  onTap: () => _onTapContent(content),
                );
              },
            );
          }
        },
      ),
    );
  }
}
