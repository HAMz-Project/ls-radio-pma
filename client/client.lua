ESX = nil
local PlayerData = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

local radioMenu = false
function PrintChatMessage(text)
    TriggerEvent('chatMessage', "system", { 255, 0, 0 }, text)
end

function enableRadio(enable)
    SetNuiFocus(true, true)
    radioMenu = enable

    SendNUIMessage({
        type = "enableui",
        enable = enable
    })
end

function hasRadio(cb)
    if (ESX == nil) then return cb(0) end
    ESX.TriggerServerCallback('ls-radio:getItemAmount', function(qtty)
        cb(qtty > 0)
    end)
end

RegisterCommand('radio', function(source, args)
    if Config.enableCmd then
        hasRadio(function (hasRadio)
            if hasRadio then
                enableRadio(true)
            else
                exports['mythic_notify']:SendAlert('error', Config.messages['dont_has_radio'])
            end
        end)
    end
end, false)

RegisterNUICallback('joinRadio', function(data, cb)
    local _source       = source
    local PlayerData    = ESX.GetPlayerData(_source)
    local playerName    = GetPlayerName(PlayerId())

    if tonumber(data.channel) <= Config.RestrictedChannels then
        if (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance' or PlayerData.job.name == 'fire') then
            exports["pma-voice"]:SetRadioChannel(0)
            exports["pma-voice"]:SetRadioChannel(tonumber(data.channel))
            exports["pma-voice"]:SetMumbleProperty("radioEnabled", true)

            exports['mythic_notify']:SendAlert('inform', Config.messages['joined_to_radio'] .. data.channel .. '.00 MHz </b>')
        elseif not (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance' or PlayerData.job.name == 'fire') then
            exports['mythic_notify']:SendAlert('error', Config.messages['restricted_channel_error'])
        end
    elseif tonumber(data.channel) > Config.RestrictedChannels then
        exports["pma-voice"]:SetRadioChannel(0)
        exports["pma-voice"]:SetRadioChannel(tonumber(data.channel))
        exports["pma-voice"]:SetMumbleProperty("radioEnabled", true)

        exports['mythic_notify']:SendAlert('inform', Config.messages['joined_to_radio'] .. data.channel .. '.00 MHz </b>')
    end

    cb('ok')
end)

RegisterNUICallback('leaveRadio', function(data, cb)
    exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)

    cb('ok')
end)

RegisterNUICallback('escape', function(data, cb)
    enableRadio(false)
    SetNuiFocus(false, false)

    cb('ok')
end)

RegisterNetEvent('ls-radio:use')
AddEventHandler('ls-radio:use', function()
    enableRadio(true)
end)

RegisterNetEvent('ls-radio:onRadioDrop')
AddEventHandler('ls-radio:onRadioDrop', function(source)
    exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)
end)

Citizen.CreateThread(function()
    while true do
        if radioMenu then
            DisableControlAction(0, 1, guiEnabled) -- LookLeftRight
            DisableControlAction(0, 2, guiEnabled) -- LookUpDown
            DisableControlAction(0, 142, guiEnabled) -- MeleeAttackAlternate
            DisableControlAction(0, 106, guiEnabled) -- VehicleMouseControlOverride

            if IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
                SendNUIMessage({
                    type = "click"
                })
            end
        end
        Citizen.Wait(0)
    end
end)