# justfile — build workflow for jason.locklin.science
#
# Outputs:
#   public/    — HTML site (zola build)
#   gemini/    — Gemtext capsule (.gmi files)
#   gopher/    — Plain text + gophermap
#
# Usage:
#   just          — list available recipes
#   just preview  — local dev server (drafts visible)
#   just build    — build all formats
#   just clean    — remove all generated output

content := "content"
gemini  := "gemini"
gopher  := "gopher"
scripts := "scripts"

# List available recipes
default:
    @just --list

# Verify required tools are installed
check-deps:
    @command -v zola   >/dev/null || { echo "MISSING: zola";   exit 1; }
    @command -v pandoc >/dev/null || { echo "MISSING: pandoc"; exit 1; }
    @[ -f {{scripts}}/gemtext.lua ] || { echo "MISSING: {{scripts}}/gemtext.lua"; exit 1; }

# Local dev server — shows drafts (future-dated posts always render in Zola)
preview:
    zola serve --drafts

# Build all output formats
build: check-deps build-web build-gemini build-gopher

# Build HTML site (zola skips drafts and future posts automatically)
build-web:
    zola build

# Convert published posts to Gemtext
build-gemini:
    sh {{scripts}}/build-gemini.sh

# Convert published posts to plain text and gophermap
build-gopher:
    sh {{scripts}}/build-gopher.sh

# Stub: fetch Mastodon replies (see scripts/fetch-comments.sh)
fetch:
    sh {{scripts}}/fetch-comments.sh

# Stub: send outgoing webmentions (see scripts/send-webmentions.sh)
send-webmentions:
    sh {{scripts}}/send-webmentions.sh

# Nightly server job: git pull && just nightly
# On FreeBSD use:  lockf -t 0 /tmp/site.lock just nightly
nightly: fetch build send-webmentions

# Remove all generated output
clean:
    rm -rf {{gemini}} {{gopher}} public
