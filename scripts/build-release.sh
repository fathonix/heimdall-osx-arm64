#!/bin/sh
set -eu

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
UPSTREAM_REPO="${UPSTREAM_REPO:-https://git.sr.ht/~grimler/Heimdall}"
UPSTREAM_REF="${UPSTREAM_REF:-v2.2.2}"
VERSION="${VERSION:-2.2.2}"
ARCH="$(uname -m)"

WORK_ROOT="${WORK_ROOT:-$REPO_ROOT/work}"
SRC_DIR="$WORK_ROOT/Heimdall"
BUILD_DIR="$WORK_ROOT/build"
DIST_DIR="${DIST_DIR:-$REPO_ROOT/dist}"

PATCH_FILE="$REPO_ROOT/patches/0001-fix-browse-dialog-on-modern-macos.patch"
WRAPPER_SRC="$REPO_ROOT/heimdall-frontend-wrapper"

QT_PREFIX="${QT_PREFIX:-$(brew --prefix qt)}"
LIBUSB_PREFIX="${LIBUSB_PREFIX:-$(brew --prefix libusb)}"
MACDEPLOYQT="$QT_PREFIX/bin/macdeployqt"
LIBUSB_DYLIB="$(find "$LIBUSB_PREFIX/lib" -maxdepth 1 -name 'libusb-1.0*.dylib' | head -n 1)"

ASSET_BASENAME="heimdall-${VERSION}-macos-${ARCH}"
APP_NAME="heimdall-frontend.app"
PACKAGED_APP="$DIST_DIR/$APP_NAME"
ARCHIVE_PATH="$DIST_DIR/$ASSET_BASENAME.tar.xz"
CHECKSUM_PATH="$DIST_DIR/$ASSET_BASENAME.tar.xz.sha256"

if [ ! -x "$MACDEPLOYQT" ]; then
	echo "macdeployqt not found at $MACDEPLOYQT" >&2
	exit 1
fi

if [ ! -f "$LIBUSB_DYLIB" ]; then
	echo "libusb dylib not found under $LIBUSB_PREFIX/lib" >&2
	exit 1
fi

rm -rf "$WORK_ROOT" "$DIST_DIR"
mkdir -p "$WORK_ROOT" "$DIST_DIR"

git clone --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPO" "$SRC_DIR"
git -C "$SRC_DIR" apply "$PATCH_FILE"

cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_OSX_ARCHITECTURES="$ARCH" \
	-DCMAKE_PREFIX_PATH="$QT_PREFIX"

cmake --build "$BUILD_DIR" --parallel

BUILT_APP="$(find "$BUILD_DIR" -type d -name "$APP_NAME" -print -quit)"
CLI_BIN="$BUILD_DIR/bin/heimdall"

if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
	echo "Built app bundle not found" >&2
	exit 1
fi

if [ ! -x "$CLI_BIN" ]; then
	echo "Built heimdall CLI not found at $CLI_BIN" >&2
	exit 1
fi

cp -R "$BUILT_APP" "$PACKAGED_APP"
"$MACDEPLOYQT" "$PACKAGED_APP" -always-overwrite

cp "$CLI_BIN" "$PACKAGED_APP/Contents/MacOS/heimdall"
cp "$WRAPPER_SRC" "$PACKAGED_APP/Contents/MacOS/heimdall-frontend-wrapper"
cp "$LIBUSB_DYLIB" "$PACKAGED_APP/Contents/MacOS/"

chmod +x "$PACKAGED_APP/Contents/MacOS/heimdall"
chmod +x "$PACKAGED_APP/Contents/MacOS/heimdall-frontend-wrapper"

plutil -replace CFBundleExecutable -string heimdall-frontend-wrapper "$PACKAGED_APP/Contents/Info.plist"

ORIG_LIBUSB="$(otool -L "$PACKAGED_APP/Contents/MacOS/heimdall" | awk '/libusb-1\.0.*dylib/ { print $1; exit }')"
if [ -n "$ORIG_LIBUSB" ]; then
	install_name_tool -change "$ORIG_LIBUSB" "@executable_path/$(basename "$LIBUSB_DYLIB")" \
		"$PACKAGED_APP/Contents/MacOS/heimdall"
fi

codesign --force --deep --sign - "$PACKAGED_APP"

tar -C "$DIST_DIR" -cJf "$ARCHIVE_PATH" "$APP_NAME"
(cd "$DIST_DIR" && shasum -a 256 "$(basename "$ARCHIVE_PATH")" > "$(basename "$CHECKSUM_PATH")")

printf 'built_archive=%s\n' "$ARCHIVE_PATH"
printf 'built_checksum=%s\n' "$CHECKSUM_PATH"
