ESX = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()




local SummonedPets                  = {}
local PetController                 = {}
---@type number
PetController.EntityHandle          = nil
PetController.ownerped              = nil
PetController.CustomId              = nil
PetController.NetId                 = nil
---@type table
PetController.Data                  = {}
---@type string
PetController.Data.Model            = nil
PetController.Data.Name             = nil
---@type boolean
PetController.Data.isAlive          = nil
---@type number
PetController.Data.Status.Happiness = nil
PetController.Data.Status.Hunger    = nil
PetController.Data.Status.Thirst    = nil
PetController.Data.Status.Joy       = nil

---@type string
PetController.owner                 = nil

---@enum statusAttribs
local statusAttribs                 = {
    "Happiness",
    "Hunger",
    "Thirst",
    "Joy"
}

---@enum Pets
local Pets                          = {
    ["dog"] = { true, model = "entityModel" }
}

function PetController:new(pet, owner, petName)
    assert(Pets[pet][1], "^7[^3PetController^7]: ^1Invalid^2 Pet<type> provided ^7")

    if not petName then
        local playerName = GetPlayerName(owner)
        local playerJob  = GetPlayerJob(owner)
        local randomNum  = math.random(1, 100)

        petName          = playerName .. "_" .. playerJob .. "_" .. randomNum
    end

    local myped = PlayerPedId()
    local instance = setmetatable({}, { __index = PetController })
    instance.EntityHandle = nil
    instance.owner = owner
    instance.ownerped = myped
    instance.CustomId = nil
    instance.NetId = nil
    instance.Data = {
        Model   = Pets[pet].model,
        isAlive = nil,
        Name    = petName or "Undefined",
        Status  = {
            Happiness = 100,
            Hunger    = 100,
            Thirst    = 100,
            Joy       = 100,
        }
    }

    return instance
end

function PetController:create()
    local myped = PlayerPedId()
    local myCoords = GetEntityCoords(myped)

    if self.Data.Name ~= "Undefined" or type(self.Data.Name) ~= "nil" then
        self.CustomId = self.Data.Name
    else
        mCore.debug.error(("^7[^3PetController^7]: ^2 Cannot create a ^6Pet^2 No name defined !^7"))
        return
    end

    self.EntityHandle = mCore.makePed(self.Data.Model, vec3(myCoords.x - .5, myCoords.y + .5, myCoords.z), false,
        true, "scenario", "anim")

    if DoesEntityExist(self.EntityHandle) then
        SummonedPets[self.CustomId] = self.EntityHandle
    else
        mCore.debug.error(("^7[^3PetController^7]:^2 Cannot save ^7(^6%s^7)^2 to ^7(^2SummonedPets^7)^2 returning a deleteing entity !^7")
            :format(self.Data.Name))

        self:destroy()
        return
    end

    self.NetId = PedToNet(self.EntityHandle)
    self.isAlive = true
    self:startStatusDegradation()


    -- Todo Config
    if Config.useTarget[Config.Target] and Config.Target == "ox" then
        exports["ox_target"]:addEntity(self.NetId, {
            {
                label = ("Pet %s"):format(self.Data.Name),
                name = "pet-a-pet",
                icon = "fas fa-paw",
                distance = 1.2,
                onSelect = (function(data)
                    print("onSelect: ", json.encode(data))
                    self:pet()
                end)
            }
        })
    end

    return { ped = self.EntityHandle, net = self.NetId }
end

function PetController:destroy()
    if DoesEntityExist(self.EntityHandle) then
        if self.CustomId then
            SummonedPets[self.CustomId] = nil
        end

        mCore.unloadModel(GetEntityModel(self.EntityHandle))
        DeleteEntity(self.EntityHandle)
    end
end

function PetController:follow()
    if DoesEntityExist(self.ownerped) and DoesEntityExist(self.EntityHandle) then
        TaskGoToEntity(self.EntityHandle, self.ownerped, 400,
            #(GetEntityCoords(self.ownerped) - GetEntityCoords(self.EntityHandle)), 1.0, 100, 0, 0)
    end
end

function PetController:sit()
    local dic = ""
    local anim = ""
    if DoesEntityExist(self.EntityHandle) then
        TaskPlayAnim(self.EntityHandle, dic, anim, 8.0, 8.0, -1, 0, 0.5, false, false, false)
    end
end

function PetController:pet()
    print("Petting a pet !")
end

function PetController:attack()
    if DoesEntityExist(self.EntityHandle) then
        local targetPed = GetPedToAttack(self)
        if type(targetPed) == "nil" then
            mCore.debug.log(("^7[^3PetController^7]:^2 ^1Cannot^2 target any ped got ^7(^1%s^7)^2 execpted ^7(^2%s^7)^7")
                :format(
                    type(targetPed),
                    "PedHandle"
                ))
            return false
        end


        -- TODO: Move pet to target ped,
        -- TODO: Make pet attack the target

        return true
    end
end

function PetController:startStatusDegradation()
    Citizen.CreateThread((function()
        while self.isAlive do
            Citizen.Wait(math.random(60000, 120000)) -- Wait b2w 1-2 mins
            self:decreaseStatus()
        end
    end))
end

function PetController:decreaseStatus()
    for i = 1, math.random(1, 2) do
        local attrToDecrease = statusAttribs[math.random(#statusAttribs)]
        local oldStatus = self.Data.Status[attrToDecrease]
        local newStatus = math.random(0, self.Data.Status[attrToDecrease] - math.random(1, 6))
        self.Data.Status[attrToDecrease] = newStatus
        mCore.debug.log(("^7[^3PetController^7]:^2 Status has change for ^6%s^2 ^6key:^2 ^7(^8%s^7)^2 ^7(^4%s^7)^2 -> ^7(^5%s^7)")
            :format(
                self.Data.Name or "Unknown",
                attrToDecrease,
                oldStatus,
                newStatus
            ))
    end
end

function PetController:onDamaged(damageAmount)
    mCore.debug.log(("^7[^3PetController^7]: ^2 Pet damaged by ^7(^1%s^7)"):format(damageAmount))
    self:decreaseStatus()
end

function PetController:MonitorHealth()
    Citizen.CreateThread((function()
        local lastHealth = GetEntityHealth(self.EntityHandle)

        while DoesEntityExist(self.EntityHandle) do
            Citizen.Wait(255)
            local currentHealth = GetEntityHealth(self.EntityHandle)

            if currentHealth < lastHealth then
                self:onDamaged(lastHealth - currentHealth)
                lastHealth = currentHealth
            end
        end
    end))
end

----------------------
-- Functions

function GetPedToAttack(self)
    if DoesEntityExist(self.EntityHandle) then
        local petCoords = GetEntityCoords(self.EntityHandle)
        local peds = GetPedsInArea(petCoords, Config.SearchTargetRadius)
        local targetPed = nil

        for _, ped in ipairs(peds) do
            if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
                if not IsTargetAFriend() and not IsTargetInSameJob() then
                    targetPed = ped
                    break
                end
            end
        end

        if targetPed then
            return targetPed
        else
            return nil
        end
    end
end

function GetPedsInArea(coord, radius)
    local Peds = {}
    local handle, ped = FindFirstPed()
    local success


    repeat
        local pedCoords = GetEntityCoords(ped)
        if #(coords - pedCoords) < radius then
            table.insert(Peds, ped)
        end
        success, ped = FindNextPed(handle)
    until not success

    EndFindPed(handle)
    return peds
end

function IsTargetAFriend()
    return true
end

function IsTargetInSameJob()
    return true
end

function IsActionMadeByOwner(self)
    if self.owner ~= source then
        return false
    end


    return true
end

----------------------
-- Events

AddEventHandler("onResourceStop", (function(r)
    if r ~= GetCurrentResourceName() then return end
    for i = 1, #SummonedPets do
        mCore.unloadModel(GetEntityModel(SummonedPets[i]))
        DeleteEntity(SummonedPets[i])
    end
end))

-- # Usage:

local i = PetController:new("dog", "playerId", "PetName")
local result = i:create() -- result = {ped= petPedHandle, net= PetPedNetId}
if DoesEntityExist(result.ped) then
    i:MonitorHealth()
end
