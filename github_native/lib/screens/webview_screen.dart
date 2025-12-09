import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Import Android specific WebView
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart'; // Required for PlatformWebViewControllerCreationParams
// Removed import 'package:shimmer/shimmer.dart';

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

    // Create Platform Specific Params
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent) // Set transparent background
      ..enableZoom(false); // Disable browser zoom

    // ANDROID SPECIFIC OPTIMIZATIONS
    if (_controller.platform is AndroidWebViewController) {
      // Force Hardware Acceleration for the view
      AndroidWebViewController.enableDebugging(false); // Turn off debug overhead
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    
    _loadHtmlWithBaseUrl();
  }

  Future<void> _loadHtmlWithBaseUrl() async {
    try {
      developer.log('Fetching HTML from: ${widget.fileUrl}', name: 'WebViewScreen');
      final htmlResponse = await http.get(Uri.parse(widget.fileUrl));

      if (htmlResponse.statusCode == 200) {
        String htmlContent = htmlResponse.body;
        
        final String directoryBaseUrl = Uri.parse(widget.fileUrl).resolve('.').toString();

        // Define two regex patterns: one for double-quoted href, one for single-quoted href
        final RegExp cssLinkRegexDouble = RegExp(r'<link[^>]*?href="([^"]+\.css)"[^>]*?>', caseSensitive: false);
        final RegExp cssLinkRegexSingle = RegExp(r"<link[^>]*?href='([^']+\.css)'[^>]*?>", caseSensitive: false);

        List<RegExpMatch> allMatches = [];
        allMatches.addAll(cssLinkRegexDouble.allMatches(htmlContent));
        allMatches.addAll(cssLinkRegexSingle.allMatches(htmlContent));

        // Sort matches by their start index in reverse order to avoid issues with string replacement indices
        allMatches.sort((a, b) => b.start.compareTo(a.start));

        for (final match in allMatches) {
          final originalLinkTag = match.group(0)!;
          final cssRelativePath = match.group(1)!;
          
          final cssUri = Uri.parse(directoryBaseUrl).resolve(cssRelativePath);

          developer.log('Attempting to fetch and embed CSS from: $cssUri', name: 'WebViewScreen');
          final cssResponse = await http.get(cssUri);

          if (cssResponse.statusCode == 200) {
            final cssContent = cssResponse.body;
            final styleTag = '<style>$cssContent</style>';
            htmlContent = htmlContent.replaceRange(match.start, match.end, styleTag);
            developer.log('Embedded CSS for: $cssUri due to MIME type issue.', name: 'WebViewScreen');
          } else {
            developer.log('Failed to fetch CSS from $cssUri. Status code: ${cssResponse.statusCode}. Leaving link tag for WebView.', name: 'WebViewScreen');
            _errorMessage = 'Failed to fetch CSS for styling: ${cssResponse.statusCode}';
          }
        }
        
        // --- PERFORMANCE OPTIMIZATIONS ---

        // 1. Add loading="lazy" to all images for better performance.
        htmlContent = htmlContent.replaceAll(
          RegExp(r'<img', caseSensitive: false),
          '<img loading="lazy"');
        developer.log('Added loading="lazy" to image tags.', name: 'WebViewScreen');

        // 2. Add defer to all external scripts for non-blocking loading.
        htmlContent = htmlContent.replaceAll(
          RegExp(r'<script(?=\s)', caseSensitive: false), // Positive lookahead for a space
          '<script defer');
        developer.log('Added defer attribute to script tags.', name: 'WebViewScreen');

        // --- END OF OPTIMIZATIONS ---

        await _controller.loadHtmlString(htmlContent, baseUrl: directoryBaseUrl);
        developer.log('Final HTML loaded into WebView with baseUrl: $directoryBaseUrl', name: 'WebViewScreen');
      } else {
        throw Exception('Failed to load file content from ${widget.fileUrl}. Status code: ${htmlResponse.statusCode}');
      }
    } catch (e) {
      final detailedError = 'Error in _loadHtmlWithBaseUrl: ${e.toString()}';
      developer.log(detailedError, name: 'WebViewScreen', error: e);
      setState(() {
        _errorMessage = detailedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Removed _buildShimmerContent() helper widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator()); // Reverted to CircularProgressIndicator
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