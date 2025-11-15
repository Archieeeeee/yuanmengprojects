require("YmMusicTools")
require("YmTools")

local platformId = 229
local msgIdBlockState = 100115
posOrg = Engine.Vector(0, 0, 0)

local typeObjs = {boss = 1000, blockUnknown=101, brick=103}
local cfgAirWallId = 1105000000000074
local cfgElements = {}
local protos = {}
local cfgCopyProps = {"debris"}
local cfgDataNames = {"ymAnimes"}
local haohaoyaId = 327
animeDemo = {cur=0, lastName=nil, lastPlay=0, lastCount=0}
ymAnimes = {}
local elesInScene = {airwall=331}


function CallbackCharCreated(playerId)
    local pos = Element:GetPosition(platformId)
    Character:SetPosition(playerId, pos + Engine.Vector(0, 0, 500))
end

function InitClient() 
    InitMusicClient()
end

function InitServer() 
    -- RegisterEventsServer()
    -- TimerManager:AddTimer(UMath:GetRandomInt(1,10), PlaySfx, "levelcomplete")
    InitBlockProto()
    PushActionToClients(true, "SyncInit", {})

    InitServerTimers()

    if not System:IsStandalone() then
        InitMusic()
    end
    RegisterEventsServer()
end

function InitVarsClient()
    
end

function InitVarsServer()
    
end

function PostInitClient()
    
end

function PostInitServer()
    
end

function OnClientInited()
    Creature:SetScale(haohaoyaId, 3)
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
    -- PushActionToClients(false, "SyncGlobalVars", varMsg)
end

function PlayAnime()
    print("PlayAnime start")

    if LoopTimerCanRun(animeDemo, "lastPlay", 5) then
        animeDemo.cur = animeDemo.cur + 1
        if animeDemo.cur > #ymAnimes.animeList then
            animeDemo.cur = 1
        end
        PushGlobalVarSingle("animeDemo", animeDemo)
        PushActionToClients(true, "SyncPlayAnime", {})
    end

    if LoopTimerCanRun(animeDemo, "lastCount", 1) then
        PushGlobalVarSingle("animeDemo", animeDemo)
        PushActionToClients(true, "SyncPlayAnimeUI", {})
    end

end

function SyncPlayAnime()
    if animeDemo.cur ~= 0 then
        -- print("PlayAnime will play aaa", MiscService:Table2JsonStr(ymAnimes))
        -- print("PlayAnime will play bbb", MiscService:Table2JsonStr(animeDemo))
        -- print("PlayAnime will play ", ymAnimes.animeList[animeDemo.cur].v)
        -- PlaySfx("oneup", 0, 0.8)
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
    
    AddTimerTask(TaskNames.task1s, "genBlock", 2, 10, GenBlock)
    AddTimerTask(TaskNames.task1s, "genBoss", 2, 30, GenBoss)
    AddTimerTask(TaskNames.task1s, "GenBlockBall", 2, 10, GenBlockBall)
    AddTimerTask(TaskNames.task1s, "playAnime", 3, 0.9, PlayAnime)
    -- AddTimerTask("1sTasks", "sfxTest", 3, 60, function ()
    --     PlaySfx("starmantwo")
    -- end)
end

function UpdateBossSync(msg)
    local cid = msg.obj.id
    if msg.action == "attack" then
        PlayThenStopAnim(1, Animation.PLAYER_TYPE.Creature, cid, "SpearStartAttack", Animation.PART_NAME.FullBody, 1.7, 0.2)
        PlayThenStopAnim(2, Animation.PLAYER_TYPE.Creature, cid, "SpearAttack", Animation.PART_NAME.FullBody, 2.7, 0.2)
        -- local player = Character:GetLocalPlayerId()
        -- Character:GrabTarget(player, cid)
    elseif msg.action == "move" then
        PlayThenStopAnim(0, Animation.PLAYER_TYPE.Creature, cid, "SitIdle", Animation.PART_NAME.FullBody, 4, 0.2)
        -- Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SitIdle", Animation.PART_NAME.FullBody)
    end
end

function SyncMoveBlock(msg)
    -- Element:SetReplicates(msg.id, false)
    local eid = msg.obj.id;
    print("SyncMoveBlock ", msg.pos.x)
    -- Element:SetPosition(eid, VectorFromTable(msg.pos), Element.COORDINATE.World)
    -- TimerManager:AddTimer(1, function ()
    -- end)
    if msg.obj.wm then
        Element:LinearMotion(eid, Engine.Vector(-1, 0, 0), 500, 0, 500, 999)
    end
    -- local pos = Element:GetPosition(msg.id)
    -- Element:MoveTo(msg.id, pos + Engine.Vector(-2000, 0, 0), 2, Element.CURVE.linear, nil)
end

function UpdateBlock(deltaTime, obj)
    local bid = obj.id
    -- if not CheckObjPosSynced(bid) then
    --     return
    -- end
    if CanObjStateInit(obj, "move.toMove") then
        print("UpdateBlock toMove")
        
        if obj.wm then
            
        end
        -- SetElementReplicatesAndChildren(bid, false)
        local pos = VectorToTable(Element:GetPosition(bid))
        PushActionToClients(true, "SyncMoveBlock", {pos = pos, obj=obj})
        -- Element:EnableMotionUnitByIndex(bid, 1, true)
        -- PushActionToClients(true, "SyncUpdateBlockPos", {eid=bid})
        -- PushActionToClients(true, "SyncStartUpdateBlockTimer", {eid=bid})
    end

    -- Element:SetPosition(bid, Element:GetPosition(bid) + Engine.Vector(-500 * GetUpdateDeltaTime(), 0, 0), Element.COORDINATE.World)
end


function SyncStartUpdateBlockTimer(msg)
    AddTimerTask(TaskNames.taskFrame, "SyncUpdateBlockPos", 0, 0, SyncUpdateBlockPos)
end

function SyncUpdateBlockPos(msg)
    local bid = msg.eid
    Element:SetPosition(bid, Element:GetPosition(bid) + Engine.Vector(-500 * GetUpdateDeltaTime(), 0, 0), Element.COORDINATE.World)
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
        PushActionToClients(true, "UpdateBossSync", {action="move", obj=obj})
        
        Creature:SetTargetPointMove(cid, posOrg + Engine.Vector(diff, 0, 200), 1)
    elseif IsObjStateCurAndInit(obj, "move", "toAttack") then
        -- TimerManager:AddTimer(1, function ()
        --     Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "CommonFallBackLoop", Animation.PART_NAME.FullBody)
        -- end)
        PushActionToClients(true, "UpdateBossSync", {action="attack", obj=obj})
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
        local state = BuildElementState(eid)
        obj.bindEid = eid
        SetElementStatePhy(state, false, false, false)
        SetElementStateColli(state, false)
        PushActionToClients(true, "SyncElementState", state)
        PushActionToClients(true, "BindSpearToBoss", {eid=eid, cid=cid})
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
    
    -- PushActionToClients(true, "PostGenBoss", {cid = cid})
end

function BuildBlockState(elementId, color1)
    local state = BuildElementState(elementId)
    SetElementStateColor(state, 1, color1)
    SetElementStatePhy(state, true, true, true)
    SetElementStateColli(state, true)
    SetElementStateMass(state, 20)
    -- print("BuildBlockState ", MiscService:Table2JsonStr(state))
    return state
end

function GenAirWall(callback)
    -- local genPos = posFarthest
    local genPos = posOrg
    local awCallback = function (awId)
        callback(awId)
    end

    -- SetElementReplicatesAndChildren(337, false)
    -- 337  331
    CopyElementAndChildrenFull(331, cfgCopyProps, awCallback, true, genPos,
    false, nil, cfgElements.airWall.size,
    198, 198, 100, nil)

    
    -- CopyElementAndChildrenFull(341, cfgCopyProps, function ()
    -- end, true, genPos,
    -- false, true, cfgElements.airWall.size,
    -- 100, 100, 500, nil)
end

--缩放元件位置由于需要同步,如果在同步之前绑定则会出问题,所以组装元件需要关闭同步,组装完成后再打开
function GenBrickDebris(pid, locX, locY, done)
    -- local pos = posFarthest + Engine.Vector(locX * 100, 0, locY * 100 + 10)
    local pos = posOrg + Engine.Vector(locX * 100, 0, locY * 100 + 10)
    local callback = function (eid)
        ServerLog("GenBrickDebris ", eid, " ", pid, " ", GetElementPosString(eid), " ", VectorToString(posOrg))
        SetCustomPropBool(eid, "debris", true)
        TimerManager:AddTimer(0, function ()
            Element:BindingToElement(eid, pid)
        end)
        -- Element:BindingToElement(eid, pid)
        -- Element:SetPosition(pid, posOrg + Engine.Vector(0, 0, 300), Element.COORDINATE.World)
        if done then
            TimerManager:AddTimer(8, function ()
                -- Element:SetReplicates(pid, true)
                -- SetElementReplicatesAndChildren(pid, true)
            end)
        end
    end
    -- CopyElementAndChildrenFull(elesInScene.brick, cfgCopyProps, callback, true, pos,
    -- false, nil, cfgElements.cube.size,
    -- 100, 200, 100, nil)

    -- elesInScene.brick 341
    CopyElementAndChildrenFull(elesInScene.brick, cfgCopyProps, callback, true, pos,
    false, nil, cfgElements.cube.size,
    100, 200, 100, nil)

    -- CopyElementAndChildrenFull(341, cfgCopyProps, callback, true, pos,
    -- false, true, cfgElements.cube.size,
    -- 100, 500, 100, nil)
end

--准备砖头类型原型,同步是可以的,因为没有后续缩放调整等
function PrepareBrick()
    local callback = function (eid)
        elesInScene.brick = eid
        InitProtoBrick()
    end
    local pos = posOrg + Engine.Vector(0, 0, 1200)
    -- SpawnElementToScene(1101002001038000, posFarthest, callback, cfgElements.cube.size, 100, 100, 100)
    -- SetElementReplicatesAndChildren(334, false)
    CopyElementAndChildrenFull(334, cfgCopyProps, callback, true, pos,
    false, nil, nil,
    0, 0, 0, nil)
end

--生成砖头
function InitProtoBrick()
    local callback = function (awId)
        protos.blockBrick.id = awId
        -- TimerManager:AddTimer(1, function ()
        --     GenBrickDebris(awId, 0, 0)
        -- end)
        GenBrickDebris(awId, 0, 0, false)
        -- GenBrickDebris(awId, 0, 1, false)
        -- GenBrickDebris(awId, 1, 0, false)
        GenBrickDebris(awId, 1, 1, true)
    end
    GenAirWall(callback)
end


function InitBlockProto()
    cfgElements.airWall = {id=1105000000000074, size=Engine.Vector(5,5,3)}
    cfgElements.cube = {id=1101002001034000, size=Engine.Vector(1,1,1)}
    cfgElements.cubeNight = {id=1101002001105000, size=Engine.Vector(1,1,1)}
    protos.blockUnknown = {}
    protos.blockUnknownMotion = {}
    protos.blockBrick = {}
    InitProtoBlockUnknown(false)
    InitProtoBlockUnknown(true)
    PrepareBrick()
    
    
end

function SyncInit()
    
end

function GenBlock()
    local rd = UMath:GetRandomInt(2,2)
    if rd == 1 then
        GenBlockUnknown(false)
        GenBlockUnknown(true)
    elseif rd == 2 then
        GenBlockBrick()
    end
end

function UpdateBrick(deltaTime, obj)
    local pos = Element:GetPosition(obj.id)
    -- Element:SetPosition(obj.id, pos + Engine.Vector(deltaTime*100, 0, 0), Element.COORDINATE.World)
    -- Element:SetPosition(obj.id, posOrg + Engine.Vector(0, 0, 800), Element.COORDINATE.World)
    if CanObjStateInit(obj, "move.toMove") then
        local pos = VectorToTable(Element:GetPosition(obj.id))
        PushActionToClients(true, "SyncMoveBrick", {pos = pos, obj=obj})
        -- Element:EnableMotionUnitByIndex(bid, 1, true)
        -- PushActionToClients(true, "SyncUpdateBlockPos", {eid=bid})
        -- PushActionToClients(true, "SyncStartUpdateBlockTimer", {eid=bid})
    end
end

function SyncMoveBrick(msg)
    Element:LinearMotion(msg.obj.id, Engine.Vector(-1, 0, 0), 500, 0, 500, 999)
end


function GenBlockBrick()
    ServerLog("GenBlockBrick startsss ")
    print("GenBlockBrick start")
    local pos = posOrg + Engine.Vector(0, -200, 550)
    local callback = function (eid)
        local obj = AddNewObj(0, typeObjs.brick, eid, 0, UpdateBrick, 17, CommonDestroy)
        AddObjState(obj, "move.toMove")
        SetObjState(obj, "move.toMove", -1, -1, 90)
        StartObjStateByName(obj, "move", "toMove")
    end
    -- CopyElementAndChildrenServerEz(protos.blockBrick.id, cfgCopyProps, callback, pos)
    CopyElementAndChildrenFull(protos.blockBrick.id, cfgCopyProps, callback, true, pos,
    true, false,
    nil, 0, 0, 0, nil)
end

function GenBlockUnknown(withMotion)
    print("GenBlockUnknown start")
    local callback = function (eid)
        print("GenBlockUnknown done", eid)
        
        -- Element:SetPosition(eid, pos, Element.COORDINATE.World)
        local obj = AddNewObj(0, typeObjs.blockUnknown, eid, 0, UpdateBlock, 15, DestroyBlock)
        obj.cid = Element:GetChildElementsFromElement(eid)[1]
        local state = BuildElementState(obj.cid)
        if withMotion then
            obj.wm = false
            SetElementStateColor(state, 1, "#2222FF")
        else
            obj.wm = true
            SetElementStateColor(state, 1, "#FF2222")
        end
        PushActionToClients(true, "SyncElementState", state)
        AddObjState(obj, "move.toMove")
        SetObjState(obj, "move.toMove", -1, -1, 90)
        StartObjStateByName(obj, "move", "toMove")
    end
    local pos = posOrg + Engine.Vector(0, -200, 650)
    if withMotion then
        pos = posOrg + Engine.Vector(0, 300, 650)
        CopyElementAndChildrenServerEz(protos.blockUnknown.id, cfgCopyProps, callback, pos)
    else
        CopyElementAndChildrenServerEz(protos.blockUnknownMotion.id, cfgCopyProps, callback, pos)
    end
    
    -- CopyElementAndChildrenServerEz(277, cfgCopyProps, callback)
end

function InitProtoBlockUnknown(withMotion)
    local genPos = posFarthest
    local awCallback = function (awId)
        -- Element:SetPosition(awId, genPos, Element.COORDINATE.World)
        SetElementScaleDstXyz(awId, cfgElements.airWall.size, 198, 198, 100)
        if withMotion then
            protos.blockUnknown.id = awId
        else
            protos.blockUnknownMotion.id = awId
        end
        local cubeScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 2.0), cfgElements.cube.size)
        local cubeCallback = function (cubeId)
            Element:SetMask(cubeId, 1)
            Element:BindingToElement(cubeId,awId)
            print("InitProtoBlockUnknown done ", awId)
            -- Element:SetPosition(awId,posOrg + Engine.Vector(0,0, 1800), Element.COORDINATE.World)
        end
        Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.cube.id, cubeCallback, genPos + Engine.Vector(0, 0, 10), Engine.Rotator(0,0,0), cubeScale, true)
    end
    -- local awScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 1.0), cfgElements.airWall.size)
    -- Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.airWall.id, awCallback, genPos, Engine.Rotator(0,0,0), awScale, true)
    if withMotion then
        CopyElementAndChildrenServerEz(291, cfgCopyProps, awCallback, genPos)
    else
        CopyElementAndChildrenServerEz(331, cfgCopyProps, awCallback, genPos)
    end
    
    -- CopyElementAndChildrenServerEz(303, cfgCopyProps, awCallback)
end

function GenBlockBall() 
    local callback = function(elementId)
        ServerLog("GenBlock res ", elementId)
        local color = getRandomColorRGBA()
        local state = BuildBlockState(elementId, color)
        PushActionToClients(true, "SyncElementState", state)
        -- System:SendToAllClients(msgIdBlockState, state)
        -- SyncElementState(state)
        Element:DestroyByTime(elementId, 15)

        -- CustomProperty:SetCustomProperty(elementId, "musicVec", CustomProperty.PROPERTY_TYPE.Vector, Engine.Vector(0, trackIdx, noteIdx))
    end
    local pos = Element:GetPosition(platformId)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001037010, callback, pos + Engine.Vector(1500, 0, 1500), Engine.Rotator(0,0,0), Engine.Vector(1, 1, 1), true)
end

function TouchBrick(obj)
    -- local children = Element:GetChildElementsFromElement(obj.id)
    -- for index, cid in ipairs(children) do
    --     if CheckCustomPropBoolHas(cid, "debris") then
    --         Element:UnBinding(cid)
    --     end
    -- end
    PushActionToClients(true, "SyncTouchBrick", obj)
end

function SyncTouchBrick(obj)
    local children = Element:GetChildElementsFromElement(obj.id)
    for index, cid in ipairs(children) do
        if CheckCustomPropBoolHas(cid, "debris") then
            Element:UnBinding(cid)
            local state = BuildElementState(cid)
            SetElementStatePhy(state, true, false, false)
            SetElementStateColli(state, true)
            -- TimerManager:AddTimer(0.2, function ()
            --     Element:AddForce(cid, Engine.Vector(0, 0, -1950))
            -- end)
            TimerManager:AddTimer(0.3, function ()
                Element:SetEnableCollision(cid, false)
            end)
            SyncElementState(state)
            Element:AddForce(cid, Engine.Vector(0, 0, 950))
            Element:DestroyByTime(cid, 3)
        end
    end
    CommonDestroy(0, obj)
    
end

function CallbackPlayerTouchEle(eid, player)
    print("CallbackPlayerTouchEle ", characterId, " ", eid)
    local obj = GetObject(eid)
    if obj == nil then
        return
    end
    if obj.type == typeObjs.brick then
        TouchBrick(obj)
    end
end

function RegisterEventsServer() 
    System:RegisterEvent(Events.ON_CHARACTER_CREATED, CallbackCharCreated)
    System:RegisterEvent(Events.ON_ELEMENT_TOUCH_PLAYER, CallbackPlayerTouchEle)
end