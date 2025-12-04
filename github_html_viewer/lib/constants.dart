// TODO: Replace with your actual GitHub OAuth Client ID
const String githubClientId = 'YOUR_GITHUB_CLIENT_ID';

// TODO: Replace with your actual GitHub OAuth Client Secret
const String githubClientSecret = 'YOUR_GITHUB_CLIENT_SECRET';

// This must match the redirect URI configured in your GitHub OAuth App settings
const String githubRedirectUri = 'github_html_viewer://callback';

const String githubAuthUrl =
    'https://github.com/login/oauth/authorize?client_id=$githubClientId&scope=repo,user&redirect_uri=$githubRedirectUri';

const String githubTokenUrl = 'https://github.com/login/oauth/access_token';
