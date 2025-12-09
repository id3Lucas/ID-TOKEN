# Project Summary: github_viewer_v2

This document summarizes the state and development history of the `github_viewer_v2` project for future reference by the Gemini assistant.

## Project Overview

- **Name:** `github_viewer_v2`
- **Type:** Flutter Application
- **Purpose:** An application to browse and view content from GitHub repositories. It includes functionality to authenticate, list repositories, browse file structures, and display file content.

## Development History (Session of 2025-12-09)

The primary goal of this session was to improve the rendering of HTML files within the application's `WebView`.

1.  **Initial Problem:** HTML content rendered in a `WebView` was not displaying its associated CSS styling correctly.

2.  **Root Cause Analysis:** Investigation of the WebView logs revealed that an external CSS file, hosted on `raw.githubusercontent.com`, was being served with an incorrect MIME type of `text/plain` instead of the required `text/css`. The WebView's strict MIME type checking was preventing the stylesheet from being applied.

3.  **Solution Implemented:**
    - The initial approach of simply providing a `baseUrl` to the `loadHtmlString` method was insufficient due to the server-side MIME type issue.
    - A more robust solution was implemented in `github_viewer_v2/lib/screens/webview_screen.dart`.
    - The final logic involves:
        a. Fetching the primary HTML content.
        b. Using two regular expressions to find all CSS `<link>` tags (handling both single and double-quoted `href` attributes).
        c. Iterating through all found CSS links in reverse order to safely modify the string.
        d. For each link, fetching the CSS content via an HTTP GET request in Dart.
        e. Replacing the original `<link>` tag in the HTML string with an inline `<style>` tag containing the fetched CSS content.
        f. Finally, loading the modified HTML string into the `WebView`, while still providing a `baseUrl` for any other relative resources (like images).

4.  **Debugging Steps:**
    - The implementation of the CSS embedding logic initially caused a `RegExp` syntax error due to how quotes were handled in the Dart raw string literal.
    - This was resolved by reverting from a single complex regex to the safer two-regex approach.

5.  **Performance Optimizations (Fluidity):**
    - To further improve loading performance and scrolling fluidity, two more optimizations were applied to the HTML content in `webview_screen.dart` before loading:
        a. **Lazy Loading Images:** Automatically added `loading="lazy"` to all `<img>` tags.
        b. **Deferring JavaScript:** Automatically added the `defer` attribute to `<script>` tags to make their loading non-blocking.

6.  **Update Project Dependencies (Completed):**
    - Executed `flutter pub upgrade --major-versions`.
    - `shared_preferences` and `webview_flutter_wkwebview` were updated.
    - Noted that 4 packages still had incompatible constraints.
    - `webview_flutter` updated to `4.13.0`.
    - `webview_flutter_android` updated to `4.10.11`.

7.  **Implement Caching for API Requests (Completed):**
    - The `shared_preferences` package was verified/added.
    - Caching logic was integrated into `github_viewer_v2/lib/services/github_service.dart`.
    - Both `getRepositories()` and `getRepositoryContents()` methods now check local cache first, then fetch from the network if data is not present or stale, and finally store network responses in `shared_preferences`.

8.  **Implement Shimmer Effect for Loading (Completed):**
    - The `shimmer` package was added to the project dependencies.
    - **For `RepoListScreen`:** Implemented a shimmer effect to replace the `CircularProgressIndicator` when loading repositories, mimicking the `ListTile` layout.
    - **For `WebViewScreen`:** An initial attempt was made to add a generic shimmer effect. However, due to the unpredictable and dynamic nature of arbitrary HTML content, the generic shimmer did not provide a good user experience. This effect was subsequently reverted, and the `CircularProgressIndicator` was restored for `WebViewScreen` to maintain clarity during HTML loading.

9.  **AI Studio Suggestion: Force Hardware Acceleration (Android) (Completed):**
    - Added `android:hardwareAccelerated="true"` to the `<application>` tag in `android/app/src/main/AndroidManifest.xml`. This explicitly enables hardware acceleration for the Android app, benefiting WebView rendering.

10. **AI Studio Suggestion: WebView Controller Configuration (Completed with Adjustments):**
    - Modified `github_viewer_v2/lib/screens/webview_screen.dart` to use platform-specific `WebViewController` creation parameters.
    - Applied general optimizations: `setBackgroundColor(Colors.transparent)` and `enableZoom(false)`.
    - Applied Android-specific optimizations: `AndroidWebViewController.enableDebugging(false)` and `setMediaPlaybackRequiresUserGesture(false)`.
    - **Note on `forceEnableSurfaceControl`:** The suggested parameter `forceEnableSurfaceControl: true` for `AndroidWebViewControllerCreationParams` was found not to exist in `webview_flutter_android` version `4.10.11` (or the 4.x.x series) after investigation. It was therefore removed to allow the application to compile. SurfaceControl optimizations are handled implicitly by the plugin in modern Flutter versions with hybrid composition.

11. **AI Studio Suggestion: iOS Specific - 120Hz (ProMotion) Issue (Completed):**
    - Added `<key>CADisableMinimumFrameDurationOnPhone</key><true/>` to `ios/Runner/Info.plist`. This aims to unlock the full frame rate (120Hz) for `WKWebView`s on compatible iOS devices, providing a smoother experience.

12. **AI Studio Suggestion: Are you in Debug Mode? (Tested in Release Mode):**
    - Confirmed with the user the importance of testing in Release mode for accurate performance assessment. User reported testing in Release mode for the HTML content.

13. **Investigation: Flip Card Smoothness (Initial Optimizations Implemented):**
    - Identified the "flip card" implementation in `PresentationView.html` and `styles.css`.
    - Implemented optimizations:
        a. Removed conflicting CSS `transition` property from `.holo-layer` in `styles.css`.
        b. Removed expensive dynamic `box-shadow` animation from JavaScript in `PresentationView.html`.
    - **User Feedback:** User reported that the improvement was "not very great." Further investigation into flip card fluidity is needed.

## Important Environment Notes

- The Flutter SDK is not in the system's `PATH`.
- To run the application, the full path to the executable must be used: `C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run`.
