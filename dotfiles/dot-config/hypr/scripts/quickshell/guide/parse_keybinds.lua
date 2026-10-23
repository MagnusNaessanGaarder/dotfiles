-- Parses ~/.config/hypr/keybindings.lua by actually running it under a stub
-- `hl` table, so the Guide's Keybinds tab can never drift from the live
-- config the way the old hand-copied list did. Outputs a JSON array of
-- {key, label, cmd} to stdout. `cmd` is a best-effort hyprctl-equivalent
-- shell command for the row's "click to run" action; it is left empty for
-- anything with no safe/unambiguous translation (mouse binds, exit, etc.),
-- which the QML side then renders as non-clickable.

local home = os.getenv("HOME")

local function mk(label, cmd)
    return { label = label, cmd = cmd or "" }
end

-- Serialises a dispatcher argument back to Lua source.
local function ser(v)
    if type(v) == "table" then
        local keys = {}
        for k in pairs(v) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do table.insert(parts, k .. " = " .. ser(v[k])) end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif type(v) == "string" then
        return string.format("%q", v)
    end
    return tostring(v)
end

-- With a Lua config, `hyprctl dispatch` takes a hl.dsp.* expression; the old
-- `hyprctl dispatch workspace 3` form is rejected. Rebuild the same call the
-- keybinding makes and single-quote it for the shell.
local function dispatch(fn, arg)
    local expr = "hl.dsp." .. fn .. "(" .. (arg ~= nil and ser(arg) or "") .. ")"
    return "hyprctl dispatch '" .. (expr:gsub("'", "'\\''")) .. "'"
end

local binds = {}

hl = {}

hl.bind = function(key, act)
    act = act or mk("(unknown)")
    table.insert(binds, { key = tostring(key), label = act.label, cmd = act.cmd })
end

hl.dsp = {}

hl.dsp.exec_cmd = function(cmd)
    return mk(cmd, cmd)
end

hl.dsp.exit = function()
    return mk("Exit Hyprland (Log Out)", "")
end

hl.dsp.focus = function(t)
    t = t or {}
    if t.direction then
        return mk("Focus Window (" .. t.direction .. ")", dispatch("focus", t))
    elseif t.workspace ~= nil then
        return mk("Switch to Workspace " .. tostring(t.workspace), dispatch("focus", t))
    end
    return mk("Focus", "")
end

hl.dsp.workspace = {}
hl.dsp.workspace.toggle_special = function(name)
    return mk("Toggle Special Workspace", dispatch("workspace.toggle_special", name))
end

hl.dsp.window = {}

hl.dsp.window.close = function()
    return mk("Close Active Window", dispatch("window.close"))
end

hl.dsp.window.float = function(t)
    return mk("Toggle Floating", dispatch("window.float", t))
end

hl.dsp.window.fullscreen = function(t)
    t = t or {}
    if t.action == "set" then
        return mk("Set Fullscreen", "")
    end
    return mk("Toggle Fullscreen", dispatch("window.fullscreen", t))
end

hl.dsp.window.resize = function(t)
    if t and t.x and t.y then
        return mk("Resize Window to " .. tostring(t.x) .. "x" .. tostring(t.y), dispatch("window.resize", t))
    end
    return mk("Resize Window (Mouse Drag)", "")
end

hl.dsp.window.center = function()
    return mk("Center Window", dispatch("window.center"))
end

hl.dsp.window.pseudo = function()
    return mk("Toggle Pseudotile", dispatch("window.pseudo"))
end

hl.dsp.window.drag = function()
    return mk("Move Window (Mouse Drag)", "")
end

hl.dsp.window.cycle_next = function()
    return mk("Cycle to Next Window", dispatch("window.cycle_next"))
end

hl.dsp.window.move = function(t)
    t = t or {}
    if t.direction then
        return mk("Move Window (" .. t.direction .. ")", dispatch("window.move", t))
    elseif t.workspace ~= nil then
        return mk("Move Window to Workspace " .. tostring(t.workspace), dispatch("window.move", t))
    end
    return mk("Move Window", "")
end

local ok, err = pcall(dofile, home .. "/.config/hypr/keybindings.lua")
if not ok then
    io.stderr:write("parse_keybinds: failed to load keybindings.lua: " .. tostring(err) .. "\n")
    io.write("[]")
    os.exit(1)
end

local function esc(s)
    s = tostring(s)
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\n', '\\n')
    return s
end

local out = { "[" }
for i, b in ipairs(binds) do
    if i > 1 then table.insert(out, ",") end
    table.insert(out, string.format('{"key":"%s","label":"%s","cmd":"%s"}', esc(b.key), esc(b.label), esc(b.cmd)))
end
table.insert(out, "]")
io.write(table.concat(out))
