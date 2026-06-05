#!/bin/sh
# build-gemini.sh — Convert Zola content to Gemtext (.gmi)
#
# For each Markdown file under content/ (excluding pages marked
# smallweb_ignore: true in frontmatter — including all draft posts), this script:
#   1. Converts Zola shortcodes to Gemtext-friendly placeholders
#   2. Calls pandoc with the custom Lua writer (scripts/gemtext.lua)
#   3. Writes output to gemini/ mirroring the content/ structure
#
# Dependencies: pandoc, sh (POSIX), sed
# Usage: sh scripts/build-gemini.sh   (or: just build-gemini)
#
# Markdown support in Gemini/Gopher posts:
#   Works cleanly:
#     - Plain paragraphs, ATX headings (# ## ###)
#     - Unordered/ordered lists
#     - Links — [text](url) becomes "=> url text" link lines
#     - Fenced code blocks — become ``` preformatted blocks
#     - Blockquotes (> text)
#     - Zola shortcodes: responsive_image → image link, alert → blockquote
#   Passes through but may look different:
#     - Inline bold/italic — stripped (Gemtext is plain text)
#     - Footnotes — converted to numbered links at end of document
#     - Tables — may render as ASCII or be flattened; test before publishing
#   Avoid or test carefully:
#     - Raw HTML blocks — stripped by pandoc
#     - Deeply nested lists — pandoc flattens
#     - All other Zola shortcodes ({{ ... }}, {% ... %}) — stripped
#   Per-post exclusion: add "smallweb_ignore: true" to frontmatter

CONTENT="content"
OUTDIR="${GEMROOT:-gemini}"
WRITER="scripts/gemtext.lua"

mkdir -p "$OUTDIR"

find "$CONTENT" -name "*.md" -not -name "_index.md" | while read -r f; do

    # Skip pages marked smallweb_ignore (drafts, web-only content, etc.)
    grep -q "smallweb_ignore: *true" "$f" && continue

    # Mirror the directory structure under gemini/
    rel="${f#$CONTENT/}"
    out="$OUTDIR/${rel%.md}.gmi"
    mkdir -p "$(dirname "$out")"

    # Pre-process: convert Zola shortcodes to plain Markdown before pandoc.
    #
    # responsive_image shortcode  ->  ![alt](/path)
    #   Zola: {{ responsive_image(src="images/foo.jpg", alt="desc") }}
    #   Gemtext writer renders Image nodes as "=> /url desc" link lines.
    #
    # alert shortcode  ->  blockquote (pandoc renders as "> text")
    #   Zola: {% alert(type="note") %} text {% end %}
    #
    # All other shortcodes are stripped (web-only widgets).
    sed \
        -e 's|{{[[:space:]]*responsive_image([^)]*src="\([^"]*\)"[^)]*alt="\([^"]*\)"[^)]*)[[:space:]]*}}|![\2](/\1)|g' \
        -e 's|{{[[:space:]]*responsive_image([^)]*alt="\([^"]*\)"[^)]*src="\([^"]*\)"[^)]*)[[:space:]]*}}|![\1](/\2)|g' \
        -e 's|{%[[:space:]]*alert([^)]*)[[:space:]]*%}|> |g' \
        -e 's|{%[[:space:]]*end[[:space:]]*%}||g' \
        -e 's|{{[^}]*}}||g' \
        -e 's|{%[^%]*%}||g' \
        "$f" \
    | pandoc \
        --from markdown \
        --to "$WRITER" \
        --wrap=none \
        -o "$out"

done
