require("globals")

function love.conf(t)
	t.title = 'Meow Over Moo!' 				-- The title show in the window title bar
	t.version = '11.5'					 	-- The minimum LÖVE version this game was made for
	t.console = false				 	 	-- Attach a console (boolean, Windows only)
	t.identity = 'MeowOverMoo'								-- LÖVE save identity (logs/settings path)
	t.window.icon = 'assets/app_icon_linux.png'			-- Native desktop/window icon
	t.window.width = SETTINGS.DISPLAY.WIDTH			 		-- The window width resolution
    t.window.height = SETTINGS.DISPLAY.HEIGHT	 			    -- The window height resolution
	t.window.minwidth = SETTINGS.DISPLAY.MINWIDTH		 			-- Minimum window width if the window is resizable
	t.window.minheight = SETTINGS.DISPLAY.MINHEIGHT					-- Minimum window height if the window is resizable
end
