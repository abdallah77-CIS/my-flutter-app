# Hematix — Donor Mobile App (Flutter)

A Flutter client for the **donor** role of the Hematix Blood Donation Management
System. It talks to the **same Spring Boot backend** as the existing web
frontend — same endpoints, same JWT auth, same validation rules. No backend
changes, no mock data.

---

## 1. Setup

These files are the `lib/` source and `pubspec.yaml`. Generate the platform
folders once, then drop the source in:

```bash
# Create a fresh Flutter project shell
flutter create hematix_donor
cd hematix_donor

# Replace the generated lib/ and pubspec.yaml with the ones provided
rm -rf lib
cp -r /path/to/provided/lib .
cp /path/to/provided/pubspec.yaml .

flutter pub get
```

**Requires Flutter 3.27 or newer** (the theme uses `CardThemeData`,
`WidgetStateProperty` and `Color.withValues`). Check with `flutter --version`.

---

## 2. Point the app at your backend

Mobile can't use `localhost` the way the web app does — on a phone or emulator
that means the device itself, not your computer. `lib/core/config.dart` handles
this automatically:

| Where you run it | Host used | Action needed |
|---|---|---|
| Android emulator | `10.0.2.2` | none |
| iOS simulator | `localhost` | none |
| **Real phone** | — | set `manualHost` to your PC's LAN IP |

For a real device, edit `lib/core/config.dart`:

```dart
static const String? manualHost = '192.168.1.14'; // your PC's IPv4
```

Find your IP with `ipconfig` (Windows) / `ifconfig` (macOS/Linux), and make sure
the phone is on the same Wi-Fi network.

> Your Spring Boot backend must also accept requests from the device. If you hit
> CORS or connection-refused errors, confirm the server is bound to `0.0.0.0`
> (not only `127.0.0.1`) and that port 8080 isn't blocked by your firewall.

---

## 3. Android configuration (required)

Two edits, both explained in `android_config_snippets/`:

1. Copy `network_security_config.xml` to
   `android/app/src/main/res/xml/network_security_config.xml`
   (create the `xml` folder if it doesn't exist).
2. Apply the two edits shown in `AndroidManifest_snippet.xml` to
   `android/app/src/main/AndroidManifest.xml` — the `INTERNET` permission and
   the `android:networkSecurityConfig` attribute.

Without step 2 the app compiles fine but **every request fails silently**,
because Android 9+ blocks plaintext `http://` by default.

For iOS over plain HTTP, add `NSAppTransportSecurity` →
`NSAllowsArbitraryLoads` to `ios/Runner/Info.plist` (development only).

Then run:

```bash
flutter run
```

---

## 4. What's included

| Screen | Endpoints used |
|---|---|
| Login | `POST /auth/login` |
| Register | `POST /auth/register` |
| Dashboard | `GET /donors/profile`, `/donation-appointments/my`, `/notifications/unread` |
| Appointments | `GET /donation-appointments/my`, `POST /donation-appointments`, `PUT /donation-appointments/{id}/cancel` |
| Donations | `GET /donations/my` |
| Notifications | `GET /notifications`, `/notifications/unread`, `PUT /notifications/{id}/read` |
| Profile | `GET /donors/profile`, `PUT /donors/profile/update` |

**Carried over from the web app, not reinvented:**

- **Donation protocol** (`lib/core/eligibility.dart`) — minimum age 18, minimum
  weight 50 kg, the 56-day interval since the last donation, and the admin-set
  `NOT_ELIGIBLE` status. Enforced on the dashboard banner, the eligibility
  summary, and *before booking* an appointment.
- **Blood group mapping** — `A+` ⇄ `A_POSITIVE`, matching the backend enum.
- **Error handling** — `ApiError` mirrors the web client: 401 with a token means
  session expired (auto-logout), 401 without one means bad credentials, and
  field-level validation errors from the backend attach to the right inputs.
- **Empty states** — a brand-new donor with no history sees "No donations yet"
  and "Eligible now" instead of blank dashes.
- **Design system** — the same palette and radii as `css/style.css`.

Role guard: signing in with an admin or hospital account is rejected with a
clear message, since this app only has donor screens.

---

## 5. Notes / limits

- **Not implemented here:** admin and hospital areas, blood-request creation,
  and the AI endpoints. This app is donor-only, as requested.
- **Polling:** each tab refetches when you switch to it, and every list supports
  pull-to-refresh. The web app's 20-second background polling was left out
  deliberately — on mobile it drains battery, and pull-to-refresh is the
  expected pattern. Add a `Timer.periodic` in `DonorShell` if you want it.
- **Eligibility is client-side**, exactly as it is on the web. It's a UX guard,
  not a security control — the backend should enforce the same rules.
