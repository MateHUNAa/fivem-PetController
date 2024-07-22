ESX = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()


RegisterCommand("create", (function()
     PetMenu = {}

     local header = "Pet Controller"

     PetMenu[#PetMenu + 1] = { title = header, description = "Here you can control all the pet stuff.", isMenuHeader = true }
     PetMenu[#PetMenu + 1] = {
          icon = "fas fa-circle-xmark",
          title = " ",
          description = "Close",
          event = "mate-petcontroller:Close"
     }

     exports["ox_lib"]:registerContext({
          id = "PetMenu",
          title = "Pet Controller",
          position = "top-right",
          options = PetMenu
     })

     exports["ox_lib"]:showContext("PetMenu")
end), false)
