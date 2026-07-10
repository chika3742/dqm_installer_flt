PROJECT_ROOT=$(realpath "$(dirname "$0")/../..")

APP_PATH="$PROJECT_ROOT/build/macos/Build/Products/Release/dqm_installer_flt.app"
DMG_PATH="$(dirname "$APP_PATH")/dqm_installer_flt_$1_macos.dmg"

# Create a UDIF bzip2-compressed disk image.
/usr/bin/hdiutil create -srcfolder "$APP_PATH" -format UDBZ "$DMG_PATH"
