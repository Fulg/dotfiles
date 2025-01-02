local wezterm = require("wezterm")

local config = wezterm.config_builder()

config = {
	automatically_reload_config = true,
	enable_tab_bar = false,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE",
	default_cursor_style = "BlinkingBar",
	-- color_scheme = "Nord (Gogh)",
	color_scheme = "Catppuccin Macchiato",
	font = wezterm.font("MonoLisa Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	font_size = 16,

	window_background_opacity = 0.9,
	macos_window_background_blur = 10,

	--background = {
	--	{
	--		source = {
	--			Color = "#282c35",
	--		},
	--		width = "100%",
	--		height = "100%",
	--		opacity = 0.95,
	--	},
	--},
	window_padding = {
		left = 3,
		right = 3,
		top = 0,
		bottom = 0,
	},
}

return config
