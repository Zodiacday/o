# TestFlight Deployment Guide (From Windows via GitHub Actions)

Since you are developing on Windows, you don't need a physical Mac to build and ship PreviewPort to TestFlight. We have configured a GitHub Actions workflow (`.github/workflows/deploy_testflight.yml`) that runs on Apple Silicon macOS runners to compile the `.ipa` and upload it directly to Apple TestFlight.

---

## 1. Required GitHub Repository Secrets

Go to your GitHub repository:
👉 **[https://github.com/Zodiacday/Previewport/settings/secrets/actions](https://github.com/Zodiacday/Previewport/settings/secrets/actions)**

Click **"New repository secret"** and add these 5 secrets:

| Secret Name | Description | How to Obtain |
| :--- | :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution Certificate (`.p12`) encoded in base64 | Export certificate from Apple Developer portal or Keychain as `.p12` |
| `P12_PASSWORD` | The password you entered when exporting the `.p12` certificate | Your chosen export password |
| `BUILD_PROVISION_PROFILE_BASE64` | App Store Provisioning Profile (`.mobileprovision`) in base64 | Download profile for `com.previewport.app` from Apple Developer portal |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API Key ID (e.g., `2X9R427NDK`) | App Store Connect ➔ Users and Access ➔ Integrations ➔ Keys |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID (UUID format) | Found at the top of the Keys tab in App Store Connect |
| `APP_STORE_CONNECT_PRIVATE_KEY`| Entire contents of your `AuthKey_XXXXX.p8` file | Downloaded once when creating the API Key in App Store Connect |

---

## 2. How to Base64 Encode Your Files (On Windows PowerShell)

You can easily encode your certificate and provisioning profile in PowerShell:

```powershell
# 1. Encode .p12 certificate to base64 string
[Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\distribution.p12")) | Set-Clipboard

# (The base64 string is now in your clipboard! Paste it into BUILD_CERTIFICATE_BASE64)

# 2. Encode .mobileprovision profile to base64 string
[Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\previewport.mobileprovision")) | Set-Clipboard

# (The base64 string is now in your clipboard! Paste it into BUILD_PROVISION_PROFILE_BASE64)
```

---

## 3. One-time TestFlight setup

The first build for each Flutter app still needs one App Store Connect setup:

1. Create an internal TestFlight group. The default group name used by CI is
   `Internal`.
2. Add your App Store Connect Apple Account to that group once.
3. Add the repository variables `APP_STORE_CONNECT_APP_ID` and
   `TESTFLIGHT_GROUP` if this repository does not use the defaults in the
   workflow.

After that, CI handles build distribution. It waits for Apple processing and
adds the new build to the internal group through the App Store Connect API.
You do not need to click **Add Builds** for every commit.

## 4. How to Deploy to TestFlight

Once you have added the secrets to GitHub:

1. Open your repository's Actions tab:
   👉 **[https://github.com/Zodiacday/Previewport/actions](https://github.com/Zodiacday/Previewport/actions)**
2. Click **"Deploy to TestFlight"** in the left sidebar.
3. Click the **"Run workflow"** button on the right.
4. GitHub Actions will:
   - Spin up an Apple Silicon macOS environment.
   - Install Flutter & project dependencies.
   - Code-sign your app with your distribution certificate.
   - Build the release `.ipa` package.
   - Upload it directly to **App Store Connect**.
   - Wait until Apple marks this exact build as processed.
   - Add it to the configured internal TestFlight group automatically.
5. The build will then be available in TestFlight for the Apple Account already
   in that group. Apple processing time varies; the workflow waits up to 30
   minutes and fails with the actual processing state if Apple rejects the build.

## 5. Reuse this flow for another Flutter project

Copy these two files into the other project:

```text
tool/attach_testflight_build.py
.github/workflows/deploy_testflight.yml
```

Then set that project's App Store Connect app ID and internal group through
repository variables. The signing and App Store Connect API secrets can be
shared at the organization level when the projects use the same Apple team.
