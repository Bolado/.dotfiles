local log = hs.logger.new('init.lua', 'verbose')

log.i('Initializing')

local function searchAndOpen(appName)
	local app = hs.application.find(appName, false)

	if app then
		log.d("Attempting to launch or focus: " .. app:name())
		local mainWin = app:mainWindow()
		if mainWin then
			mainWin:focus()
		else
			log.w("Application " .. appName .. " has no main window")
			-- try to activate the app anyway
			app:activate()
		end
	else
		log.w("Application not found: " .. appName)
		-- try to launch it
		hs.application.launchOrFocus(appName)
	end
end

-- cmd + 1 focus to Arc
hs.hotkey.bind({ "cmd" }, "1", function()
	searchAndOpen('Arc')
end)

-- cmd + 2 focus on Code
hs.hotkey.bind({ "cmd" }, "2", function()
	searchAndOpen('Visual Studio Code - Insiders')
end)

-- cmd + 3 focus on Ghostty
hs.hotkey.bind({ "cmd" }, "3", function()
	searchAndOpen('Ghostty')
end)

-- cmd + 4 focus on Arc and switch to whatsapp/discord tab
hs.hotkey.bind({ "cmd" }, "4", function()
	log.i("Switching to WhatsApp/Discord tab in Arc")
	hs.osascript.applescript([[
    tell application "Arc"
	if (count of windows) is 0 then
		make new window
	end if
    activate

	tell first window
		set tabsCount to count of tabs
		set currentURL to URL of active tab
		set targetURL to ""

        -- if we not on whatsapp or discord tab, go to whatsapp, else switch between them
		if currentURL contains "web.whatsapp.com" then
			set targetURL to "discord.com"
		else if currentURL contains "discord.com" then
			set targetURL to "web.whatsapp.com"
		else
			set targetURL to "web.whatsapp.com"
		end if

		repeat with i from 1 to tabsCount
			tell tab i
				set _url to URL
				if _url contains targetURL then
					select
					exit repeat
				end if
			end tell
		end repeat
	end tell
    end tell
    ]])
end)

-- cmd + 5 focus on IntelliJ IDEA
hs.hotkey.bind({ "cmd" }, "5", function()
	searchAndOpen('IntelliJ')
end)


-- cmd + P open or select the tab in Arc with Proxmox
hs.hotkey.bind({ "cmd" }, "P", function()
	hs.osascript.applescript([[
    tell application "Arc"
	if (count of windows) is 0 then
		make new window
	end if
    activate

	tell first window
		set tabsCount to count of tabs
        set foundTab to false
		    repeat with i from 1 to tabsCount
			    tell tab i
				    set _url to URL
				    if _url contains "proxmox.bolado.dev" then
					    select
                        set foundTab to true
				    end if
			    end tell
		    end repeat
            if not foundTab then
                make new tab with properties {URL:"https://proxmox.bolado.dev"}
            end if
	    end tell
    end tell
    ]])
end)

-- cmd + shift + F change frontmost window to fill screen
hs.hotkey.bind({ "cmd", "shift" }, "F", function()
	local win = hs.window.frontmostWindow()

	if win then
		local screen = win:screen()
		local maxFrame = screen:frame()
		win:setFrame(maxFrame)
	else
		log.w("No frontmost window found")
	end
end)

-- cmd + N open silverbullet tab on Arc
hs.hotkey.bind({ "cmd" }, "N", function()
	hs.osascript.applescript([[
    tell application "Arc"
	if (count of windows) is 0 then
		make new window
	end if
    activate

	tell first window
		set tabsCount to count of tabs
        set foundTab to false
		    repeat with i from 1 to tabsCount
			    tell tab i
				    set _url to URL
				    if _url contains "notes.bolado.dev" then
					    select
                        set foundTab to true
				    end if
			    end tell
		    end repeat
            if not foundTab then
                make new tab with properties {URL:"https://notes.bolado.dev"}
            end if
	    end tell
    end tell
	]])
end)
