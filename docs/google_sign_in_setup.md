# Google Sign-In Setup Guide (BYOC)

Memento uses a **BYOC (Bring Your Own Credentials)** model. This means each user creates their own Google OAuth credentials rather than using shared app credentials. This approach:

- ✅ No app verification required from Google
- ✅ Works immediately after setup
- ✅ Your data stays in your control
- ✅ No reliance on a centralized service

## Quick Start (5 minutes)

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project selector (top left) → **New Project**
3. Name it "Memento" (or anything you like)
4. Click **Create**

### 2. Enable the Photos Library API

1. In your new project, go to **APIs & Services** > **Library**
2. Search for **"Photos Library API"**
3. Click **Enable**

### 3. Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** (for personal use)
3. Fill in required fields:
   - **App name**: "Memento"
   - **User support email**: Your email
   - **Developer contact info**: Your email
4. Click **Save and Continue** three times
5. Click **Back to Dashboard**

### 4. Create OAuth Credentials

#### For iOS:

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **iOS** as application type
4. Name: "Memento iOS"
5. Bundle ID: `com.zachatrocity.memento`
6. Click **Create**
7. Copy the **Client ID** (looks like: `1234567890-abc123.apps.googleusercontent.com`)

#### For Android:

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **Android** as application type
5. Name: "Memento Android"
6. Package name: `com.zachatrocity.memento`
7. SHA-1 certificate fingerprint:
   
   **For development (debug):**
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy the SHA-1 from the `AndroidDebugKey` entry
   
   **For release:** Use your release keystore's SHA-1
   
8. Click **Create**

### 5. Add Test User

1. Go to **APIs & Services** > **OAuth consent screen**
2. Scroll to **Test users**
3. Click **Add users**
4. Enter your Google account email
5. Click **Save**

### 6. Enter Client ID in Memento

1. Open the Memento app
2. Go to **Settings**
3. Tap **Configure Google Photos**
4. Paste your Client ID from Step 4
5. Tap **Save**

### 7. Sign In

1. Go to **Albums** tab
2. Tap **Sign in with Google**
3. Select your Google account
4. Accept the permissions
5. Your albums should appear!

## Troubleshooting

### "Error 10: Developer Error" (Android)

**Cause:** SHA-1 fingerprint doesn't match

**Fix:** 
1. Run `./gradlew signingReport` in the `android` directory
2. Copy the exact SHA-1 from `AndroidDebugKey`
3. In Google Cloud Console, edit your Android OAuth credential
4. Add the SHA-1 fingerprint

### "Error 401: invalid_client" (iOS)

**Cause:** Wrong Client ID format

**Fix:** Make sure you copied the iOS Client ID (not the Android one). It should look like:
```
1234567890-abc123def456ghi789jkl012mno345.apps.googleusercontent.com
```

### "App is not verified" warning

This is normal for BYOC apps in testing mode. Click **Advanced** > **Go to Memento (unsafe)**. Since you're using your own credentials for personal use, this warning is expected.

### Can't see albums after signing in

1. Make sure you added your email as a **test user** (Step 5)
2. Check that **Photos Library API** is enabled (Step 2)
3. Try signing out and back in

## Security Notes

- Your Client ID is stored securely in your device's encrypted storage
- The app never sends your credentials to any server
- All communication is directly between your device and Google's APIs
- You can revoke access anytime at [Google Account permissions](https://myaccount.google.com/permissions)

## Going Further

### Publishing to App Store/Play Store?

If you want to distribute the app publicly, you'll need to:

1. **Verify your OAuth consent screen** (takes several days)
2. Add app icons, screenshots, privacy policy
3. Submit for review

But for personal/family use, the BYOC testing mode works perfectly!

## Need Help?

- [Google Photos Library API Docs](https://developers.google.com/photos/library/guides/get-started)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- File an issue on GitHub
