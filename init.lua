local hyper = { "cmd", "alt", "ctrl", "shift" }
local bluetooth = require("hs._asm.undocumented.bluetooth")

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()

-- Open up various apps 
local applicationHotkeys = {
  a = 'Google Chrome',
  w = 'iTerm',
  s = 'IntelliJ IDEA',
  q = 'Quiver',
  z = 'Spotify',
  x = 'Station',
  d = 'Sublime Text'
}
for key, app in pairs(applicationHotkeys) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(app)
  end)
end

hs.hotkey.bind(hyper, "1", function()
  hs.application.launchOrFocus('Finder')
end)

hs.hotkey.bind(hyper, "2", function()
  hs.application.launchOrFocus('Microsoft To Do')
end)

hs.hotkey.bind(hyper, "3", function()
  hs.application.launchOrFocus('Sequel Pro')
end)

-- Check what's playing on Spotify
hs.hotkey.bind(hyper, "§", function()
  hs.spotify.displayCurrentTrack()
end)

-- Bring up clipboard history from Alfred
hs.hotkey.bind(hyper, "c", function()
  hs.eventtap.keyStroke({"alt"}, "space")
  hs.eventtap.keyStrokes("cb")
  hs.eventtap.keyStroke({},"return",hs.eventtap.keyRepeatInterval())
end)

-- Search google for highlighed text
hs.hotkey.bind(hyper, "f", function()
  hs.eventtap.keyStroke({"cmd"}, "c")
  local search = "https://www.google.com/search?q=" .. hs.pasteboard.getContents():gsub(" ", "%%20")
  hs.urlevent.openURLWithBundle(search, 'com.google.Chrome')
end)

-- Open link in chrome
hs.hotkey.bind(hyper, "e", function()
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.urlevent.openURLWithBundle(hs.pasteboard.getContents(), 'com.google.Chrome')
end)

-- Get correlated events goggles from message id {created}.{id}
hs.hotkey.bind(hyper, "g", function()
  hs.eventtap.keyStroke({"cmd"}, "c")
  local goggles = "https://tools.hubteam.com/api/get/private.hubapi.com%2Femail%2Fv1%2Fcorrelated-events%2F" .. hs.pasteboard.getContents():gsub("%.", "%%2F") .. "%2Fevents?label=Correlated%20Email%20Events"
  hs.urlevent.openURLWithBundle(goggles, 'com.google.Chrome')
end)

-- Copy, find and paste highlighted text
hs.hotkey.bind(hyper, "v", function()
  hs.eventtap.keyStroke({"cmd"}, "c", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"cmd"}, "f")
  hs.eventtap.keyStroke({"cmd"}, "v", hs.eventtap.keyRepeatInterval())
end)

-- Highlight word cursor is on
hs.hotkey.bind(hyper, "`", function()
  hs.eventtap.keyStroke({"alt"}, "right")
  hs.eventtap.keyStroke({"alt", "shift"}, "left")
end)

-- Opengrok selected text
hs.hotkey.bind(hyper, "space", function()
  hs.eventtap.keyStroke({"cmd"}, "c", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"alt"}, "space")
  hs.eventtap.keyStrokes("opengrok \"")
  hs.eventtap.keyStroke({"cmd"}, "v", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStrokes("\"")
  hs.eventtap.keyStroke({}, "return", hs.eventtap.keyRepeatInterval())
end)

-- Look up highlighted timestamp as date in Alfred
hs.hotkey.bind(hyper, "t", function()
  hs.eventtap.keyStroke({"cmd"}, "c", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"alt"}, "space")
  hs.eventtap.keyStrokes("ts ")
  hs.eventtap.keyStroke({"cmd"}, "v", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({}, "return", hs.eventtap.keyRepeatInterval())
end)

-- Move chrome tab from one window to another
hs.hotkey.bind(hyper, "r", function()
  hs.eventtap.keyStroke({"cmd"}, "l", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.eventtap.keyStroke({"cmd"}, "w", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"cmd"}, "`")
  hs.eventtap.keyStroke({"cmd"}, "t", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"cmd"}, "v")
  hs.eventtap.keyStroke({}, "return", hs.eventtap.keyRepeatInterval())
end)


mouseCircle = nil
mouseCircleTimer = nil

function mouseHighlight()
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    -- Get the current co-ordinates of the mouse pointer
    mousepoint = hs.mouse.getAbsolutePosition()
    -- Prepare a big red circle around the mouse pointer
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:show()

    -- Set a timer to delete the circle after 2 seconds
    mouseCircleTimer = hs.timer.doAfter(2, function() mouseCircle:delete() end)
end
hs.hotkey.bind(hyper, "4", mouseHighlight)


local workWifi = 'HS-Corp'
local outputDeviceName = 'Built-in Output'
hs.wifi.watcher.new(function()
    local currentWifi = hs.wifi.currentNetwork()
    local currentOutput = hs.audiodevice.current(false)
    if not currentWifi then return end
    if (currentWifi == workWifi and currentOutput.name == outputDeviceName) then
        hs.audiodevice.findDeviceByName(outputDeviceName):setOutputMuted(true)
        -- bluetooth.power(true)
    end
end):start()

-- local previousWifi = hs.wifi.currentNetwork()

-- hs.wifi.watcher.new(function()
--     local newWifi = hs.wifi.currentNetwork()
--     if not newWifi then return end
--     if (previousWifi == workWifi and newWifi ~= previousWifi) then
--         -- bluetooth.power(false)
--     end
--     previousWifi = hs.wifi.currentNetwork()
-- end):start()

function caffeinateCallback(eventType)
    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
        bluetooth.power(false)
    elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
        bluetooth.power(true)
    end
end
--bluetooth.power(true)
hs.caffeinate.watcher.new(caffeinateCallback):start()


local PASTEBIN_API_DEVELOPER_KEY = "cc36e4661ef3e0887c0c23220f66e4b2"
local PASTEBIN_API_USER_KEY = "b07e53bad2ee7572d5a0bd873c510c6c"
local PASTEBIN_API_PASTE_PRIVATE = "1"
local PASTEBIN_API_PASTE_EXPIRE = "1D"

hs.hotkey.bind(hyper, "p", function()
    hs.eventtap.keyStroke({"cmd"}, "c")
    local board = hs.pasteboard.getContents()
    local response = hs.http.asyncPost(
        "http://pastebin.com/api/api_post.php",
        "api_option=paste" ..
            "&api_dev_key=" .. PASTEBIN_API_DEVELOPER_KEY ..
            "&api_user_key=" .. PASTEBIN_API_USER_KEY ..
            "&api_paste_private=" .. PASTEBIN_API_PASTE_PRIVATE ..
            "&api_paste_expire_date=" .. PASTEBIN_API_PASTE_EXPIRE ..
            "&api_paste_code=" .. hs.http.encodeForQuery(board),
        {},
        function(http_code, response)
            if http_code == 200 then
                hs.pasteboard.setContents(response)
                hs.notify.new({title="Pastebin Paste Successful", informativeText=response}):send()
                hs.urlevent.openURLWithBundle(response, 'com.google.Chrome')
            else
                hs.notify.new({title="Pastebin Paste Failed!", informativeText=response}):send()
            end
        end
        )
    end)

function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == "Finder") then
            -- Bring all Finder windows forward when one gets activated
            appObject:selectMenuItem({"Window", "Bring All to Front"})
        end
    end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

hs.loadSpoon("WifiNotifier")
spoon.WifiNotifier:start()

-- caffeine = hs.menubar.new()
-- function setCaffeineDisplay(state)
--     if state then
--         caffeine:setTitle("AWAKE")
--     else
--         caffeine:setTitle("SLEEPY")
--     end
-- end

-- function caffeineClicked()
--     setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
-- end

-- if caffeine then
--     caffeine:setClickCallback(caffeineClicked)
--     setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
-- end

-- hs.hotkey.bind(hyper, 'L', function() hs.caffeinate.systemSleep() end)
