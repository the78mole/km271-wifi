traverse = 'topdown'

function Image(el)
    if el.classes:includes("float-right") then
        local caption = pandoc.utils.stringify(el.caption or {})
        local width = "0.40\\textwidth"
        local redwidth = "0.38\\textwidth"
        local height = ""

        for _, attr in ipairs(el.attributes) do
            if attr[1] == "width" then
                width = attr[2]
                redwidth = attr[2]
                -- Falls z. B. "35%" → umwandeln
                if width:match("%%$") then
                    local pct = tonumber(width:match("^(%d+)%%"))
                    if pct then
                        width = string.format("%.2f\\textwidth", pct / 100)
                        redwidth = string.format("%.2f\\textwidth",
                        (pct - 2) / 100)
                    end
                end
            end
            if attr[1] == "height" then
                height = string.format(",height=%s", attr[2])
            end
        end

        local latex = string.format([[
  \begin{wrapfigure}{r}{%s}
    \centering
    \includegraphics[width=%s%s]{%s}
  \end{wrapfigure}
  ]], width, redwidth, height, el.src)
        return {pandoc.RawInline("latex", latex)}
    end
end

function Figure(el)
    local img = el.content[1].content[1] 
    local caption = pandoc.utils.stringify(el.caption)

    if img.t == "Image" and img.classes:includes("float-right") then

        -- new start
        local width = "0.40\\textwidth"
        local redwidth = "0.38\\textwidth"

        for _, attr in ipairs(img.attributes) do
            if attr[1] == "width" then
                width = attr[2]
                redwidth = attr[2]
                -- Falls z. B. "35%" → umwandeln
                if width:match("%%$") then
                    local pct = tonumber(width:match("^(%d+)%%"))
                    if pct then
                        width = string.format("%.2f\\textwidth", pct / 100)
                        redwidth = string.format("%.2f\\textwidth",
                        (pct - 2) / 100)
                    end
                end
            end
        end
        -- new end

        local latex = string.format([[
  \begin{wrapfigure}{r}{%s}
    \centering
    \includegraphics[width=%s]{%s}
    \caption{%s}
  \end{wrapfigure}
  ]], width, redwidth, img.src, caption)

        return {pandoc.RawBlock("latex", latex)}
    end
end
