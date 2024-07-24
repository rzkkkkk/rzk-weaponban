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

            exports['oxmysql']:execute('UPDATE players SET weapon_ban_end = @weapon_ban_end WHERE citizenid = @citizenid', {
                ['@weapon_ban_end'] = os.date('%Y-%m-%d %H:%M:%S', banEnd),
                ['@citizenid'] = Target.PlayerData.citizenid
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
            exports['oxmysql']:execute('UPDATE players SET weapon_ban_end = NULL WHERE citizenid = @citizenid', {
                ['@citizenid'] = Target.PlayerData.citizenid
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

QBCore.Commands.Add('weaponbanstatus', 'Check your weapon ban status', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    exports['oxmysql']:execute('SELECT weapon_ban_end FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid
    }, function(result)
        if result[1] and result[1].weapon_ban_end then
            local banEndTime = os.time({year = tonumber(result[1].weapon_ban_end:sub(1, 4)), month = tonumber(result[1].weapon_ban_end:sub(6, 7)), day = tonumber(result[1].weapon_ban_end:sub(9, 10)), hour = tonumber(result[1].weapon_ban_end:sub(12, 13)), min = tonumber(result[1].weapon_ban_end:sub(15, 16)), sec = tonumber(result[1].weapon_ban_end:sub(18, 19))})
            if banEndTime > os.time() then
                local timeLeft = os.date('%X', os.difftime(banEndTime, os.time()))
                TriggerClientEvent('QBCore:Notify', src, 'Your weapon ban ends in ' .. timeLeft, 'info')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You are not currently banned from using weapons.', 'success')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You are not currently banned from using weapons.', 'success')
        end
    end)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source

    exports['oxmysql']:execute('SELECT weapon_ban_end FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid
    }, function(result)
        if result[1] and result[1].weapon_ban_end then
            local banEndTime = os.time({year = tonumber(result[1].weapon_ban_end:sub(1, 4)), month = tonumber(result[1].weapon_ban_end:sub(6, 7)), day = tonumber(result[1].weapon_ban_end:sub(9, 10)), hour = tonumber(result[1].weapon_ban_end:sub(12, 13)), min = tonumber(result[1].weapon_ban_end:sub(15, 16)), sec = tonumber(result[1].weapon_ban_end:sub(18, 19))})
            if banEndTime > os.time() then
                TriggerClientEvent('QBCore:Client:CheckWeaponBan', src, true)
            else
                exports['oxmysql']:execute('UPDATE players SET weapon_ban_end = NULL WHERE citizenid = @citizenid', {
                    ['@citizenid'] = Player.PlayerData.citizenid
                })
            end
        end
    end)
end)
