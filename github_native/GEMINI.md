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

### Native Flip Card Implementation (`NativeFlipCardScreen`) (IN PROGRESS)
A new screen `NativeFlipCardScreen` (`lib/screens/native_flip_card_screen.dart`) was created to replace the WebView-based card for `PresentationView.html`.

**Current Status:**
1.  **Basic Structure & Flip Animation:** The screen implements a basic card structure with 3D flip animation using `AnimationController` and `Transform`.
2.  **Gyroscope Integration:** `sensors_plus` is integrated to provide motion data (`_currentDx`, `_currentDy`) for the hologram effect.
3.  **Initial Hologram Effect:** A multi-layered hologram effect with blend modes (`BlendMode.screen`, `BlendMode.overlay`) and parallax is implemented, scaled to simulate `background-size: 200%`.
4.  **Content Integration:** Text content (company name, agent name, data grid, disclaimer) and asset paths (profile photo, QR code, chip SVG) have been extracted from the original HTML/CSS and integrated into the native Flutter widgets, respecting original styling (colors, font weights, letter spacing, shadows).
5.  **Layout Responsiveness:** Initial attempts to make layout more responsive (e.g., card dimensions, photo size, reduced `SizedBox` heights, `Flexible` widgets for content) have been made to address `RenderFlex overflow` errors.

**Feedback Received:**
-   The native card is "more fluid".
-   The hologram animation in the original is "much more beautiful".
-   Layout `RenderFlex overflow` errors persist, indicating content is still too large for the allocated space in some configurations.

**Remaining Tasks:**
1.  **Resolve `RenderFlex overflow` errors:** Further refine the layout in `_buildFrontContent` and `_buildBackContent`, potentially by:
    *   Making font sizes truly responsive (calculating based on available width/height, possibly using `FittedBox`).
    *   Adjusting `SizedBox` heights/widths to be proportional or dynamic.
    *   Ensuring fixed-size elements (like the photo and QR code) scale appropriately without causing overflow.
    *   Revisiting `mainAxisAlignment` and `crossAxisAlignment` for better distribution.
2.  **Improve Hologram Animation Fidelity:**
    *   Investigate if `BlendMode.screen` and `BlendMode.overlay` can be tuned further or if alternative Flutter rendering techniques are needed to precisely match the CSS `mix-blend-mode`.
    *   Fine-tune parallax scaling (`holoShiftX`, `holoShiftY`) for each layer to achieve the "beautiful" effect of the original.
    *   Explore ways to simulate `background-attachment: fixed` more accurately, possibly using a `CustomPainter` that can position elements relative to the global viewport despite the card's rotation.
3.  **Load Actual Images:** Ensure the user has replaced placeholder images with real ones (which they have confirmed).
4.  **Refine Content Styling:** Fine-tune font sizes, letter spacing, shadows to perfectly match the original HTML/CSS.

## Important Environment Notes

- The Flutter SDK is not in the system's `PATH`.
- To run the application, the full path to the executable must be used: `C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run`.