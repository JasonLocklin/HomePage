#!/bin/sh
# build-gopher.sh — Convert Zola content to plain text and a Gopher menu
#
# For each Markdown file under content/ (excluding pages marked
# smallweb_ignore: true in frontmatter — including all draft posts), this script:
#   1. Strips Zola shortcodes
#   2. Calls pandoc to produce plain text
#   3. Writes a .txt file under gopher/ mirroring content/
#   4. Generates gopher/gophermap as a root menu
#
# Dependencies: pandoc, sh (POSIX), sed, hostname
# Usage: sh scripts/build-gopher.sh   (or: just build-gopher)

CONTENT="content"
OUTDIR="${GOPHERROOT:-gopher}"
HOST=$(hostname)
PORT=70

mkdir -p "$OUTDIR"

find "$CONTENT" -name "*.md" -not -name "_index.md" | while read -r f; do

    grep -q "smallweb_ignore: *true" "$f" && continue

    rel="${f#$CONTENT/}"
    out="$OUTDIR/${rel%.md}.txt"
    mkdir -p "$(dirname "$out")"

    # Extract title from YAML frontmatter for the file header
    title=$(sed -n '/^---$/,/^---$/p' "$f" \
            | grep "^title:" \
            | sed 's/title:[[:space:]]*//' \
            | tr -d '"')

    # Strip Zola shortcodes, then render to plain text via pandoc
    { printf "%s\n\n" "$title"
      sed \
          -e 's|{{[[:space:]]*responsive_image([^)]*alt="\([^"]*\)"[^)]*)[[:space:]]*}}|[image: \1]|g' \
          -e 's|{{[^}]*}}||g' \
          -e 's|{%[^%]*%}||g' \
          "$f" \
      | pandoc --from markdown --to plain --wrap=none
    } > "$out"

done

# Build root gophermap
# Format: type<TAB>display<TAB>selector<TAB>host<TAB>port
{ printf "i%s\t\tfake\t0\n\n" "$HOST"
  # List posts newest-first (sort -r on path works because files are dated)
  find "$OUTDIR" -name "*.txt" | sort -r | while read -r tf; do
      rel="/${tf#$OUTDIR/}"
      title=$(head -1 "$tf")
      printf "0%s\t%s\t%s\t%s\n" "$title" "$rel" "$HOST" "$PORT"
  done
} > "$OUTDIR/gophermap"
