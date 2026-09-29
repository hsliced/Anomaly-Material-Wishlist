-- ============================================================
-- Anomaly Material Wishlist - Style Module
-- Version: v0.6.7
--
-- v0.6.7
--   - Rise HUD title changed from all caps to title case
--   - Added lighter-weight Rise title/material typography
--   - Added subtle dark text outline to Rise title/material names
--   - Added dark translucent outer silhouette around Rise HUD
--   - Outer silhouette now includes the left wedge/triangle
--   - Existing gold/brown inner border retained
--   - Classic renderer intentionally unchanged
--   - Layout, positioning, text scaling, and persistence unchanged
-- ============================================================

local Style = {}

Style.VERSION = "0.6.7"

local D2D_AVAILABLE =
    type(d2d) == "table"
    and type(d2d.register) == "function"
    and type(d2d.Font) == "table"
    and type(d2d.Font.new) == "function"

function Style.d2d_available()
    return D2D_AVAILABLE
end

local function clamp(v, lo, hi)
    if v < lo then
        return lo
    end

    if v > hi then
        return hi
    end

    return v
end

local function finite(n)
    return
        type(n) == "number"
        and n == n
        and math.abs(n) < 10000000
end


------------------------------------------------------------
-- SHARED GEOMETRY
------------------------------------------------------------

local REF_H = 1440
local REF_W = 640

local MIN_RES_SCALE = 0.75
local MAX_RES_SCALE = 1.00

local DEFAULT_RIGHT_MARGIN = 36

-- v0.6.5 vertical placement retained.
local DEFAULT_TOP_FRACTION = 0.1675

-- v0.6.6 horizontal placement retained.
local DEFAULT_LEFT_SHIFT = 28


local function resolution_scale(surface_h)

    return
        clamp(
            (
                tonumber(surface_h)
                or REF_H
            ) / REF_H,
            MIN_RES_SCALE,
            MAX_RES_SCALE
        )
end


function Style.default_position(
    surface_w,
    surface_h
)

    local rs =
        resolution_scale(
            surface_h
        )

    local width =
        math.floor(
            REF_W * rs
        )

    local margin =
        math.max(
            24,
            math.floor(
                DEFAULT_RIGHT_MARGIN
                * rs
            )
        )

    local x =
        math.max(
            12,
            math.floor(
                surface_w
                - width
                - margin
                - (
                    DEFAULT_LEFT_SHIFT
                    * rs
                )
            )
        )

    local y =
        math.max(
            90,
            math.floor(
                surface_h
                * DEFAULT_TOP_FRACTION
            )
        )

    return x, y
end


------------------------------------------------------------
-- TEXT SCALE PRESETS
------------------------------------------------------------

local SCALE_PRESETS = {
    0.8,
    0.9,
    1.0,
    1.1,
    1.2,
    1.3,
    1.4
}


function Style.normalize_text_scale(value)

    value =
        tonumber(value)
        or 1.0

    local best =
        SCALE_PRESETS[1]

    local best_delta =
        math.abs(
            value - best
        )

    for _, candidate
        in ipairs(SCALE_PRESETS)
    do

        local delta =
            math.abs(
                value
                - candidate
            )

        if delta < best_delta then

            best =
                candidate

            best_delta =
                delta
        end
    end

    return best
end


function Style.next_text_scale(
    value,
    direction
)

    value =
        Style.normalize_text_scale(
            value
        )

    local idx = 1

    for i, candidate
        in ipairs(SCALE_PRESETS)
    do

        if candidate == value then
            idx = i
            break
        end
    end

    idx =
        clamp(
            idx + direction,
            1,
            #SCALE_PRESETS
        )

    return
        SCALE_PRESETS[idx]
end


------------------------------------------------------------
-- D2D RESOURCES
------------------------------------------------------------

local fonts = {}
local registered = false


local function make_font_set(scale)

    return {
        -- Classic keeps the older heavier hierarchy.
        title =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    18 * scale + 0.5
                ),
                true,
                false
            ),

        material =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    16 * scale + 0.5
                ),
                true,
                false
            ),

        -- Rise gets lighter title/material weights.
        rise_title =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    18 * scale + 0.5
                ),
                false,
                false
            ),

        rise_material =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    16 * scale + 0.5
                ),
                false,
                false
            ),

        summary =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    13 * scale + 0.5
                ),
                false,
                false
            ),

        meta =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    13 * scale + 0.5
                ),
                false,
                false
            ),

        source =
            d2d.Font.new(
                "Tahoma",
                math.floor(
                    13 * scale + 0.5
                ),
                false,
                false
            )
    }
end


local function get_fonts(scale)

    scale =
        Style.normalize_text_scale(
            scale
        )

    return
        fonts[
            string.format(
                "%.1f",
                scale
            )
        ]
end


local function measure(
    font,
    text
)

    if font == nil then
        return 0, 0
    end

    local ok,
          w,
          h =
        pcall(function()

            return
                font:measure(
                    tostring(
                        text or ""
                    )
                )

        end)

    if not ok then
        return 0, 0
    end

    return
        tonumber(w) or 0,
        tonumber(h) or 0
end


local function wrap_pixels(
    text,
    font,
    max_width
)

    text =
        tostring(
            text or ""
        )

    if text == "" then
        return {
            ""
        }
    end

    local full =
        measure(
            font,
            text
        )

    if full <= max_width then

        return {
            text
        }
    end

    local lines = {}
    local current = ""

    for word
        in string.gmatch(
            text,
            "%S+"
        )
    do

        local proposed =
            current == ""
            and word
            or (
                current
                .. " "
                .. word
            )

        local width =
            measure(
                font,
                proposed
            )

        if current == ""
            or width <= max_width
        then

            current =
                proposed

        else

            lines[#lines + 1] =
                current

            current =
                word
        end
    end

    if current ~= "" then

        lines[#lines + 1] =
            current
    end

    if #lines == 0 then

        lines[1] =
            text
    end

    return lines
end


local function source_lines(
    material,
    font,
    max_width
)

    return
        wrap_pixels(
            material.sources_text
            or "",
            font,
            max_width
        )
end


------------------------------------------------------------
-- TEXT OUTLINE HELPER
------------------------------------------------------------

local function draw_outlined_text(
    font,
    text,
    x,
    y,
    text_color,
    outline_color,
    outline_size
)

    local o =
        math.max(
            1,
            outline_size
            or 1
        )

    d2d.text(
        font,
        text,
        x - o,
        y,
        outline_color
    )

    d2d.text(
        font,
        text,
        x + o,
        y,
        outline_color
    )

    d2d.text(
        font,
        text,
        x,
        y - o,
        outline_color
    )

    d2d.text(
        font,
        text,
        x,
        y + o,
        outline_color
    )

    d2d.text(
        font,
        text,
        x,
        y,
        text_color
    )
end


------------------------------------------------------------
-- RISE PALETTE / GEOMETRY
------------------------------------------------------------

local RISE = {
    wedge = 28,
    header_h = 44,
    content_inset = 22,
    title_icon_area = 38,
    item_indent = 12,
    meta_indent = 22,
    summary_top = 10,
    item_top = 12,
    item_bottom = 16,
    material_line = 23,
    meta_line = 19,
    bottom_pad = 14,
    radius = 5,

    panel = 0xDD111516,
    body = 0xD91A1D1E,
    header = 0xE0463528,
    wedge_color = 0xF05C442D,

    -- Existing inner border.
    border = 0xCC765F3E,

    -- v0.6.7 external contrast treatment.
    outer_border = 0xB8080A0B,
    text_outline = 0xE0101112,

    rule = 0xFF9F8352,
    title = 0xFFFFD68A,
    summary = 0xFFD6B66E,
    text = 0xFFF4F4F4,
    meta = 0xFFD2D2D2,
    source = 0xFFCDBF9D,
    accent = 0xFFB99355,
    icon_frame = 0xFFB89452,
    icon = 0xFFE5B955,
    icon_dark = 0xFF75552C
}


local function draw_rise_emblem(
    x,
    y,
    rs
)

    local frame =
        27 * rs

    d2d.fill_rounded_rect(
        x,
        y,
        frame,
        frame,
        3 * rs,
        3 * rs,
        RISE.icon_dark
    )

    d2d.outline_rect(
        x,
        y,
        frame,
        frame,
        math.max(
            1,
            1.25 * rs
        ),
        RISE.icon_frame
    )

    local cx =
        x + frame / 2

    local cy =
        y + frame / 2

    local r =
        7 * rs

    d2d.fill_quad(
        cx,
        cy - r,
        cx + r,
        cy,
        cx,
        cy + r,
        cx - r,
        cy,
        RISE.icon
    )

    d2d.fill_circle(
        cx,
        cy,
        3 * rs,
        RISE.icon_dark
    )
end


local function rise_height(
    ctx,
    hud_w,
    rs,
    fs
)

    local header_h =
        RISE.header_h
        * rs

    local h =
        header_h
        + (
            RISE.summary_top
            * rs
        )
        + (
            22
            * fs.scale
        )

    if ctx.database_error ~= "" then

        return
            h
            + (
                70
                * fs.scale
            )
    end

    if #ctx.active == 0 then

        return
            h
            + (
                48
                * fs.scale
            )
    end

    local body_w =
        hud_w
        - (
            RISE.wedge
            * rs
        )

    local source_w =
        body_w
        - (
            (
                RISE.content_inset
                + RISE.meta_indent
                + 24
            )
            * rs
        )

    for _, entry
        in ipairs(ctx.active)
    do

        local lines =
            source_lines(
                entry.material,
                fs.fonts.source,
                source_w
            )

        h =
            h
            + (
                RISE.item_top
                * rs
            )
            + (
                RISE.material_line
                * fs.scale
            )
            + (
                RISE.meta_line
                * fs.scale
            )
            + (
                #lines
                * RISE.meta_line
                * fs.scale
            )
            + (
                RISE.item_bottom
                * rs
            )
    end

    return
        h
        + (
            RISE.bottom_pad
            * rs
        )
end


local function draw_rise(
    ctx,
    surface_w,
    surface_h
)

    local user_scale =
        Style.normalize_text_scale(
            ctx.text_scale
        )

    local fontset =
        get_fonts(
            user_scale
        )

    if not fontset then
        return
    end

    local rs =
        resolution_scale(
            surface_h
        )

    local hud_w =
        math.floor(
            REF_W
            * rs
        )

    local fs = {
        scale =
            user_scale,

        fonts =
            fontset
    }

    local x, y =
        ctx.x,
        ctx.y

    local wedge =
        RISE.wedge
        * rs

    local header_h =
        RISE.header_h
        * rs

    local body_x =
        x + wedge

    local body_w =
        hud_w
        - wedge

    local h =
        rise_height(
            ctx,
            hud_w,
            rs,
            fs
        )

    --------------------------------------------------------
    -- v0.6.7 DARK OUTER SILHOUETTE
    --------------------------------------------------------

    local outer =
        math.max(
            2,
            2.5 * rs
        )

    -- Dark backing around the rectangular body.
    d2d.fill_rounded_rect(
        body_x - outer,
        y - outer,
        body_w + outer * 2,
        h + outer * 2,
        (
            RISE.radius
            + 2
        ) * rs,
        (
            RISE.radius
            + 2
        ) * rs,
        RISE.outer_border
    )

    -- Dark backing around the wedge itself.
    -- This is intentionally slightly larger than the colored wedge
    -- so its diagonal edges remain visible against dark/brown scenery.
    d2d.fill_quad(
        x - outer,
        y + header_h / 2,

        body_x - outer,
        y - outer,

        body_x
            + (8 * rs)
            + outer,
        y + header_h / 2,

        body_x - outer,
        y
            + header_h
            + outer,

        RISE.outer_border
    )

    --------------------------------------------------------
    -- EXISTING RISE PANEL
    --------------------------------------------------------

    d2d.fill_rounded_rect(
        body_x,
        y,
        body_w,
        h,
        RISE.radius * rs,
        RISE.radius * rs,
        RISE.panel
    )

    d2d.fill_rounded_rect(
        body_x + 3,
        y
            + header_h
            + (4 * rs),
        body_w - 6,
        h
            - header_h
            - (4 * rs)
            - 3,
        3 * rs,
        3 * rs,
        RISE.body
    )

    d2d.fill_rect(
        body_x,
        y,
        body_w,
        header_h,
        RISE.header
    )

    d2d.fill_quad(
        x,
        y + header_h / 2,

        body_x,
        y,

        body_x + (8 * rs),
        y + header_h / 2,

        body_x,
        y + header_h,

        RISE.wedge_color
    )

    -- Existing gold/brown inner border remains.
    d2d.outline_rect(
        body_x,
        y,
        body_w,
        h,
        math.max(
            1,
            1.0 * rs
        ),
        RISE.border
    )

    local icon_x =
        body_x
        + (
            RISE.content_inset
            * rs
        )

    local icon_y =
        y
        + (
            (
                header_h
                - 27 * rs
            )
            / 2
        )

    draw_rise_emblem(
        icon_x,
        icon_y,
        rs
    )

    local title_x =
        body_x
        + (
            (
                RISE.content_inset
                + RISE.title_icon_area
            )
            * rs
        )

    local title_y =
        y
        + (10 * rs)

    local outline_px =
        math.max(
            1,
            math.floor(
                rs + 0.5
            )
        )

    draw_outlined_text(
        fontset.rise_title,
        "Anomaly Material Wishlist",
        title_x,
        title_y,
        RISE.title,
        RISE.text_outline,
        outline_px
    )

    local rule_x =
        body_x
        + (
            RISE.content_inset
            * rs
        )

    local rule_y =
        y
        + header_h
        - (2 * rs)

    d2d.line(
        rule_x,
        rule_y,

        body_x
            + body_w
            - (14 * rs),

        rule_y,

        math.max(
            1,
            1.1 * rs
        ),

        RISE.rule
    )

    local content_x =
        body_x
        + (
            RISE.content_inset
            * rs
        )

    local current_y =
        y
        + header_h
        + (
            RISE.summary_top
            * rs
        )

    d2d.text(
        fontset.summary,

        tostring(
            ctx.item_count
        )
            .. " materials  |  "
            .. tostring(
                ctx.total_count
            )
            .. " items remaining",

        content_x,
        current_y,
        RISE.summary
    )

    current_y =
        current_y
        + (
            25
            * user_scale
        )

    if ctx.database_error ~= "" then

        draw_outlined_text(
            fontset.rise_material,
            "DATABASE ERROR",
            content_x,
            current_y,
            RISE.text,
            RISE.text_outline,
            outline_px
        )

        d2d.text(
            fontset.source,
            ctx.database_error,
            content_x,
            current_y
                + (
                    25
                    * user_scale
                ),
            RISE.meta
        )

        return
    end

    if #ctx.active == 0 then

        draw_outlined_text(
            fontset.rise_material,
            "Wishlist is empty.",
            content_x,
            current_y
                + (
                    10
                    * user_scale
                ),
            RISE.text,
            RISE.text_outline,
            outline_px
        )

        return
    end

    local item_x =
        content_x
        + (
            RISE.item_indent
            * rs
        )

    local meta_x =
        content_x
        + (
            RISE.meta_indent
            * rs
        )

    local source_w =
        body_w
        - (
            (
                RISE.content_inset
                + RISE.meta_indent
                + 24
            )
            * rs
        )

    for _, entry
        in ipairs(ctx.active)
    do

        local material =
            entry.material

        current_y =
            current_y
            + (
                RISE.item_top
                * rs
            )

        local lines =
            source_lines(
                material,
                fontset.source,
                source_w
            )

        local block_h =
            (
                RISE.material_line
                * user_scale
            )
            + (
                RISE.meta_line
                * user_scale
            )
            + (
                #lines
                * RISE.meta_line
                * user_scale
            )

        d2d.fill_rect(
            content_x,
            current_y
                + (2 * rs),
            math.max(
                2,
                3 * rs
            ),
            block_h
                - (3 * rs),
            RISE.accent
        )

        draw_outlined_text(
            fontset.rise_material,
            material.name
                .. "  x"
                .. tostring(
                    entry.amount
                ),
            item_x,
            current_y,
            RISE.text,
            RISE.text_outline,
            outline_px
        )

        current_y =
            current_y
            + (
                RISE.material_line
                * user_scale
            )

        d2d.text(
            fontset.meta,
            material.levels,
            meta_x,
            current_y,
            RISE.meta
        )

        current_y =
            current_y
            + (
                RISE.meta_line
                * user_scale
            )

        for _, line
            in ipairs(lines)
        do

            d2d.text(
                fontset.source,
                line,
                meta_x,
                current_y,
                RISE.source
            )

            current_y =
                current_y
                + (
                    RISE.meta_line
                    * user_scale
                )
        end

        current_y =
            current_y
            + (
                RISE.item_bottom
                * rs
            )
    end
end


------------------------------------------------------------
-- CLASSIC CYAN RENDERER
-- Intentionally unchanged from v0.6.6.
------------------------------------------------------------

local CLASSIC = {
    header_h = 40,
    inset = 18,
    summary_top = 9,
    item_top = 13,
    item_bottom = 15,
    material_line = 23,
    meta_line = 19,
    bottom_pad = 14,
    radius = 4,

    panel = 0xDD080D10,
    body = 0xD912181C,
    header = 0xE0185564,
    border = 0xAA33A5BD,
    rule = 0xFF4BC4D8,
    title = 0xFFEAFDFF,
    summary = 0xFF72D3E4,
    text = 0xFFF2F2F2,
    meta = 0xFFBEC9CD,
    source = 0xFFC8B99E,
    accent = 0xFF47BFD3
}


local function classic_height(
    ctx,
    hud_w,
    rs,
    user_scale,
    fontset
)

    local h =
        (
            CLASSIC.header_h
            * rs
        )
        + (
            CLASSIC.summary_top
            * rs
        )
        + (
            22
            * user_scale
        )

    if ctx.database_error ~= "" then

        return
            h
            + (
                70
                * user_scale
            )
    end

    if #ctx.active == 0 then

        return
            h
            + (
                48
                * user_scale
            )
    end

    local source_w =
        hud_w
        - (
            (
                CLASSIC.inset
                + 42
            )
            * rs
        )

    for _, entry
        in ipairs(ctx.active)
    do

        local lines =
            source_lines(
                entry.material,
                fontset.source,
                source_w
            )

        h =
            h
            + (
                CLASSIC.item_top
                * rs
            )
            + (
                CLASSIC.material_line
                * user_scale
            )
            + (
                CLASSIC.meta_line
                * user_scale
            )
            + (
                #lines
                * CLASSIC.meta_line
                * user_scale
            )
            + (
                CLASSIC.item_bottom
                * rs
            )
    end

    return
        h
        + (
            CLASSIC.bottom_pad
            * rs
        )
end


local function draw_classic_d2d(
    ctx,
    surface_w,
    surface_h
)

    local user_scale =
        Style.normalize_text_scale(
            ctx.text_scale
        )

    local fontset =
        get_fonts(
            user_scale
        )

    if not fontset then
        return
    end

    local rs =
        resolution_scale(
            surface_h
        )

    local hud_w =
        math.floor(
            REF_W
            * rs
        )

    local x, y =
        ctx.x,
        ctx.y

    local header_h =
        CLASSIC.header_h
        * rs

    local h =
        classic_height(
            ctx,
            hud_w,
            rs,
            user_scale,
            fontset
        )

    d2d.fill_rounded_rect(
        x,
        y,
        hud_w,
        h,
        CLASSIC.radius * rs,
        CLASSIC.radius * rs,
        CLASSIC.panel
    )

    d2d.fill_rounded_rect(
        x + 3,
        y + header_h + 3,
        hud_w - 6,
        h - header_h - 6,
        3 * rs,
        3 * rs,
        CLASSIC.body
    )

    d2d.fill_rect(
        x,
        y,
        hud_w,
        header_h,
        CLASSIC.header
    )

    d2d.outline_rect(
        x,
        y,
        hud_w,
        h,
        math.max(
            1,
            1.0 * rs
        ),
        CLASSIC.border
    )

    local content_x =
        x
        + (
            CLASSIC.inset
            * rs
        )

    d2d.text(
        fontset.title,
        "ANOMALY MATERIAL WISHLIST",
        content_x,
        y + (9 * rs),
        CLASSIC.title
    )

    local rule_y =
        y
        + header_h
        - (2 * rs)

    d2d.line(
        content_x,
        rule_y,
        x
            + hud_w
            - (
                CLASSIC.inset
                * rs
            ),
        rule_y,
        math.max(
            1,
            1.1 * rs
        ),
        CLASSIC.rule
    )

    local current_y =
        y
        + header_h
        + (
            CLASSIC.summary_top
            * rs
        )

    d2d.text(
        fontset.summary,
        tostring(
            ctx.item_count
        )
            .. " materials  |  "
            .. tostring(
                ctx.total_count
            )
            .. " items remaining",
        content_x,
        current_y,
        CLASSIC.summary
    )

    current_y =
        current_y
        + (
            25
            * user_scale
        )

    if ctx.database_error ~= "" then

        d2d.text(
            fontset.material,
            "DATABASE ERROR",
            content_x,
            current_y,
            CLASSIC.text
        )

        d2d.text(
            fontset.source,
            ctx.database_error,
            content_x,
            current_y
                + (
                    25
                    * user_scale
                ),
            CLASSIC.meta
        )

        return
    end

    if #ctx.active == 0 then

        d2d.text(
            fontset.material,
            "Wishlist is empty.",
            content_x,
            current_y
                + (
                    10
                    * user_scale
                ),
            CLASSIC.text
        )

        return
    end

    local item_x =
        content_x
        + (11 * rs)

    local meta_x =
        content_x
        + (22 * rs)

    local source_w =
        hud_w
        - (
            (
                CLASSIC.inset
                + 42
            )
            * rs
        )

    for _, entry
        in ipairs(ctx.active)
    do

        local material =
            entry.material

        current_y =
            current_y
            + (
                CLASSIC.item_top
                * rs
            )

        local lines =
            source_lines(
                material,
                fontset.source,
                source_w
            )

        local block_h =
            (
                CLASSIC.material_line
                * user_scale
            )
            + (
                CLASSIC.meta_line
                * user_scale
            )
            + (
                #lines
                * CLASSIC.meta_line
                * user_scale
            )

        d2d.fill_rect(
            content_x,
            current_y
                + (2 * rs),
            math.max(
                2,
                3 * rs
            ),
            block_h
                - (3 * rs),
            CLASSIC.accent
        )

        d2d.text(
            fontset.material,
            material.name
                .. "  x"
                .. tostring(
                    entry.amount
                ),
            item_x,
            current_y,
            CLASSIC.text
        )

        current_y =
            current_y
            + (
                CLASSIC.material_line
                * user_scale
            )

        d2d.text(
            fontset.meta,
            material.levels,
            meta_x,
            current_y,
            CLASSIC.meta
        )

        current_y =
            current_y
            + (
                CLASSIC.meta_line
                * user_scale
            )

        for _, line
            in ipairs(lines)
        do

            d2d.text(
                fontset.source,
                line,
                meta_x,
                current_y,
                CLASSIC.source
            )

            current_y =
                current_y
                + (
                    CLASSIC.meta_line
                    * user_scale
                )
        end

        current_y =
            current_y
            + (
                CLASSIC.item_bottom
                * rs
            )
    end
end


------------------------------------------------------------
-- EMERGENCY NON-D2D FALLBACK
------------------------------------------------------------

function Style.draw_emergency_classic(ctx)

    local width = 560

    local x, y =
        ctx.x,
        ctx.y

    local active =
        ctx.active
        or {}

    local line_h = 19
    local height = 64

    for _, entry
        in ipairs(active)
    do

        height =
            height
            + 62
            + (
                #(
                    entry.material.source_lines
                    or {}
                )
                * line_h
            )
    end

    if #active == 0 then
        height = 105
    end

    draw.filled_rect(
        x - 8,
        y - 6,
        width,
        height,
        0xD0080D10
    )

    draw.filled_rect(
        x - 8,
        y - 6,
        width,
        38,
        0xE0185564
    )

    draw.filled_rect(
        x + 10,
        y + 34,
        width - 36,
        2,
        0xFF4BC4D8
    )

    draw.text(
        "ANOMALY MATERIAL WISHLIST",
        x + 10,
        y + 3,
        0xFFEAFDFF
    )

    draw.text(
        tostring(
            ctx.item_count
        )
            .. " materials | "
            .. tostring(
                ctx.total_count
            )
            .. " items remaining",
        x + 10,
        y + 42,
        0xFF72D3E4
    )

    local cy =
        y + 70

    if ctx.database_error ~= "" then

        draw.text(
            "DATABASE ERROR: "
                .. ctx.database_error,
            x + 10,
            cy,
            0xFFFFFFFF
        )

        return
    end

    if #active == 0 then

        draw.text(
            "Wishlist is empty.",
            x + 10,
            cy,
            0xFFFFFFFF
        )

        return
    end

    for _, entry
        in ipairs(active)
    do

        local m =
            entry.material

        draw.filled_rect(
            x + 10,
            cy + 2,
            3,
            55,
            0xFF47BFD3
        )

        draw.text(
            m.name
                .. " x"
                .. tostring(
                    entry.amount
                ),
            x + 22,
            cy,
            0xFFFFFFFF
        )

        cy =
            cy + 20

        draw.text(
            m.levels,
            x + 32,
            cy,
            0xFFBEC9CD
        )

        cy =
            cy + 19

        local lines =
            m.source_lines
            or {
                m.sources_text
                or ""
            }

        for _, line
            in ipairs(lines)
        do

            draw.text(
                line,
                x + 32,
                cy,
                0xFFC8B99E
            )

            cy =
                cy
                + line_h
        end

        cy =
            cy + 15
    end
end


------------------------------------------------------------
-- D2D REGISTRATION
------------------------------------------------------------

function Style.register_d2d(
    context_provider
)

    if not D2D_AVAILABLE
        or registered
    then
        return
    end

    registered =
        true

    d2d.register(
        function()

            for _, scale
                in ipairs(
                    SCALE_PRESETS
                )
            do

                fonts[
                    string.format(
                        "%.1f",
                        scale
                    )
                ] =
                    make_font_set(
                        scale
                    )
            end
        end,

        function()

            local surface_w,
                  surface_h =
                d2d.surface_size()

            if not finite(surface_w)
                or not finite(surface_h)
            then
                return
            end

            local ctx =
                context_provider(
                    surface_w,
                    surface_h
                )

            if type(ctx) ~= "table"
                or not ctx.visible
                or ctx.ref_open
            then
                return
            end

            if ctx.style == "classic" then

                draw_classic_d2d(
                    ctx,
                    surface_w,
                    surface_h
                )

            else

                draw_rise(
                    ctx,
                    surface_w,
                    surface_h
                )
            end
        end
    )
end


return Style

-- ============================================================
-- END - Anomaly Material Wishlist Style Module v0.6.7
-- ============================================================