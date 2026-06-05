-- pandoc custom writer: Markdown + YAML frontmatter -> Gemtext (.gmi)
--
-- Gemtext rules enforced here:
--   * Links must be on their own line (=> URL label)
--   * Headings use #/##/### prefix
--   * Preformatted blocks use ``` fences
--   * Blockquotes use > prefix (one per line)
--
-- Links inside paragraphs are collected and placed AFTER the paragraph text.
-- Zola shortcodes (responsive_image, alert) are converted before pandoc runs
-- by build-gemini.sh -- by the time this writer sees the AST they are gone.

local stringify = pandoc.utils.stringify

-- Render an inline list, collecting links separately.
-- Returns: plain text string, list of "=> url label" strings
local function render_inlines(inlines)
    local text, links = {}, {}
    for _, el in ipairs(inlines) do
        if el.t == "Link" then
            local label = stringify(el.content)
            table.insert(text, label)
            -- pandoc 3.x: el.target is the URL string directly
            local url = type(el.target) == "string" and el.target or el.target[1]
            table.insert(links, "=> " .. url .. " " .. label)
        elseif el.t == "Image" then
            -- In pandoc 3.x: el.src = URL string, el.caption = alt Inlines
            table.insert(links, "=> " .. el.src .. " " .. stringify(el.caption or el.content))
        elseif el.t == "Code" then
            table.insert(text, el.text)
        elseif el.t == "Space" or el.t == "SoftBreak" then
            table.insert(text, " ")
        elseif el.t == "LineBreak" then
            table.insert(text, "\n")
        else
            table.insert(text, stringify(pandoc.Inlines({el})))
        end
    end
    return table.concat(text), links
end

-- Render one block element into the output list.
local function render_block(block, out)
    if block.t == "Para" or block.t == "Plain" then
        local text, links = render_inlines(block.content)
        if text ~= "" then
            table.insert(out, text)
            table.insert(out, "")
        end
        for _, link in ipairs(links) do
            table.insert(out, link)
        end
        if #links > 0 then table.insert(out, "") end

    elseif block.t == "Header" then
        local prefix = string.rep("#", math.min(block.level, 3)) .. " "
        table.insert(out, prefix .. stringify(block.content))
        table.insert(out, "")

    elseif block.t == "BulletList" or block.t == "OrderedList" then
        for _, item in ipairs(block.content) do
            -- items are lists of blocks; stringify the first para
            table.insert(out, "* " .. stringify(item))
        end
        table.insert(out, "")

    elseif block.t == "BlockQuote" then
        for _, inner in ipairs(block.content) do
            table.insert(out, "> " .. stringify(inner.content or inner))
        end
        table.insert(out, "")

    elseif block.t == "CodeBlock" then
        -- optional language label after the fence
        local info = block.attr and block.attr.classes and block.attr.classes[1] or ""
        table.insert(out, "```" .. info)
        table.insert(out, block.text)
        table.insert(out, "```")
        table.insert(out, "")

    elseif block.t == "HorizontalRule" then
        table.insert(out, "────────────────────")
        table.insert(out, "")

    elseif block.t == "Figure" then
        -- Standalone images (pandoc 3.x wraps them in Figure blocks)
        -- Walk content to find the Image inline
        for _, inner in ipairs(block.content) do
            render_block(inner, out)
        end

    elseif block.t == "Div" then
        -- pass-through: render child blocks
        for _, child in ipairs(block.content) do
            render_block(child, out)
        end
    end
    -- other block types (RawBlock, Table, etc.) are silently skipped
end

-- Entry point called by pandoc
function Writer(doc, opts)
    local meta = doc.meta
    local out  = {}

    -- Title
    local title = stringify(meta.title or "Untitled")
    table.insert(out, "# " .. title)
    table.insert(out, "")

    -- Date and author on one line
    local date   = stringify(meta.date   or "")
    local author = stringify(meta.author or "")
    if date ~= "" and author ~= "" then
        table.insert(out, "> " .. date .. " · " .. author)
    elseif date ~= "" then
        table.insert(out, "> " .. date)
    end
    table.insert(out, "")

    -- Description (if present)
    local desc = stringify(meta.description or "")
    if desc ~= "" then
        table.insert(out, desc)
        table.insert(out, "")
    end

    -- Tags
    if meta.tags then
        local tagline = {}
        for _, t in ipairs(meta.tags) do
            table.insert(tagline, stringify(t))
        end
        table.insert(out, "Tags: " .. table.concat(tagline, ", "))
        table.insert(out, "")
    end

    table.insert(out, "────────────────────")
    table.insert(out, "")

    -- Body
    for _, block in ipairs(doc.blocks) do
        render_block(block, out)
    end

    return table.concat(out, "\n")
end
