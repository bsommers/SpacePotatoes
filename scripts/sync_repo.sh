#!/usr/bin/env bash
# Sync repository: pull authoritative updates from upstream (bsommers/SpacePotatoes)
# and push updates to origin (spicyspacepotatoes/SpacePotatoes).
#
# Adapted from flowscope's scripts/sync_repo.sh; only the config block below differs.
#
# Usage:
#   ./scripts/sync_repo.sh            # Pull from upstream and push to origin
#   ./scripts/sync_repo.sh --pull-only # Only pull from upstream
#   ./scripts/sync_repo.sh --push-only # Only push to origin
#   ./scripts/sync_repo.sh --status    # Check remote sync status
#   ./scripts/sync_repo.sh --dry-run   # Preview actions without pushing
#
set -euo pipefail

TARGET_FILE="${BASH_SOURCE[0]}"
while [ -L "$TARGET_FILE" ]; do
    TARGET_DIR="$(cd -P "$(dirname "$TARGET_FILE")" && pwd)"
    TARGET_FILE="$(readlink "$TARGET_FILE")"
    [[ "$TARGET_FILE" != /* ]] && TARGET_FILE="$TARGET_DIR/$TARGET_FILE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$TARGET_FILE")" && pwd)"
REPO_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ── Project config ──
PROJECT_NAME="SpacePotatoes"
UPSTREAM_SLUG="bsommers/SpacePotatoes"
ORIGIN_SLUG="spicyspacepotatoes/SpacePotatoes"
UPSTREAM_URL="https://github.com/${UPSTREAM_SLUG}.git"
ORIGIN_URL="https://github.com/${ORIGIN_SLUG}.git"
BRANCH="${SYNC_BRANCH:-main}"

# Parse options
MODE="all"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --pull-only) MODE="pull" ;;
        --push-only) MODE="push" ;;
        --status)    MODE="status" ;;
        --dry-run)   DRY_RUN=true ;;
        --help|-h)
            echo "Usage: $0 [--pull-only|--push-only|--status|--dry-run]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

# Ensure upstream remote exists
if ! git remote get-url upstream >/dev/null 2>&1; then
    echo "==> Configuring 'upstream' remote ($UPSTREAM_URL)..."
    git remote add upstream "$UPSTREAM_URL"
fi

# Ensure origin remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "==> Configuring 'origin' remote ($ORIGIN_URL)..."
    git remote add origin "$ORIGIN_URL"
fi

UPSTREAM_ACTUAL="$(git remote get-url upstream 2>/dev/null || true)"
ORIGIN_ACTUAL="$(git remote get-url origin 2>/dev/null || true)"

echo "==> ${PROJECT_NAME} Repository Sync"
echo "    Upstream (Authoritative): $UPSTREAM_ACTUAL"
echo "    Origin   (Organization):  $ORIGIN_ACTUAL"
echo "    Branch:                   $BRANCH"
echo

if [[ "$MODE" == "status" ]]; then
    echo "==> Fetching status from remotes..."
    git fetch upstream "$BRANCH" --quiet 2>/dev/null || echo "    (upstream/$BRANCH unreachable)"
    git fetch origin "$BRANCH" --quiet 2>/dev/null || echo "    (origin/$BRANCH not yet created or unreachable)"
    
    LOCAL_REV="$(git rev-parse HEAD)"
    UPSTREAM_REV="$(git rev-parse "upstream/$BRANCH" 2>/dev/null || echo "unknown")"
    ORIGIN_REV="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "unknown")"
    
    echo "    Local:    $LOCAL_REV"
    echo "    Upstream: $UPSTREAM_REV"
    echo "    Origin:   $ORIGIN_REV"
    
    if [[ "$LOCAL_REV" == "$UPSTREAM_REV" ]]; then
        echo "    ✓ Local is in sync with upstream."
    else
        BEHIND="$(git rev-list --count HEAD..upstream/"$BRANCH" 2>/dev/null || echo 0)"
        AHEAD="$(git rev-list --count upstream/"$BRANCH"..HEAD 2>/dev/null || echo 0)"
        echo "    ! Local vs Upstream: $AHEAD ahead, $BEHIND behind."
    fi
    exit 0
fi

# Check for uncommitted changes if pulling
if [[ "$MODE" == "all" || "$MODE" == "pull" ]]; then
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "⚠️  Working tree has uncommitted modifications or untracked files."
        echo "   Proceeding with pull (merge will fail safely if conflicts occur)..."
    fi

    echo "==> [1/2] Pulling authoritative updates from upstream/$BRANCH..."
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "    [dry-run] git fetch upstream $BRANCH"
        echo "    [dry-run] git merge upstream/$BRANCH"
    else
        git fetch upstream "$BRANCH"
        git merge "upstream/$BRANCH" --ff-only 2>/dev/null || git merge "upstream/$BRANCH" -m "chore: sync with upstream authoritative"
        echo "    ✓ Successfully updated from upstream."
    fi
fi

# Push to origin
if [[ "$MODE" == "all" || "$MODE" == "push" ]]; then
    echo "==> [2/2] Pushing updates to origin/$BRANCH..."
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "    [dry-run] git push origin $BRANCH"
    else
        if git push origin "$BRANCH"; then
            echo "    ✓ Successfully pushed to origin/$BRANCH."
        else
            echo "⚠️  Push to origin/$BRANCH failed."
            echo "   If the repository ${ORIGIN_SLUG} does not exist yet on GitHub, create it with:"
            echo "     gh repo create ${ORIGIN_SLUG} --private --source=. --remote=origin"
            exit 1
        fi
    fi
fi

echo
echo "==> Sync complete!"
