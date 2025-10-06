# Google Maps Setup Guide

This guide explains how to configure Google Maps API keys for the Arkad Flutter app.

## Getting Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/google/maps-apis)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API** (for Web)
4. Create an API key (or use an existing one)

## Using the Same Key for All Platforms

You can use the **same API key** for Android, iOS, and Web. For security, restrict your API key in the Google Cloud Console:

- **Android**: Add your app's SHA-1 fingerprint
- **iOS**: Add your bundle identifier (`se.arkadtlth.nexpo`)
- **Web**: Add your domain (e.g., `app.arkadtlth.se`)

## Configuration Steps

### Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

### iOS

Edit `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

### Web

Edit `web/index.html`:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

## Security Notes

⚠️ **Important**: The API key will be visible in your compiled app.

To protect your API key:

1. **Restrict by platform** in Google Cloud Console
2. **Set usage quotas** to prevent abuse
3. **Monitor usage** regularly in the Google Cloud Console

For production apps, consider:
- Using separate keys for development and production
- Implementing server-side key management for sensitive operations
- Setting up billing alerts

## Troubleshooting

### Map shows "For development purposes only" watermark
Your API key is not properly configured. Check that:
1. The API key is correctly placed in all platform files
2. The required APIs are enabled in Google Cloud Console
3. The API key restrictions allow your app to use it

### Map doesn't load on Android
- Verify the SHA-1 fingerprint is added to API key restrictions
- Check that "Maps SDK for Android" is enabled

### Map doesn't load on iOS
- Verify the bundle identifier is added to API key restrictions
- Check that "Maps SDK for iOS" is enabled

### Map doesn't load on Web
- Verify your domain is added to API key restrictions
- Check that "Maps JavaScript API" is enabled

## Reference

- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google Cloud Console](https://console.cloud.google.com/google/maps-apis)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
