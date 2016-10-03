#!/bin/bash
set -x

cd "$PROJECT_DIR"
REVCOUNT=$(git rev-list --count HEAD)
let BUILD_VERSION=$REVCOUNT+100
GITHASH=$(git rev-list --max-count=1 --pretty=format:%h HEAD | tail -1)
GITMODIFIED=$(git diff --quiet HEAD || echo " M")
BUILD_VERSION_DETAILS=`echo "$BUILD_VERSION-$GITHASH$GITMODIFIED"`

cd "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"
# RELEASE_VERSION=$(/usr/libexec/PListBuddy -c "Print CFBundleShortVersionString" Info.plist)
/usr/libexec/PListBuddy -c "Set CFBundleVersion $BUILD_VERSION" Info.plist
/usr/libexec/PListBuddy -c "Set CFBundleVersion $BUILD_VERSION" tawidget/Info.plist

# CFBundleVersionDetails = our own key
/usr/libexec/PListBuddy -c "Delete CFBundleVersionDetails" Info.plist || true
/usr/libexec/PListBuddy -c "Delete CFBundleVersionDetails" tawidget/Info.plist || true
/usr/libexec/PListBuddy -c "Add CFBundleVersionDetails string $BUILD_VERSION_DETAILS" Info.plist
/usr/libexec/PListBuddy -c "Add CFBundleVersionDetails string $BUILD_VERSION_DETAILS" tawidget/Info.plist

