class AuthConfig {
  // --- Google Sign-In Configuration ---
  // To get your Client ID, visit: https://console.cloud.google.com/
  static const String googleClientIdWeb = '946947936252-kfe7ro8l6lvuutp82hdtigevn6c329c9.apps.googleusercontent.com';
  
  // --- Facebook Configuration ---
  // To get your App ID, visit: https://developers.facebook.com/
  static const String facebookAppId = '123456789012345'; // REPLACE WITH REAL APP ID
  static const String facebookClientToken = 'YOUR_CLIENT_TOKEN'; // Optional but recommended
  
  // --- Apple Configuration ---
  // To get your Services ID, visit: https://developer.apple.com/
  static const String appleServiceId = 'com.plantora.auth';
  static const String appleRedirectUri = 'https://plantora-auth.firebaseapp.com/__/auth/handler';
}
