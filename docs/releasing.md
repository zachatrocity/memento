# Releasing

## PR dev builds (label-driven)

To generate a dev APK for a pull request (useful for Obtanium / quick device testing):

1. Add the **`dev-build`** label to the PR.
2. GitHub Actions will build a **debug APK** and upload it to the workflow **Artifacts**.
3. The workflow will comment on the PR with a link to the run + artifact name.

Notes:
- This build does **not** use signing secrets.
- Artifacts expire (currently **7 days**).


This repo uses **pure GitHub Actions** for releases.

## Workflows

### 1) Dev (rolling) release: `dev-latest`

Workflow: `.github/workflows/dev-release.yaml`

Triggers:

- **Manual**: run the workflow via GitHub UI (`workflow_dispatch`)
- **Push to `main`**: only publishes if the commit message contains **`[dev-release]`**
  - This avoids publishing on every push.

What it does:

- Builds an Android **release APK**
- Creates/updates a rolling GitHub Release with tag/name: **`dev-latest`**
- Uploads a stable-named asset: **`swell-dev-latest.apk`** (replaced on every update)

Android signing:

- If Android signing secrets are present, the APK is signed with your **upload keystore**.
- If not, the build falls back to the default debug signing config (useful for templates, not for real distribution).

### 2) Store release (Play Console Internal)

Workflow: `.github/workflows/store-release.yaml`

Trigger:

- Push a tag matching **`v*`** (example: `v1.2.3`)

What it does:

- Validates `pubspec.yaml` version matches the tag (X.Y.Z)
- Builds a **release AAB** (and also an APK for convenience)
- Uploads to **Google Play → Internal track**
- Sets build number deterministically from `github.run_number`

## Versioning rules

- Tags must be `vX.Y.Z` (example: `v1.2.3`).
- `pubspec.yaml` must contain `version: X.Y.Z+<anything>`.
  - The workflow checks the **build name** (`X.Y.Z`) matches the tag.
- The CI build number is set to `github.run_number` during builds.

## Required secrets

Add these in **GitHub → Settings → Secrets and variables → Actions → Secrets**.

### Android signing (used by both workflows)

- `ANDROID_KEYSTORE_BASE64` — base64 of your JKS file (upload keystore)
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

The workflow decodes these into:

- `android/app/upload-keystore.jks`
- `android/key.properties`

See: `scripts/ci/android_setup_signing.sh`.

### Google Play upload (store release only)

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — service account JSON with Play publishing access

Notes:

- The workflow currently uploads to package name: `com.splashpad.swell`
- Ensure the app exists in Play Console and the service account has access.

## iOS (optional / TODO)

The store workflow includes a guarded iOS job placeholder.

To enable it:

- Set secret `IOS_RELEASE_ENABLED` to `true`
- Implement the lane and add the required iOS secrets (not yet wired)

Suggested secrets (TODO):

- `IOS_DISTRIBUTION_CERT_P12_BASE64`
- `IOS_DISTRIBUTION_CERT_PASSWORD`
- `IOS_PROVISION_PROFILE_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`

When iOS is not configured, the workflow **does not fail**.

## Local tagging example

```bash
# Ensure pubspec.yaml has version: 1.2.3+...

git tag v1.2.3
git push origin v1.2.3
```
