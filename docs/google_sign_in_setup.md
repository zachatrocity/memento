# Google Sign-In Setup Guide

This guide walks you through configuring Google Sign-In for Memento to access Google Photos.

## Prerequisites

- A Google account
- Access to [Google Cloud Console](https://console.cloud.google.com/)

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Name it "Memento" or something memorable

## Step 2: Enable the Photos Library API

1. In the Google Cloud Console, go to **APIs & Services** > **Library**
2. Search for "Photos Library API"
3. Click **Enable**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** (unless you're a Google Workspace customer)
3. Fill in the required fields:
   - App name: "Memento"
   - User support email: Your email
   - Developer contact information: Your email
4. Click **Save and Continue**
5. On the **Scopes** screen, click **Add or Remove Scopes**
6. Add these scopes:
   - `.../auth/photoslibrary.readonly` (View your Google Photos library)
   - `.../auth/photoslibrary.sharing` (Access shared albums)
7. Click **Save and Continue**
8. On the **Test users** screen, add your email address as a test user
9. Click **Save and Continue** and then **Back to Dashboard**

## Step 4: Create OAuth 2.0 Credentials

### For Android:

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **Android** as the application type
4. Name: "Memento Android"
5. Package name: `com.zachatrocity.memento`
6. SHA-1 certificate fingerprint:
   - For debug: Run `cd android && ./gradlew signingReport` and copy the SHA-1 from the debug key
   - For release: Use your release keystore's SHA-1
7. Click **Create**
8. Copy the **Client ID** (you'll need it for iOS)

### For iOS:

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **iOS** as the application type
4. Name: "Memento iOS"
5. Bundle ID: `com.zachatrocity.memento`
6. Click **Create**
7. Copy the **Client ID** (looks like `1234567890-abc123def456.apps.googleusercontent.com`)

## Step 5: Configure the App

### iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Find the `CFBundleURLTypes` section
3. Replace `YOUR_CLIENT_ID` with your iOS Client ID from Step 4, but reversed:
   - If your Client ID is: `1234567890-abc123def456.apps.googleusercontent.com`
   - Use: `com.googleusercontent.apps.1234567890-abc123def456`

Example:
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.1234567890-abc123def456</string>
</array>
```

### Android Configuration

No additional configuration needed! The `google_sign_in` package handles Android automatically with the package name and SHA-1 fingerprint you configured in Step 4.

## Step 6: Test the Integration

1. Run the app: `flutter run`
2. Navigate to the Albums screen
3. Tap "Sign in with Google"
4. You should see a Google Sign-In popup
5. After signing in, your Google Photos albums should appear

## Troubleshooting

### "Error 10: Developer Error" (Android)
- Make sure the SHA-1 fingerprint in Google Cloud Console matches your debug keystore
- Run `cd android && ./gradlew signingReport` to get the correct fingerprint
- The package name must exactly match: `com.zachatrocity.memento`

### "Error 401: invalid_client" (iOS)
- Make sure you've reversed the Client ID correctly
- The format should be: `com.googleusercontent.apps.NUMBER-STRING`

### App not shown in Google account permissions
- Make sure you're added as a test user in the OAuth consent screen
- The app is in "Testing" mode, not "Production"

## Going to Production

Before releasing to the Play Store or App Store:

1. **Publish your OAuth consent screen**:
   - Go to **OAuth consent screen** in Google Cloud Console
   - Click **Publish App**
   - Complete the verification process (may take several days)

2. **Add release SHA-1** (Android):
   - Get your release keystore's SHA-1
   - Add it to the Android OAuth client ID in Google Cloud Console

3. **Configure App Store/Play Store links** in the OAuth consent screen

## References

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Photos Library API](https://developers.google.com/photos/library/guides/get-started)
- [OAuth 2.0 for Mobile & Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
