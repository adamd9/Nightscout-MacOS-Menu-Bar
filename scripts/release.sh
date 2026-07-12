#!/usr/bin/env bash
#
# Create a GitHub release for the current app version.
#
# The app is distributed through the Mac App Store, so GitHub releases are
# informational only: they tag the version and point users to the App Store
# rather than shipping standalone binaries.
#
# Usage:
#   scripts/release.sh              Create & publish the release for the current version
#   scripts/release.sh --dry-run    Print what would happen; make no changes
#
# Optional environment variables:
#   RELEASE_HIGHLIGHTS   Override the auto-generated changelog, e.g.
#                        RELEASE_HIGHLIGHTS=$'- Fixed X\n- Improved Y'
#
# Requirements: gh (authenticated), git.

set -euo pipefail

APP_STORE_URL="https://apps.apple.com/au/app/nightscout-menu-bar/id1639776072?mt=12"
APP_BUNDLE_ID="com.greatmachineinthesky.NightscoutMenuBar"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PBXPROJ="NightscoutMenuBar.xcodeproj/project.pbxproj"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" || "${DRY_RUN_ENV:-0}" == "1" ]]; then
    DRY_RUN=1
fi

# --- Read the app target's version (ignoring the test target) ----------------
# Prints the value of build setting $1 from the configuration block that also
# declares the app's bundle identifier, so the test target (1.0) is skipped.
read_app_setting() {
    awk -v key="$1" -v bid="$APP_BUNDLE_ID" '
        $0 ~ (key " = ")                       { v = $3; gsub(/;/, "", v) }
        $0 ~ ("PRODUCT_BUNDLE_IDENTIFIER = " bid ";") { print v; exit }
    ' "$PBXPROJ"
}

VERSION="$(read_app_setting MARKETING_VERSION)"
BUILD="$(read_app_setting CURRENT_PROJECT_VERSION)"

if [[ -z "$VERSION" ]]; then
    echo "error: could not read MARKETING_VERSION from $PBXPROJ" >&2
    exit 1
fi

TAG="$VERSION"
TITLE="App Store Version $VERSION"

echo "Version : $VERSION"
echo "Build   : ${BUILD:-unknown}"
echo "Tag     : $TAG"
echo "Title   : $TITLE"

# --- Guard against duplicates ------------------------------------------------
if gh release view "$TAG" >/dev/null 2>&1; then
    echo "error: a GitHub release for '$TAG' already exists" >&2
    exit 1
fi

# --- Build the highlights / changelog ----------------------------------------
HIGHLIGHTS="${RELEASE_HIGHLIGHTS:-}"
if [[ -z "$HIGHLIGHTS" ]]; then
    # Most recent non-prerelease tag (excludes anything with a hyphen, e.g. -rc1).
    PREV_TAG="$(git tag --sort=-v:refname | grep -Ev -- '-' | head -n1 || true)"
    if [[ -n "$PREV_TAG" && "$PREV_TAG" != "$TAG" ]]; then
        HIGHLIGHTS="$(git log "${PREV_TAG}..HEAD" --no-merges --pretty=format:'- %s' || true)"
    fi
    [[ -z "$HIGHLIGHTS" ]] && HIGHLIGHTS="- Maintenance and bug fixes"
fi

NOTES="$(cat <<EOF
## Nightscout Menu Bar $VERSION

Available on the Mac App Store.

Download or update: $APP_STORE_URL

Standalone binaries are no longer distributed on GitHub — installing from the
App Store gives you a signed, notarized build with automatic updates.

### Highlights
$HIGHLIGHTS
EOF
)"

echo "------------------------------------------------------------------------"
printf '%s\n' "$NOTES"
echo "------------------------------------------------------------------------"

if [[ "$DRY_RUN" == "1" ]]; then
    echo "(dry run) No tag pushed and no release created."
    exit 0
fi

# --- Tag & publish -----------------------------------------------------------
if ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    git tag -a "$TAG" -m "$TITLE"
fi
git push origin "refs/tags/$TAG"

printf '%s\n' "$NOTES" | gh release create "$TAG" \
    --title "$TITLE" \
    --notes-file - \
    --latest \
    --verify-tag

echo "Done: $(gh release view "$TAG" --json url --jq .url)"
