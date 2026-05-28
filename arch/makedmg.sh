#!/bin/bash

VERSION=$(cat Version)
applicationName="CheeseCutter.app"
backgroundPictureName="background.png"
source="build/dmg_temp"
title="CheeseCutter ${VERSION}"
size=35000
finalDMGName="dist/CheeseCutter_${VERSION}.dmg"

rm -rf "${source}"
mkdir -p "${source}"
cp -r "dist/${applicationName}" "${source}/"

rm -f build/pack.temp.dmg
hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k build/pack.temp.dmg
device=$(hdiutil attach -readwrite -noverify -noautoopen "build/pack.temp.dmg" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 5

# Copy distribution files, background picture, and symlinks AFTER mounting.
# This triggers Finder filesystem events so Finder immediately indexes and recognizes
# the .background folder and its contents, allowing AppleScript to set the background successfully.
mkdir -p /Volumes/"${title}"/.background
cp arch/background.png /Volumes/"${title}"/.background/
cp -r tunes /Volumes/"${title}"/
cp dist/ct2util /Volumes/"${title}"/tunes/
codesign --force --sign - /Volumes/"${title}"/tunes/ct2util
cp README.md LICENSE.md ChangeLog /Volumes/"${title}"/
ln -s /Applications /Volumes/"${title}"/Applications
chflags hidden /Volumes/"${title}"/README.md /Volumes/"${title}"/LICENSE.md /Volumes/"${title}"/ChangeLog

echo '
   tell application "Finder"
     tell disk "'${title}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 1052, 450}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set background picture of theViewOptions to file ".background:background.png"
           delay 1
	         set position of item "'${applicationName}'" of container window to {140, 205}
           set position of item "tunes" of container window to {326, 205}
           set position of item "Applications" of container window to {512, 205}
           update without registering applications
           close
           open
           delay 5
           end tell
   end tell
' | osascript

# Since the Finder AppleScript has closed and opened the window to write the .DS_Store,
# we now make the files read-only on the mounted volume before detaching.
chmod -Rf go-w /Volumes/"${title}"
sync
sync
hdiutil detach ${device} 2>/dev/null || true
hdiutil convert build/pack.temp.dmg -format UDZO -imagekey zlib-level=9 -o ${finalDMGName}
rm build/pack.temp.dmg
rm -rf "${source}"
