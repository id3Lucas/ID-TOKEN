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
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    
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

      // 2. Define two regex patterns: one for double-quoted href, one for single-quoted href
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

      final baseUrl = widget.fileUrl.substring(0, widget.fileUrl.lastIndexOf('/') + 1);
      developer.log('Base URL for resolving CSS: $baseUrl', name: 'WebViewScreen');

      // Create a list of futures for parallel CSS downloads
      List<Future<Map<String, String?>>> cssDownloadFutures = [];
      List<Map<String, dynamic>> cssLinkDetails = []; // To store original tag, path, and match details

      for (final match in allMatches) {
        final originalLinkTag = match.group(0)!;
        final cssRelativePath = match.group(1)!;

        // Ensure it's a relative path (not http/https)
        if (cssRelativePath.startsWith('http://') || cssRelativePath.startsWith('https://') || cssRelativePath.startsWith('//')) {
          developer.log('Skipping absolute CSS path: $cssRelativePath', name: 'WebViewScreen');
          continue;
        }

        final cssUri = Uri.parse(baseUrl).resolve(cssRelativePath);
        developer.log('Scheduling CSS download for: $cssUri', name: 'WebViewScreen');

        cssLinkDetails.add({
          'match': match,
          'originalLinkTag': originalLinkTag,
          'cssRelativePath': cssRelativePath,
          'cssUri': cssUri,
        });

        cssDownloadFutures.add(
          http.get(cssUri).then((response) {
            if (response.statusCode == 200) {
              developer.log('CSS downloaded successfully from: $cssUri', name: 'WebViewScreen');
              return {'cssContent': response.body, 'cssUri': cssUri.toString()};
            } else {
              developer.log('Failed to download CSS from $cssUri. Status code: ${response.statusCode}', name: 'WebViewScreen');
              return {'cssContent': null, 'cssUri': cssUri.toString()};
            }
          }).catchError((e) {
            developer.log('Error downloading CSS from $cssUri: $e', name: 'WebViewScreen');
            return {'cssContent': null, 'cssUri': cssUri.toString()};
          })
        );
      }

      // Wait for all CSS downloads to complete
      final List<Map<String, String?>> downloadedCssResults = await Future.wait(cssDownloadFutures);

      // Sort matches by their start index in reverse order to avoid issues with string replacement indices
      // This step is crucial for `replaceRange` to work correctly when multiple replacements occur.
      cssLinkDetails.sort((a, b) => (b['match'] as RegExpMatch).start.compareTo((a['match'] as RegExpMatch).start));

      // Process downloaded CSS and embed into HTML
      for (int i = 0; i < cssLinkDetails.length; i++) {
        final detail = cssLinkDetails[i];
        final match = detail['match'] as RegExpMatch;
        final originalLinkTag = detail['originalLinkTag'] as String;
        final cssRelativePath = detail['cssRelativePath'] as String;
        final cssUri = detail['cssUri'] as Uri;
        
        // Find the corresponding downloaded content in the `downloadedCssResults`
        // We need to match by cssUri because the order of cssLinkDetails might be different after sorting
        final downloadedResult = downloadedCssResults.firstWhere(
          (result) => result['cssUri'] == cssUri.toString(),
          orElse: () => {'cssContent': null, 'cssUri': cssUri.toString()} // Fallback
        );

        final cssContent = downloadedResult['cssContent'];

        if (cssContent != null) {
          final styleTag = '<style>$cssContent</style>';
          htmlContent = htmlContent.replaceRange(match.start, match.end, styleTag);
          developer.log('Replaced $originalLinkTag with <style> tag for $cssUri.', name: 'WebViewScreen');
        } else {
          _errorMessage = "Could not load CSS from $cssRelativePath (URI: $cssUri)";
          developer.log('Embedding failed for $cssUri due to previous download error.', name: 'WebViewScreen');
          // If a specific CSS failed, we can still try to load the rest.
          // The _errorMessage will reflect the last failure.
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