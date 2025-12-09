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

## Important Environment Notes

- The Flutter SDK is not in the system's `PATH`.
- To run the application, the full path to the executable must be used: `C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run`.