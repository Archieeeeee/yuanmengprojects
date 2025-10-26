require("YmMusicTools")
require("YmTools")

local platformId = 229
local msgIdBlockState = 100115
local posOrg = Engine.Vector(0, 0, 0)

local typeBoss = 10000
local cfgAirWallId = 1105000000000074
local cfgElements = {}
local protos = {}
local cfgCopyProps = {}


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
    InitVars()
    InitBlockProto()
end

function InitVars()
    posOrg = Element:GetPosition(platformId)
end

function InitServerTimers() 
    -- TimerManager:AddLoopTimer(5, GenBlock)
    AddLoopTimerWithInit(0, 1, RunAllTimerTasks, "1sTasks")
    AddTimerTask("1sTasks", "genBlock", 0, 10, GenBlock)
    AddTimerTask("1sTasks", "genBoss", 0, 30, GenBoss)
    -- AddTimerTask("1sTasks", "sfxTest", 3, 60, function ()
    --     PlaySfx("starmantwo")
    -- end)
end

function UpdateBossSync(msg)
    local cid = msg.obj.id
    if msg.action == "attack" then
        PlayThenStopAnim(1, Animation.PLAYER_TYPE.Creature, cid, "SpearStartAttack", Animation.PART_NAME.FullBody, 1.7, 0.2)
        PlayThenStopAnim(2, Animation.PLAYER_TYPE.Creature, cid, "SpearAttack", Animation.PART_NAME.FullBody, 2.7, 0.2)
        -- TimerManager:AddTimer(1, function ()
        --     Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SpearStartAttack", Animation.PART_NAME.FullBody)
        -- end)
        -- TimerManager:AddTimer(1.7, function ()
        --         Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SpearAttack", Animation.PART_NAME.FullBody)
        --     end)
        -- TimerManager:AddTimer(2.7, function ()
        --     Animation:StopAnim(Animation.PLAYER_TYPE.Creature, cid, "SpearAttack", Animation.PART_NAME.FullBody)
        -- end)
        -- Creature:DestroyByTime(cid,29)
    elseif msg.action == "move" then
        PlayThenStopAnim(0, Animation.PLAYER_TYPE.Creature, cid, "SitIdle", Animation.PART_NAME.FullBody, 4, 0.2)
        -- Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SitIdle", Animation.PART_NAME.FullBody)
    end
end

function UpdateBoss(deltaTime, obj)
    -- print("UpdateBoss ", MiscService:Table2JsonStr(obj))
    local cid = obj.id
    if IsObjStateCurAndInit(obj, "move", "toMove") then
        local state = GetObjState(obj, "move.toMove")
        if state.dir == nil then
            state.dir = false
        end
        state.dir = (not state.dir)
        local diff = -300
        if state.dir then
            diff = (-1 * diff)
        end
        PushAction(true, "UpdateBossSync", {action="move", obj=obj})
        
        Creature:SetTargetPointMove(cid, posOrg + Engine.Vector(diff, 0, 200), 1)
    elseif IsObjStateCurAndInit(obj, "move", "toAttack") then
        -- TimerManager:AddTimer(1, function ()
        --     Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "CommonFallBackLoop", Animation.PART_NAME.FullBody)
        -- end)
        PushAction(true, "UpdateBossSync", {action="attack", obj=obj})
    end
end

function PostGenBoss(msg)
    print("PostGenBoss")
    local cid = msg.cid
end

function GenBoss()
    local pos = posOrg + Engine.Vector(500,0,1000)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001034000, GenBossAfterPlatform, pos, Engine.Rotator(0,0,0), Engine.Vector(20,5,1), true)
    Element:SpawnElement(Element.SPAWN_SOURCE.Scene, 251, function ()
        
    end, pos, Engine.Rotator(0,0,0), Engine.Vector(1,1,1), true)
end

function DestroyBoss(deltaTime, obj)
    Element:Destroy(obj.bindEid)
    Creature:Destroy(obj.id)
    Element:Destroy(obj.pid)
    
end

function BindSpearToBoss(msg)
    Element:BindingToCharacterOrNPC(msg.eid, msg.cid, Character.SOCKET_NAME.Prop_R, Character.SOCKET_MODE.SnapToTarget)
end

function GenBossAfterPlatform(pid)
    local pos = Element:GetPosition(pid)
    local cid = Creature:SpawnCreature(1114000000000002, pos + Engine.Vector(0, 0, 200), Engine.Vector(0,0,0), 1)
    local obj = AddNewObj(0, typeBoss, cid, 1, UpdateBoss, 29, DestroyBoss)
    obj.pid = pid

    AddObjState(obj, "move.toMove")
    SetObjState(obj, "move.toMove", -1, -1, 5)
    AddObjState(obj, "move.toAttack")
    SetObjState(obj, "move.toAttack", -1, -1, 5)
    SetObjStateNext(obj, "move.toMove", "move", "toAttack")
    SetObjStateNext(obj, "move.toAttack", "move", "toMove")
    StartObjStateByName(obj, "move", "toMove")

    print("GenBoss after ", MiscService:Table2JsonStr(obj))

    local callback = function (eid)
        local state = GetElementState(eid)
        obj.bindEid = eid
        SetElementStatePhy(state, false, false, false)
        SetElementStateColli(state, false)
        PushAction(true, "SyncElementState", state)
        PushAction(true, "BindSpearToBoss", {eid=eid, cid=cid})
    end

    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001034000, callback, pos, Engine.Rotator(0,0,0), Engine.Vector(1,1,1), true)

    -- TimerManager:AddTimer(3,function ()
    --     CheckAllObjStates(0.1)
    -- end)
    
    -- TimerManager:AddTimer(2,function ()
    --     -- Creature:SetCreatureGravityInfluence(cid, false)
    --     Creature:SetPosition(cid, Creature:GetPosition(cid))
    --     -- UpdateAllObjStates(GetUpdateDeltaTime())
    -- end)
    
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

function InitBlockProto()
    cfgElements.airWall = {id=1105000000000074, size=Engine.Vector(5,5,3)}
    cfgElements.cube = {id=1101002001034000, size=Engine.Vector(1,1,1)}
    protos.blockUnknown = {}
    InitProtoBlockUnknown()
end

function GenBlock()
    local rd = UMath:GetRandomInt(1,1)
    if rd == 1 then
        GenBlockUnknown()
    end
end

function GenBlockUnknown()
    print("GenBlockUnknown start")
    local callback = function (eid)
        print("GenBlockUnknown done", eid)
        Element:SetPosition(eid, posOrg + Engine.Vector(0, 0, 900), Element.COORDINATE.World)
    end
    -- CopyElementAndChildren(protos.blockUnknown.id, cfgCopyProps, callback)
    CopyElementAndChildren(277, cfgCopyProps, callback)
end

function InitProtoBlockUnknown()
    local genPos = Engine.Vector(-10000, -10000, -10000)
    local awCallback = function (awId)
        protos.blockUnknown.id = awId
        local cubeScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 2.0), cfgElements.cube.size)
        local cubeCallback = function (cubeId)
            Element:BindingToElement(cubeId,awId)
            print("InitProtoBlockUnknown done ", awId)
            -- Element:SetPosition(awId,posOrg + Engine.Vector(0,0, 1800), Element.COORDINATE.World)
        end
        Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.cube.id, cubeCallback, genPos + Engine.Vector(0, 0, 10), Engine.Rotator(0,0,0), cubeScale, true)
    end
    local awScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 2.0), cfgElements.airWall.size)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.airWall.id, awCallback, genPos, Engine.Rotator(0,0,0), awScale, true)
end

function GenBlockBall() 
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