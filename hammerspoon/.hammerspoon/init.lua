-- doing this below to avoid undefined-global diagnostic warnings
---@diagnostic disable-next-line: undefined-global
local hs = hs

-- Load WinWin spoon
local WinWin = hs.loadSpoon("WinWin")

local log = hs.logger.new('init.lua', 'verbose')

local currentEditor = "Zed"
local currentBrowser = "Zen"

local function now()
    return hs.timer.secondsSinceEpoch()
end

log.i('Initializing')

local function searchAndOpen(appName)
    local start = now()
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
    log.d(string.format("searchAndOpen(%s) took %.4f ms", tostring(appName), (now() - start) * 1000))
end

local function getBrowserApp()
    return hs.application.find(currentBrowser, true)
end

-- prob there is a better way of getting into the tab toolbar
local function openNewBrowserTab(url)
    local start = now()
    local cmd = string.format('open -a %q %q', currentBrowser, url)

    log.d("openNewBrowserTab: running shell command: " .. cmd)

    local ok, _, _, rc = hs.execute(cmd)
    if not ok or rc ~= 0 then
        log.w(string.format("openNewBrowserTab: command failed (rc=%s) for URL '%s'", tostring(rc), url))
        return
    end

    log.d(string.format("openNewBrowserTab: launched '%s' with URL '%s' in %.4f ms",
        currentBrowser, url, (now() - start) * 1000))
end

local function getBrowserTabToolbar()
    local start = now()
    local app = getBrowserApp()
    if not app or not app:isRunning() then
        log.w("browser not found or not running")
        log.d(string.format("getBrowserTabToolbar() failed (no app) after %.4f ms", (now() - start) * 1000))
        return nil
    end

    local win = app:focusedWindow() or app:mainWindow()
    if not win then
        log.w("No browser window found")
        log.d(string.format("getBrowserTabToolbar() failed (no window) after %.4f ms", (now() - start) * 1000))
        return nil
    end

    local axWin = hs.axuielement.windowElement(win)
    if not axWin then
        log.w("Could not get AX window element for browser")
        log.d(string.format("getBrowserTabToolbar() failed (no axWin) after %.4f ms", (now() - start) * 1000))
        return nil
    end

    local mainGroup = axWin[1]
    if not mainGroup then
        log.w("No main group found in browser window")
        log.d(string.format("getBrowserTabToolbar() failed (no mainGroup) after %.4f ms", (now() - start) * 1000))
        return nil
    end

    local toolbars = mainGroup:childrenWithRole("AXToolbar")
    for _, toolbar in ipairs(toolbars) do
        local tabGroups = toolbar:childrenWithRole("AXTabGroup")
        if #tabGroups > 0 then
            log.d(string.format("getBrowserTabToolbar() succeeded in %.4f ms", (now() - start) * 1000))
            return toolbar
        end
    end

    log.i("Tab toolbar not found in browser")
    log.d(string.format("getBrowserTabToolbar() failed (no toolbar) after %.4f ms", (now() - start) * 1000))
    return nil
end

-- get only the active tab in browser by walking AXTabGroup > AXGroup > tab children
-- annoying for/if nesting but works
local function getActiveTab(callback)
    local start = now()
    local tabToolbar = getBrowserTabToolbar()
    if not tabToolbar then
        log.d(string.format("getActiveTab(): no tabToolbar (%.4f ms total)", (now() - start) * 1000))
        if callback then callback(nil) end
        return
    end

    local scanStart = now()
    local activeTitle = nil

    local tabGroups = tabToolbar:childrenWithRole("AXTabGroup") or {}
    for _, tabGroup in ipairs(tabGroups) do
        local groups = tabGroup:childrenWithRole("AXGroup") or {}
        for _, group in ipairs(groups) do
            local children = group:attributeValue("AXChildren") or {}
            for _, el in ipairs(children) do
                local role    = el:attributeValue("AXRole")
                local subrole = el:attributeValue("AXSubrole")
                if role == "AXRadioButton" and subrole == "AXTabButton" then
                    local isActive = el:attributeValue("AXValue")
                    if isActive == true or isActive == 1 then
                        activeTitle = el:attributeValue("AXTitle")
                        goto done_active
                    end
                end
            end
        end
    end

    ::done_active::
    local scanElapsed = (now() - scanStart) * 1000
    local totalElapsed = (now() - start) * 1000
    log.d(string.format("getActiveTab(): found '%s' (scan %.4f ms, total %.4f ms)",
        tostring(activeTitle), scanElapsed, totalElapsed))

    if callback then callback(activeTitle) end
end

-- activate a tab by checking if tabName argument is inside the title
-- if not found and a fallback URL is provided, open a new tab with that URL
-- annoying for/if nesting but works
local function activateTab(tabName, callback, fallbackUrl)
    local start = now()
    local tabToolbar = getBrowserTabToolbar()
    if not tabToolbar then
        log.d(string.format("activateTab(%s): no tabToolbar (%.4f ms total)",
            tostring(tabName), (now() - start) * 1000))
        if callback then callback(false) end
        return
    end

    local scanStart = now()
    local needle = tabName:lower()
    local targetTab = nil
    local targetTitle = nil

    local tabGroups = tabToolbar:childrenWithRole("AXTabGroup") or {}
    for _, tabGroup in ipairs(tabGroups) do
        local groups = tabGroup:childrenWithRole("AXGroup") or {}
        for _, group in ipairs(groups) do
            local children = group:attributeValue("AXChildren") or {}
            for _, el in ipairs(children) do
                local role    = el:attributeValue("AXRole")
                local subrole = el:attributeValue("AXSubrole")
                if role == "AXRadioButton" and subrole == "AXTabButton" then
                    local title = el:attributeValue("AXTitle") or ""
                    log.d(string.format("activateTab(%s): checking tab title '%s'",
                        tostring(tabName), title))
                    if title:lower():find(needle, 1, true) then
                        targetTab = el
                        targetTitle = title
                        goto done_scan
                    end
                end
            end
        end
    end

    ::done_scan::
    local scanElapsed = (now() - scanStart) * 1000

    if not targetTab then
        log.w(string.format("activateTab(%s): tab not found (scan %.4f ms, total %.4f ms)",
            tostring(tabName), scanElapsed, (now() - start) * 1000))
        if fallbackUrl then
            log.i(string.format("activateTab(%s): opening new browser tab with URL '%s'", tostring(tabName), fallbackUrl))
            openNewBrowserTab(fallbackUrl)
        end
        if callback then callback(false) end
        return
    end

    local beforePress = now()
    log.i(string.format("Found and activating tab: %s", targetTitle))
    targetTab:performAction("AXPress")
    local pressElapsed = (now() - beforePress) * 1000

    log.d(string.format("activateTab(%s): AXPress took %.4f ms (scan %.4f ms, total %.4f ms)",
        tostring(tabName), pressElapsed, scanElapsed, (now() - start) * 1000))
    if callback then callback(true) end
end

-- cmd + 1 focus on browser
hs.hotkey.bind({ "cmd" }, "1", function()
    searchAndOpen(currentBrowser)
end)

-- cmd + 2 focus on the current code editor
hs.hotkey.bind({ "cmd" }, "2", function()
    searchAndOpen(currentEditor)
end)

-- cmd + 3 focus on Ghostty
hs.hotkey.bind({ "cmd" }, "3", function()
    local currentWindowInFocus = hs.window.focusedWindow()
    local currentApp = currentWindowInFocus:application()
    local currentAppName = currentApp:name()

    if currentAppName == "Ghostty" then
        -- TODO: implement logic to cycle between ghostty windows if there are multiple
    else
        hs.application.launchOrFocus("Ghostty")
    end
end)

-- cmd + 4 focus on browser and switch between WhatsApp/Discord tabs
hs.hotkey.bind({ "cmd" }, "4", function()
    log.i("Switching to WhatsApp/Discord tab in browser")

    searchAndOpen(currentBrowser)

    getActiveTab(function(activeTab)
        log.i("Active tab: " .. tostring(activeTab))

        if activeTab and activeTab:find("WhatsApp") then
            log.i("WhatsApp tab is active")
            activateTab("Discord")
        elseif activeTab and activeTab:find("Discord") then
            log.i("Discord tab is active")
            activateTab("WhatsApp")
        else
            activateTab("Discord")
        end
    end)
end)

-- cmd + 5 focus on IntelliJ IDEA
hs.hotkey.bind({ "cmd" }, "5", function()
    searchAndOpen('IntelliJ')
end)

-- cmd + P focus browser and select the tab whose title contains "proxmox",
-- or open a new tab with https://proxmox.bolado.dev if not found
hs.hotkey.bind({ "cmd" }, "P", function()
    log.i("Activating browser tab with title containing 'proxmox'")
    searchAndOpen(currentBrowser)
    activateTab("proxmox", nil, "https://proxmox.bolado.dev")
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

-- cmd + N focus browser and select the tab whose title contains "notes -"
-- or open a new tab with https://notes.bolado.dev if not found
-- our silverbullet script makes it easy by setting "notes -" at the beginning of the title
hs.hotkey.bind({ "cmd" }, "N", function()
    log.i("Activating browser tab with title containing 'notes -'")
    searchAndOpen(currentBrowser)
    activateTab("notes -", nil, "https://notes.bolado.dev")
end)

-- cmd + F fullscreen focused window
hs.hotkey.bind({ "cmd", "shift" }, "F", function()
    WinWin:moveAndResize("maximize")
end)

-- cmd + ctrl + v 'write' clipboard content when its not possible to just paste
hs.hotkey.bind({ "cmd", "ctrl" }, "v", function()
    local clipboardContent = hs.pasteboard.getContents()
    if clipboardContent then
        hs.eventtap.keyStrokes(clipboardContent)
    end
end)
