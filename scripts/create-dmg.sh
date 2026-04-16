#!/bin/bash
set -euo pipefail

# Create a styled DMG with app + Applications folder drag-to-install layout
APP_NAME="${1:?Usage: create-dmg.sh APP_NAME APP_BUNDLE OUTPUT_DMG}"
APP_BUNDLE="${2:?}"
OUTPUT_DMG="${3:?}"

VOLUME_NAME="$APP_NAME"
DMG_TEMP="$(mktemp -u).dmg"
STAGING_DIR="$(mktemp -d)"

# Detach any existing volume with this name
if [ -d "/Volumes/$VOLUME_NAME" ]; then
    echo "Detaching existing volume..."
    hdiutil detach "/Volumes/$VOLUME_NAME" -quiet -force 2>/dev/null || true
fi

ACTUAL_MOUNT=""
cleanup() {
    if [ -n "$ACTUAL_MOUNT" ] && [ -d "$ACTUAL_MOUNT" ]; then
        hdiutil detach "$ACTUAL_MOUNT" -quiet -force 2>/dev/null || true
    fi
    rm -rf "$STAGING_DIR"
    rm -f "$DMG_TEMP"
}
trap cleanup EXIT

echo "Staging DMG contents..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Calculate size needed (app size + 10MB padding)
SIZE_KB=$(du -sk "$STAGING_DIR" | awk '{print $1}')
SIZE_KB=$((SIZE_KB + 10240))

echo "Creating writable DMG (${SIZE_KB}KB)..."
hdiutil create -size "${SIZE_KB}k" \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -fs HFS+ \
    -format UDRW \
    "$DMG_TEMP"

echo "Mounting DMG..."
MOUNT_OUTPUT=$(hdiutil attach "$DMG_TEMP" -readwrite -noverify -noautoopen)
ACTUAL_MOUNT=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/.*' | head -1 | sed 's/[[:space:]]*$//')
echo "Mounted at: $ACTUAL_MOUNT"

# Get the disk name as Finder sees it (last path component)
DISK_NAME=$(basename "$ACTUAL_MOUNT")

echo "Configuring DMG window layout..."
# Use DS_Store approach with AppleScript for icon positioning
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$DISK_NAME"
        open
        delay 1

        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false

        -- Window size and position
        set the bounds of container window to {100, 100, 640, 440}

        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128

        -- Position the app icon on the left, Applications on the right
        set position of item "$APP_NAME.app" of container window to {130, 150}
        set position of item "Applications" of container window to {410, 150}

        close
        open

        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Set the volume icon if the app has one
APP_ICON="$ACTUAL_MOUNT/$APP_NAME.app/Contents/Resources/AppIcon.icns"
if [ -f "$APP_ICON" ]; then
    cp "$APP_ICON" "$ACTUAL_MOUNT/.VolumeIcon.icns"
    SetFile -c icnC "$ACTUAL_MOUNT/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$ACTUAL_MOUNT" 2>/dev/null || true
fi

sync

echo "Unmounting..."
hdiutil detach "$ACTUAL_MOUNT" -quiet

echo "Converting to compressed DMG..."
rm -f "$OUTPUT_DMG"
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$OUTPUT_DMG"

echo "DMG created: $OUTPUT_DMG"
