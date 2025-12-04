class Repository {
  final String name;
  final String htmlUrl;
  final String? defaultBranch;

  Repository({required this.name, required this.htmlUrl, this.defaultBranch});

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'],
      htmlUrl: json['html_url'],
      defaultBranch: json['default_branch'],
    );
  }
}

class RepositoryContent {
  final String name;
  final String path;
  final String type; // 'file' or 'dir'
  final String? downloadUrl; // For files

  RepositoryContent({required this.name, required this.path, required this.type, this.downloadUrl});

  factory RepositoryContent.fromJson(Map<String, dynamic> json) {
    return RepositoryContent(
      name: json['name'],
      path: json['path'],
      type: json['type'],
      downloadUrl: json['download_url'],
    );
  }
}
