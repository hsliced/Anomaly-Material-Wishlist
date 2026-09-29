-- ============================================================
-- Anomaly Material Wishlist
-- Version: v0.6.6
--
-- v0.6.6
--   - Renamed user-facing mod UI to Anomaly Material Wishlist
--   - Wishlist editor instructions moved into window title
--   - Removed redundant legacy reset-position button
--   - Reset wishlist position now uses the top-right default
--   - Added bottom breathing room to Wishlist editor
--   - Retains Direct2D Rise and Classic HUD styles
--   - Retains user-adjustable HUD text size
--   - Retains fixed-width, height-resizable Material Counts
--   - Retains persistent positions/sizes
--   - Retains shared F8 and Auto-show after save loads
--   - Retains external JSON material database
--
-- ZIP structure:
--   vortex_override_instructions.json
--   reframework/
--   ├─ autorun/
--   │  ├─ SmithyAnomaly.lua
--   │  └─ SmithyAnomalyStyle.lua
--   └─ data/
--      └─ SmithyAnomalyData.json
-- ============================================================

local MOD_NAME = "Anomaly Material Wishlist"
local VERSION = "0.6.6"

local style_ok, Style =
    pcall(
        require,
        "SmithyAnomalyStyle"
    )

if not style_ok
    or type(Style) ~= "table"
then
    Style = nil

    log.error(
        "[" ..
        MOD_NAME ..
        "] Could not load SmithyAnomalyStyle.lua: " ..
        tostring(
            style_ok
            and "invalid module"
            or Style
        )
    )
end

local DATABASE_PATHS = {
    "SmithyAnomalyData.json",
    "data/SmithyAnomalyData.json",
    "reframework/data/SmithyAnomalyData.json"
}

local WISHLIST_JSON =
    "smithy_anomaly_wishlist.json"

local SETTINGS_JSON =
    "smithy_anomaly_settings.json"

local PROBE_JSON =
    "smithy_anomaly_probe_v0.6.6.json"


local function attempt(fn)

    local ok, value =
        pcall(fn)

    if ok then
        return value
    end

    return nil
end


local function finite(n)

    return
        type(n) == "number"
        and n == n
        and math.abs(n) < 10000000
end


local function clamp(
    v,
    lo,
    hi
)

    if v < lo then
        return lo
    end

    if v > hi then
        return hi
    end

    return v
end


------------------------------------------------------------
-- DATABASE
------------------------------------------------------------

local database = nil
local families = {}

local database_revision =
    "NOT LOADED"

local database_error =
    ""

local database_loaded_path =
    "NONE"


local function validate_database(data)

    if type(data) ~= "table" then
        return false,
            "Database root is not a table."
    end

    if type(data.families) ~= "table" then
        return false,
            "Database is missing families."
    end

    if #data.families == 0 then
        return false,
            "Database families list is empty."
    end

    for fi, family
        in ipairs(data.families)
    do

        if type(family) ~= "table" then
            return false,
                "Family " ..
                tostring(fi) ..
                " is invalid."
        end

        if type(family.title) ~= "string" then
            return false,
                "Family " ..
                tostring(fi) ..
                " has no title."
        end

        if type(family.tiers) ~= "table" then
            return false,
                "Family " ..
                family.title ..
                " has no tiers."
        end

        for ti, material
            in ipairs(family.tiers)
        do

            if type(material) ~= "table" then
                return false,
                    family.title ..
                    " tier " ..
                    tostring(ti) ..
                    " is invalid."
            end

            if type(material.name) ~= "string" then
                return false,
                    family.title ..
                    " tier " ..
                    tostring(ti) ..
                    " has no material name."
            end

            if type(material.short) ~= "string" then
                return false,
                    material.name ..
                    " has no short name."
            end

            if type(material.levels) ~= "string" then
                return false,
                    material.name ..
                    " has no level range."
            end

            if type(material.sources) ~= "table" then
                return false,
                    material.name ..
                    " has no source list."
            end
        end
    end

    return true, ""
end


local function load_database()

    database = nil
    families = {}

    database_revision =
        "NOT LOADED"

    database_loaded_path =
        "NONE"

    database_error =
        ""

    local found_data = nil
    local found_path = nil

    for _, path
        in ipairs(DATABASE_PATHS)
    do

        local data =
            attempt(function()

                return
                    json.load_file(
                        path
                    )

            end)

        if type(data) == "table" then

            found_data = data
            found_path = path

            break
        end
    end

    if found_data == nil then

        database_error =
            "Could not load SmithyAnomalyData.json from reframework/data."

        return false
    end

    local valid,
          reason =
        validate_database(
            found_data
        )

    if not valid then

        database_revision =
            "INVALID"

        database_loaded_path =
            tostring(
                found_path
                or "UNKNOWN"
            )

        database_error =
            reason

        return false
    end

    database =
        found_data

    families =
        found_data.families

    database_revision =
        tostring(
            found_data.revision
            or "UNVERSIONED"
        )

    database_loaded_path =
        tostring(
            found_path
            or "UNKNOWN"
        )

    log.info(
        "[" ..
        MOD_NAME ..
        "] Loaded material database: " ..
        database_loaded_path ..
        " | revision " ..
        database_revision
    )

    return true
end


------------------------------------------------------------
-- SOURCE FORMATTING / FALLBACK WRAPPING
------------------------------------------------------------

local SOURCE_WRAP_CHARS = 56


local function wrap_text_lines(
    text,
    max_chars
)

    text =
        tostring(
            text or ""
        )

    max_chars =
        tonumber(max_chars)
        or SOURCE_WRAP_CHARS

    if #text <= max_chars then
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

        if current == "" then

            current =
                word

        elseif #current + 1 + #word
            <= max_chars
        then

            current =
                current ..
                " " ..
                word

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


local function source_text(source)

    if type(source) == "string" then
        return source
    end

    if type(source) ~= "table" then
        return "Unknown"
    end

    local name =
        tostring(
            source.name
            or "Unknown"
        )

    if source.levels ~= nil then

        return
            name ..
            " [" ..
            tostring(
                source.levels
            ) ..
            "]"
    end

    return name
end


local function material_sources_text(material)

    local parts = {}

    for _, source
        in ipairs(
            material.sources
            or {}
        )
    do

        parts[#parts + 1] =
            source_text(
                source
            )
    end

    return
        table.concat(
            parts,
            " | "
        )
end


local function material_source_lines(material)

    return
        wrap_text_lines(
            material_sources_text(
                material
            ),
            SOURCE_WRAP_CHARS
        )
end


------------------------------------------------------------
-- CURSOR HELPERS
------------------------------------------------------------

local function get_cursor_pos()

    return
        attempt(function()

            return
                imgui.get_cursor_pos()

        end)
end


local function set_cursor_pos(
    x,
    y
)

    attempt(function()

        imgui.set_cursor_pos(
            {
                x,
                y
            }
        )

    end)
end


------------------------------------------------------------
-- SHARED OVERLAY / HOTKEYS
------------------------------------------------------------

_G.HSOverlayState =
    _G.HSOverlayState
    or {
        visible = true
    }

local hs =
    _G.HSOverlayState


_G.HSHotkeys =
    _G.HSHotkeys
    or {
        f8_down = false,
        f8_generation = 0
    }

local hs_hotkeys =
    _G.HSHotkeys

local last_f8_generation =
    hs_hotkeys.f8_generation


local function update_shared_f8()

    local key_down =
        attempt(function()

            return
                reframework:is_key_down(
                    0x77
                )

        end) == true

    if key_down
        and not hs_hotkeys.f8_down
    then

        hs_hotkeys.f8_generation =
            hs_hotkeys.f8_generation + 1
    end

    hs_hotkeys.f8_down =
        key_down
end


------------------------------------------------------------
-- STATE
------------------------------------------------------------

local enabled = true
local overlay_visible = false

local auto_open = false
local auto_show_after_save = false

local rise_style_hud = true
local hud_text_scale = 1.0

local hud_position_initialized =
    false

local save_state_initialized =
    false

local save_loaded =
    false


local wishlist_x = 30
local wishlist_y = 180

local wishlist_editor_dismissed =
    false


local DEFAULT_WISHLIST_EDITOR_WIDTH =
    560

local DEFAULT_WISHLIST_EDITOR_HEIGHT =
    560

local wishlist_editor_width =
    DEFAULT_WISHLIST_EDITOR_WIDTH

local wishlist_editor_height_saved =
    DEFAULT_WISHLIST_EDITOR_HEIGHT


local material_editor_x = 650
local material_editor_y = 180

local material_editor_open =
    false

local DEFAULT_MATERIAL_EDITOR_HEIGHT =
    760

local MIN_MATERIAL_EDITOR_HEIGHT =
    360

local MAX_MATERIAL_EDITOR_HEIGHT =
    1400

local material_editor_height =
    DEFAULT_MATERIAL_EDITOR_HEIGHT


local POSITION_APPLY_FRAMES = 3
local SIZE_APPLY_FRAMES = 3

local wishlist_position_frames =
    POSITION_APPLY_FRAMES

local wishlist_size_frames =
    SIZE_APPLY_FRAMES

local material_position_frames =
    POSITION_APPLY_FRAMES

local material_size_frames =
    SIZE_APPLY_FRAMES


local wishlist = {}

local snapshots = {}
local probe_enabled = false

local clear_confirmation_open =
    false


------------------------------------------------------------
-- MATERIAL EDITOR LAYOUT
------------------------------------------------------------

local FAMILY_COLUMNS = 4

local MATERIAL_LABEL_WIDTH = 130
local COUNT_WIDTH = 22

local FAMILY_COLUMN_PITCH = 205
local FAMILY_BAND_GAP = 18

local MATERIAL_EDITOR_WIDTH =
    FAMILY_COLUMN_PITCH *
    FAMILY_COLUMNS +
    20

local CLEAR_CONFIRM_RESERVED_LINES =
    4

local EDITOR_META_PREFIX =
    "    "

local EDITOR_ITEM_SPACING =
    5


------------------------------------------------------------
-- WISHLIST PERSISTENCE / HELPERS
------------------------------------------------------------

local function save_wishlist()

    pcall(function()

        json.dump_file(
            WISHLIST_JSON,
            {
                schema_version = 1,

                mod =
                    MOD_NAME,

                last_ui_version =
                    VERSION,

                last_database_revision =
                    database_revision,

                wishlist =
                    wishlist
            }
        )

    end)
end


local function get_count(name)

    return
        wishlist[name]
        or 0
end


local function set_count(
    name,
    value
)

    value =
        math.max(
            0,
            tonumber(value)
            or 0
        )

    if value == 0 then
        wishlist[name] =
            nil
    else
        wishlist[name] =
            value
    end
end


local function add_one(name)

    set_count(
        name,
        get_count(name) + 1
    )

    save_wishlist()
end


local function subtract_one(name)

    set_count(
        name,
        get_count(name) - 1
    )

    save_wishlist()
end


local function complete_material(name)

    set_count(
        name,
        0
    )

    save_wishlist()
end


local function clear_entire_wishlist()

    wishlist = {}

    clear_confirmation_open =
        false

    save_wishlist()
end


local function wishlist_item_count()

    local count = 0

    for _, amount
        in pairs(wishlist)
    do

        if amount > 0 then
            count =
                count + 1
        end
    end

    return count
end


local function wishlist_total_count()

    local total = 0

    for _, amount
        in pairs(wishlist)
    do

        total =
            total +
            amount
    end

    return total
end


local function active_wishlist()

    local result = {}

    for _, family
        in ipairs(families)
    do

        for _, material
            in ipairs(
                family.tiers
            )
        do

            local amount =
                get_count(
                    material.name
                )

            if amount > 0 then

                result[#result + 1] = {
                    material = material,
                    amount = amount
                }
            end
        end
    end

    return result
end


local function load_wishlist()

    local data =
        attempt(function()

            return
                json.load_file(
                    WISHLIST_JSON
                )

        end)

    if type(data) == "table"
        and type(data.wishlist) == "table"
    then

        wishlist =
            data.wishlist
    end
end


------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

local function save_settings()

    pcall(function()

        json.dump_file(
            SETTINGS_JSON,
            {
                schema_version = 26,

                enabled =
                    enabled,

                auto_open =
                    auto_open,

                auto_show_after_save =
                    auto_show_after_save,

                rise_style_hud =
                    rise_style_hud,

                hud_text_scale =
                    hud_text_scale,

                hud_position_initialized =
                    hud_position_initialized,

                wishlist_x =
                    wishlist_x,

                wishlist_y =
                    wishlist_y,

                wishlist_editor_width =
                    wishlist_editor_width,

                wishlist_editor_height =
                    wishlist_editor_height_saved,

                material_editor_x =
                    material_editor_x,

                material_editor_y =
                    material_editor_y,

                material_editor_height =
                    material_editor_height,

                material_editor_open =
                    material_editor_open
            }
        )

    end)
end


local function load_settings()

    local data =
        attempt(function()

            return
                json.load_file(
                    SETTINGS_JSON
                )

        end)

    if type(data) ~= "table" then

        hud_position_initialized =
            false

        return
    end

    if type(data.enabled) ==
        "boolean"
    then
        enabled =
            data.enabled
    end

    if type(data.auto_open) ==
        "boolean"
    then
        auto_open =
            data.auto_open
    end

    if type(
        data.auto_show_after_save
    ) == "boolean"
    then
        auto_show_after_save =
            data.auto_show_after_save
    end

    if type(
        data.rise_style_hud
    ) == "boolean"
    then
        rise_style_hud =
            data.rise_style_hud
    end

    if finite(
        data.hud_text_scale
    ) then

        hud_text_scale =
            Style
            and Style.normalize_text_scale(
                data.hud_text_scale
            )
            or clamp(
                data.hud_text_scale,
                0.8,
                1.4
            )
    end

    local found_saved_position =
        false

    if finite(
        data.wishlist_x
    ) then

        wishlist_x =
            math.floor(
                data.wishlist_x
            )

        found_saved_position =
            true

    elseif finite(
        data.panel_x
    ) then

        wishlist_x =
            math.floor(
                data.panel_x
            )

        found_saved_position =
            true
    end

    if finite(
        data.wishlist_y
    ) then

        wishlist_y =
            math.floor(
                data.wishlist_y
            )

        found_saved_position =
            true

    elseif finite(
        data.panel_y
    ) then

        wishlist_y =
            math.floor(
                data.panel_y
            )

        found_saved_position =
            true
    end

    if type(
        data.hud_position_initialized
    ) == "boolean"
    then

        hud_position_initialized =
            data.hud_position_initialized

    elseif found_saved_position then

        hud_position_initialized =
            true
    end

    if finite(
        data.wishlist_editor_width
    ) then

        wishlist_editor_width =
            math.max(
                320,
                math.floor(
                    data.wishlist_editor_width
                )
            )
    end

    if finite(
        data.wishlist_editor_height
    ) then

        wishlist_editor_height_saved =
            math.max(
                240,
                math.floor(
                    data.wishlist_editor_height
                )
            )
    end

    if finite(
        data.material_editor_x
    ) then

        material_editor_x =
            math.floor(
                data.material_editor_x
            )
    end

    if finite(
        data.material_editor_y
    ) then

        material_editor_y =
            math.floor(
                data.material_editor_y
            )
    end

    if finite(
        data.material_editor_height
    ) then

        material_editor_height =
            clamp(
                math.floor(
                    data.material_editor_height
                ),
                MIN_MATERIAL_EDITOR_HEIGHT,
                MAX_MATERIAL_EDITOR_HEIGHT
            )
    end

    if type(
        data.material_editor_open
    ) == "boolean"
    then

        material_editor_open =
            data.material_editor_open
    end

    wishlist_position_frames =
        POSITION_APPLY_FRAMES

    wishlist_size_frames =
        SIZE_APPLY_FRAMES

    material_position_frames =
        POSITION_APPLY_FRAMES

    material_size_frames =
        SIZE_APPLY_FRAMES
end


------------------------------------------------------------
-- PROBE
------------------------------------------------------------

local function get_singleton(type_name)

    return
        attempt(function()

            return
                sdk.get_managed_singleton(
                    type_name
                )

        end)
end


local function save_probe()

    pcall(function()

        json.dump_file(
            PROBE_JSON,
            {
                mod =
                    MOD_NAME,

                version =
                    VERSION,

                database_revision =
                    database_revision,

                database_loaded_path =
                    database_loaded_path,

                database_error =
                    database_error,

                style_module_loaded =
                    Style ~= nil,

                direct2d_available =
                    Style
                    and Style.d2d_available()
                    or false,

                rise_style_hud =
                    rise_style_hud,

                hud_text_scale =
                    hud_text_scale,

                hud_position_initialized =
                    hud_position_initialized,

                auto_show_after_save =
                    auto_show_after_save,

                save_loaded =
                    save_loaded,

                shared_f8_generation =
                    hs_hotkeys.f8_generation,

                last_f8_generation =
                    last_f8_generation,

                wishlist_x =
                    wishlist_x,

                wishlist_y =
                    wishlist_y,

                wishlist_editor_width =
                    wishlist_editor_width,

                wishlist_editor_height =
                    wishlist_editor_height_saved,

                material_editor_x =
                    material_editor_x,

                material_editor_y =
                    material_editor_y,

                material_editor_height =
                    material_editor_height,

                material_editor_open =
                    material_editor_open,

                snapshot_count =
                    #snapshots,

                snapshots =
                    snapshots
            }
        )

    end)
end


local function capture_probe(reason)

    table.insert(
        snapshots,
        {
            timestamp =
                os.date(
                    "%Y-%m-%d %H:%M:%S"
                ),

            reason =
                reason
                or "manual",

            database_revision =
                database_revision,

            database_loaded_path =
                database_loaded_path,

            rise_style_hud =
                rise_style_hud,

            hud_text_scale =
                hud_text_scale,

            hud_position_initialized =
                hud_position_initialized,

            auto_show_after_save =
                auto_show_after_save,

            save_loaded =
                save_loaded,

            shared_f8_generation =
                hs_hotkeys.f8_generation,

            wishlist_x =
                wishlist_x,

            wishlist_y =
                wishlist_y,

            wishlist_editor_width =
                wishlist_editor_width,

            wishlist_editor_height =
                wishlist_editor_height_saved,

            material_editor_x =
                material_editor_x,

            material_editor_y =
                material_editor_y,

            material_editor_height =
                material_editor_height,

            gui_found =
                get_singleton(
                    "snow.gui.GuiManager"
                ) ~= nil,

            player_manager_found =
                get_singleton(
                    "snow.player.PlayerManager"
                ) ~= nil,

            equip_data_found =
                get_singleton(
                    "snow.data.EquipDataManager"
                ) ~= nil,

            data_manager_found =
                get_singleton(
                    "snow.data.DataManager"
                ) ~= nil
        }
    )

    if #snapshots > 100 then

        table.remove(
            snapshots,
            1
        )
    end

    save_probe()
end


------------------------------------------------------------
-- VISIBILITY / SAVE STATE
------------------------------------------------------------

local function visible_now()

    return
        enabled
        and overlay_visible
end


local function set_visibility(value)

    overlay_visible =
        value == true

    hs.visible =
        overlay_visible
end


local function get_master_player()

    local pm =
        attempt(function()

            return
                sdk.get_managed_singleton(
                    "snow.player.PlayerManager"
                )

        end)

    if pm == nil then
        return nil
    end

    return
        attempt(function()

            return
                pm:call(
                    "findMasterPlayer"
                )

        end)
end


local function detect_save_loaded()

    return
        get_master_player() ~= nil
end


local function update_save_visibility()

    local currently_loaded =
        detect_save_loaded()

    if not save_state_initialized then

        save_state_initialized =
            true

        save_loaded =
            currently_loaded

        if auto_show_after_save then
            set_visibility(
                save_loaded
            )
        end

        return
    end

    if currently_loaded ==
        save_loaded
    then
        return
    end

    local was_loaded =
        save_loaded

    save_loaded =
        currently_loaded

    if auto_show_after_save then

        if not was_loaded
            and save_loaded
        then

            set_visibility(
                true
            )

        elseif was_loaded
            and not save_loaded
        then

            set_visibility(
                false
            )
        end
    end

    log.info(
        "[" ..
        MOD_NAME ..
        "] Save state changed: " ..
        tostring(
            was_loaded
        ) ..
        " -> " ..
        tostring(
            save_loaded
        )
    )
end


local function process_shared_f8()

    update_shared_f8()

    if hs_hotkeys.f8_generation ==
        last_f8_generation
    then
        return
    end

    last_f8_generation =
        hs_hotkeys.f8_generation

    set_visibility(
        not visible_now()
    )
end


------------------------------------------------------------
-- UI HELPERS
------------------------------------------------------------

local function editor_item_gap()

    for _ = 1,
        EDITOR_ITEM_SPACING
    do

        imgui.spacing()
    end
end


local function draw_database_error()

    imgui.text(
        "DATABASE ERROR"
    )

    imgui.text(
        database_error
    )

    imgui.text(
        "Expected location:"
    )

    imgui.text(
        "reframework/data/SmithyAnomalyData.json"
    )

    imgui.text(
        "Material lookup is disabled until the database loads."
    )
end


local function draw_clear_confirmation_area(
    suffix
)

    suffix =
        tostring(
            suffix or ""
        )

    if clear_confirmation_open then

        imgui.text(
            "Clear the entire wishlist?"
        )

        if imgui.button(
            "Cancel##clear_wishlist_cancel_" ..
            suffix
        ) then

            clear_confirmation_open =
                false
        end

        imgui.same_line()

        if imgui.button(
            "Clear All##clear_wishlist_confirm_" ..
            suffix
        ) then

            clear_entire_wishlist()
        end

        imgui.spacing()
        imgui.spacing()

    else

        if imgui.button(
            "Clear Entire Wishlist##clear_wishlist_open_" ..
            suffix
        ) then

            clear_confirmation_open =
                true
        end

        for _ = 1,
            CLEAR_CONFIRM_RESERVED_LINES
        do

            imgui.spacing()
        end
    end
end


local function draw_wishlist_entry(
    entry,
    item_index
)

    local material =
        entry.material

    imgui.text(
        material.name ..
        " x" ..
        tostring(
            entry.amount
        )
    )

    imgui.same_line()

    if imgui.button(
        "Done##wishlist_done_" ..
        tostring(item_index)
    ) then

        complete_material(
            material.name
        )

        return true
    end

    imgui.text(
        EDITOR_META_PREFIX ..
        material.levels
    )

    for _, line
        in ipairs(
            material_source_lines(
                material
            )
        )
    do

        imgui.text(
            EDITOR_META_PREFIX ..
            line
        )
    end

    editor_item_gap()

    return false
end


local function draw_wishlist_preview()

    local active =
        active_wishlist()

    imgui.text(
        "ANOMALY MATERIAL WISHLIST"
    )

    imgui.spacing()
    imgui.spacing()

    if database_error ~= "" then

        draw_database_error()

        return
    end

    if #active == 0 then

        imgui.text(
            "Wishlist is empty."
        )

        return
    end

    for item_index, entry
        in ipairs(active)
    do

        if draw_wishlist_entry(
            entry,
            item_index
        ) then

            break
        end
    end
end


local function change_text_scale(direction)

    if Style then

        hud_text_scale =
            Style.next_text_scale(
                hud_text_scale,
                direction
            )

    else

        hud_text_scale =
            clamp(
                math.floor(
                    (
                        hud_text_scale
                        + direction * 0.1
                    )
                    * 10
                    + 0.5
                ) / 10,
                0.8,
                1.4
            )
    end

    save_settings()
end


local function draw_visibility_controls()

    imgui.text(
        "DISPLAY"
    )

    local changed,
          value =
        imgui.checkbox(
            "Visible now (F8)",
            overlay_visible
        )

    if changed then

        set_visibility(
            value
        )
    end

    changed,
    value =
        imgui.checkbox(
            "Auto-show after save loads",
            auto_show_after_save
        )

    if changed then

        auto_show_after_save =
            value

        save_state_initialized =
            false

        update_save_visibility()

        save_settings()
    end

    if auto_show_after_save then

        imgui.text(
            "Auto: hidden until your save loads. F8 still toggles it."
        )

    else

        changed,
        value =
            imgui.checkbox(
                "Show on script load (manual mode)",
                auto_open
            )

        if changed then

            auto_open =
                value

            save_settings()
        end
    end

    changed,
    value =
        imgui.checkbox(
            "Rise-style passive HUD",
            rise_style_hud
        )

    if changed then

        rise_style_hud =
            value

        save_settings()
    end

    imgui.text(
        "HUD text size"
    )

    if imgui.button(
        "-##hud_text_scale"
    ) then

        change_text_scale(
            -1
        )
    end

    imgui.same_line()

    imgui.text(
        string.format(
            "%.1fx",
            hud_text_scale
        )
    )

    imgui.same_line()

    if imgui.button(
        "+##hud_text_scale"
    ) then

        change_text_scale(
            1
        )
    end

    imgui.same_line()

    if imgui.button(
        "Reset##hud_text_scale"
    ) then

        hud_text_scale =
            1.0

        save_settings()
    end

    if not Style then

        imgui.text(
            "Style module unavailable: emergency renderer active."
        )

    elseif not Style.d2d_available() then

        imgui.text(
            "Direct2D unavailable: emergency Classic renderer active."
        )
    end
end


local function draw_wishlist_controls()

    imgui.spacing()
    imgui.spacing()

    if imgui.button(
        "Edit Material Counts"
    ) then

        material_editor_open =
            true

        material_position_frames =
            POSITION_APPLY_FRAMES

        material_size_frames =
            SIZE_APPLY_FRAMES

        save_settings()
    end

    imgui.spacing()
    imgui.spacing()
    imgui.spacing()

    draw_visibility_controls()

    imgui.spacing()
    imgui.spacing()
    imgui.spacing()

    draw_clear_confirmation_area(
        "wishlist"
    )

    imgui.spacing()
    imgui.spacing()
end


------------------------------------------------------------
-- MATERIAL EDITOR
------------------------------------------------------------

local function draw_material_row(
    material,
    family_index,
    tier_index
)

    local amount =
        get_count(
            material.name
        )

    if imgui.button(
        material.short ..
        "##label_" ..
        tostring(family_index) ..
        "_" ..
        tostring(tier_index),
        MATERIAL_LABEL_WIDTH,
        0
    ) then

        add_one(
            material.name
        )

        amount =
            get_count(
                material.name
            )
    end

    imgui.same_line()

    if imgui.button(
        "-##minus_" ..
        tostring(family_index) ..
        "_" ..
        tostring(tier_index)
    ) then

        subtract_one(
            material.name
        )

        amount =
            get_count(
                material.name
            )
    end

    imgui.same_line()

    imgui.button(
        tostring(amount) ..
        "##count_" ..
        tostring(family_index) ..
        "_" ..
        tostring(tier_index),
        COUNT_WIDTH,
        0
    )

    imgui.same_line()

    if imgui.button(
        "+##plus_" ..
        tostring(family_index) ..
        "_" ..
        tostring(tier_index)
    ) then

        add_one(
            material.name
        )
    end
end


local function draw_family_card(
    family,
    family_index
)

    imgui.begin_group()

    imgui.text(
        family.title
    )

    imgui.spacing()

    for tier_index, material
        in ipairs(
            family.tiers
        )
    do

        draw_material_row(
            material,
            family_index,
            tier_index
        )
    end

    imgui.end_group()
end


local function draw_family_band(
    first_family_index
)

    local start =
        get_cursor_pos()

    if not start then

        for offset = 0,
            FAMILY_COLUMNS - 1
        do

            local idx =
                first_family_index +
                offset

            local family =
                families[idx]

            if family then

                draw_family_card(
                    family,
                    idx
                )

                if offset <
                    FAMILY_COLUMNS - 1
                then

                    imgui.same_line()
                end
            end
        end

        imgui.spacing()
        imgui.spacing()
        imgui.spacing()

        return
    end

    local base_x =
        start.x
        or start[1]
        or 0

    local base_y =
        start.y
        or start[2]
        or 0

    local max_end_y =
        base_y

    for column = 1,
        FAMILY_COLUMNS
    do

        local idx =
            first_family_index +
            column - 1

        local family =
            families[idx]

        if family then

            set_cursor_pos(
                base_x +
                (
                    column - 1
                ) *
                FAMILY_COLUMN_PITCH,
                base_y
            )

            draw_family_card(
                family,
                idx
            )

            local after =
                get_cursor_pos()

            if after then

                local ay =
                    after.y
                    or after[2]
                    or base_y

                if ay >
                    max_end_y
                then

                    max_end_y =
                        ay
                end
            end
        end
    end

    set_cursor_pos(
        base_x,
        max_end_y +
        FAMILY_BAND_GAP
    )
end


local function draw_material_editor_content()

    if database_error ~= "" then

        draw_database_error()

        return
    end

    imgui.text(
        "MATERIAL COUNTS"
    )

    imgui.text(
        "Click a material name or + to add one. Use - to subtract."
    )

    imgui.spacing()
    imgui.spacing()

    local family_index = 1

    while family_index <=
        #families
    do

        draw_family_band(
            family_index
        )

        family_index =
            family_index +
            FAMILY_COLUMNS
    end

    imgui.spacing()
    imgui.spacing()
    imgui.spacing()

    draw_clear_confirmation_area(
        "material_editor"
    )

    imgui.spacing()
    imgui.spacing()
    imgui.spacing()
end


------------------------------------------------------------
-- WISHLIST EDITOR WINDOW
------------------------------------------------------------

local function draw_wishlist_editor()

    local ref_open =
        reframework:is_drawing_ui()

    if not ref_open then

        wishlist_editor_dismissed =
            false

        wishlist_position_frames =
            POSITION_APPLY_FRAMES

        wishlist_size_frames =
            SIZE_APPLY_FRAMES

        return
    end

    if not enabled
        or wishlist_editor_dismissed
    then
        return
    end

    if wishlist_position_frames > 0 then

        imgui.set_next_window_pos(
            {
                wishlist_x - 8,
                wishlist_y - 6
            },
            1
        )

        wishlist_position_frames =
            wishlist_position_frames - 1
    end

    if wishlist_size_frames > 0 then

        imgui.set_next_window_size(
            {
                wishlist_editor_width,
                wishlist_editor_height_saved
            },
            1
        )

        wishlist_size_frames =
            wishlist_size_frames - 1
    end

    local open =
        imgui.begin_window(
            "Anomaly Material Wishlist - drag title bar to move / edges to resize",
            true,
            288
        )

    local ok, err =
        pcall(function()

            local pos =
                imgui.get_window_pos()

            if wishlist_position_frames <= 0
                and pos
                and finite(pos.x)
                and finite(pos.y)
            then

                local new_x =
                    math.max(
                        8,
                        math.floor(
                            pos.x + 8
                        )
                    )

                local new_y =
                    math.max(
                        6,
                        math.floor(
                            pos.y + 6
                        )
                    )

                if new_x ~= wishlist_x
                    or new_y ~= wishlist_y
                then

                    wishlist_x =
                        new_x

                    wishlist_y =
                        new_y

                    hud_position_initialized =
                        true

                    save_settings()
                end
            end

            local size =
                attempt(function()

                    return
                        imgui.get_window_size()

                end)

            if wishlist_size_frames <= 0
                and size
            then

                local width =
                    size.x
                    or size[1]

                local height =
                    size.y
                    or size[2]

                if finite(width)
                    and finite(height)
                then

                    local nw =
                        math.max(
                            320,
                            math.floor(
                                width
                            )
                        )

                    local nh =
                        math.max(
                            240,
                            math.floor(
                                height
                            )
                        )

                    if nw ~=
                        wishlist_editor_width
                        or nh ~=
                        wishlist_editor_height_saved
                    then

                        wishlist_editor_width =
                            nw

                        wishlist_editor_height_saved =
                            nh

                        save_settings()
                    end
                end
            end

            if not open then

                wishlist_editor_dismissed =
                    true

                return
            end

            draw_wishlist_preview()
            draw_wishlist_controls()
        end)

    imgui.end_window()

    if not ok then
        error(err)
    end
end


------------------------------------------------------------
-- MATERIAL COUNTS WINDOW
------------------------------------------------------------

local function draw_material_editor_window()

    if not reframework:is_drawing_ui()
        or not enabled
        or not material_editor_open
    then
        return
    end

    if material_position_frames > 0 then

        imgui.set_next_window_pos(
            {
                material_editor_x,
                material_editor_y
            },
            1
        )

        material_position_frames =
            material_position_frames - 1
    end

    if material_size_frames > 0 then

        imgui.set_next_window_size(
            {
                MATERIAL_EDITOR_WIDTH,
                material_editor_height
            },
            1
        )

        material_size_frames =
            material_size_frames - 1
    end

    attempt(function()

        imgui.set_next_window_size_constraints(
            {
                MATERIAL_EDITOR_WIDTH,
                MIN_MATERIAL_EDITOR_HEIGHT
            },
            {
                MATERIAL_EDITOR_WIDTH,
                MAX_MATERIAL_EDITOR_HEIGHT
            }
        )

    end)

    local open =
        imgui.begin_window(
            "Anomaly Material Counts",
            true,
            290
        )

    local ok, err =
        pcall(function()

            local pos =
                imgui.get_window_pos()

            if material_position_frames <= 0
                and pos
                and finite(pos.x)
                and finite(pos.y)
            then

                local nx =
                    math.max(
                        0,
                        math.floor(
                            pos.x
                        )
                    )

                local ny =
                    math.max(
                        0,
                        math.floor(
                            pos.y
                        )
                    )

                if nx ~= material_editor_x
                    or ny ~= material_editor_y
                then

                    material_editor_x =
                        nx

                    material_editor_y =
                        ny

                    save_settings()
                end
            end

            local size =
                attempt(function()

                    return
                        imgui.get_window_size()

                end)

            if material_size_frames <= 0
                and size
            then

                local width =
                    size.x
                    or size[1]

                local height =
                    size.y
                    or size[2]

                if finite(height) then

                    local nh =
                        clamp(
                            math.floor(
                                height
                            ),
                            MIN_MATERIAL_EDITOR_HEIGHT,
                            MAX_MATERIAL_EDITOR_HEIGHT
                        )

                    if nh ~=
                        material_editor_height
                    then

                        material_editor_height =
                            nh

                        save_settings()
                    end
                end

                if finite(width)
                    and math.abs(
                        width -
                        MATERIAL_EDITOR_WIDTH
                    ) > 2
                then

                    imgui.set_next_window_size(
                        {
                            MATERIAL_EDITOR_WIDTH,
                            material_editor_height
                        },
                        1
                    )
                end
            end

            if not open then

                material_editor_open =
                    false

                save_settings()

                return
            end

            draw_material_editor_content()
        end)

    imgui.end_window()

    if not ok then
        error(err)
    end
end


------------------------------------------------------------
-- STYLE CONTEXT / DIRECT2D REGISTRATION
------------------------------------------------------------

local function style_context(
    surface_w,
    surface_h
)

    if not hud_position_initialized
        and Style
    then

        local dx, dy =
            Style.default_position(
                surface_w,
                surface_h
            )

        wishlist_x =
            dx

        wishlist_y =
            dy

        hud_position_initialized =
            true

        wishlist_position_frames =
            POSITION_APPLY_FRAMES

        save_settings()
    end

    local active =
        active_wishlist()

    local styled_active = {}

    for _, entry
        in ipairs(active)
    do

        styled_active[
            #styled_active + 1
        ] = {
            amount =
                entry.amount,

            material = {
                name =
                    entry.material.name,

                levels =
                    entry.material.levels,

                sources_text =
                    material_sources_text(
                        entry.material
                    ),

                source_lines =
                    material_source_lines(
                        entry.material
                    )
            }
        }
    end

    return {
        visible =
            visible_now(),

        ref_open =
            reframework:is_drawing_ui(),

        style =
            rise_style_hud
            and "rise"
            or "classic",

        text_scale =
            hud_text_scale,

        x =
            wishlist_x,

        y =
            wishlist_y,

        active =
            styled_active,

        item_count =
            wishlist_item_count(),

        total_count =
            wishlist_total_count(),

        database_error =
            database_error
    }
end


if Style
    and Style.d2d_available()
then

    Style.register_d2d(
        style_context
    )
end


local function draw_emergency_passive_overlay()

    if reframework:is_drawing_ui()
        or not visible_now()
    then
        return
    end

    if Style
        and Style.d2d_available()
    then
        return
    end

    if Style then

        Style.draw_emergency_classic(
            style_context(
                1920,
                1080
            )
        )

        return
    end

    draw.filled_rect(
        wishlist_x - 8,
        wishlist_y - 6,
        560,
        90,
        0xD0000000
    )

    draw.text(
        "Anomaly Material Wishlist",
        wishlist_x,
        wishlist_y,
        0xFFFFFFFF
    )

    draw.text(
        "Style module missing.",
        wishlist_x,
        wishlist_y + 24,
        0xFFFFFFFF
    )
end


------------------------------------------------------------
-- FRAME LOOP
------------------------------------------------------------

re.on_frame(function()

    update_save_visibility()
    process_shared_f8()

    local ok1,
          err1 =
        pcall(
            draw_wishlist_editor
        )

    if not ok1 then

        wishlist_editor_dismissed =
            true

        log.error(
            "[" ..
            MOD_NAME ..
            "] Wishlist editor error: " ..
            tostring(err1)
        )
    end

    local ok2,
          err2 =
        pcall(
            draw_material_editor_window
        )

    if not ok2 then

        material_editor_open =
            false

        log.error(
            "[" ..
            MOD_NAME ..
            "] Material editor error: " ..
            tostring(err2)
        )
    end

    local ok3,
          err3 =
        pcall(
            draw_emergency_passive_overlay
        )

    if not ok3 then

        log.error(
            "[" ..
            MOD_NAME ..
            "] Passive overlay error: " ..
            tostring(err3)
        )
    end
end)


------------------------------------------------------------
-- SCRIPT GENERATED UI
------------------------------------------------------------

re.on_draw_ui(function()

    if not imgui.tree_node(
        "Anomaly Material Wishlist " ..
        VERSION
    ) then
        return
    end

    local changed,
          value =
        imgui.checkbox(
            "Enable wishlist",
            enabled
        )

    if changed then

        enabled =
            value

        save_settings()
    end

    draw_visibility_controls()

    imgui.spacing()

    imgui.text(
        tostring(
            wishlist_item_count()
        ) ..
        " material types | " ..
        tostring(
            wishlist_total_count()
        ) ..
        " total items"
    )

    if imgui.button(
        "Focus / reopen wishlist"
    ) then

        enabled =
            true

        wishlist_editor_dismissed =
            false

        wishlist_position_frames =
            POSITION_APPLY_FRAMES

        wishlist_size_frames =
            SIZE_APPLY_FRAMES
    end

    imgui.same_line()

    if imgui.button(
        "Open Material Counts"
    ) then

        material_editor_open =
            true

        material_position_frames =
            POSITION_APPLY_FRAMES

        material_size_frames =
            SIZE_APPLY_FRAMES

        save_settings()
    end

    if imgui.button(
        "Reset wishlist position"
    ) then

        hud_position_initialized =
            false

        wishlist_editor_dismissed =
            false

        wishlist_position_frames =
            POSITION_APPLY_FRAMES

        save_settings()
    end

    if imgui.button(
        "Reset wishlist size"
    ) then

        wishlist_editor_width =
            DEFAULT_WISHLIST_EDITOR_WIDTH

        wishlist_editor_height_saved =
            DEFAULT_WISHLIST_EDITOR_HEIGHT

        wishlist_editor_dismissed =
            false

        wishlist_size_frames =
            SIZE_APPLY_FRAMES

        save_settings()
    end

    if imgui.button(
        "Reset material editor"
    ) then

        material_editor_x = 650
        material_editor_y = 180

        material_editor_height =
            DEFAULT_MATERIAL_EDITOR_HEIGHT

        material_editor_open =
            true

        material_position_frames =
            POSITION_APPLY_FRAMES

        material_size_frames =
            SIZE_APPLY_FRAMES

        save_settings()
    end

    if imgui.tree_node(
        "Smithy detection / diagnostics"
    ) then

        imgui.text(
            "Passive HUD"
        )

        imgui.text(
            "Style module loaded: " ..
            tostring(
                Style ~= nil
            )
        )

        imgui.text(
            "Direct2D available: " ..
            tostring(
                Style
                and Style.d2d_available()
                or false
            )
        )

        imgui.text(
            "HUD style: " ..
            (
                rise_style_hud
                and "Rise"
                or "Classic"
            )
        )

        imgui.text(
            "HUD text size: " ..
            string.format(
                "%.1fx",
                hud_text_scale
            )
        )

        imgui.text(
            "Position initialized: " ..
            tostring(
                hud_position_initialized
            )
        )

        imgui.spacing()
        imgui.spacing()

        imgui.text(
            "Material Database"
        )

        imgui.text(
            "Revision: " ..
            database_revision
        )

        imgui.text(
            "Loaded from: " ..
            database_loaded_path
        )

        if database_error ~= "" then

            imgui.text(
                "Status: ERROR"
            )

            imgui.text(
                database_error
            )

        else

            imgui.text(
                "Status: OK"
            )
        end

        if imgui.button(
            "Reload Material Database"
        ) then

            load_database()
            save_wishlist()
        end

        imgui.spacing()
        imgui.spacing()

        imgui.text(
            "Save/player detection"
        )

        imgui.text(
            "Master player found: " ..
            tostring(
                detect_save_loaded()
            )
        )

        imgui.text(
            "Tracked save loaded: " ..
            tostring(
                save_loaded
            )
        )

        imgui.text(
            "Auto-show after save: " ..
            tostring(
                auto_show_after_save
            )
        )

        imgui.spacing()
        imgui.spacing()

        imgui.text(
            "Shared HS hotkeys"
        )

        imgui.text(
            "F8 generation: " ..
            tostring(
                hs_hotkeys.f8_generation
            )
        )

        imgui.text(
            "Last F8 generation processed: " ..
            tostring(
                last_f8_generation
            )
        )

        imgui.text(
            "F8 key down: " ..
            tostring(
                hs_hotkeys.f8_down
            )
        )

        imgui.spacing()
        imgui.spacing()

        imgui.text(
            "Wishlist position: " ..
            tostring(
                wishlist_x
            ) ..
            ", " ..
            tostring(
                wishlist_y
            )
        )

        imgui.text(
            "Wishlist editor size: " ..
            tostring(
                wishlist_editor_width
            ) ..
            " x " ..
            tostring(
                wishlist_editor_height_saved
            )
        )

        imgui.text(
            "Material editor position: " ..
            tostring(
                material_editor_x
            ) ..
            ", " ..
            tostring(
                material_editor_y
            )
        )

        imgui.text(
            "Material editor height: " ..
            tostring(
                material_editor_height
            )
        )

        imgui.text(
            "Material editor fixed width: " ..
            tostring(
                MATERIAL_EDITOR_WIDTH
            )
        )

        imgui.text(
            "Material editor open: " ..
            tostring(
                material_editor_open
            )
        )

        imgui.spacing()
        imgui.spacing()

        imgui.text(
            "Automatic Smithy requirement detection is not implemented yet."
        )

        imgui.text(
            "Native Rise GUI cloning is not implemented yet."
        )

        imgui.spacing()

        changed,
        value =
            imgui.checkbox(
                "Enable Smithy Probe",
                probe_enabled
            )

        if changed then
            probe_enabled =
                value
        end

        if imgui.button(
            "Capture Smithy Probe"
        ) then

            capture_probe(
                "manual"
            )
        end

        imgui.text(
            "Snapshots: " ..
            tostring(
                #snapshots
            )
        )

        imgui.text(
            "Probe JSON: " ..
            PROBE_JSON
        )

        imgui.text(
            "Wishlist JSON: " ..
            WISHLIST_JSON
        )

        imgui.text(
            "Settings JSON: " ..
            SETTINGS_JSON
        )

        imgui.tree_pop()
    end

    imgui.tree_pop()
end)


------------------------------------------------------------
-- INITIALIZE
------------------------------------------------------------

load_database()
load_settings()
load_wishlist()

if auto_show_after_save then

    save_state_initialized =
        false

    update_save_visibility()

else

    overlay_visible =
        auto_open

    hs.visible =
        overlay_visible

    save_loaded =
        detect_save_loaded()

    save_state_initialized =
        true
end

last_f8_generation =
    hs_hotkeys.f8_generation

wishlist_position_frames =
    POSITION_APPLY_FRAMES

wishlist_size_frames =
    SIZE_APPLY_FRAMES

material_position_frames =
    POSITION_APPLY_FRAMES

material_size_frames =
    SIZE_APPLY_FRAMES

save_probe()
save_wishlist()
save_settings()

log.info(
    "[" ..
    MOD_NAME ..
    "] v" ..
    VERSION ..
    " loaded | DB " ..
    database_revision ..
    " | Style module " ..
    tostring(
        Style ~= nil
    ) ..
    " | Direct2D " ..
    tostring(
        Style
        and Style.d2d_available()
        or false
    ) ..
    " | HUD " ..
    (
        rise_style_hud
        and "Rise"
        or "Classic"
    ) ..
    " | Text " ..
    string.format(
        "%.1fx",
        hud_text_scale
    ) ..
    " | Save loaded " ..
    tostring(
        save_loaded
    )
)

if database_error ~= "" then

    log.error(
        "[" ..
        MOD_NAME ..
        "] Database error: " ..
        database_error
    )
end

-- ============================================================
-- END - Anomaly Material Wishlist v0.6.6
-- ============================================================