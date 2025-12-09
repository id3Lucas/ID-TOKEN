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
