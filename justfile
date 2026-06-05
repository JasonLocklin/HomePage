# justfile — build workflow for jason.locklin.science
#
# Outputs:
#   public/    — HTML site (zola build)
#   gemini/    — Gemtext capsule (.gmi files)
#   gopher/    — Plain text + gophermap
#
# Usage:
#   just                   — list available recipes
#   just preview           — local dev server (drafts visible)
#   just build             — build all formats
#   just new-post "Title"  — create a new draft post
#   just clean             — remove all generated output
#
# Production (OpenBSD server) — override output paths with env vars:
#   WEBROOT=/var/www/htdocs/jason.locklin.science \
#   GEMROOT=/var/gemini/jason.locklin.science \
#   GOPHERROOT=/var/gopher/jason.locklin.science \
#   just build

content := "content"
scripts := "scripts"

# Output paths — override with env vars on production server (just preview always serves locally)
webroot    := env_var_or_default("WEBROOT",    "public")
gemroot    := env_var_or_default("GEMROOT",    "gemini")
gopherroot := env_var_or_default("GOPHERROOT", "gopher")

# List available recipes
default:
    @just --list

# Verify required tools are installed
check-deps:
    @command -v zola   >/dev/null || { echo "MISSING: zola";   exit 1; }
    @command -v pandoc >/dev/null || { echo "MISSING: pandoc"; exit 1; }
    @[ -f {{scripts}}/gemtext.lua ] || { echo "MISSING: {{scripts}}/gemtext.lua"; exit 1; }

# Local dev server — shows drafts (zola serve uses in-memory output, ignores WEBROOT)
preview:
    zola serve --drafts

# Build all output formats
build: check-deps build-web build-gemini build-gopher

# Build HTML site; inject XSL stylesheet PI into Atom feeds for browser viewing
build-web:
    #!/bin/sh
    set -e
    zola build --output-dir '{{webroot}}'
    find '{{webroot}}' -name "atom.xml" | while read -r f; do
        awk 'NR==1{print; print "<?xml-stylesheet type=\"text/xsl\" href=\"/feed.xsl\"?>"; next}1' \
            "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done

# Convert published posts to Gemtext
build-gemini:
    GEMROOT={{gemroot}} sh {{scripts}}/build-gemini.sh

# Convert published posts to plain text and gophermap
build-gopher:
    GOPHERROOT={{gopherroot}} sh {{scripts}}/build-gopher.sh

# Start a new blog post: just new-post "My Post Title"
new-post title:
    #!/bin/sh
    set -e
    slug=$(printf '%s' '{{title}}' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    out="content/posts/${slug}.md"
    printf -- '---\ntitle: "%s"\ndate: %s\ndraft: true\ntaxonomies:\n  tags: []\n  categories: []\n---\n\n' \
        '{{title}}' "$(date '+%Y-%m-%d')" > "$out"
    echo "Created: $out"

# Announce a new post to Mastodon: just announce "Title" "https://url"
# Requires MASTODON_TOKEN env var — see scripts/announce-post.sh for setup
announce title url:
    MASTODON_TOKEN="${MASTODON_TOKEN}" sh {{scripts}}/announce-post.sh '{{title}}' '{{url}}'

# Stub: fetch Mastodon replies (see scripts/fetch-comments.sh)
fetch:
    sh {{scripts}}/fetch-comments.sh

# Stub: send outgoing webmentions (see scripts/send-webmentions.sh)
send-webmentions:
    sh {{scripts}}/send-webmentions.sh

# Nightly server job: git pull && just nightly
# On OpenBSD use: flock /tmp/site.lock just nightly
nightly: fetch build send-webmentions

# Remove all generated output (local defaults only — production paths not affected)
clean:
    rm -rf public gemini gopher
