-- Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
-- Translated from dot-config/hypr/animations.conf
-- Pattern confirmed against Hyprland's official example hyprland.lua

hl.curve("wind",   { type = "bezier", points = { {0.1, 0.9}, {0.1, 1} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1, 1.05}, {0.1, 1} } })
hl.curve("winOut", { type = "bezier", points = { {0.3, 0.2}, {0.05, 1} } })
hl.curve("liner",  { type = "bezier", points = { {1, 1}, {1, 1} } })

hl.config({
    animations = {
        enabled = true,
    },
})

hl.animation({ leaf = "windows",     enabled = true, speed = 2.5, bezier = "wind",   style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.5, bezier = "winIn",  style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "wind",   style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2.5, bezier = "wind" })
