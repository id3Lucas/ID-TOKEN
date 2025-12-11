# Project Summary: github_native (Fork of github_viewer_v2)

This project is a fork of `github_viewer_v2`, created with the primary goal of improving the performance and fluidity of complex UI animations, specifically the "flip card" effect with its holographic elements.

## Motivation

The original `github_viewer_v2` project utilizes a `WebView` to display HTML content, including an ID card with an intricate flip animation and hologram effect. Despite extensive optimization efforts within the WebView (hardware acceleration, CSS/JS tuning, etc.), achieving perfectly smooth 60/120 FPS animations proved challenging due to the inherent overhead and limitations of WebViews for such demanding visual effects on mobile platforms.

## Purpose of this Fork

The `github_native` project aims to address these fluidity concerns by:

1.  **Implementing performance-critical UI components using native Flutter widgets.** This leverages Flutter's direct GPU access, optimized rendering pipeline, and robust animation capabilities.
2.  **Replacing the `WebViewScreen`'s functionality for specific HTML content (like the ID card) with a custom-built Flutter widget.** This allows for a completely native user experience for highly interactive elements.

## Strategy

The main strategy involves:
- Identifying sections of the `WebViewScreen` that display content better suited for native implementation (e.g., the interactive flip card).
- Developing a dedicated Flutter widget (e.g., `NativeFlipCard`) to replicate the visual design and interactive behavior of the HTML card using Flutter's `Transform`, `sensors_plus` package for gyro data, and native animation controllers.
- Integrating this new native widget into the application flow, bypassing the WebView for that specific content.

This fork serves as a testbed for comparing the performance characteristics of WebView-based vs. native Flutter implementations for complex animations.

## Development Progress

### Renaming from `github_viewer_v2` to `github_native` (COMPLETE)
This was a challenging process due to deep caching and numerous references to the old project name across various platform files. The following steps were undertaken:
1.  **Initial File Modifications:** `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart` were updated to use `github_native` or `com.example.github_native`.
2.  **Directory Renames:** The Kotlin package directory `android/app/src/main/kotlin/com/example/github_viewer_v2` was renamed to `android/app/src/main/kotlin/com/example/github_native`, and the `package` declaration inside `MainActivity.kt` was updated.
3.  **Cross-Platform File Updates:** Numerous occurrences of `github_viewer_v2` were replaced with `github_native` in files like `windows/CMakeLists.txt`, `windows/runner/Runner.rc`, `windows/runner/main.cpp`, `web/manifest.json`, `web/index.html`, `README.md`, `linux/CMakeLists.txt`, `linux/runner/my_application.cc`, `macos/Runner.xcodeproj/project.pbxproj`, `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`, and `macos/Runner/Configs/AppInfo.xcconfig`.
4.  **Aggressive Cache Clearing & `flutter create --org`:** Due to persistent issues with the old app name launching, a thorough cleanup (manual deletion of `build`, `android/build`, `android/.gradle`, `.dart_tool` folders) was combined with `flutter create --org com.example.github_native .` to force Flutter to reconfigure the project with the new package identifier.
5.  **Result:** The `github_native` application now successfully launches with the correct package name `com.example.github_native`.

### Native Flip Card Implementation (`NativeFlipCardScreen`) (COMPLETE)
A new screen `NativeFlipCardScreen` (`lib/screens/native_flip_card_screen.dart`) was created to replace the WebView-based card for `PresentationView.html`.

**Completed Tasks:**
1.  **Resolved `RenderFlex overflow` errors:** Implemented responsive sizing for elements within `_buildFrontContent` and `_buildBackContent` using `cardWidth` and `cardHeight` proportions. This includes dynamic font sizes, image sizes, padding, and spacing.
2.  **Improved Hologram Animation Fidelity:** Tuned parallax values (`holoShiftX`, `holoShiftY` multipliers), increased opacities of `ColorFiltered` layers, and refined gradient colors/stops within `_buildHologramEffect` to achieve a more visually impactful effect closer to the original HTML.
3.  **Content Styling:** Fine-tuned font sizes, letter spacing, and shadows to match the original HTML/CSS more precisely where possible.
4.  **Gyroscope Integration:** `sensors_plus` is integrated to provide motion data (`_currentDx`, `_currentDy`) for the hologram effect.
5.  **Basic Structure & Flip Animation:** The screen implements a basic card structure with 3D flip animation using `AnimationController` and `Transform`.

### Static Analysis and Deprecation Cleanup (COMPLETE)
All warnings and deprecations reported by `flutter analyze` have been addressed across the project.

**Specific Changes Include:**
1.  **`lib/screens/file_browser_screen.dart`**:
    *   Replaced deprecated `WillPopScope` with `PopScope`, using `canPop` and `onPopInvokedWithResult` for navigation control.
    *   Declared `_pathHistory` field as `final`.
2.  **`lib/screens/login_screen.dart`**:
    *   Added `if (!mounted) return;` checks before using `BuildContext` (e.g., `Navigator.of(context)`, `ScaffoldMessenger.of(context)`) after `await` calls to resolve `use_build_context_synchronously` warnings.
3.  **`lib/screens/repo_list_screen.dart`**:
    *   Added an `if (!mounted) return;` check before using `BuildContext` in the `_signOut` method after an `await` call.
4.  **`lib/screens/native_flip_card_screen.dart`**:
    *   Updated deprecated `gyroscopeEvents.listen` to `gyroscopeEventStream().listen`.
    *   Replaced all instances of `Color.withOpacity(value)` with `Color.withAlpha((255 * value).round())` to address deprecation warnings and avoid precision loss.
5.  **`lib/screens/webview_screen.dart`**:
    *   Removed unused `import 'dart:convert';`.
    *   Removed unnecessary `import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';`.
    *   Removed unused local variable `originalLinkTag`.

## Important Environment Notes

- The Flutter SDK is not in the system's `PATH`.
- To run the application, the full path to the executable must be used: `C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run`.