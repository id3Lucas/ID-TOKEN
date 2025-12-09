import 'package:flutter/material.dart';
// Removed developer import
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
  List<String> _pathHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchContents();
  }

  void _fetchContents() {
    setState(() {
      // developer.log('Fetching contents for ${widget.owner}/${widget.repoName} at path: $_currentPath', name: 'FileBrowserScreen'); // Log removed
      _contentsFuture = _githubService.getRepositoryContents(
        widget.owner,
        widget.repoName,
        path: _currentPath,
      );
    });
  }

  void _onTapContent(RepositoryContent content) {
    if (content.type == 'dir') {
      _pathHistory.add(_currentPath);
      setState(() {
        _currentPath = content.path;
      });
      _fetchContents();
    } else if (content.type == 'file' && content.name.endsWith('.html') && content.downloadUrl != null) {
      Navigator.of(context).pushNamed(
        '/webview',
        arguments: {'fileUrl': content.downloadUrl!, 'fileName': content.name},
      );
    } else if (content.type == 'file') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This is not an HTML file.')),
      );
    }
  }

  bool _onWillPop() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        _currentPath = _pathHistory.removeLast();
      });
      _fetchContents();
      return false; // Do not pop the route
    }
    return true; // Pop the route
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _onWillPop(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.repoName} / $_currentPath'),
        ),
        body: FutureBuilder<List<RepositoryContent>>(
          future: _contentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // developer.log('Error fetching contents: ${snapshot.error}', name: 'FileBrowserScreen'); // Log removed
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // developer.log('No contents found for ${widget.owner}/${widget.repoName} at path: $_currentPath', name: 'FileBrowserScreen'); // Log removed
              return const Center(child: Text('No contents found in this directory.'));
            } else {
              final contents = snapshot.data!;
              // developer.log('Contents received for ${widget.owner}/${widget.repoName} at path: $_currentPath:', name: 'FileBrowserScreen'); // Log removed
              // for (var content in contents) { // Log removed
              //   developer.log('- Name: ${content.name}, Type: ${content.type}, Path: ${content.path}', name: 'FileBrowserScreen'); // Log removed
              // }
              return ListView.builder(
                itemCount: contents.length,
                itemBuilder: (context, index) {
                  final content = contents[index];
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
      ),
    );
  }
}
