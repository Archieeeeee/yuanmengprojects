require("YmTools")

local platformId = 229
local msgIdBlockState = 100115

function CallbackCharCreated(playerId)
    local pos = Element:GetPosition(platformId)
    Character:SetPosition(playerId, pos + Engine.Vector(0, 0, 500))
end

function InitClient() 
    print("BindNotify ")
    System:BindNotify(msgIdBlockState, OnClientNotify)
end

function InitServer() 
    -- RegisterEventsServer()
    TimerManager:AddTimer(UMath:GetRandomInt(1,10), PlaySfx, "levelcomplete")
    InitServerTimers()
end

function InitServerTimers() 
    TimerManager:AddLoopTimer(5, GenBlock)
end

function OnClientNotify(msgId, msg)
    print("OnClientNotify ", elementId)
    if msgId == msgIdBlockState then
        SetBlockState(msg)
    end
end

function SetBlockState(elementId)
    print("SetBlockState ", elementId)
    local color = getRandomColorRGBA()
    Element:SetColor(elementId, 1, color)
    Element:SetPhysics(elementId, true, true, true)
    Element:SetEnableCollision(elementId, true)
    Element:SetMass(elementId, 20)
end

function GenBlock() 
    local callback = function(elementId)
        print("SpawnElement res ", elementId)
        System:SendToAllClients(msgIdBlockState, elementId)
        SetBlockState(elementId)
        Element:DestroyByTime(elementId, 8)

        -- CustomProperty:SetCustomProperty(elementId, "musicVec", CustomProperty.PROPERTY_TYPE.Vector, Engine.Vector(0, trackIdx, noteIdx))
    end
    local pos = Element:GetPosition(platformId)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001037010, callback, pos + Engine.Vector(1500, 0, 1500), Engine.Rotator(0,0,0), Engine.Vector(1, 1, 1), true)
end

function RegisterEventsServer() 
    System:RegisterEvent(Events.ON_CHARACTER_CREATED, CallbackCharCreated)
end