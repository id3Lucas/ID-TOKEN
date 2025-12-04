// TODO: Replace with your actual GitHub OAuth Client ID
const String githubClientId = 'Ov23liFDMPNu223N42MW';

// TODO: Replace with your actual GitHub OAuth Client Secret
const String githubClientSecret = '60cb95f50239dddf86d9f8b60d228feffda0760e';

// This must match the redirect URI configured in your GitHub OAuth App settings
const String githubRedirectUri = 'http://localhost:8080/';

const String githubAuthUrl =
    'https://github.com/login/oauth/authorize?client_id=$githubClientId&scope=repo,user&redirect_uri=$githubRedirectUri';

const String githubTokenUrl = 'https://github.com/login/oauth/access_token';
