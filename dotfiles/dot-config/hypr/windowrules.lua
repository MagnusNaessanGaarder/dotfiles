-- Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
-- Translated from dot-config/hypr/windowrules.conf
--
-- Updated against a confirmed hl.window_rule() / hl.layer_rule() field reference
-- (source-derived from Hyprland itself). Remaining uncertainty is called out inline.

-- hl.window_rule({
-- name = "volume-float",
-- VERIFY: "namespace" is not a documented match key for hl.window_rule() --
-- it's documented for hl.layer_rule() instead. The original repo line
-- (`windowrule = match:namespace Volume float`) may have targeted a layer
-- surface, not a window. If this rule doesn't take effect, try:
-- hl.layer_rule({ name = "volume-blur", match = { namespace = "Volume" }, ... })
-- match = { namespace = "Volume" },
--float = true,
-- })

hl.window_rule({
	name = "brave-tile",
	match = { class = "Brave-browser" },
	tile = true,
})

hl.window_rule({
	name = "thunar-float-center",
	match = { class = "thunar" },
	float = true,
	center = true,
	size = "50% 50%",
})

hl.window_rule({
	name = "badlion-float-center",
	match = { class = "BadlionClient" },
	float = true,
	center = true,
	size = "50% 50%",
})

hl.window_rule({
	name = "discord-float-center",
	-- Fixed: match key is camelCase "initialTitle", not "initial_title"
	match = { initial_title = "discord" },
	float = true,
	center = true,
	size = "50% 50%",
	monitor = "DP-2",
})

hl.window_rule({
	name = "brave-google-login-popup",
	-- Fixed: match key is camelCase "initialTitle", not "initial_title"
	match = { initial_title = "Untitled - Brave" },
	float = true,
	center = true,
	size = "50% 50%",
})

hl.window_rule({
	name = "pulsemixer-border-color",
	match = { title = "^(Volume)$" },
	-- Fixed (again): border_color needs the same gradient-table shape as
	-- general.col.active_border in the official example -- a plain string
	-- isn't accepted, it needs a "colors" array even for a solid color.
	border_color = { colors = { "rgba(185ac4ff)", "rgba(185ac4ff)" } },
})

hl.window_rule({
	name = "pavucontrol-float",
	match = { class = "pavucontrol" },
	float = true,
	move = "69.5% 55%",
	size = "30% 40%",
})

-- Layer rule -- confirmed shape, "blur" is a plain bool per hl.layer_rule() reference
hl.layer_rule({
	name = "logout-dialog-blur",
	match = { namespace = "logout_dialog" },
	blur = true,
})

hl.layer_rule({
	name = "volume-blur",
	match = { namespace = "Volume" },
})
