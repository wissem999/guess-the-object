# In-App Update System — Complete Guide

## How It Works

The update system checks `update.json` on GitHub every time the app starts. If a newer version is found, it downloads the APK and opens Android's package installer.

## Architecture

```
update.json (GitHub) → UpdateService.checkForUpdate() → UpdateDialog → downloadApk() → installApk() → MethodChannel → Kotlin → Android Installer
```

## Key Files

| File | Purpose |
|---|---|
| `lib/services/_update_service_native.dart` | Core update logic: check, download, install |
| `lib/widgets/update_dialog.dart` | UI dialog with progress bar |
| `lib/app.dart` | Triggers update check on startup |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Native APK installer via MethodChannel |
| `android/app/src/main/res/xml/file_paths.xml` | FileProvider paths for APK sharing |
| `android/app/src/main/AndroidManifest.xml` | `REQUEST_INSTALL_PACKAGES` permission |
| `.github/workflows/build.yml` | CI auto-updates `update.json` on build |
| `update.json` (repo root) | Version manifest served via raw.githubusercontent.com |

## How to Release a New Version

1. Edit `version:` in `pubspec.yaml` (e.g., `1.2.0+20`)
2. `git add -A && git commit -m "feat: description" && git push origin main`
3. CI automatically:
   - Builds APK
   - Creates GitHub Release with APK
   - Updates `update.json` with new version + download URL
4. That's it. Users get the update next time they open the app.

## update.json Format

```json
{
  "version": "1.2.0",
  "apk_url": "https://github.com/user/repo/releases/download/v1.2.0/app-release.apk",
  "update_message": "Bug fixes and improvements"
}
```

## Critical Implementation Details

### 1. Streaming Download (NOT `http.get()`)
The APK is ~50MB. Loading it into memory with `http.get()` causes OOM on phones.
Use streaming instead:

```dart
final client = http.Client();
final request = http.Request('GET', Uri.parse(apkUrl));
final response = await client.send(request);

final sink = file.openWrite();
await for (final chunk in response.stream) {
  sink.add(chunk);
}
await sink.flush();
await sink.close();
client.close();
```

### 2. FileProvider Must Cover Both Cache Paths
`getTemporaryDirectory()` can return either `getCacheDir()` or `getExternalCacheDir()` depending on device. `file_paths.xml` must have both:

```xml
<paths>
    <cache-path name="apk" path="." />
    <external-cache-path name="external-apk" path="." />
</paths>
```

### 3. MethodChannel Name
Must match between Dart and Kotlin exactly:
- Dart: `static const _channel = MethodChannel('your.package.name/apk_installer');`
- Kotlin: `private val CHANNEL = "your.package.name/apk_installer"`

### 4. FileProvider Authority
Uses `${applicationId}.fileProvider` in AndroidManifest.xml.
In Kotlin, use `"${packageName}.fileProvider"` (packageName = applicationId at runtime).

### 5. Android Installer Intent
```kotlin
Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
    data = uri
    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
    putExtra(Intent.EXTRA_RETURN_RESULT, true)
}
```

### 6. Auth Router Persistence
The GoRouter redirect must check if auth state is still loading before redirecting to login:
```dart
final authAsync = ref.read(authStateProvider);
if (authAsync is AsyncLoading) return null; // Don't redirect while loading
final user = authAsync.valueOrNull;
```
Without this, the app flashes the login screen on restart because Firebase hasn't restored the session yet.

### 7. Package Name Consistency
The `applicationId` in `build.gradle.kts` MUST match what's registered in Firebase Console.
Changing the package name means the in-app update can't overwrite the old app (Android sees them as different apps). If you must change it, the user needs one uninstall.

### 8. CI Workflow
- Push to `main` → GitHub Actions builds APK
- Caches the release keystore so signing is consistent across builds
- Auto-creates GitHub Release with the APK
- Auto-updates `update.json` with `[skip ci]` to prevent loops
- APK artifact is also uploaded for download from Actions tab

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Update dialog shows but download fails | OOM from loading entire APK into memory | Use streaming download (`client.send()` + `response.stream`) |
| "Could not open installer" | FileProvider can't find APK file | Add `<external-cache-path>` to `file_paths.xml` |
| Login flash on restart | Router redirects before auth state resolves | Check `is AsyncLoading` before redirecting |
| Update can't overwrite old app | Package name changed | Must uninstall old app once |
| Google Sign-In fails | Package name + SHA-1 not in Firebase Console | Register the app in Firebase Console |
