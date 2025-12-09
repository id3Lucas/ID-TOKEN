# GitHub HTML Viewer (v2 - PAT Edition)

This is a Flutter application for Android that allows you to browse your GitHub repositories and view HTML files using a **Personal Access Token (PAT)**.

This version is simpler and more reliable than the previous OAuth2-based version.

## Setup Instructions

### Step 1: Generate a GitHub Personal Access Token

1.  Go to your GitHub account settings: [https://github.com/settings/tokens](https://github.com/settings/tokens)
2.  Click on **"Generate new token"**. You might be prompted for your password.
3.  Give your token a descriptive **Note**, for example, `android-html-viewer`.
4.  Set the **Expiration** for the token. For testing, you can choose 30 days.
5.  Under **"Select scopes"**, check the box next to **`repo`**. This will grant the token permission to access your public and private repositories.
6.  Scroll down and click **"Generate token"**.
7.  **Immediately copy your new token.** This is the only time you will see it. Store it somewhere safe temporarily.

### Step 2: Run the Application

1.  Ensure you have an Android device connected or an emulator running.
2.  Open your terminal and navigate to the project directory:
    ```bash
    cd C:\Users\llhuillier\Desktop\Github\ID-TOKEN\github_viewer_v2
    ```
3.  Run the application:
    ```bash
    C:\Users\llhuillier\Desktop\flutter\bin\flutter.bat run
    ```

### Step 3: Log In with Your Token

1.  Once the app launches, you will see a login screen with a text box.
2.  **Paste your GitHub Personal Access Token** into the text box.
3.  Tap the **"Login"** button.
4.  If the token is valid, you will be taken to a list of your repositories.

You can now browse your files and view your HTML pages.