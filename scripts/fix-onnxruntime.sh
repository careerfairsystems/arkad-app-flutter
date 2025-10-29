#!/bin/bash

# Fix ONNX Runtime framework MinimumOSVersion to match app deployment target
# This script patches the Info.plist of onnxruntime.framework to set MinimumOSVersion to 15.6

set -e

echo "Fixing onnxruntime.framework MinimumOSVersion..."

# Find onnxruntime.framework in the built app
FRAMEWORK_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/onnxruntime.framework"

if [ ! -d "$FRAMEWORK_PATH" ]; then
    echo "onnxruntime.framework not found at $FRAMEWORK_PATH, skipping..."
    exit 0
fi

INFO_PLIST="$FRAMEWORK_PATH/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Info.plist not found in onnxruntime.framework, skipping..."
    exit 0
fi

echo "Found framework at: $FRAMEWORK_PATH"

# Check if MinimumOSVersion already exists
if /usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$INFO_PLIST" 2>/dev/null; then
    echo "Updating existing MinimumOSVersion to 15.6..."
    /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 15.6" "$INFO_PLIST"
else
    echo "Adding MinimumOSVersion 15.6..."
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 15.6" "$INFO_PLIST"
fi

echo "Successfully updated onnxruntime.framework MinimumOSVersion to 15.6"
