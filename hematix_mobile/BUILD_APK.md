# Getting an APK without installing Flutter

You don't need Flutter, Android Studio, or a JDK on your machine. GitHub builds
the APK for you and you download the finished file.

---

## ⚠️ Do this FIRST — set your backend address

An APK on a real phone **cannot reach `localhost`** — that means the phone
itself. If you skip this step the app installs and opens, but every screen
fails with "Could not reach the server."

1. Find your computer's local IP address:
   - **Windows:** open Command Prompt → `ipconfig` → look for **IPv4 Address**
     (something like `192.168.1.14`)
   - **macOS/Linux:** `ifconfig | grep inet`

2. Open `lib/core/config.dart` and set it:

   ```dart
   static const String? manualHost = '192.168.1.14'; // ← your IPv4 here
   ```

3. Open `tool/patch_android.sh` and add the same IP to the domain list
   (uncomment the example line and replace the IP).

Your phone must be on the **same Wi-Fi** as the computer running the backend,
and the backend must listen on `0.0.0.0` rather than only `127.0.0.1`. In Spring
Boot, add this to `application.properties`:

```properties
server.address=0.0.0.0
```

Also allow port 8080 through your computer's firewall.

---

## Build the APK (about 5 minutes)

### 1. Create a GitHub account and repository
Go to [github.com](https://github.com) → sign up (free) → **New repository** →
name it `hematix-donor` → keep it **Private** if you prefer → **Create**.

### 2. Upload the project
On the new repo page click **uploading an existing file**, then drag in the
**contents** of the `hematix_mobile` folder — `lib`, `tool`, `.github`,
`pubspec.yaml`, `README.md`.

> Important: upload what's *inside* `hematix_mobile`, not the folder itself, so
> `pubspec.yaml` sits at the repository root.
>
> If the `.github` folder doesn't appear in the file picker, it's hidden:
> press `Ctrl+H` (Windows/Linux) or `Cmd+Shift+.` (macOS) in the dialog to show
> hidden files. Without it the build won't start.

Click **Commit changes**.

### 3. Let it build
Open the **Actions** tab. A run called *Build Android APK* starts on its own.
Wait for the green checkmark (roughly 4–6 minutes the first time).

If nothing starts, click **Build Android APK** in the left sidebar →
**Run workflow**.

### 4. Download
Click the finished run → scroll to **Artifacts** → download
**hematix-donor-apk**. It arrives as a `.zip`; unzip it to get
`app-release.apk`.

---

## Install on your phone

1. Copy the APK to the phone (USB cable, Google Drive, or email it to yourself).
2. Tap it. Android will warn about installing from an unknown source — allow it
   for your file manager or browser when prompted.
3. Open **Hematix** and log in with a donor account.

This is an unsigned debug-key release build: fine for testing and for showing
the project, but it can't go on the Play Store as-is.

---

## If the build fails

Open the failed run in the Actions tab and read the red step.

| Message | Fix |
|---|---|
| `No pubspec.yaml file found` | You uploaded the folder instead of its contents. `pubspec.yaml` must be at the repo root. |
| Workflow never starts | `.github/workflows/build-apk.yml` wasn't uploaded (hidden folder — see step 2). |
| Errors in `flutter analyze` | Analysis is set to `continue-on-error`, so it won't block the build. Genuine compile errors appear in the **Build release APK** step instead — send me that log and I'll fix the code. |
| `Gradle task assembleRelease failed` | Usually a transient network hiccup on the runner. Re-run the job first. |

---

## Alternative: build locally later

If you do install Flutter eventually:

```bash
flutter create --platforms=android .
bash tool/patch_android.sh
flutter pub get
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.
