-- server/weaponban.lua

local QBCore = exports['qb-core']:GetCoreObject()

local function parseDuration(duration)
    local hours, minutes, seconds = 0, 0, 0
    local patterns = {
        { "h", function(v) hours = v end },
        { "m", function(v) minutes = v end },
        { "s", function(v) seconds = v end }
    }
    for _, pattern in ipairs(patterns) do
        local value = string.match(duration, "(%d+)" .. pattern[1])
        if value then
            pattern[2](tonumber(value))
        end
    end
    return hours * 3600 + minutes * 60 + seconds
end

local function parseDate(dateString)
    local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
    local year, month, day, hour, min, sec = dateString:match(pattern)
    if year and month and day and hour and min and sec then
        return os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})
    else
        return nil
    end
end

QBCore.Commands.Add('weaponban', 'Ban a player from using weapons', {{name='id', help='Player ID'}, {name='duration', help='Duration (e.g., 1h30m)'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local targetId = tonumber(args[1])
    local duration = args[2]
    local Target = QBCore.Functions.GetPlayer(targetId)

    if QBCore.Functions.HasPermission(src, 'god') then
        if Target then
            local banDuration = parseDuration(duration)
            local banEnd = os.time() + banDuration

            exports.oxmysql:execute('UPDATE players SET weapon_ban_end = ? WHERE citizenid = ?', {
                os.date('%Y-%m-%d %H:%M:%S', banEnd),
                Target.PlayerData.citizenid
            }, function()
                TriggerClientEvent('QBCore:Notify', src, 'Player weapon banned successfully.', 'success')
                TriggerClientEvent('QBCore:Notify', targetId, 'You have been banned from using weapons.', 'error')
                TriggerClientEvent('QBCore:Client:CheckWeaponBan', targetId, true)
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Player not found.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command.', 'error')
    end
end, 'god')

QBCore.Commands.Add('weaponunban', 'Unban a player from using weapons', {{name='id', help='Player ID'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local targetId = tonumber(args[1])
    local Target = QBCore.Functions.GetPlayer(targetId)

    if QBCore.Functions.HasPermission(src, 'god') then
        if Target then
            exports.oxmysql:execute('UPDATE players SET weapon_ban_end = NULL WHERE citizenid = ?', {
                Target.PlayerData.citizenid
            }, function()
                TriggerClientEvent('QBCore:Notify', src, 'Player weapon unbanned successfully.', 'success')
                TriggerClientEvent('QBCore:Notify', targetId, 'You have been unbanned from using weapons.', 'success')
                TriggerClientEvent('QBCore:Client:CheckWeaponBan', targetId, false)
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Player not found.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command.', 'error')
    end
end, 'god')

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source

    exports.oxmysql:execute('SELECT weapon_ban_end FROM players WHERE citizenid = ?', {
        Player.PlayerData.citizenid
    }, function(result)
        if result[1] and result[1].weapon_ban_end then
            local banEndTime = parseDate(result[1].weapon_ban_end)
            if banEndTime and banEndTime > os.time() then
                TriggerClientEvent('QBCore:Client:CheckWeaponBan', src, true)
            else
                exports.oxmysql:execute('UPDATE players SET weapon_ban_end = NULL WHERE citizenid = ?', {
                    Player.PlayerData.citizenid
                })
            end
        end
    end)
end)
