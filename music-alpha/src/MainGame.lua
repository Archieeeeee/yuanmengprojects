require("YmMusicTools")
require("YmTools")

local platformId = 229
local msgIdBlockState = 100115
posOrg = Engine.Vector(0, 0, 0)

local typeObjs = {boss = 1000, blockUnknown=101}
local cfgAirWallId = 1105000000000074
local cfgElements = {}
local protos = {}
local cfgCopyProps = {}
local cfgDataNames = {"ymAnimes"}
local haohaoyaId = 327
animeDemo = {cur=0, lastName=nil, lastPlay=0, lastCount=0}
ymAnimes = {}


function CallbackCharCreated(playerId)
    local pos = Element:GetPosition(platformId)
    Character:SetPosition(playerId, pos + Engine.Vector(0, 0, 500))
end

function InitClient() 
    print("BindNotify InitClient")
    InitVars()
    BindNotifyAction()
end

function InitServer() 
    -- RegisterEventsServer()
    -- TimerManager:AddTimer(UMath:GetRandomInt(1,10), PlaySfx, "levelcomplete")
    InitVars()
    InitBlockProto()
    PushAction(true, "SyncInit", {})

    InitServerTimers()
end

function InitVars()
    posOrg = Element:GetPosition(platformId)
    LoadGlobalVarsFromData(cfgDataNames)
    print("animeData sss ", MiscService:Table2JsonStr(ymAnimes))
    -- print("animeData aaa ", MiscService:Table2JsonStr(animeData))
    -- print("animeData bbb ", animeData.m)
    -- for index, value in ipairs(animeData.animeList) do
    --     print("animeData index ", value.name)
    -- end
    -- print("animeData ", animeData)

    -- local varMsg = BuildSyncVarMsg()
    -- PushSyncVar(varMsg, "posOrg", posOrg)
    -- PushSyncVar(varMsg, "ymAnimes", ymAnimes)
    -- PushAction(false, "SyncGlobalVars", varMsg)
end

function PlayAnime()
    print("PlayAnime start")

    if LoopTimerCanRun(animeDemo, "lastPlay", 5) then
        animeDemo.cur = animeDemo.cur + 1
        if animeDemo.cur > #ymAnimes.animeList then
            animeDemo.cur = 1
        end
        PushGlobalVarSingle("animeDemo", animeDemo)
        PushAction(true, "SyncPlayAnime", {})
    end

    if LoopTimerCanRun(animeDemo, "lastCount", 1) then
        PushGlobalVarSingle("animeDemo", animeDemo)
        PushAction(true, "SyncPlayAnimeUI", {})
    end

end

function SyncPlayAnime()
    if animeDemo.cur ~= 0 then
        print("PlayAnime will play aaa", MiscService:Table2JsonStr(ymAnimes))
        print("PlayAnime will play bbb", MiscService:Table2JsonStr(animeDemo))
        print("PlayAnime will play ", ymAnimes.animeList[animeDemo.cur].v)
        PlayThenStopAnim(0, Animation.PLAYER_TYPE.Creature, haohaoyaId, ymAnimes.animeList[animeDemo.cur].v, Animation.PART_NAME.FullBody, 4.5, 0.2)
    end
end

function SyncPlayAnimeUI()
    print("SyncPlayAnime start ", MiscService:Table2JsonStr(animeDemo))
    local nextCur = animeDemo.cur + 1
    if nextCur > #ymAnimes.animeList then
        nextCur = 1
    end

    local cd = math.ceil(5 - GetGameTimeCur() + animeDemo.lastPlay)
    if animeDemo.cur ~= 0 then
        UI:SetText({101432}, UMath:NumberToString(cd))
        UI:SetText({101433}, string.format("正在播放: %s", ymAnimes.animeList[animeDemo.cur].n))
        UI:SetText({101211}, string.format("下一个: %s", ymAnimes.animeList[nextCur].n))
    end
end

function InitServerTimers() 
    -- TimerManager:AddLoopTimer(5, GenBlock)
    AddLoopTimerWithInit(0, 1, RunAllTimerTasks, "1sTasks")
    AddTimerTask("1sTasks", "genBlock", 2, 10, GenBlock)
    AddTimerTask("1sTasks", "genBoss", 2, 30, GenBoss)
    AddTimerTask("1sTasks", "playAnime", 3, 0.9, PlayAnime)
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

function UpdateBlock(deltaTime, obj)
    local bid = obj.id
    if CanObjStateInit(obj, "move.toMove") then
        Element:EnableMotionUnitByIndex(bid, 1, true)
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
    -- 投掷物
    Element:Destroy(obj.bindEid)
    -- 角色
    Creature:Destroy(obj.id)
    -- 平台
    Element:Destroy(obj.pid)
    
end

function DestroyBlock(deltaTime, obj)
    -- print("DestroyBlock start")
    DestroyElementAndChildren(obj.id)
end

function BindSpearToBoss(msg)
    Element:BindingToCharacterOrNPC(msg.eid, msg.cid, Character.SOCKET_NAME.Prop_R, Character.SOCKET_MODE.SnapToTarget)
end

function GenBossAfterPlatform(pid)
    local pos = Element:GetPosition(pid)
    local cid = Creature:SpawnCreature(1114000000000002, pos + Engine.Vector(0, 0, 200), Engine.Vector(0,0,0), 1)
    local obj = AddNewObj(0, typeObjs.boss, cid, 1, UpdateBoss, 29, DestroyBoss)
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
    cfgElements.cubeNight = {id=1101002001105000, size=Engine.Vector(1,1,1)}
    protos.blockUnknown = {}
    InitProtoBlockUnknown()

    TimerManager:AddTimer(1, function ()
        Creature:SetScale(haohaoyaId, 3)
    end)
    
end

function SyncInit()
    
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
        Element:SetPosition(eid, posOrg + Engine.Vector(0, 0, 500), Element.COORDINATE.World)
        local obj = AddNewObj(0, typeObjs.blockUnknown, eid, 0, UpdateBlock, 8, DestroyBlock)
        AddObjState(obj, "move.toMove")
        SetObjState(obj, "move.toMove", -1, -1, 90)
        StartObjStateByName(obj, "move", "toMove")
    end
    CopyElementAndChildren(protos.blockUnknown.id, cfgCopyProps, callback)
    -- CopyElementAndChildren(277, cfgCopyProps, callback)
end

function InitProtoBlockUnknown()
    local genPos = Engine.Vector(-10000, -10000, -10000)
    local awCallback = function (awId)
        Element:SetPosition(awId, genPos, Element.COORDINATE.World)
        SetElementScaleDstXyz(awId, cfgElements.airWall.size, 198, 198, 100)
        protos.blockUnknown.id = awId
        local cubeScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 2.0), cfgElements.cube.size)
        local cubeCallback = function (cubeId)
            Element:BindingToElement(cubeId,awId)
            print("InitProtoBlockUnknown done ", awId)
            -- Element:SetPosition(awId,posOrg + Engine.Vector(0,0, 1800), Element.COORDINATE.World)
        end
        Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.cube.id, cubeCallback, genPos + Engine.Vector(0, 0, 10), Engine.Rotator(0,0,0), cubeScale, true)
    end
    -- local awScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 1.0), cfgElements.airWall.size)
    -- Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.airWall.id, awCallback, genPos, Engine.Rotator(0,0,0), awScale, true)
    CopyElementAndChildren(291, cfgCopyProps, awCallback)
    -- CopyElementAndChildren(303, cfgCopyProps, awCallback)
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