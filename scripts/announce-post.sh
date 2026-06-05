#!/bin/sh
# announce-post.sh — Post a new blog entry announcement to Mastodon
#
# Usage:
#   MASTODON_TOKEN=<token> sh scripts/announce-post.sh "Title" "https://url"
#   MASTODON_TOKEN=<token> MASTODON_INSTANCE=fosstodon.org sh scripts/announce-post.sh "Title" "https://url"
#
# Setup (one-time):
#   1. Log in to your Mastodon instance
#   2. Preferences → Development → New Application
#      Scopes needed: write:statuses
#   3. Copy "Your access token" — export it as MASTODON_TOKEN in your shell or store
#      it in a file outside the repo and source it before running: . ~/.mastodon_env
#
# Tip: add to justfile — just announce "Title" "https://url"
#
# Dependencies: curl

INSTANCE="${MASTODON_INSTANCE:-mastodon.social}"
TOKEN="${MASTODON_TOKEN:-}"
TITLE="${1:-}"
URL="${2:-}"

if [ -z "$TOKEN" ]; then
    printf 'Error: MASTODON_TOKEN is not set\n' >&2
    printf 'Usage: MASTODON_TOKEN=<token> sh %s "<title>" "<url>"\n' "$0" >&2
    exit 1
fi

if [ -z "$TITLE" ] || [ -z "$URL" ]; then
    printf 'Usage: sh %s "<post title>" "<post url>"\n' "$0" >&2
    exit 1
fi

STATUS="${TITLE}

${URL}"

result=$(curl -s -X POST "https://${INSTANCE}/api/v1/statuses" \
    -H "Authorization: Bearer ${TOKEN}" \
    --data-urlencode "status=${STATUS}" \
    --data-urlencode "visibility=public")

# Print the URL of the posted status on success
printf '%s\n' "$result" | grep -o '"url":"[^"]*"' | head -1 | sed 's/"url":"//;s/"//'
