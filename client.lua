local QBCore = exports['qb-core']:GetCoreObject()

local isWeaponBanned = false

RegisterNetEvent('QBCore:Client:CheckWeaponBan')
AddEventHandler('QBCore:Client:CheckWeaponBan', function(status)
    isWeaponBanned = status
end)

CreateThread(function()
    while true do
        Wait(1000)
        if isWeaponBanned then
            local playerPed = PlayerPedId()
            local weapon = GetSelectedPedWeapon(playerPed)
            if weapon and weapon ~= `WEAPON_UNARMED` then
                RemoveWeaponFromPed(playerPed, weapon)
                QBCore.Functions.Notify('You are banned from using weapons.', 'error')
            end
        end
    end
end)
