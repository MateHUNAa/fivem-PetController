ESX = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()


RegisterNetEvent("mate:ui:show", (function()
     SendNUIMessage({
          type = "m-toggleUI",
          value = false
     })
end))

RegisterNetEvent("mate:ui:hide", (function()
     SendNUIMessage({
          type = "m-toggleUI",
          value = true
     })
end))





AddEventHandler('onResourceStop', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          TriggerServerEvent("mate-aaaaaa:CleanUP")
     end
end)
