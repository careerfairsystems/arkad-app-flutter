#!/bin/bash

cd $(dirname "$(realpath "$0")")/..
pwd

# Extract current version and build number
FULL_VERSION=$(grep -m 1 '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=$(echo "$FULL_VERSION" | cut -d '+' -f 1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d '+' -f 2)

gum log --structured --level debug "Current version is" version "$VERSION_NAME+$BUILD_NUMBER"

echo "What type of release?"
TYPE=$(gum choose "patch" "minor" "major")

# Calculate new version name and increment build number
NEW_VERSION_NAME=$(semver -i "$TYPE" "$VERSION_NAME")
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_FULL_VERSION="${NEW_VERSION_NAME}+${NEW_BUILD_NUMBER}"

gum log --structured --level debug "New version is" version "$NEW_FULL_VERSION"

preform_release() {
  gum log --structured --level debug "Compiling and publishing"

  # Update pubspec.yaml with new version and build number
  sed -i '' "s/^version:[[:space:]]*[0-9a-zA-Z.+-]*/version: $NEW_FULL_VERSION/" pubspec.yaml

  # Update iOS Info.plist with new build number
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" ios/Runner/Info.plist

  gum log --structured --level info "Updated build number to $NEW_BUILD_NUMBER in pubspec.yaml and Info.plist"

  git cliff --tag $NEW_VERSION_NAME >CHANGELOG.md
  git add CHANGELOG.md
  git add pubspec.yaml
  git add ios/Runner/Info.plist

  git commit -m "chore(publishing): $NEW_FULL_VERSION"
  git tag -a "v$NEW_VERSION_NAME" -m "Release version v$NEW_VERSION_NAME"

  git push origin --tags

  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    "v$NEW_FULL_VERSION" 'Release is complete!'

}
gum confirm "Do you want to preform release?" && preform_release
