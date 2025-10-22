require("YmMusicTools")
require("YmTools")

local platformId = 229
local msgIdBlockState = 100115

local typeBoss = 10000


function CallbackCharCreated(playerId)
    local pos = Element:GetPosition(platformId)
    Character:SetPosition(playerId, pos + Engine.Vector(0, 0, 500))
end

function InitClient() 
    print("BindNotify InitClient")
    BindNotifyAction()
end

function InitServer() 
    -- RegisterEventsServer()
    -- TimerManager:AddTimer(UMath:GetRandomInt(1,10), PlaySfx, "levelcomplete")
    InitServerTimers()
end

function InitServerTimers() 
    -- TimerManager:AddLoopTimer(5, GenBlock)
    AddLoopTimerWithInit(0, 1, RunAllTimerTasks, "1sTasks")
    AddTimerTask("1sTasks", "genBlock", 0, 5, GenBlock)
    AddTimerTask("1sTasks", "genBoss", 0, 30, GenBoss)
    -- AddTimerTask("1sTasks", "sfxTest", 3, 60, function ()
    --     PlaySfx("starmantwo")
    -- end)
end

function UpdateBossSync(msg)
    local cid = msg.obj.id
    if msg.action == "move" then
        TimerManager:AddTimer(2, function ()
            Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SpearStartAttack", Animation.PART_NAME.FullBody)
        end)
        TimerManager:AddTimer(2.7, function ()
            TimerManager:AddLoopTimer(1, function ()
                Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SpearAttack", Animation.PART_NAME.FullBody)
            end)
        end)
        Creature:DestroyByTime(cid,29)
    end
end

function UpdateBoss(deltaTime, obj)
    -- print("UpdateBoss ", MiscService:Table2JsonStr(obj))
    if obj.state == "init" then
        obj.state = "move"
        local cid = obj.id
        -- TimerManager:AddTimer(1, function ()
        --     Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "CommonFallBackLoop", Animation.PART_NAME.FullBody)
        -- end)
        PushAction(true, "UpdateBossSync", {action="move", obj=obj})
        
    end
end

function PostGenBoss(msg)
    print("PostGenBoss")
    local cid = msg.cid
end

function GenBoss()
    local cid = Creature:SpawnCreature(1114000000000002, Element:GetPosition(platformId) + Engine.Vector(0,0,1000), Engine.Vector(0,0,0),1)
    local obj = AddNewObjState(0, typeBoss, cid, 1, UpdateBoss)
    -- obj.lastUpdateTs = GetGameTimeCur()
    
    TimerManager:AddTimer(2,function ()
        Creature:SetCreatureGravityInfluence(cid, false)
        Creature:SetPosition(cid, Creature:GetPosition(cid))
        -- UpdateAllObjStates(GetUpdateDeltaTime())
    end)
    
    -- PushAction(true, "PostGenBoss", {cid = cid})
end

function GetElementState(elementId)
    return {eid=elementId}
end

function SetElementStateColor(state, idx, color)
    if state.colors == nil then
        state.colors = {}
    end
    table.insert(state.colors, {n=idx, c=color})
end

function SetElementStatePhy(state, phyAffectForce, phyCarrible, phyColliChar)
    state.phys = {phyAffectForce, phyCarrible, phyColliChar}
end

function SetElementStateColli(state, enableColli)
    state.colls = enableColli
end

function SetElementStateMass(state, massNum)
    state.mass = massNum
end


function BuildBlockState(elementId, color1)
    local state = GetElementState(elementId)
    SetElementStateColor(state, 1, color1)
    SetElementStatePhy(state, true, true, true)
    SetElementStateColli(state, true)
    SetElementStateMass(state, 20)
    -- print("BuildBlockState ", MiscService:Table2JsonStr(state))
    return state
end

--同步元件状态
function SyncElementState(state)
    -- print("SyncElementState ", MiscService:Table2JsonStr(state))
    local elementId = state.eid

    if state.colors ~= nil then
        -- print("SyncElementState setcolor", MiscService:Table2JsonStr(state.colors))
        for key, value in pairs(state.colors) do
            Element:SetColor(elementId, value.n, value.c)
        end
    end

    if state.phys ~= nil then
        Element:SetPhysics(elementId, state.phys[1], state.phys[2], state.phys[3])
    end

    if state.colls ~= nil then
        Element:SetEnableCollision(elementId, state.colls)
    end

    if state.mass ~= nil then
        Element:SetMass(elementId, state.mass)
    end
end

function OnClientNotify(msgId, msg)
    print("OnClientNotify ", MiscService:Table2JsonStr(msg))
    if msgId == msgIdBlockState then
        if not System:IsStandalone() then
            SyncElementState(msg)
        end
    end
end



function GenBlock() 
    local callback = function(elementId)
        ServerLog("GenBlock res ", elementId)
        local color = getRandomColorRGBA()
        local state = BuildBlockState(elementId, color)
        PushAction(true, "SyncElementState", state)
        -- System:SendToAllClients(msgIdBlockState, state)
        -- SyncElementState(state)
        Element:DestroyByTime(elementId, 15)

        -- CustomProperty:SetCustomProperty(elementId, "musicVec", CustomProperty.PROPERTY_TYPE.Vector, Engine.Vector(0, trackIdx, noteIdx))
    end
    local pos = Element:GetPosition(platformId)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001037010, callback, pos + Engine.Vector(1500, 0, 1500), Engine.Rotator(0,0,0), Engine.Vector(1, 1, 1), true)
end

function RegisterEventsServer() 
    System:RegisterEvent(Events.ON_CHARACTER_CREATED, CallbackCharCreated)
end