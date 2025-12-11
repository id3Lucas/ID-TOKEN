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

7.  **Implement Caching for API Requests (Completed with Adjustment):**
    - The `shared_preferences` package was verified/added.
    - Caching logic was integrated into `github_viewer_v2/lib/services/github_service.dart`.
    - `getRepositories()` method uses caching.
    - **Adjustment:** Caching for `getRepositoryContents()` was temporarily disabled during debugging due to stale data issues, and remains disabled as per user request (to be revisited later).

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

13. **Investigation: Flip Card Smoothness (Optimizations and Simplified Hologram Tested):**
    - Identified the "flip card" implementation in `PresentationView.html` and `styles.css`.
    - Implemented optimizations in `Vue id token/PresentationView.html` and `Vue id token/styles.css`:
        a. Removed conflicting CSS `transition` property from `.holo-layer`.
        b. Removed expensive dynamic `box-shadow` animation from JavaScript.
    - **Debugging Directory Visibility:**
        - User reported `Vue id token version 2` was not visible in the app.
        - Investigated through `developer.log` statements in `FileBrowserScreen` and `RepoListScreen`.
        - Found that the GitHub API *does* return `Vue id token version 2` at the root of the `ID-TOKEN` repository.
        - Problem was identified as stale cache in `GitHubService` (for `getRepositoryContents`).
        - **Resolution:** Temporarily disabling caching in `getRepositoryContents` revealed the directory.
    - **Simplified Hologram Test (in `Vue id token version 2`):**
        - Created a copy of `Vue id token` named `Vue id token version 2` with a significantly simplified hologram effect (reduced layers, removed expensive blend modes).
        - User confirmed that the simplified hologram `PresentationView.html` **functions correctly** and the "flip card" fluidity is now acceptable with this version.

## **Fork Creation: github_native**

To achieve even greater fluidity and native performance for critical UI components like the "flip card", a new Flutter project named `github_native` was forked from `github_viewer_v2`.

**Purpose:** This fork will serve as a testbed to implement the "flip card" (and other complex animations) directly using Flutter widgets, leveraging native rendering capabilities for optimal performance.

**Renaming and Configuration (Ongoing Troubleshooting):**
The `github_native` project was intended to be renamed from `github_viewer_v2`. Initial steps included updating:
- `pubspec.yaml` (`name` and `description`)
- `android/app/build.gradle.kts` (`namespace` and `applicationId`)
- `android/app/src/main/AndroidManifest.xml` (`android:label`)
- `android/app/src/main/kotlin/com/example/github_native/MainActivity.kt` (file path and package declaration)
- `web/manifest.json` (`name` and `short_name`)
- `web/index.html` (`apple-mobile-web-app-title` and `<title>`)
- `README.md` (title, description, and setup path)
- `linux/CMakeLists.txt` (`BINARY_NAME` and `APPLICATION_ID`)
- `linux/runner/my_application.cc` (window titles)
- `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` (`BuildableName` references)
- `macos/Runner.xcodeproj/project.pbxproj` (product references, test host paths, and bundle identifiers)
- `macos/Runner/Configs/AppInfo.xcconfig` (`PRODUCT_NAME` and `PRODUCT_BUNDLE_IDENTIFIER`)

Despite these changes, the `flutter run` command still attempts to launch the app with the old `com.example.github_viewer_v2` package ID, leading to a `ClassNotFoundException`. This indicates a persistent caching issue within the Flutter/Gradle build system or remaining references to the old name in less obvious places. Aggressive manual cleanup of build artifacts and a comprehensive re-application of renaming steps are underway to resolve this.

## Important Environment Notes

- The Flutter SDK is not in the system's `PATH`.
- To run the application, the full path to the executable must be used: `C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run`.

## Development History (Session of 2025-12-11)

**Goal:** Analyze the `github_native` project for best practices and refactor key components.

1.  **Code Analysis:**
    - Ran `flutter analyze` on the `github_native` project.
    - Identified **23 issues**, including critical compilation errors (duplicate methods, undefined variables from dead hologram code) and deprecations (`Color.withOpacity`).

2.  **Refactoring `NativeFlipCardScreen`:**
    - Addressed the large file size (~700 lines) of `native_flip_card_screen.dart`.
    - **Refactored** the widget by extracting the front and back card layouts into dedicated widgets:
        - `lib/widgets/native_id_card_front.dart` (`NativeIDCardFront`)
        - `lib/widgets/native_id_card_back.dart` (`NativeIDCardBack`)
    - **Cleaned Up:** Removed the duplicate `_handleFlip` and `dispose` methods and the undefined `_buildHologramEffect` code.
    - **Modernized:** Replaced deprecated `withOpacity(val)` calls with `withValues(alpha: val)`.

3.  **UI Fixes:**
    - **Border Radius Issue:** Fixed an issue where the card's gradient background overflowed the rounded corners. Wrapped the card content in a `ClipRRect` within `native_flip_card_screen.dart` to enforce the border radius.

4.  **Verification:**
    - Re-ran `flutter analyze` after refactoring.
    - **Result:** **0 issues found**. The project is now clean and follows better architectural practices.

5.  **Simplify `Vue id token version light`:**
    - **Request:** User requested to remove all holographic animations, the flip card mechanic, and the back side of the card from the "light" version of the ID view.
    - **Implementation:**
        - Modified `Vue id token version light/PresentationView.html` to remove the back card (`.id-card-back`), hologram elements, and simplify the script (no physics).
        - Modified `Vue id token version light/styles.css` to clean up unused styles.
    - **Result:** A static, lightweight front-facing ID card view.

6.  **Remove Zoom Feature (Requested):**
    - **Request:** User requested to also remove the zoom feature from the "light" version.
    - **Implementation:**
        - Modified `Vue id token version light/PresentationView.html`: Removed `#zoom-wrapper`, `#zoom-btn`, and specific zoom-related JavaScript functions (`enterFullscreen`, `updateZoomScale`, `toggleZoom`).
        - Modified `Vue id token version light/styles.css`: Removed all styles related to the zoom wrapper, zoom button, and `.is-zoomed` state.
    - **Result:** The "light" version is now purely the static card, centered in the viewport, with no interactive elements besides the chip animation (CSS).

7.  **Remove Chip Element (Requested):**
    - **Request:** User requested to remove the chip element and its associated animation due to redundancy.
    - **Implementation:**
        - Modified `Vue id token version light/PresentationView.html`: Removed the `.chip` container and its SVG content.
        - Modified `Vue id token version light/styles.css`: Removed `.chip` styles, the `@keyframes wave-chip` animation, and the chip's positioning in the landscape media query.
    - **Result:** The chip icon is gone, further simplifying the card's appearance.
