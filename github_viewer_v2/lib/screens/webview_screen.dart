import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    
    _loadHtmlWithEmbeddedCss();
  }

  Future<void> _loadHtmlWithEmbeddedCss() async {
    try {
      // 1. Download the HTML content
      final htmlResponse = await http.get(Uri.parse(widget.fileUrl));
      if (htmlResponse.statusCode != 200) {
        throw Exception('Failed to load HTML. Status code: ${htmlResponse.statusCode}');
      }
      String htmlContent = htmlResponse.body;

      // 2. Find relative CSS links
      final RegExp cssLinkRegex = RegExp(
        r'<link[^>]*?href="([^"]+\.css)"[^>]*?rel="stylesheet"[^>]*?>',
        caseSensitive: false,
      );

      final matches = cssLinkRegex.allMatches(htmlContent);
      if (matches.isEmpty) {
        await _controller.loadHtmlString(htmlContent);
        return; // No CSS to process
      }
      
      // Get the base URL to resolve relative paths
      final baseUrl = widget.fileUrl.substring(0, widget.fileUrl.lastIndexOf('/') + 1);

      for (final match in matches) {
        final originalLinkTag = match.group(0)!;
        final cssPath = match.group(1)!;

        // Don't process absolute URLs
        if (cssPath.startsWith('http://') || cssPath.startsWith('https://')) {
          continue;
        }

        // 3. Download the CSS content
        final cssUrl = baseUrl + cssPath;
        final cssResponse = await http.get(Uri.parse(cssUrl));
        
        if (cssResponse.statusCode == 200) {
          // 4. Embed the CSS into a <style> tag
          final cssContent = cssResponse.body;
          final styleTag = '<style>$cssContent</style>';
          htmlContent = htmlContent.replaceFirst(originalLinkTag, styleTag);
        }
        // If CSS download fails, we simply leave the <link> tag as is.
      }

      // 5. Load the final HTML
      await _controller.loadHtmlString(htmlContent);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
