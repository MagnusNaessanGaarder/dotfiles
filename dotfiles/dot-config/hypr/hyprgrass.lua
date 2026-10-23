-- Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
-- Translated from dot-config/hypr/hyprgrass.conf
-- Confirmed against horriblename/hyprgrass/docs/configuration.md (the plugin's own
-- Lua migration docs) -- NOT the same guesswork as before, this is the documented API.

-- Documented plugin options (only these four are documented -- workspace_swipe_fingers,
-- workspace_swipe_edge, emulate_touchpad_swipe, and the "experimental" block from the old
-- .conf do NOT appear in the plugin's current Lua docs. They may have been removed/renamed
-- in the Lua rewrite. Left out below rather than guessed -- check
-- https://github.com/horriblename/hyprgrass/blob/main/docs/lua_migration.md if you relied on them.)
local function setup_hyprgrass()
	if hl.plugin.hyprgrass == nil then
		return
	end

	hl.config({
		plugin = {
			hyprgrass = {
				sensitivity = 4.0,
				long_press_delay = 400,
				resize_on_border_long_press = true,
				edge_margin = 10,
			},
		},
	})

	-- Hyprland's own gesture settings the hyprgrass docs recommend alongside it
	hl.config({
		gestures = {
			workspace_swipe_touch = true,
			workspace_swipe_cancel_ratio = 0.15,
		},
	})

	-- swipe left from right edge: hyprgrass-bind = , edge:r:l, workspace, +1
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "edge", origin = "right", direction = "left" },
		action = hl.dsp.focus({ workspace = "+1" }),
	})

	-- hyprgrass-bind = , edge:l:r, workspace, -1
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "edge", origin = "left", direction = "right" },
		action = hl.dsp.focus({ workspace = "-1" }),
	})

	-- swipe down from right edge: hyprgrass-bind = , edge:r:d, exec, pamixer -d 10
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "edge", origin = "right", direction = "down" },
		action = hl.dsp.exec_cmd("pamixer -d 10"),
	})

	-- hyprgrass-bind = , edge:r:u, exec, pamixer -i 10
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "edge", origin = "right", direction = "up" },
		action = hl.dsp.exec_cmd("pamixer -i 10"),
	})

	-- tap with 3 fingers: hyprgrass-bind = , tap:3, exec, wofi
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "tap", fingers = 3 },
		action = hl.dsp.exec_cmd("wofi"),
	})

	-- hyprgrass-bindm = , longpress:2, movewindow
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "longpress", fingers = 2 },
		action = hl.dsp.window.drag(),
		mouse = true,
	})

	-- hyprgrass-bindm = , longpress:3, resizewindow
	hl.plugin.hyprgrass.bind({
		pattern = { kind = "longpress", fingers = 3 },
		action = hl.dsp.window.resize(),
		mouse = true,
	})
end

setup_hyprgrass()
hl.on("config.reloaded", setup_hyprgrass)
