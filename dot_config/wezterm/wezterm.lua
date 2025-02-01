local wezterm = require("wezterm")
local platform = require("utils.platform")
local appearance = require("appearance")

local config = wezterm.config_builder()

if appearance.is_dark() then
	config.color_scheme = "Catppuccin Macchiato"
else
	config.color_scheme = "Catppuccin Latte"
end

config.font = wezterm.font({ family = "Monolisa Nerd Font" })
config.font_size = 16

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9

config.macos_window_background_blur = 30
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS|MACOS_FORCE_ENABLE_SHADOW"
-- Sets the font for the window frame (tab bar)
config.window_frame = {
	-- Berkeley Mono for me again, though an idea could be to try a
	-- serif font here instead of monospace for a nicer look?
	font = wezterm.font({ family = "Monolisa Nerd Font", weight = "Bold" }),
	font_size = 13,
}

wezterm.on("update-status", function(window)
	-- Grab the utf8 character for the "powerline" left facing
	-- solid arrow.
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

	-- Grab the current window's configuration, and from it the
	-- palette (this is the combination of your chosen colour scheme
	-- including any overrides).
	local color_scheme = window:effective_config().resolved_palette
	local bg = color_scheme.background
	local fg = color_scheme.foreground

	window:set_right_status(wezterm.format({
		-- First, we draw the arrow...
		{ Background = { Color = "none" } },
		{ Foreground = { Color = bg } },
		{ Text = SOLID_LEFT_ARROW },
		-- Then we draw our text
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = " " .. wezterm.hostname() .. " " },
	}))
end)

local function move_pane(key, direction)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection(direction),
	}
end

local function resize_pane(key, direction)
	return {
		key = key,
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ direction, 3 }),
	}
end

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- ... add these new entries to your config.keys table
	{
		-- I'm used to tmux bindings, so am using the quotes (") key to
		-- split horizontally, and the percent (%) key to split vertically.
		key = '"',
		-- Note that instead of a key modifier mapped to a key on your keyboard
		-- like CTRL or ALT, we can use the LEADER modifier instead.
		-- This means that this binding will be invoked when you press the leader
		-- (CTRL + A), quickly followed by quotes (").
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "%",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "a",
		-- When we're in leader mode _and_ CTRL + A is pressed...
		mods = "LEADER|CTRL",
		-- Actually send CTRL + A key to the terminal
		action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
	},
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),
	resize_pane("DownArrow", "Down"),
	resize_pane("UpArrow", "Up"),
	resize_pane("LeftArrow", "Left"),
	resize_pane("RightArrow", "Right"),
}

return config
