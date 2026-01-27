# Logo Setup Instructions

## Steps to Add Your Custom Logo

1. **Save your logo image** as `logo_gears.png` in the following location:
   ```
   c:\Users\ferna\fixit\fixit\assets\images\logo_gears.png
   ```

2. **Image Requirements:**
   - Format: PNG (transparent background recommended)
   - Recommended size: 128x128 pixels or larger
   - The image will be automatically scaled to fit

3. **Verify the setup:**
   - Run `flutter pub get` (already done)
   - Hot reload or restart your app
   - The logo should appear in all screens replacing the settings icon

## What Was Changed

✅ Updated `pubspec.yaml` to include assets folder
✅ Created `lib/core/widgets/app_logo.dart` - reusable logo widget
✅ Updated 7 screens to use the new logo:
   - Home Screen
   - Bookings Screen
   - Support/Chat Screen
   - Admin Home Screen
   - Admin Appointments Screen
   - Admin Technicians Screen
   - Admin Reports Screen

## Fallback

If the image file is not found, the app will automatically fall back to the settings icon, so the app won't crash.

## Your Logo Image

Make sure to save the gears logo image you provided to:
```
assets/images/logo_gears.png
```
