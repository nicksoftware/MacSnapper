# Mac Snap Installation Guide

Welcome to Mac Snap! This guide will help you install and set up the ultimate window management tool for macOS.

## 📥 Installation Methods

### Method 1: DMG Installer (Recommended)

1. **Download the latest release:**
   - Visit the [Mac Snap Releases](https://github.com/nicolusmaluleke/MacSnapper/releases) page
   - Download the latest `MacSnap-Installer-X.X.X.dmg` file

2. **Install the app:**
   - Double-click the downloaded DMG file
   - Drag "Mac Snap.app" to the Applications folder
   - Eject the DMG when done

3. **Launch and setup:**
   - Open Mac Snap from Applications folder
   - Grant Accessibility permissions when prompted
   - Configure your preferred hotkeys

### Method 2: Build from Source

If you're a developer or want to build the latest version:

```bash
# Clone the repository
git clone https://github.com/nicolusmaluleke/MacSnapper.git
cd MacSnapper

# Build using Xcode
xcodebuild -project MacSnapper.xcodeproj \
  -scheme MacSnapper \
  -configuration Release \
  clean build

# Or create a DMG installer
chmod +x scripts/create_dmg.sh
./scripts/create_dmg.sh
```

### Method 3: Direct App Bundle

For quick testing (unsigned version):

1. Download the app bundle from GitHub Actions artifacts
2. Move to Applications folder
3. Right-click → Open (to bypass Gatekeeper)
4. Grant required permissions

## 🔐 Required Permissions

Mac Snap needs these permissions to function:

### Accessibility Permission (Required)
- **Purpose:** Control and resize windows
- **How to grant:**
  1. System Preferences → Security & Privacy → Privacy
  2. Select "Accessibility" from the left sidebar
  3. Click the lock icon and enter your password
  4. Check the box next to "Mac Snap"

### Screen Recording Permission (Optional)
- **Purpose:** Enhanced window detection on some systems
- **Note:** Only required on macOS 10.15+ with certain security settings

## ⚙️ Initial Setup

### 1. Configure Global Hotkeys

Default hotkeys:
- `⌥⌃ + ←` - Snap left half
- `⌥⌃ + →` - Snap right half
- `⌥⌃ + ↑` - Maximize window
- `⌥⌃ + ↓` - Center window

To customize:
1. Open Mac Snap preferences
2. Go to "Shortcuts" tab
3. Click on any hotkey to change it
4. Test your new hotkeys

### 2. Choose Your Operating Mode

**Menu Bar Mode (Recommended):**
- App runs in background
- Access via menu bar icon
- Minimal system impact

**Window Mode:**
- Traditional app window
- Full settings interface
- Easy access to all features

### 3. Premium Features (Optional)

Unlock advanced features:
- Advanced snapping patterns (thirds, custom zones)
- Custom keyboard shortcuts
- Multi-monitor window management
- Window presets and exclusions

**Free Trial:** 7 days of all premium features
**Subscription:** $4.99/month or $39.99/year

## 🔧 Troubleshooting

### Common Issues

**App won't launch:**
- Check that you've granted Accessibility permission
- Try right-clicking and selecting "Open" (for unsigned builds)
- Restart your Mac if permissions were just granted

**Hotkeys not working:**
- Verify Accessibility permission is granted
- Check for conflicting system shortcuts
- Try different key combinations

**Window snapping not precise:**
- Ensure you're using the latest version
- Check for conflicting window management apps
- Try toggling the Accessibility permission off and on

### Performance Tips

1. **Enable "Launch at Login"** for seamless experience
2. **Use Menu Bar mode** for better performance
3. **Exclude problematic apps** in settings if needed
4. **Keep the app updated** for latest improvements

## 🆘 Getting Help

- **Issues:** [GitHub Issues](https://github.com/nicolusmaluleke/MacSnapper/issues)
- **Feature Requests:** [GitHub Discussions](https://github.com/nicolusmaluleke/MacSnapper/discussions)
- **Email Support:** nicolusmaluleke@gmail.com

## 🔄 Updating

### Automatic Updates (Coming Soon)
The app will check for updates automatically and notify you.

### Manual Updates
1. Download the latest DMG from releases
2. Replace the old app in Applications folder
3. Your settings will be preserved

## 🗑️ Uninstalling

To completely remove Mac Snap:

1. **Quit the app:**
   - Right-click menu bar icon → Quit
   - Or force quit if needed

2. **Remove the app:**
   ```bash
   rm -rf /Applications/Mac\ Snap.app
   ```

3. **Remove preferences (optional):**
   ```bash
   rm -rf ~/Library/Preferences/com.nicksoftware.macsnap.plist
   rm -rf ~/Library/Application\ Support/Mac\ Snap/
   ```

4. **Remove Accessibility permission:**
   - System Preferences → Security & Privacy → Privacy
   - Select "Accessibility" and remove Mac Snap

---

**Enjoy effortless window management with Mac Snap! 🪟✨**
