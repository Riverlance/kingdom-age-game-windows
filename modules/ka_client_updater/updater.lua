_G.ClientUpdater = { }

local updaterWindow

local startTime = 0

function ClientUpdater.init()
    ClientUpdater.m = modules.ka_client_updater

    connect(g_updater, {
        onUpdated        = ClientUpdater.onUpdated,
        onUpdateStart    = ClientUpdater.onUpdateStart,
        onUpdateProgress = ClientUpdater.onUpdateProgress,
        onUpdateEnd      = ClientUpdater.onUpdateEnd,
    })

    updaterWindow = g_ui.displayUI('updater')
    updaterWindow:hide()
end

function ClientUpdater.terminate()
    disconnect(g_updater, {
        onUpdated        = ClientUpdater.onUpdated,
        onUpdateStart    = ClientUpdater.onUpdateStart,
        onUpdateProgress = ClientUpdater.onUpdateProgress,
        onUpdateEnd      = ClientUpdater.onUpdateEnd,
    })

    updaterWindow:destroy()
    updaterWindow = nil

    _G.ClientUpdater = nil
end

function ClientUpdater.onUpdated()
    updaterWindow:hide()
end

function ClientUpdater.onUpdateStart()
    startTime = g_clock.millis()
    updaterWindow:show()
    updaterWindow:getChildById('topText'):setText('Starting...')
end

function ClientUpdater.onUpdateProgress(receivedObj, totalObj, receivedBytes)
    local percent = (receivedObj/totalObj) * 100
    local deltaTime = (g_clock.millis() - startTime) / 1000
    local avgSpeed = receivedBytes / 1024 / deltaTime
    local receivedMB = receivedBytes / 1024 / 1024

    updaterWindow:getChildById('topText'):setText(string.format('Downloading: %s of %s files', tostring(receivedObj):comma(), tostring(totalObj):comma()))
    updaterWindow:getChildById('bottomText'):setText(string.format('Received: %.2f MB (%.2f %s/s)', receivedMB, avgSpeed < 1024 and avgSpeed or avgSpeed / 1024, avgSpeed < 1024 and "kB" or "MB"))
    updaterWindow:getChildById('rightText'):setText(string.format('%.2f%%', percent))
    updaterWindow:getChildById('bar'):setPercent(percent)
end

function ClientUpdater.onUpdateEnd()
    local callback = function()
        g_platform.spawnProcess("Kingdom Age Online.exe", { })
        exit()
    end
    displayOkCancelBox(tr("Info"), tr("Your client has been updated. Click OK to restart the client."), callback)
end
