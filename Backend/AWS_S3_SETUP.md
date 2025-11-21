# AWS S3 Setup Instructions for AgriCartApp

Follow these steps to enable image uploads to AWS S3 and store public URLs in MongoDB Atlas.

---

## 1. Create an S3 Bucket

1. Log in to your AWS Console.
2. Go to **S3** service.
3. Click **Create bucket**.
4. Enter a unique bucket name (e.g., `agricart-images`).
5. Select a region (e.g., `us-east-1`).
6. Leave other settings as default and click **Create bucket**.

## 2. Set Bucket Policy for Public Read

1. Go to your bucket > **Permissions** > **Bucket Policy**.
2. Add this policy (replace `YOUR_BUCKET_NAME`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    }
  ]
}
```

3. Save the policy.

## 3. Create IAM User for S3 Access

1. Go to **IAM** > **Users** > **Add user**.
2. Set username (e.g., `agricart-s3-uploader`).
3. Select **Programmatic access**.
4. Click **Next: Permissions**.
5. Attach policy: `AmazonS3FullAccess` (or create a custom policy for your bucket).
6. Complete user creation and download credentials (Access Key ID & Secret Access Key).

## 4. Add Credentials to Environment

Add these to your `.env` file or Render environment variables:

```
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_S3_BUCKET_NAME=your-bucket-name
AWS_S3_REGION=your-region
```

## 5. Deploy and Test

- Restart your backend service.
- Test product image upload and verify images appear in S3 and URLs are public.

---

## Troubleshooting

- Ensure IAM user has correct permissions.
- Ensure bucket policy allows public read.
- Check environment variables are set correctly.
- Images should be accessible via URLs like:
  `https://your-bucket-name.s3.your-region.amazonaws.com/products/your-image.jpg`

---

For questions, see AWS S3 documentation or ask your backend developer.

---

## Mobile App Camera & Gallery Permissions (Flutter)

To support capturing images from the camera and selecting from the gallery in the Flutter app (chat image upload & product images), add the following platform-specific permissions.

### Android

Add these lines near the top of `AgriCart/android/app/src/main/AndroidManifest.xml` (already added if you see them):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<!-- Android 13+ (API 33) for reading images from gallery -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

Notes:
- If your compile/target SDK < 33 you may still need `READ_EXTERNAL_STORAGE` for older devices; current implementation relies on scoped storage so it's not required for most cases.
- The `image_picker` plugin will handle runtime permission prompts automatically. If you implement custom camera flows, use `permission_handler` or `ActivityCompat.requestPermissions`.
- Keep `android.permission.POST_NOTIFICATIONS` if you want Firebase messaging notifications on Android 13+.

### iOS

Add usage description keys to `AgriCart/ios/Runner/Info.plist` (already inserted if present):

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture product and chat images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images for chat and products.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone may be needed for future video capture features.</string>
```

### Testing Permissions

1. Run on a physical device or emulator.
2. Tap the attachment icon in the chat screen.
3. Choose Camera or Gallery.
4. On first use, OS should prompt for permission. Grant it and verify upload succeeds.

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Camera returns black image | Emulator lacks camera | Test on physical device or configure emulator camera input |
| Permission denied error | User rejected prompt | In app, show retry UI or direct to Settings |
| iOS build fails after adding keys | Plist syntax error | Ensure keys are inside `<dict>` and XML is well-formed |
| Android gallery empty | Missing READ_MEDIA_IMAGES (API 33+) | Confirm permission in manifest & rebuild |

### Rebuilding After Changes

After altering manifest or Info.plist:

```bash
flutter clean
flutter pub get
flutter run
```

---
