import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer; // Keep developer.log for internal tracking

class WebViewScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const WebViewScreen({super.key, required this.fileUrl, required this.fileName});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  // Removed _debugMessages and _addDebugMessage

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPermissionRequestHandler((request) {
        // Grant all permissions requested by the web content.
        // In a production app, you might want to be more selective,
        // but for this use case, granting access is the goal.
        request.grant();
      });
    
    _loadHtmlWithEmbeddedCss();
  }

  Future<void> _loadHtmlWithEmbeddedCss() async {
    try {
      developer.log('Attempting to load HTML from: ${widget.fileUrl}', name: 'WebViewScreen');

      // 1. Download the HTML content
      final htmlResponse = await http.get(Uri.parse(widget.fileUrl));
      if (htmlResponse.statusCode != 200) {
        throw Exception('Failed to load HTML from ${widget.fileUrl}. Status code: ${htmlResponse.statusCode}');
      }
      String htmlContent = htmlResponse.body;
      developer.log('HTML content downloaded. Length: ${htmlContent.length}', name: 'WebViewScreen');

      // 2. Define two very permissive regex patterns: one for double-quoted href, one for single-quoted href
      // This will match ANY <link> tag with an href ending in .css, regardless of rel attribute.
      final RegExp cssLinkRegexDouble = RegExp(
        r'<link[^>]*?href="([^"]+\.css)"[^>]*?>', // Removed rel="stylesheet" constraint
        caseSensitive: false,
      );
      final RegExp cssLinkRegexSingle = RegExp(
        r"<link[^>]*?href='([^']+\.css)'[^>]*?>", // Removed rel='stylesheet' constraint
        caseSensitive: false,
      );

      // Collect all matches from both regexes
      List<RegExpMatch> allMatches = [];
      allMatches.addAll(cssLinkRegexDouble.allMatches(htmlContent));
      allMatches.addAll(cssLinkRegexSingle.allMatches(htmlContent));
      
      developer.log('Found ${allMatches.length} CSS link matches (permissive regex).', name: 'WebViewScreen');
      if (allMatches.isEmpty) {
        developer.log('No external CSS links found or matched.', name: 'WebViewScreen');
      }

      // Sort matches by their start index in reverse order to avoid issues with string replacement indices
      allMatches.sort((a, b) => b.start.compareTo(a.start));

      // Get the base URL to resolve relative paths
      final baseUrl = widget.fileUrl.substring(0, widget.fileUrl.lastIndexOf('/') + 1);
      developer.log('Base URL for resolving CSS: $baseUrl', name: 'WebViewScreen');

      for (final match in allMatches) {
        final originalLinkTag = match.group(0)!;
        final cssRelativePath = match.group(1)!; // Capture group 1 is the path

        developer.log('Processing CSS link: $originalLinkTag, relative path: $cssRelativePath', name: 'WebViewScreen');

        // Ensure it's a relative path (not http/https)
        if (cssRelativePath.startsWith('http://') || cssRelativePath.startsWith('https://') || cssRelativePath.startsWith('//')) {
          developer.log('Skipping absolute CSS path: $cssRelativePath', name: 'WebViewScreen');
          continue;
        }

        // 3. Construct the full CSS URL using Uri.resolve for robustness
        final cssUri = Uri.parse(baseUrl).resolve(cssRelativePath);
        developer.log('Constructed CSS URL: $cssUri', name: 'WebViewScreen');

        // 4. Download the CSS content
        final cssResponse = await http.get(cssUri);
        
        if (cssResponse.statusCode == 200) {
          developer.log('CSS downloaded successfully from: $cssUri', name: 'WebViewScreen');
          // 5. Embed the CSS into a <style> tag
          final cssContent = cssResponse.body;
          final styleTag = '<style>$cssContent</style>';
          
          // Replace the original <link> tag with the <style> tag
          htmlContent = htmlContent.replaceRange(match.start, match.end, styleTag);
          developer.log('Replaced $originalLinkTag with <style> tag.', name: 'WebViewScreen');
        } else {
          final errorMsg = 'Failed to download CSS from $cssUri. Status code: ${cssResponse.statusCode}';
          developer.log(errorMsg, name: 'WebViewScreen');
          // Display a message in the app if CSS download fails
          _errorMessage = "Could not load CSS from $cssRelativePath: Status ${cssResponse.statusCode}";
        }
      }

      // 6. Load the final HTML
      await _controller.loadHtmlString(htmlContent);
      developer.log('Final HTML loaded into WebView.', name: 'WebViewScreen');

    } catch (e) {
      final detailedError = 'Error in _loadHtmlWithEmbeddedCss: ${e.toString()}';
      developer.log(detailedError, name: 'WebViewScreen', error: e);
      setState(() {
        _errorMessage = detailedError; // Display the error directly in the app
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_errorMessage != null) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $_errorMessage'),
            ));
          }
          return WebViewWidget(controller: _controller);
        },
      ),
    );
  }
}
