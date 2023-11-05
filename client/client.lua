local QBCore = exports['qb-core']:GetCoreObject()

local Countdown = 5
local currentRace = {}
local startTime = 0
local maxDistance = 20
local flareStartDistance = 100
local hasFinished = false
local FinishedUITimeout = false
local ghosted = false
local currentTime = 0
local inviteRaceId = nil
local useDebug = Config.Debug
local opponent = nil
local opponentId = nil
local finishBlip = nil
local PlayerJob = {}

local finishParticle
local finishEntity

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

local function finishRace()
    currentRace = nil
    RemoveBlip(finishBlip)
    finishBlip = nil
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


local function updateCountdown(value)
    SendNUIMessage({
        action = "Countdown",
        data = {
            value = value
        },
        active = true
    })
end

RegisterNetEvent('cw-head2head:client:notifyFinish', function(text)
    SendNUIMessage({
        action = "Finish",
        data = {
            value = text
        },
        active = true
    })
end)

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

local function showNonLoopParticle(dict, particleName, coords, scale, time)
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Wait(0)
    end

    UseParticleFxAssetNextCall(dict)

    local particleHandle = StartParticleFxLoopedAtCoord(particleName, coords.x, coords.y, coords.z-0.5, 0.0, 0.0, 0.0,
    scale, false, false, false)
    SetParticleFxLoopedColour(particleHandle,0.0,0.0,1.0)
    return particleHandle
end

local function DeletePile()
    if DoesEntityExist(finishEntity) then
        DeleteEntity(finishEntity)
        finishEntity = nil
    end
end

local function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(10)
    end
end

local function getPosition()
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)    
    local plyDistance = #(plyCoords.xy-currentRace.finishCoords.xy)

    local opponentId = GetPlayerFromServerId(opponentId)
    local target = GetPlayerPed(opponentId)
    local opponentCoords = GetEntityCoords(target, 0)
    local opponentDistance = #(opponentCoords.xy-currentRace.finishCoords.xy)

    if plyDistance < opponentDistance then
        return 1
    elseif plyDistance == opponentDistance then
        return '-'
    end
    return 2
end

local function handleFlare ()
    -- QBCore.Functions.Notify('Lighting '..checkpoint, 'success')

    local Size = 1.0
    local finishParticle = showNonLoopParticle('core', 'exp_grd_flare',
        currentRace.finishCoords, Size)

    SetTimeout(Config.FlareTime, function()
        StopParticleFxLooped(finishParticle, false)
        particleHandle = nil
        DeletePile()
    end)
end

local function CreatePile()
    ClearAreaOfObjects(currentRace.finishCoords.x, currentRace.finishCoords.y, currentRace.finishCoords.z, 50.0, 0)
    LoadModel(Config.FinishModel)

    local Obj = CreateObject(Config.FinishModel, currentRace.finishCoords.x, currentRace.finishCoords.y, currentRace.finishCoords.z, 0, 0, 0) -- CHANGE ONE OF THESE TO MAKE NETWORKED???
    PlaceObjectOnGroundProperly(Obj)
    -- FreezeEntityPosition(Obj, 1)
    SetEntityAsMissionEntity(Obj, 1, 1)

    return Obj
end

local function DoPilePfx()
    handleFlare()
    finishEntity = CreatePile()
end

local function setupRace()
    CreateThread(function()
        while true do
            if currentRace ~= nil then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                if currentRace.started and not currentRace.finished then
                    local distanceToFinish = #(pos.xy - currentRace.finishCoords.xy)
                    if finishEntity == nil and not hasFinished and distanceToFinish < flareStartDistance then
                        DoPilePfx()
                    end
                    if not hasFinished and distanceToFinish < maxDistance then
                        PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                        TriggerServerEvent('cw-head2head:server:finishRacer', currentRace.raceId, QBCore.Functions.GetPlayerData().citizenid, GetTimeDifference(GetCloudTimeAsInt(), startTime) )
                        hasFinished = true
                        Countdown = 5
                        Wait(1000)
                        finishRace()
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
            if not hasFinished then
                currentTime = GetTimeDifference(GetCloudTimeAsInt(), startTime)
                SendNUIMessage({
                    action = "Update",
                    type = "race",
                    data = {
                        Time = currentTime,
                        Ghosted = ghosted,
                        Started = currentRace.started,
                        Position = getPosition()
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

RegisterNetEvent('cw-head2head:client:checkDistance', function(raceId, coords, amount, host)
    local citizenId = QBCore.Functions.GetPlayerData().citizenid
    if useDebug then
        print('checking if close to race', raceId, citizenId, host)
    end
    if host ~= citizenId and playerIsWithinDistance(coords) and isInDriverSeat() then
        if useDebug then
            print('can join')
        end
        inviteRaceId = raceId
        local text = Lang:t('info.you_got_an_invite')
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

RegisterNetEvent('cw-head2head:client:joinRace', function()
    if useDebug then
        print('attempting to join', inviteRaceId)
    end
    if inviteRaceId then
        local citizenId = QBCore.Functions.GetPlayerData().citizenid
        local racerName = ''
        TriggerServerEvent('cw-head2head:server:joinRace', citizenId, racerName, inviteRaceId)
        handleHighBeams()
    else
        QBCore.Functions.Notify(Lang:t('error.you_have_no_invites'), 'error')
    end
end)

local defaultLightsState = 0
RegisterNetEvent('cw-head2head:client:setupRace', function(data)
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
    local finishCoords = nil
    if GetFirstBlipInfoId( 8 ) ~= 0 then
        local waypointBlip = GetFirstBlipInfoId( 8 ) 
        local coord = Citizen.InvokeNative( 0xFA7C7F0AADF25D09, waypointBlip, Citizen.ResultAsVector( ) )
        finishCoords = vector3(coord.x,coord.y,coord.z)
    end
    TriggerServerEvent('cw-head2head:server:setupRace', citizenId, racerName, startCoords, amount, 'head2head', finishCoords)
    handleHighBeams()
end)

RegisterNetEvent('cw-head2head:client:raceCountdown', function(race)
    QBCore.Functions.TriggerCallback('cw-head2head:server:getPlayers', function(players)
        Players = players
        currentRace = race
        hasFinished = false
        if useDebug then
            print('Starting Countdown', dump(race))
        end
        if currentRace.raceId ~= nil then
            finishBlip = AddBlipForCoord(currentRace.finishCoords)
            setupRaceUI()
            setupRace()
            opponent = getOpponent()
            SetNewWaypoint(currentRace.finishCoords.x, currentRace.finishCoords.y)
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
        id = 'head2headJoin',
        title = Lang:t('menu.join'),
        icon = 'check',
        type = 'client',
        event = 'cw-head2head:client:joinRace',
        shouldClose = true
    },
    {
        id = 'head2headFree',
        title = Lang:t('menu.setup'),
        icon = 'comments',
        type = 'client',
        event = 'cw-head2head:client:setupRace',
        value = 0,
        shouldClose = true
    }
}

for i, value in pairs(Config.BuyIns) do
    items[#items+1] = {
        id = 'head2head'..value,
        title = Lang:t('menu.setup')..' ($'..value..')',
        icon = 'comments-dollar',
        type = 'client',
        event = 'cw-head2head:client:setupRace',
        value = value,
        shouldClose = true
    }
end

local radialMenu = nil

local function addRadialMenu()
    radialMenu = exports['qb-radialmenu']:AddOption({
        id = 'head2head',
        title = Lang:t('menu.title'),
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
        Wait(2000)					-- mandatory wait
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

RegisterNetEvent('cw-head2head:client:debugMap', function()
    if #markers > 0 then
        print('removing markers')
        for i, marker in pairs(markers) do
            RemoveBlip(marker)
        end
        markers = {}
    else
        print('adding markers')
        for i, coord in pairs(Config.Finishes) do
            markers[#markers+1] = AddBlipForCoord(coord.x, coord.y, coord.z)
        end    
    end
end)

RegisterNetEvent('cw-head2head:client:toggleDebug', function(debug)
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