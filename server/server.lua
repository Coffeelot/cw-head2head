local QBCore = exports['qb-core']:GetCoreObject()
local useDebug = Config.Debug

function dump(o)
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

local activeRaces = {}

local race = {
    racers = { nil, nil},
    startCoords = nil,
    finishCoords = nil,
    winner = nil,
    started = false,
    finished = false,
    forMoney = false,
    amount = 0
}

local function generateRaceId()
    local RaceId = "IR-" .. math.random(1111, 9999)
    while activeRaces[RaceId] ~= nil do
        RaceId = "IR-" .. math.random(1111, 9999)
    end
    return RaceId
end

local function getFinish(startCoords)
    local count = 0
    for i=1, 100 do
        local finishCoords = Config.Finishes[math.random(1,#Config.Finishes)]
        local distance = #(finishCoords.xy-startCoords.xy)
        if tonumber(distance) > Config.MinimumDistance and tonumber(distance) < Config.MaximumDistance then
            return finishCoords
        end
    end
end

RegisterNetEvent('cw-head2head:server:setupRace', function(citizenId, racerName, startCoords, amount, type, waypoint)
    local raceId = generateRaceId()
    if useDebug then
        print('setting up', citizenId, racerName, startCoords, amount)
    end

    local finishCoords = 'none'
    if type == 'head2head' then
        if waypoint == nil then
            finishCoords = getFinish(startCoords)
        else
            finishCoords = waypoint
        end
    end
    if finishCoords then
        activeRaces[raceId] = {
            raceId = raceId,
            type = type,
            racers = { { citizenId = citizenId, racerName = racerName, source = source } },
            startCoords = startCoords,
            finishCoords = finishCoords,
            winner = nil,
            started = false,
            finished = false,
            amount = amount,
        }
        if Config.SoloRace then
            TriggerEvent('cw-head2head:server:startRace', raceId) -- Used for debugging
        else
            TriggerClientEvent('cw-'..type..':client:checkDistance', -1, raceId, startCoords, amount, citizenId)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t("error.failed_to_find_a_waypoint"), "error")
    end
end)

RegisterNetEvent('cw-head2head:server:startRace', function(raceId)
    if useDebug then
        print('starting race')
    end
    activeRaces[raceId].started = false
    for citizenId, racer in pairs(activeRaces[raceId].racers) do
        if useDebug then
            print('racer', dump(racer))
        end
        local Player = QBCore.Functions.GetPlayerByCitizenId(racer.citizenId)
        if Player ~= nil then
            if useDebug then
                print('pinging player', Player.PlayerData.source)
            end
            if activeRaces[raceId].amount > 0 then
                if useDebug then
                    print('money', activeRaces[raceId].amount)
                end
                Player.Functions.RemoveMoney(Config.MoneyType, activeRaces[raceId].amount, "Head2Head")
            end
            if activeRaces[raceId].type == 'head2head' then
                TriggerClientEvent('cw-head2head:client:raceCountdown', Player.PlayerData.source, activeRaces[raceId])
            else
                TriggerClientEvent('cw-outrun:client:raceCountdown', Player.PlayerData.source, activeRaces[raceId])
            end
        end
    end
end)

RegisterNetEvent('cw-head2head:server:raceStarted', function(raceId)
    activeRaces[raceId].started = true
end)

RegisterNetEvent('cw-head2head:server:joinRace', function(citizenId, racerName, raceId)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if useDebug then
        print('money', Player.PlayerData.money[Config.MoneyType], activeRaces[raceId].amount)
    end
    if activeRaces[raceId].started then
        TriggerClientEvent('QBCore:Notify', source, Lang:t("error.race_already_started"), "error")
    elseif activeRaces[raceId].amount > 0 and Player.PlayerData.money[Config.MoneyType] < activeRaces[raceId].amount then
        TriggerClientEvent('QBCore:Notify', source, Lang:t("error.not_enough_money"), "error")
    else
        if useDebug then
            print('type: ', activeRaces[raceId].type)
        end
        activeRaces[raceId].racers[#activeRaces[raceId].racers+1] = { citizenId = citizenId, source = source, racerName = racerName }
        if #activeRaces[raceId].racers > 1 then
            TriggerEvent('cw-head2head:server:startRace', raceId)
        end
    end
end)

RegisterNetEvent('cw-head2head:server:outrunWinner', function(raceId, citizenId, opponentSource, finishTime)
    if useDebug then
        print('finishing outrun with ', citizenId, 'as the winner. race id:', raceId)
        print('Loser ', opponentSource)
    end
    TriggerClientEvent('cw-outrun:client:notifyFinish', source, Lang:t('info.winner'))
    TriggerClientEvent('cw-outrun:client:notifyFinish', opponentSource, Lang:t('info.loser'))
    if activeRaces[raceId].amount > 0 then
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
        Player.Functions.AddMoney(Config.MoneyType, activeRaces[raceId].amount*2, 'outrun winner')
    end
end)

RegisterNetEvent('cw-head2head:server:finishRacer', function(raceId, citizenId, finishTime)
    if useDebug then
        print('finishing', citizenId, 'in race', raceId)
    end
    if activeRaces[raceId].winner == nil then
        activeRaces[raceId].winner = citizenId
        TriggerClientEvent('cw-head2head:client:notifyFinish', source, Lang:t('info.winner'))
        if activeRaces[raceId].amount > 0 then
            local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
            Player.Functions.AddMoney(Config.MoneyType, activeRaces[raceId].amount*2, 'head2head winner')
        end
    else
        activeRaces[raceId].finished = true
        TriggerClientEvent('cw-head2head:client:notifyFinish', source, Lang:t('info.loser'))
    end
end)

QBCore.Functions.CreateCallback('cw-head2head:server:getPlayers', function(_, cb)
    local players = GetPlayers()
    local playerIds = {}
    for index, player in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(tonumber(player))
        local citizenid = Player.PlayerData.citizenid
        playerIds[#playerIds+1] = {
            citizenid =citizenid,
            sourceplayer = player,
            id = player
        }
    end
    cb(playerIds)
end)


QBCore.Commands.Add('impsetup', 'setup impromtu',{}, false, function(source)
    TriggerClientEvent('cw-head2head:client:setupRace', source)
end, 'admin')

QBCore.Commands.Add('impjoin', 'join impromtu',{}, false, function(source)
    TriggerClientEvent('cw-head2head:client:joinRace', source)
end, 'admin')

QBCore.Commands.Add('impdebug', 'debug impromtu',{}, false, function(source)
    TriggerClientEvent('cw-head2head:client:debugMap', source)
end, 'admin')

QBCore.Commands.Add('cwdebughead2head', 'toggle debug for head2head', {}, true, function(source, args)
    useDebug = not useDebug
    print('debug is now:', useDebug)
    TriggerClientEvent('cw-head2head:client:toggleDebug',source, useDebug)
end, 'admin')