// TODO: Replace with your actual GitHub OAuth Client ID
const String githubClientId = 'Ov23liFDMPNu223N42MW';

// TODO: Replace with your actual GitHub OAuth Client Secret
const String githubClientSecret = 'b35fd10539a883288777df823b48cb6f27dd0780';

// This must match the redirect URI configured in your GitHub OAuth App settings
const String githubRedirectUri = 'https://github_html_viewer://callback';

const String githubAuthUrl =
    'https://github.com/login/oauth/authorize?client_id=$githubClientId&scope=repo,user&redirect_uri=$githubRedirectUri';

const String githubTokenUrl = 'https://github.com/login/oauth/access_token';
