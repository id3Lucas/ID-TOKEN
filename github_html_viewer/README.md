# GitHub HTML Viewer (Android)

This is a Flutter application for Android that allows you to log into your GitHub account, browse your repositories, and view HTML files directly within a WebView.

## Setup Instructions

To get this application running, you need to configure a GitHub OAuth App and update the application's constants.

### Step 1: Create a GitHub OAuth App

1.  Go to your GitHub account settings: [https://github.com/settings/developers](https://github.com/settings/developers)
2.  Click on **"OAuth Apps"** in the left sidebar.
3.  Click the **"New OAuth App"** button.
4.  Fill in the details:
    *   **Application name:** `GitHub HTML Viewer` (or any name you prefer)
    *   **Homepage URL:** `https://github.com/` (or your personal GitHub profile URL)
    *   **Application description:** `View HTML files from GitHub repositories on Android.`
    *   **Authorization callback URL:** `github_html_viewer://callback`
        *   **Important:** This URL must exactly match the `githubRedirectUri` in `lib/constants.dart` and the `data android:scheme` and `android:host` in `android/app/src/main/AndroidManifest.xml`.
5.  Click **"Register application"**.
6.  Once created, you will see a **"Client ID"** and **"Client Secret"**. Copy these values.

### Step 2: Update `lib/constants.dart`

Open the file `github_html_viewer/lib/constants.dart` and replace the placeholder values with your GitHub OAuth App's **Client ID** and **Client Secret**:

```dart
// TODO: Replace with your actual GitHub OAuth Client ID
const String githubClientId = 'YOUR_GITHUB_CLIENT_ID'; // <--- PASTE YOUR CLIENT ID HERE

// TODO: Replace with your actual GitHub OAuth Client Secret
const String githubClientSecret = 'YOUR_GITHUB_CLIENT_SECRET'; // <--- PASTE YOUR CLIENT SECRET HERE

// This must match the redirect URI configured in your GitHub OAuth App settings
const String githubRedirectUri = 'github_html_viewer://callback';

const String githubAuthUrl =
    'https://github.com/login/oauth/authorize?client_id=$githubClientId&scope=repo,user&redirect_uri=$githubRedirectUri';

const String githubTokenUrl = 'https://github.com/login/oauth/access_token';
```

### Step 3: Run the Application

1.  Make sure you have the Flutter SDK installed and configured correctly (run `flutter doctor` to verify).
2.  Navigate to the project directory in your terminal:
    ```bash
    cd C:\Users\llhuillier\Desktop\Github\ID-TOKEN\github_html_viewer
    ```
3.  Run `flutter pub get` to ensure all dependencies are fetched:
    ```bash
    C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat pub get
    ```
4.  Connect an Android device or start an Android emulator.
5.  Run the application:
    ```bash
    C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run
    ```

The app should now launch on your Android device/emulator. You will see a "Login with GitHub" button. Tap it to start the OAuth flow.

## Project Structure

*   `lib/main.dart`: Main application entry point, routing, and initial authentication check.
*   `lib/constants.dart`: Stores GitHub OAuth credentials and URLs.
*   `lib/models/repository.dart`: Data models for GitHub repositories and their contents.
*   `lib/services/auth_service.dart`: Handles GitHub OAuth login, token storage, and logout.
*   `lib/services/github_service.dart`: Interacts with the GitHub API to fetch repositories and file contents.
*   `lib/screens/login_screen.dart`: UI for initiating GitHub login.
*   `lib/screens/repo_list_screen.dart`: Displays the list of user's GitHub repositories.
*   `lib/screens/file_browser_screen.dart`: Allows browsing files within a selected repository.
*   `lib/screens/webview_screen.dart`: Displays the content of an HTML file in a WebView.