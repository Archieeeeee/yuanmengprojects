
require("YmMusicTools")
require("YmDataTable")

--游戏运行时间,如果游戏暂停了这个时间不会增加
local RunningTime = 0
MsgIds = {commonAction=100244}
local clientTimeState = {}
local serverTimeState = {}
TaskNames = {task1s="1sTasks", taskFrame="frameTasks"}
-- 复制元件并设置位置后,客户端通知服务器已完成,这时候需要维护这张表,新加obj时会检查这张表并标记
local tempPosSynced = {[123]={createTs=0}}
posFarthest = Engine.Vector(-80000, -80000, -80000)

local timerTaskState = {groupName = {taskName = {initTs=0, initDelay=0, delay=3, lastRunTs=0, count=0, active=true, func=nil}}}
-- local testStates = {{idle={startTs=12345, endTs=27382}}, {move={startTs=12345, endTs=27382}}}

local testStates = {
    move = {
        cur = "idle", startTs = 0, endTs = 0, nextStates = {},
        states = {
            idle = {
                cur = "", startTs = 0, endTs = 0, nextStates = {["move"]="moving", ["attack"]="startAttack"}
            },
            moving =  {
                cur = "", startTs = 0, endTs = 0, nextStates = {}
            }
        },
    },
    attack = {
        cur = "", startTs = 0, endTs = 0, nextStates = {},
        states = {
            startAttack = {
                cur = "", startTs = 0, endTs = 0, nextStates = {["attack"]="startAttack", ["lookState.childState"]="goNext"}
            },
            endAttack =  {
                cur = "", startTs = 0, endTs = 0, nextStates = {}
            }
        },
    }
}
local objectsAio = {[27007]={id=27007, state="move", states=testStates }}

--name 是空表示添加到obj  "xx.aa.cccc"
function AddObjState(obj, name)
    print("before AddObjState ", name, " ", MiscService:Table2JsonStr(obj))
    if name == nil then
        name = "objStates"
    else
        name = string.format("objStates.%s", name)
    end
    
    print("beforeAAA AddObjState ", name, " ", MiscService:Table2JsonStr(obj))
    local ss = string.split(name, ".")
    print("beforeBBB AddObjState ", MiscService:Table2JsonStr(ss), " ", MiscService:Table2JsonStr(obj))
    local parent = obj
    local child = nil
    -- lookState  childState
    for index, name in ipairs(ss) do
        child = parent["states"][name]
        if child == nil then
            child = {cur = "", startTs = 0, endTs = 0, dur=0, inited = false, nextStates = {}, states={} }
            parent["states"][name] = child
        end
        parent = child
    end

    print("after AddObjState ", MiscService:Table2JsonStr(obj))
end

-- move.toMove
function CanObjStateInit(obj, name)
    local state = GetObjState(obj, name)
    if state == nil then
        return false
    else
        if state.inited then
            return false
        else
            state.inited = true
            return true
        end
    end
end

-- move   toMove
function IsObjStateCurAndInit(obj, name, value)
    return IsObjStateCur(obj, name, value) and CanObjStateInit(obj, string.format("%s.%s", name, value))
end

-- move   toMove
function IsObjStateCur(obj, name, value)
    local state = GetObjState(obj, name)
    if state == nil then
        return false
    else
        return (state.cur == value)
    end
end

function GetObjState(obj, name)
    name = string.format("objStates.%s", name)
    -- print("beforeAAA GetObjState ", name, " ", MiscService:Table2JsonStr(obj))
    local ss = string.split(name, ".")
    -- print("beforeBBB GetObjState ", MiscService:Table2JsonStr(ss), " ", MiscService:Table2JsonStr(obj))
    local state = obj
    -- lookState  childState
    for index, name in ipairs(ss) do
        state = state["states"][name]
        if state == nil then
            return nil
        end
    end
    return state
end

function SetObjState(obj, name, startTs, endTs, dur)
    local state = GetObjState(obj, name)
    if startTs >= 0 then
        state.startTs = startTs
    end
    if endTs >= 0 then
        state.endTs = endTs
    end
    if dur >= 0 then
        state.dur = dur
    end
    print("after SetObjState ", MiscService:Table2JsonStr(obj))
end

function SetObjStateNext(obj, name, key, value)
    print("SetObjStateNext ", name)
    local state = GetObjState(obj, name)
    state.nextStates[key] = value
    print("SetObjStateNext after ", name, " ", MiscService:Table2JsonStr(obj))
end

function StartObjStateByName(obj, name, value)
    local state = GetObjState(obj, name)
    StartObjStateDirect(state, value)
end

function StartObjStateDirect(state, value)
    local childState = state.states[value]
    childState.startTs = GetGameTimeCur()
    childState.endTs = 0
    childState.inited = false
    state.cur = value
end

function CheckAllObjStates(deltaTime)
    for id, obj in pairs(objectsAio) do
        if obj.active then
            CheckObjStates(obj, deltaTime)
        end
    end
end

function CheckObjStates(obj, deltaTime)
    -- print("CheckObjStates ", MiscService:Table2JsonStr(obj))
    if (obj.states ~= nil) and (obj.states.objStates ~= nil) then
        for key, childState in pairs(obj.states.objStates.states) do
            CheckSingleObjState(childState, deltaTime, obj)
        end
    end
end

function CheckSingleObjState(state, deltaTime, obj)
    --检查当前状态名称对应的状态
    if (state.cur ~= nil) and (state.cur ~= "") then
        local childState = state.states[state.cur]
        if childState.startTs > 0 and childState.endTs == 0 then
            if GetGameTimeCur() - childState.startTs > childState.dur then
                UpdateObjStateNext(childState, obj)
            end
        end
    end
    
    if state.states ~= nil then
        for key, childState in pairs(state.states) do
            CheckSingleObjState(childState, deltaTime, obj)
        end
    end
end


function string:split(sep, pattern)
	if sep == "" then
		return self:totable()
	end
	local rs = {}
	local previdx = 1
	while true do
		local startidx, endidx = self:find(sep, previdx, not pattern)
		if not startidx then
			table.insert(rs, self:sub(previdx))
			break
		end
		table.insert(rs, self:sub(previdx, startidx - 1))
		previdx = endidx + 1
	end
	return rs
end

-- {["attack"]="startAttack", ["lookState.childState"]="goNext"}
function UpdateObjStateNext(stateArg, obj)
    print("UpdateObjStateNext ", MiscService:Table2JsonStr(stateArg))
    stateArg.endTs = GetGameTimeCur()
    local nextStates = stateArg.nextStates
    if nextStates ~= nil then
        for stateName, stateValue in pairs(nextStates) do
            StartObjStateByName(obj, stateName, stateValue)
        end
    end
end

function OnUpdateTimeStateSingle(state)
    local lastGameTime = state.gameTime
    local curTs = TimerManager:GetTimeSeconds()
    local pausedTotal = state.pausedTimeTotal
    if state.paused then
        pausedTotal = state.pausedTimeTotal + (curTs - state.pauseTs)
        state.gameTime = curTs - pausedTotal
    end
    state.gameTime = curTs - pausedTotal
    --calc deltaTime
    state.deltaTime = state.gameTime - lastGameTime
end

--client 和 server的方法分别操作不同的数据,方便取值不同的数据
function OnUpdateFrame(isClient)
    local state = clientTimeState
    if not isClient then
        state = serverTimeState
    end
    
    --gen delta
    OnUpdateTimeStateSingle(state)
    --delta ready
    UpdateAllObjects(GetUpdateDeltaTime())
    CheckAllObjStates(state.deltaTime)
end

function InitTimeState()
    clientTimeState = GetTimeStateInit()
    serverTimeState = GetTimeStateInit()
end

function GetTimeStateInit()
    local state = {gameTime=0, paused=false, pauseTs=0, unpauseTs=0, pausedTimeTotal=0, deltaTime=0}
    return state
end

function PauseGame(state)
    state.paused = true
    state.pauseTs = TimerManager:GetTimeSeconds()
end

function UnpauseGame(state)
    state.paused = false
    state.unpauseTs = TimerManager:GetTimeSeconds()
    state.pausedTimeTotal = state.pausedTimeTotal + (state.unpauseTs - state.pauseTs)
end

function BindNotifyAction()
    System:BindNotify(MsgIds.commonAction, function(msgId, msg)
        DoAction(msg)
    end)
end


---@param doSelf any 是否在本机执行
---@param dstId any 目标id, 空代表发送到服务端
function PushAction(doSelf, funcName, funcArg, dstId, toAllClients)
    local msg = {funcName = funcName, funcArg = funcArg}
    if toAllClients then
        if not System:IsStandalone() then
            System:SendToAllClients(MsgIds.commonAction, msg)
        end
    else
        if dstId == nil then
            System:SendToServer(MsgIds.commonAction, msg)
        else
            System:SendToClient(dstId, MsgIds.commonAction, msg)
        end
    end

    if doSelf then
        DoAction(msg)
    end
end

function PushActionToClients(doSelf, funcName, funcArg)
    PushAction(doSelf, funcName, funcArg, nil, true)
end

function PushActionToServer(doSelf, funcName, funcArg)
    PushAction(doSelf, funcName, funcArg, nil, false)
end

function PushActionToPlayer(doSelf, funcName, funcArg, playerId)
    PushAction(doSelf, funcName, funcArg, playerId, false)
end

function GetUpdateDeltaTime() 
    if System:IsServer() or System:IsStandalone() then
        return serverTimeState.deltaTime
    else
        return clientTimeState.deltaTime
    end
end

--返回运行的总时间长短,游戏暂停的时候这个值不会增长
function GetGameTimeCur()
    if System:IsServer() or System:IsStandalone() then
        return serverTimeState.gameTime
    else
        return clientTimeState.gameTime
    end
end

-- 服务端日志输出，可以选择是否发送给客户端由客户端进行输出，方便联网调试
function ServerLog(...)
    Log:PrintLog(...)

    if Debug then
        -- 将服务端日志发送至客户端
        System:SendToAllClients(
            NetMsg.SeverLog,
            {...}
        )
    end
end

function DoAction(msg)
    -- print("DoAction ", MiscService:Table2JsonStr(msg))
    _G[msg.funcName](msg.funcArg)
end

function AddNewObj(groupType, type, id, updateDur, updateFunc, lifeDur, destroyFunc)
    local obj = {id=id, group=groupType, type=type, updateDur=updateDur, updateFunc=updateFunc, lastUpdateTs=0,
        posSynced = false,
        lifeDur=lifeDur, destroyFunc=destroyFunc, active=true, createTs=GetGameTimeCur(), states={}}
    AddObjState(obj, nil)
    objectsAio[id] = obj
    CheckObjPosSynced(id)
    return obj
end

function UpdateAllObjects(deltaTime)
    -- remove unactive
    local removeIds = {}
    for id, obj in pairs(objectsAio) do
        if not obj.active then
            table.insert(removeIds, id)
        end
    end
    for index, value in ipairs(removeIds) do
        print("remove unactive object ", value)
        objectsAio[value] = nil
    end
    -- check active
    for id, obj in pairs(objectsAio) do
        local timeCur = GetGameTimeCur()
        -- print("UpdateAllObjStates ", timeCur, " ", MiscService:Table2JsonStr(obj))
        if obj.active then
            if obj.lifeDur >= 0 and (timeCur - obj.createTs > obj.lifeDur) then
                obj.active = false
                if obj.destroyFunc ~= nil then
                    obj.destroyFunc(deltaTime, obj)
                end
            elseif (timeCur - obj.lastUpdateTs) < obj.updateDur then
            elseif obj.updateFunc ~= nil then
                -- print("UpdateAllObjStates updateFunc", MiscService:Table2JsonStr(obj))
                obj.lastUpdateTs = timeCur
                obj.updateFunc(deltaTime, obj)
            end
        end
    end
end

-- 扩展AddLoopTimer,允许初始延迟参数
function AddLoopTimerWithInit(initialDelay, delay, callback, ...)
    TimerManager:AddTimer(initialDelay, callback, ...)
    local addDelayTimer = function (...)
        TimerManager:AddLoopTimer(delay, callback, ...)
    end
    TimerManager:AddTimer(initialDelay, addDelayTimer, ...)
end

-- function SystemAddTimerTask(initialDelay, delay, callback)
--     TimerManager:AddLoopTimer(delay, callback)
-- end

function AddTimerTask(groupName, taskName, initialDelay, delayTime, callback)
    if timerTaskState[groupName] == nil then
        timerTaskState[groupName] = {}
    end
    local now = GetGameTimeCur()
    timerTaskState[groupName][taskName] = {initTs=now, initDelay=initialDelay, delay=delayTime, lastRunTs=now, count=0, active=true, func=callback}
    print("AddTimerTask done ", MiscService:Table2JsonStr(timerTaskState))
end

--检查所有的定时任务并执行
---@param groupName string 定时任务组的名称
function RunAllTimerTasks(groupName)
    -- print("RunAllTimerTasks start ", MiscService:Table2JsonStr(timerTaskState))
    if timerTaskState[groupName] == nil then
        return
    end
    for key, task in pairs(timerTaskState[groupName]) do
        if task.active then
            local delay = task.delay
            -- first run
            if task.count == 0 then
                delay = task.initDelay
            end
            local ts = GetGameTimeCur()
            -- ServerLog("checking task ", ts, " ", MiscService:Table2JsonStr(task))
            if ts - task.lastRunTs > delay then
                RunTask(task)
            end
        end
    end
end

function RunTask(task)
    print("RunTask start")
    task.lastRunTs = GetGameTimeCur()
    task.count = task.count + 1
    task.func()
end

function SetTaskActive(name, activeTo)
    timerTaskState[name].active = activeTo
end

function PlayThenStopAnim(delay, type, id, name, partname, stopDelay, stopBlendDur)
    if delay == 0 then
        Animation:PlayAnim(type, id, name, partname)
    else
        TimerManager:AddTimer(delay, function ()
            Animation:PlayAnim(type, id, name, partname)
        end)
    end
    TimerManager:AddTimer(stopDelay, function ()
        Animation:StopAnim(type, id, name, partname, stopBlendDur)
    end)
end

--缩放元件到指定大小
function SetElementScaleDst(eid, dstSize, orgSize)
    Element:SetScale(eid, GetScaleDstCalc(dstSize, orgSize))
end

--- 缩放元件到指定大小
--- @param x number 长,像素单位
function SetElementScaleDstXyz(eid, orgSize, x, y, z)
    Element:SetScale(eid, GetScaleDstCalcXyz(orgSize, x, y, z))
end

--计算缩放到指定大小需要的缩放参数
function GetScaleDstCalc(dstSize, orgSize)
    return Engine.Vector(dstSize.x/orgSize.x, dstSize.y/orgSize.y, dstSize.z/orgSize.z)
end

--计算缩放到指定大小需要的缩放参数
function GetScaleDstCalcXyz(orgSize, x, y, z)
    return Engine.Vector(x/100.0/orgSize.x, y/100.0/orgSize.y, z/100.0/orgSize.z)
end

function GetElementChildrenSize(eid, resTable)
    if resTable.size == nil then
        resTable.size = 0
    end
    resTable.size = resTable.size + 1
    local children = Element:GetChildElementsFromElement(eid)
    if children ~= nil then
        for index, child in ipairs(children) do
            GetElementChildrenSize(child, resTable)
        end
    end
end

function SetElementChildrenSize(eid)
    local res = {size=0}
    GetElementChildrenSize(eid, res)
    CustomProperty:SetCustomProperty(eid, "childNum", CustomProperty.PROPERTY_TYPE.Number, res.size)
end

function CopyElementAndChildrenServerEz(eid, props, callbackDone, dstPos)
    --syncPosRemote多数情况仍然是必须的,只不过如果立即运动仍然需要先明确设置位置因为远程调用可能尚未完成
    local param = BuildCopyEleParam(true, dstPos, true, false, nil)
    CopyElementAndChildrenDetailed(eid, props, callbackDone, param)
end

function CopyElementAndChildrenServerEzScale(eid, props, callbackDone, dstPos, orgSize, x, y, z, scaleNum)
    local param = BuildCopyEleParam(true, dstPos, true, false, nil)
    SetCopyEleParamScale(param, orgSize, x, y, z, scaleNum)
    CopyElementAndChildrenDetailed(eid, props, callbackDone, param)
end

function CopyElementAndChildrenFull(eid, props, callbackDone, replicates, dstPos, syncStateRemote, postSetReplicates, orgSize, x, y, z, scaleNum)
    local param = BuildCopyEleParam(replicates, dstPos, syncStateRemote, postSetReplicates, nil)
    SetCopyEleParamScale(param, orgSize, x, y, z, scaleNum)
    CopyElementAndChildrenDetailed(eid, props, callbackDone, param)
end

function BuildCopyEleParam(replicates, dstPos, syncStateRemote, postSetReplicates, dstScale)
    return {replicates = replicates, dstPos = dstPos, syncStateRemote = syncStateRemote, postSetReplicates = postSetReplicates, dstScale = dstScale}
end

function SetCopyEleParamScale(param, orgSize, x, y, z, scaleNum)
    if orgSize ~= nil then
        param.dstScale = {orgSize=orgSize, x=x, y=y, z=z}
    end
    if scaleNum ~= nil then
        param.dstScale = {scaleNum = scaleNum}
    end
end

--- 复制元件
---@param eid any
---@param props any
---@param callbackDone any
---@param replicates any 元件默认的relicates属性,true时会在客户端同步生成
---@param dstPos any 位置
---@param syncStateRemote any 是否将位置同步到客户端,完成后会通知服务器,服务器后续可以对元件进行运动,因为服务器需要先关闭replicates,而这时候位置同步可能还未完成,所以需要明确通知服务器同步完成时间
---@param postSetReplicates any 复制元件后是否重新设置relicates属性,通常都需要默认开,复制后关
function CopyElementAndChildrenDetailed(eid, props, callbackDone, param)
    SetElementChildrenSize(eid)
    CopyElementAndChildrenHandle( param, eid, nil, props, callbackDone)
end

function IsAllChildrenGened(srcEid, copyEid)
    local num = CustomProperty:GetCustomProperty(srcEid, "childNum", CustomProperty.PROPERTY_TYPE.Number)
    local genNum = CustomProperty:GetCustomProperty(copyEid, "genChildNum", CustomProperty.PROPERTY_TYPE.Number)
    return (num == genNum)
end

function GetParentIdFar(eid)
    local pid = Element:GetAttachParentElement(eid)
    if (pid == nil) or (pid == 0) then
        return eid
    else
        return GetParentIdFar(pid)
    end
end

function CopyElementAndChildrenHandle(srcTable, eid, parentId, props, callbackDone)
    -- print("json test ", MiscService:Table2JsonStr({pos= Engine.Vector(0,0,0)}))
    -- print("CopyElementAndChildrenHandle start ", MiscService:Table2JsonStr(srcTable), " ", eid)
    local callback = function(copyId)
        local genNum = 0
        if srcTable.copyRootId == nil then
            srcTable.copyRootId = copyId
            srcTable.srcRootId = eid
        else
            genNum = CustomProperty:GetCustomProperty(srcTable.copyRootId, "genChildNum", CustomProperty.PROPERTY_TYPE.Number)
        end
        CustomProperty:SetCustomProperty(srcTable.copyRootId, "genChildNum", CustomProperty.PROPERTY_TYPE.Number, genNum + 1)
        if parentId ~= nil then
            Element:BindingToElement(copyId, parentId)
        end

        local children = Element:GetChildElementsFromElement(eid)
        if children ~= nil then
            for index, child in ipairs(children) do
                CopyElementAndChildrenHandle(srcTable, child, copyId, props, callbackDone)
            end
        end

        -- 检查是否全都生成了，如果生成将复制出来的父节点id找出来作为参数回调最后的方法
        if IsAllChildrenGened(srcTable.srcRootId, srcTable.copyRootId) then
            --
            if srcTable.postSetReplicates ~= nil then
                local stateRp = BuildElementState(srcTable.copyRootId)
                SetElementStateReplicates(stateRp, srcTable.postSetReplicates)
                SetElementStateEnableChildren(stateRp)
                -- TimerManager:AddTimer(1, function ()
                --     SyncElementState(stateRp)
                -- end)
                SyncElementState(stateRp)
            end

            local state = BuildElementState(srcTable.copyRootId)
            local toSetState = false
            if srcTable.dstPos ~= nil then
                toSetState = true
                SetElementStatePos(state, srcTable.dstPos)
            end

            if srcTable.dstScale ~= nil then
                toSetState = true
                if srcTable.dstScale.orgSize ~= nil then
                    SetElementStateScale(state, GetScaleDstCalcXyz(srcTable.dstScale.orgSize, srcTable.dstScale.x, srcTable.dstScale.y, srcTable.dstScale.z))
                else
                    SetElementStateScale(state, srcTable.dstScale.scaleNum)
                end
            end

            if toSetState then
                SyncElementState(state)
                --检查状态是否需要同步到远端
                if srcTable.replicates ~= nil and srcTable.postSetReplicates ~= nil then
                    --初始同步但是后续不要求同步,这种情况需要把状态远程同步给客户端
                    if srcTable.replicates and (not srcTable.postSetReplicates) then
                        SetElementStateDoneAction(state, "OnPosSync")
                        -- TimerManager:AddTimer(1, function ()
                        --     PushActionToClients(true, "SyncElementState", state)
                        -- end)
                        -- PushActionToClients(false, "SyncElementState", state)
                        TimerManager:AddTimer(1, function ()
                            PushActionToClients(false, "SyncElementState", state)
                        end)
                    end
                end
            end

            

            callbackDone(srcTable.copyRootId)
        end
    end
    CopyElementSingle(eid, props, callback, srcTable.replicates)
end

function CopyEle(eid, parentId, props)
    local callback = function (copyId)
        if parentId ~= nil then
            Element:BindingToElement(copyId, parentId)
        end

        local children = Element:GetChildElementsFromElement(eid)
        for index, child in ipairs(children) do
            CopyEle(child, copyId)
        end
    end
    CopyElementSingle(eid, props, callback, true)
end

--复制单个元件以及属性
function CopyElementSingle(eid, props, callbackDone, replicates)
    local callback = function (id)
        print("CopyElementSingle done ", eid, " ", id)
        for index, value in ipairs(props) do
            local prop = CustomProperty:GetCustomProperty(eid, value.name, value.type)
            if prop ~= nil then
                CustomProperty:SetCustomProperty(id, value.name, value.type, prop)
            end
        end
        CustomProperty:SetCustomProperty(id, "genChildNum", CustomProperty.PROPERTY_TYPE.Number, 0)

        callbackDone(id)
    end
    Element:SpawnElement(Element.SPAWN_SOURCE.Scene, eid, callback, Element:GetPosition(eid), Element:GetRotation(eid), Element:GetScale(eid), replicates)
end

function DestroyElementAndChildren(eid)
    print("DestroyElementAndChildren ", eid)
    local children = Element:GetChildElementsFromElement(eid)
    if children ~= nil then
        for index, child in ipairs(children) do
            DestroyElementAndChildren(child)
        end
    end
    Element:Destroy(eid)
end

function GetTableFromGlobal(name)
    local varName = string.format("%s%s", name, "Str")
    local data = _G[varName]
    local dataTable = MiscService:JsonStr2Table(data)
    return dataTable
end

function LoadGlobalVarsFromData(names)
    for index, name in ipairs(names) do
        _G[name] = GetTableFromGlobal(name)
    end
end

function LoopTimerCanRun(theTable, name, dur)
    if GetGameTimeCur() - theTable[name] < dur then
        return false
    end
    theTable[name] = GetGameTimeCur()
    return true
end

--用于在前后台同步全局变量,初始化
function BuildSyncVarMsg()
    return {names={}, values={}}
end

--用于在前后台同步全局变量,添加变量
function PushSyncVar(msg, name, value)
    table.insert(msg.names, name)
    msg.values[name] = value
end

--用于在前后台同步全局变量 {names={"posorg", "speed"}, values={}}
function SyncGlobalVars(msg)
    print("SyncGlobalVars aaa", MiscService:Table2JsonStr(msg))
    for index, name in ipairs(msg.names) do
        _G[name] = msg.values[name]
        print("SyncGlobalVars bbb ", MiscService:Table2JsonStr(_G[name]))
    end
end

--用于在前后台同步全局变量单个
function PushGlobalVarSingle(name, value)
    local varMsg = BuildSyncVarMsg()
    PushSyncVar(varMsg, name, value)
    PushActionToClients(false, "SyncGlobalVars", varMsg)
end


function SyncElementState(state)
    print("SyncElementState ", state.eid, " ", Element:GetType(state.eid), " ", Element:GetPosition(state.eid))
    
    
    if state.setChildren ~= nil then
        SyncElementStateAndChildrenById(state.eid, state)
    else
        SyncElementStateById(state.eid, state)
    end
end

--同步元件状态
function SyncElementStateById(elementId, state)
    -- print("SyncElementState ", MiscService:Table2JsonStr(state))
    if state.replicates ~= nil then
        print("SyncElementState SetReplicates", state.replicates)
        Element:SetReplicates(elementId, state.replicates)
    end

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

    if state.motion ~= nil then
        Element:EnableMotionUnitByIndex(elementId, state.motion.index, state.motion.enable)
    end

    if state.pos ~= nil then
        print("SyncElementState pos 1")
        Element:SetPosition(elementId, VectorFromTable(state.pos), Element.COORDINATE.World)
        if state.notifyActionName ~= nil then
            PushActionToServer(false, state.notifyActionName, {eid=elementId})
        end
    end

    if state.scale ~= nil then
        Element:SetScale(elementId, state.scale)
    end
end

function SyncElementStateAndChildren(state)
    SyncElementStateAndChildrenById(state.eid, state)
end

function SyncElementStateAndChildrenById(eid, state)
    SyncElementStateById(eid, state)
    if state.setChildren ~= nil and state.setChildren then
        local children = Element:GetChildElementsFromElement(state.elementId)
        if children ~= nil then
            for index, child in ipairs(children) do
                SyncElementStateAndChildrenById(child, state)
            end
        end
    end
end


function BuildElementState(elementId)
    return {eid=elementId}
end

function SetElementStateColor(state, idx, color)
    if state.colors == nil then
        state.colors = {}
    end
    table.insert(state.colors, {n=idx, c=color})
end

function SetElementStateMotion(state, index, enable)
    state.motion = {index=index, enable=enable}
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

function SetElementStateReplicates(state, enable)
    state.replicates = enable
end

function SetElementStateEnableChildren(state)
    state.setChildren = true
end



function SetElementStatePos(state, pos)
    state.pos = VectorToTable(pos)
end

function SetElementStateScale(state, scale)
    state.scale = scale
end

function SetElementStateDoneAction(state, actionName)
    state.notifyActionName = actionName
end

function SetElementReplicatesAndChildren(eid, enable)
    local state = BuildElementState(eid)
    SetElementStateReplicates(state, enable)
    SyncElementStateAndChildren(state)
end

function CheckTempPosSynced()
    -- remove unactive
    local removeIds = {}
    for id, obj in pairs(tempPosSynced) do
        if GetGameTimeCur() - obj.createTs > 60 then
            table.insert(removeIds, id)
        end
    end
    for index, value in ipairs(removeIds) do
        print("remove unactive tempPosSynced ", value)
        tempPosSynced[value] = nil
    end
end

function CheckObjPosSynced(id)
    local obj = objectsAio[id]
    if obj == nil then
        return false
    end
    if obj.posSynced then
        return true
    end
    if tempPosSynced[id] ~= nil then
        obj.posSynced = true
        return true
    end
    return false
end

function OnPosSync(msg)
    tempPosSynced[msg.eid] = {createTs = GetGameTimeCur()}
    CheckObjPosSynced(msg.eid)
end

function VectorToTable(vec)
    return {x=vec.X, y=vec.Y, z=vec.Z}
end

function VectorFromTable(tab)
    return Engine.Vector(tab.x, tab.y, tab.z)
end

--检查失效的元件位置
function DebugAnaObjects()
    for key, value in pairs(objectsAio) do
        local eles = Element:GetElementsInRegio(posFarthest, 200, 200, 200)
        if eles ~= nil then
            print("DebugAnaObjects posFarthest elements ", #eles)
        end
        -- local pos = Element:GetPosition(key)
        -- if pos ~= nil then
        --     if pos.X <= posFarthest.X or pos.Y <= posFarthest.Y or pos.Z <= posFarthest.Z then
        --         print("ERROR obj pos ", MiscService:Table2JsonStr(value))
        --     end
        -- end
    end
end

--把预设组件创建到场景
function SpawnElementToScene(eleId, pos, callbackFunc, orgSize, x, y, z)
    local scale = GetScaleDstCalcXyz(orgSize, x, y, z)
    local callback = function (eid)
        callbackFunc(eid)
    end
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, eleId, callback, pos, Engine.Rotator(0,0,0), scale, true)
end

--一般销毁
function CommonDestroy(deltaTime, obj)
    DestroyElementAndChildren(obj.id)
end