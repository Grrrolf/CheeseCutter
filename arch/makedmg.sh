#!/bin/bash

VERSION=$(cat Version)
applicationName="CheeseCutter.app"
backgroundPictureName="background.png"
source="build/dmg_temp"
title="CheeseCutter ${VERSION}"
size=20000
finalDMGName="dist/CheeseCutter_${VERSION}.dmg"

rm -rf "${source}"
mkdir -p "${source}"
cp -r "dist/${applicationName}" "${source}/"
cp -r tunes README.md LICENSE.md ChangeLog "${source}/"
mkdir -p "${source}/.background"
cp arch/background.png "${source}/.background/"
ln -s /Applications "${source}/Applications"
chflags hidden "${source}/README.md" "${source}/LICENSE.md" "${source}/ChangeLog"
chmod -R go-w "${source}"

hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k build/pack.temp.dmg
device=$(hdiutil attach -readwrite -noverify -noautoopen "build/pack.temp.dmg" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 5

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
           set background picture of theViewOptions to file ".background:'${backgroundPictureName}'"
           delay 1
	         set position of item "'${applicationName}'" of container window to {140, 205}
           set position of item "tunes" of container window to {326, 205}
           set position of item "Applications" of container window to {512, 205}
           update without registering applications
           close
           open
           delay 5
           eject
           end tell
   end tell
' | osascript

sync
sync
hdiutil detach ${device} 2>/dev/null || true
hdiutil convert build/pack.temp.dmg -format UDZO -imagekey zlib-level=9 -o ${finalDMGName}
rm build/pack.temp.dmg
rm -rf "${source}"
