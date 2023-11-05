local QBCore = exports['qb-core']:GetCoreObject()

local Countdown = 5
local currentRace = {}
local startTime = 0
local maxDistance = 20
local hasFinished = false
local FinishedUITimeout = false
local currentTime = 0
local inviteRaceId = nil
local useDebug = Config.Debug
local opponent = nil
local opponentId = nil
local role = nil
local winTimer = nil
local distance = nil
local marker = nil
local PlayerJob = {}

local function dump(o)
   if type(o) == 'table' then
   local s = '{ '
   for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
   end
   return s .. '} '
   else
   return tostring(o)
   end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function(JobInfo)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
    end)
end)

RegisterNetEvent('cw-outrun:client:notifyFinish', function(text)
    hasFinished = true
    role = nil
    winTimer = nil
    distance = nil
    currentRace = nil
    RemoveBlip(marker)
    marker = nil
    Countdown = 5
    SendNUIMessage({
        action = "Finish",
        data = {
            value = text
        },
        active = false
    })
end)

local function updateCountdown(value)
    SendNUIMessage({
        action = "Countdown",
        data = {
            value = value
        },
        active = true
    })
end

local function getOpponent()
    local ply = GetPlayerPed(-1)
    for i, racer in pairs(currentRace.racers) do
        local playerIdx = GetPlayerFromServerId(racer.source)
        local target = GetPlayerPed(playerIdx)
        if ply ~= target then
            opponentId = racer.source
            return target
        end
    end
end

local function distanceToOpponent()
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)    

    local opponentId = GetPlayerFromServerId(opponentId)
    local target = GetPlayerPed(opponentId)
    
    local opponentCoords = GetEntityCoords(target, 0)
    local distance = #(opponentCoords.xy-plyCoords.xy)

    if distance == 0 then
        SetBlipSprite(marker, 488)
        SetBlipColour(marker, 1)
    else
        RemoveBlip(marker)
        marker = AddBlipForCoord(opponentCoords)
        SetBlipSprite(marker, 488)
        SetBlipColour(marker, 2)

    end
    return distance
end

local function finishRace()
    currentRace = nil
end

local function handleMouse()
    distance = distanceToOpponent()
    if distance == 0 then
        if winTimer == nil then
            winTimer = GetCloudTimeAsInt()            
        end
        if not hasFinished and Config.Outrun.TimeToOutrun <= GetTimeDifference(GetCloudTimeAsInt(), winTimer) then
            hasFinished = true
            TriggerServerEvent('cw-head2head:server:outrunWinner', currentRace.raceId, QBCore.Functions.GetPlayerData().citizenid, opponentId, GetTimeDifference(GetCloudTimeAsInt(), startTime) )
        end
    else
        winTimer = nil
    end
end

local function handleCat()
    distance = distanceToOpponent()
    if distance <= Config.Outrun.CatchDistance and distance ~= 0 then
        if winTimer == nil then
            winTimer = GetCloudTimeAsInt()            
        end
        if not hasFinished and Config.Outrun.TimeToCatch <= GetTimeDifference(GetCloudTimeAsInt(), winTimer) then
            hasFinished = true
            TriggerServerEvent('cw-head2head:server:outrunWinner', currentRace.raceId, QBCore.Functions.GetPlayerData().citizenid, opponentId, GetTimeDifference(GetCloudTimeAsInt(), startTime) )
        end
    else
        winTimer = nil
    end
end

local function setupRace()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
    
            if currentRace ~= nil then
                if currentRace.started and not currentRace.finished then
                    if role == 'mouse' then
                        handleMouse()
                    else
                        handleCat()
                    end
                end
            else
                break;
            end
            Wait(0)
        end
    end)
end

local function setupRaceUI()
    CreateThread(function()
        while true do
            if not hasFinished and currentRace ~= nil then
                currentTime = GetTimeDifference(GetCloudTimeAsInt(), startTime)
                local timeToWin = Config.Outrun.TimeToOutrun
                if role == 'cat' then
                    timeToWin = Config.Outrun.TimeToCatch
                end
                local time = 0
                if winTimer ~= nil then
                    time = GetTimeDifference(GetCloudTimeAsInt(), winTimer)
                end
                SendNUIMessage({
                    action = "Update",
                    type = "race",
                    data = {
                        Time = currentTime,
                        Ghosted = ghosted,
                        Started = currentRace.started,
                        Type = currentRace.type,
                        Role = role,
                        OutrunTimer = time,
                        OutrunTimeToWin = timeToWin,
                        Distance = distance,
                    },
                    active = true
                })
            else
                if not FinishedUITimeout then
                    FinishedUITimeout = true
                    SetTimeout(10000, function()
                        FinishedUITimeout = false
                        SendNUIMessage({
                            action = "Update",
                            type = "race",
                            data = {},
                            racedata = RaceData,
                            active = false
                        })
                    end)
                end
                break
            end
            Wait(12)
        end
    end)
end

local Players = {}

local function playerIsWithinDistance(coords)
    local ply = PlayerPedId()
    if useDebug then
        print('player', ply)
    end
    local plyCoords = GetEntityCoords(ply, 0)    
    local distance = #(coords.xy-plyCoords.xy)
    if useDebug then
       print('distance', distance)
    end
    if(distance < Config.InviteDistance) then
        return true
    end
    return false
end

local function isInDriverSeat()
    if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId() then 
        return true
      else
        return false
      end
end

RegisterNetEvent('cw-outrun:client:checkDistance', function(raceId, coords, amount, host)
    local citizenId = QBCore.Functions.GetPlayerData().citizenid
    if useDebug then
        print('checking if close to outrun race', raceId, citizenId, host)
    end
    if host ~= citizenId and playerIsWithinDistance(coords) and isInDriverSeat() then
        if useDebug then
            print('can join')
        end
        inviteRaceId = raceId
        local text = Lang:t('info.you_got_an_invite_outrun')
        if amount and amount > 0 then
            text = text..' ($'..amount..')'
        end
        QBCore.Functions.Notify(text, 'success')
        SetTimeout(Config.InviteTimer, function()
            inviteRaceId = nil
        end)
    else
        if useDebug then
            print('can NOT join')
        end
    end
end)

local function allNeonAreOn(vehicle)
    if IsVehicleNeonLightEnabled(vehicle, 1) and IsVehicleNeonLightEnabled(vehicle, 2) and IsVehicleNeonLightEnabled(vehicle, 3) and IsVehicleNeonLightEnabled(vehicle, 0) then
        return true
    else
        return false
    end
end

local function handleHighBeams()
    local PlayerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(PlayerPed, false)
    SetVehicleFullbeam(vehicle, true)
    local FlashUnderglow = Config.FlashUnderglow and allNeonAreOn(vehicle)
    if FlashUnderglow then
        SetVehicleNeonLightEnabled(vehicle, 2 , false)
    end
    Wait(400)
    SetVehicleFullbeam(vehicle, false)
    if FlashUnderglow then
        SetVehicleNeonLightEnabled(vehicle, 2 , true)
        SetVehicleNeonLightEnabled(vehicle, 0, false)
        SetVehicleNeonLightEnabled(vehicle, 1 , false)
    end
    Wait(400)
    SetVehicleFullbeam(vehicle, true)
    if FlashUnderglow then
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1 , true)
        SetVehicleNeonLightEnabled(vehicle, 3 , false)
    end
    Wait(400)
    SetVehicleFullbeam(vehicle, false)
    if FlashUnderglow then
        SetVehicleNeonLightEnabled(vehicle, 3 , true)
    end
end

RegisterNetEvent('cw-outrun:client:joinRace', function()
    if useDebug then
        print('attempting to join', inviteRaceId)
    end
    if inviteRaceId then
        local citizenId = QBCore.Functions.GetPlayerData().citizenid
        local racerName = ''
        TriggerServerEvent('cw-head2head:server:joinRace', citizenId, racerName, inviteRaceId)
        handleHighBeams()
        role = 'cat'
    else
        QBCore.Functions.Notify(Lang:t('error.you_have_no_invites'), 'error')
    end
end)

local defaultLightsState = 0
RegisterNetEvent('cw-outrun:client:setupRace', function(data)
    if useDebug then
        print('setting up race: $'..data.value)
    end
    local citizenId = QBCore.Functions.GetPlayerData().citizenid
    local racerName = ''
    local startCoords = GetEntityCoords(GetPlayerPed(-1), 0)
    local amount = data.value
    if useDebug then
        print(citizenId, dump(startCoords))
    end
    TriggerServerEvent('cw-head2head:server:setupRace', citizenId, racerName, startCoords, amount, 'outrun')
    handleHighBeams()
    role = 'mouse'
end)

RegisterNetEvent('cw-outrun:client:raceCountdown', function(race)
    QBCore.Functions.TriggerCallback('cw-head2head:server:getPlayers', function(players)
        Players = players
        currentRace = race
        winTimer = nil
        hasFinished = false
        if useDebug then
            print('Starting Countdown', dump(race))
        end
        if currentRace.raceId ~= nil then
            setupRaceUI()
            setupRace()
            opponent = getOpponent()
            while Countdown ~= 0 do
                if currentRace ~= nil then
                    if useDebug then
                        print('Countdown')
                    end
                    if Countdown <= 5 then
                        updateCountdown(Countdown)
                        PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
                    end
                    Countdown = Countdown - 1
                else
                    break
                end
                Wait(1000)
            end
            updateCountdown(Lang:t("success.race_go"))
            TriggerServerEvent('cw-head2head:server:raceStarted', currentRace.raceId)
            startTime = GetCloudTimeAsInt()
            currentRace.started = true
            Countdown = 5
        else
            QBCore.Functions.Notify(Lang:t("error.already_in_race"), 'error')
        end
    end)
end)

local markers = {}

local items = {
    {
        id = 'outrunJoin',
        title = Lang:t('menu.join'),
        icon = 'check',
        type = 'client',
        event = 'cw-outrun:client:joinRace',
        shouldClose = true
    },
    {
        id = 'outrunFree',
        title = Lang:t('menu.setup'),
        icon = 'comments',
        type = 'client',
        event = 'cw-outrun:client:setupRace',
        value = 0,
        shouldClose = true
    }
}

for i, value in pairs(Config.BuyIns) do
    items[#items+1] = {
        id = 'outrun'..value,
        title = Lang:t('menu.setup')..' ($'..value..')',
        icon = 'comments-dollar',
        type = 'client',
        event = 'cw-outrun:client:setupRace',
        value = value,
        shouldClose = true
    }
end

local radialMenu = nil

local function addRadialMenu()
    radialMenu = exports['qb-radialmenu']:AddOption({
        id = 'outrun',
        title = Lang:t('menu.title_outrun'),
        icon = 'flag-checkered',
        type = 'client',
        items = items
    })
end

local function removeRadialMenu()
    if radialMenu then
        exports['qb-radialmenu']:RemoveOption(radialMenu)
    end
    radialMenu = nil
end

local function isJobValidated()
    if Config.BlackListedJobs then
        local Player = QBCore.Functions.GetPlayerData()
        local JobInBlackList = Config.BlackListedJobs[Player.job.name]
        if JobInBlackList then
            if JobInBlackList.onlyDuty then
                if Player.job.onduty then
                    return false
                else
                    return true
                end
            else
                return false
            end
        else
            return true
        end
    end
    return true
end

Citizen.CreateThread(function()
	local isInCar = false
	while true do
        Citizen.Wait(2000)				-- mandatory wait
        local ped = GetPlayerPed(-1)	-- get local ped
        if IsPedInAnyVehicle(ped, false) then
            if isJobValidated() then
                local veh = GetVehiclePedIsIn(ped, false)
                if isInCar == false then
                    isInCar = true
                    addRadialMenu()
                end
            end
        else
            if isInCar == true then
                isInCar = false
                removeRadialMenu()
            end
        end 
    end
end)

RegisterNetEvent('cw-outrun:client:toggleDebug', function(debug)
   print('Setting debug to',debug)
   useDebug = debug
end)

AddEventHandler('onResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then return end
    if DoesEntityExist(finishEntity) then
         print('deleting', finishEntity)
         DeleteEntity(finishEntity)
     end
     if radialMenu then
        exports['qb-radialmenu']:RemoveOption(radialMenu)
    end
     radialMenu = nil
end)