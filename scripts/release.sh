#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
timestamp=$(date +%Y%m%d-%H%M%S)
release_dir=${AUTOQUIT_RELEASE_DIR:-"$project_dir/build/releases/$timestamp"}
archive_path="$release_dir/AutoQuit.xcarchive"
export_path="$release_dir/export"
export_options="$project_dir/Config/ExportOptions-DeveloperID.plist"

mkdir -p "$release_dir"

echo "1/4 Archive with Apple Development signing"
xcodebuild \
  -project "$project_dir/AutoQuit.xcodeproj" \
  -scheme AutoQuit \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$archive_path" \
  archive

echo "2/4 Export with Developer ID Application signing"
if ! xcodebuild \
    -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$export_options"; then
  echo "Developer ID export failed."
  echo "If the log contains errSecInternalComponent, allow codesign to access"
  echo "the Developer ID private key in Keychain Access, then run this script again."
  exit 1
fi

app_path="$export_path/AutoQuit.app"
codesign --verify --deep --strict --verbose=2 "$app_path"

if [[ -z ${NOTARYTOOL_PROFILE:-} ]]; then
  echo "3/4 Notarization skipped: NOTARYTOOL_PROFILE is not set"
  echo "4/4 Signed app: $app_path"
  exit 0
fi

upload_zip="$release_dir/AutoQuit-notarization.zip"
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app_path/Contents/Info.plist")
build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$app_path/Contents/Info.plist")
distribution_zip="$release_dir/AutoQuit-$version-$build.zip"

echo "3/4 Notarize and staple"
ditto -c -k --keepParent "$app_path" "$upload_zip"
xcrun notarytool submit "$upload_zip" \
  --keychain-profile "$NOTARYTOOL_PROFILE" \
  --wait
xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"

echo "4/4 Validate Gatekeeper and package"
spctl -a -vv --type execute "$app_path"
ditto -c -k --keepParent "$app_path" "$distribution_zip"
echo "Release package: $distribution_zip"
