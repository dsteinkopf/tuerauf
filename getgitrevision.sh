#!/bin/bash
set -x

cd "$PROJECT_DIR"
REVCOUNT=$(git rev-list --count HEAD)
let BUILD_VERSION=$REVCOUNT+100
GITHASH=$(git rev-list --max-count=1 --pretty=format:%h HEAD | tail -1)
GITMODIFIED=$(git diff --quiet HEAD || echo " M")
BUILD_VERSION_DETAILS=`echo "$BUILD_VERSION-$GITHASH$GITMODIFIED"`

cd "$BUILT_PRODUCTS_DIR"

# RELEASE_VERSION=$(/usr/libexec/PListBuddy -c "Print CFBundleShortVersionString" $INFOPLIST_PATH)
/usr/libexec/PListBuddy -c "Set :CFBundleVersion $BUILD_VERSION" $INFOPLIST_PATH
/usr/libexec/PListBuddy -c "Set :CFBundleVersion $BUILD_VERSION" $DWARF_DSYM_FILE_NAME/Contents/Info.plist

# CFBundleVersionDetails = our own new key
/usr/libexec/PListBuddy -c "Delete :CFBundleVersionDetails" $INFOPLIST_PATH || true
/usr/libexec/PListBuddy -c "Add :CFBundleVersionDetails string $BUILD_VERSION_DETAILS" $INFOPLIST_PATH
