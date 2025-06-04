# GitHub Repository Setup Guide

This guide explains how to set up your GitHub repository for automated builds and releases of Mac Snap.

## 🔐 Required GitHub Secrets

To enable automated builds and releases, add these secrets to your GitHub repository:

### Repository Settings → Secrets and Variables → Actions

#### For General Releases (Required)
These secrets enable basic building and DMG creation:

- **No secrets required** for basic unsigned builds
- The workflow will create unsigned builds automatically

#### For Code-Signed Releases (Recommended)
For signed releases that users can install without security warnings:

```
CERTIFICATES_P12
```
- **Description:** Base64-encoded .p12 certificate file
- **How to get:** Export your Developer ID certificate from Keychain Access
- **Command:** `base64 -i YourCertificate.p12 | pbcopy`

```
CERTIFICATES_PASSWORD
```
- **Description:** Password for the .p12 certificate file
- **Value:** The password you set when exporting the certificate

#### For App Store Releases (Optional)
If you want to automatically upload to App Store Connect:

```
APPSTORE_ISSUER_ID
```
- **Description:** App Store Connect API issuer ID
- **Found in:** App Store Connect → Users and Access → Integrations → App Store Connect API

```
APPSTORE_KEY_ID
```
- **Description:** App Store Connect API key ID
- **Found in:** Same location as issuer ID

```
APPSTORE_PRIVATE_KEY
```
- **Description:** App Store Connect API private key (base64 encoded)
- **How to get:** Download .p8 file, then `base64 -i AuthKey_XXXXXX.p8 | pbcopy`

```
APP_STORE_CERTIFICATES_P12
```
- **Description:** Base64-encoded Mac App Store certificate
- **How to get:** Export Mac App Store certificate from Keychain Access

```
APP_STORE_CERTIFICATES_PASSWORD
```
- **Description:** Password for the App Store certificate

## 🚀 How to Create Releases

### Automatic Releases

1. **Create a Git tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build the app
   - Run tests
   - Create DMG installer
   - Generate release notes
   - Upload to GitHub Releases

### Manual Builds

For development/testing builds:

1. **Push to any branch** - Creates unsigned build artifacts
2. **Push to main** - Creates App Store build (if configured)
3. **Push tags** - Creates full release with DMG

## 📋 Workflow Overview

The GitHub Actions workflow includes three jobs:

### 1. Build and Test Job
- **Triggers:** All pushes and pull requests
- **Actions:**
  - Builds debug version
  - Runs unit tests
  - Creates unsigned release build
  - Uploads artifacts for download

### 2. Release Job
- **Triggers:** Git tags (v*.*.*)
- **Actions:**
  - Builds signed release
  - Creates professional DMG installer
  - Generates release notes
  - Creates GitHub release
  - Uploads DMG for distribution

### 3. App Store Job
- **Triggers:** Main branch and tags
- **Actions:**
  - Builds App Store version
  - Uploads to App Store Connect (if configured)

## 🛠️ Local Development Builds

To create a DMG locally:

```bash
# Build and create DMG
./scripts/create_dmg.sh

# The DMG will be created in dist/ folder
open dist/
```

## 📦 Release Strategy

### Version Numbering
- Use semantic versioning: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Pre-releases: `v1.0.0-beta.1`, `v1.0.0-alpha.1`

### Release Frequency
- **Major releases** (v2.0.0): New features, breaking changes
- **Minor releases** (v1.1.0): New features, no breaking changes
- **Patch releases** (v1.0.1): Bug fixes only

### Release Process
1. Update CHANGELOG.md with new version
2. Commit changes to main branch
3. Create and push git tag
4. GitHub Actions handles the rest!

## 🔍 Monitoring Builds

### Check Build Status
- Visit your repository's "Actions" tab
- Monitor build progress and logs
- Download artifacts for testing

### Build Artifacts
- **Unsigned builds:** Available for 7 days
- **Release DMGs:** Available for 90 days
- **GitHub Releases:** Permanent until deleted

## 🐛 Troubleshooting

### Common Issues

**Build fails with signing errors:**
- Check that certificate secrets are properly base64 encoded
- Verify certificate password is correct
- Ensure certificate hasn't expired

**DMG creation fails:**
- Check that `scripts/create_dmg.sh` is executable
- Verify all required files exist (README.md, LICENSE)
- Check disk space on GitHub runner

**App Store upload fails:**
- Verify App Store Connect API credentials
- Check bundle ID matches App Store Connect
- Ensure app version is incremented

### Getting Help

1. **Check build logs** in GitHub Actions
2. **Review secrets** are properly configured
3. **Test locally** using the build scripts
4. **Open an issue** if problems persist

---

**Ready to automate your Mac Snap releases! 🚀**