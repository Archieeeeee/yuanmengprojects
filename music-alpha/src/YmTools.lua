
require("YmMusicTools")
require("YmDataTable")

--游戏运行时间,如果游戏暂停了这个时间不会增加
local RunningTime = 0
MsgIds = {commonAction=100244}
local clientTimeState = {}
local serverTimeState = {}
local gameTimeState = {}
TaskNames = {task1s="1sTasks", taskFrame="frameTasks"}
-- 复制元件并设置位置后,客户端通知服务器已完成,这时候需要维护这张表,新加obj时会检查这张表并标记
local tempPosSynced = {[123]={createTs=0}}
posFarthest = Engine.Vector(-80000, -80000, -80000)
ObjGroups = {Element=0, MotionUnit=2}
CfgTools = {MotionUnit={Types={Pos=1, Scale=3, Rotate=5}}}
local toolIdPools = {}
toolCommonCfgs = {serverPlayerId = -1}

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

function GetObject(id)
    return objectsAio[id]
end

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
    local fullname = ""
    for index, name in ipairs(ss) do
        child = parent["states"][name]
        if index == 1 then
            fullname = name
        else
            fullname = string.format("%s.%s", fullname, name)
        end
        if child == nil then
            child = {cur = "", startTs = 0, endTs = 0, totalTime=0, cycleTime=0, nextStates = {},
                states={}, count=0, numLimit=0, fullname=fullname, actionTs=0, nextStatesEnd={},
                initDelay=0, cycleDelay=0, totalDelta=0, cycleDelta=0, actionDelta=0}
            parent["states"][name] = child
        end
        parent = child
    end

    print("after AddObjState ", MiscService:Table2JsonStr(obj))
    return child
end

-- -- move.toMove
-- function CanObjStateInit(obj, name)
--     local state = GetObjState(obj, name)
--     if state == nil then
--         return false
--     else
--         if state.inited then
--             return false
--         else
--             state.inited = true
--             return true
--         end
--     end
-- end

-- -- move   toMove
-- function IsObjStateCurAndInit(obj, name, value)
--     return IsObjStateCur(obj, name, value) and CanObjStateInit(obj, string.format("%s.%s", name, value))
-- end

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

---设置状态参数。startTs---(initDelay)[---cycleStartTs---(cycleTime)---cycleEndTs---(cycleDelay)]---endTs
---状态开始(调用startFunc),初始等待,周期开始(调用cycleStartFunc),持续期间调用updateFunc,等待totalTime或者numLimit之后,状态结束(调用endFunc)
---@param obj any
---@param name string move.moveLeft
---@param startTs any 状态开始
---@param endTs any 状态结束标志,不需要设置
---@param dur any 
function SetObjState(obj, name, totalTime, cycleTime)
    local state = GetObjState(obj, name)
    if totalTime ~= 0 then
        state.totalTime = totalTime
    end
    if cycleTime ~= 0 then
        state.cycleTime = cycleTime
    end
    print("after SetObjState ", MiscService:Table2JsonStr(obj))
    return state
end

function SetObjStateFunc(obj, name, startFunc, endFunc, cycleStartFunc, actionFunc, updateFunc)
    local state = GetObjState(obj, name)
    if startFunc ~= nil then
        state.startFunc = startFunc
    end
    if endFunc ~= nil then
        state.endFunc = endFunc
    end
    if cycleStartFunc ~= nil then
        state.cycleStartFunc = cycleStartFunc
    end
    if actionFunc ~= nil then
        state.actionFunc = actionFunc
    end
    if updateFunc ~= nil then
        state.updateFunc = updateFunc
    end
    return state
end


function SetObjStateNextCycle(obj, name, key, value)
    SetObjStateNextByProp(obj, "nextStates", name, key, value)
end

function SetObjStateNextEnd(obj, name, key, value)
    SetObjStateNextByProp(obj, "nextStatesEnd", name, key, value)
end

function SetObjStateNextByProp(obj, propName, name, key, value)
    print("SetObjStateNext ", name)
    local state = GetObjState(obj, name)
    state[propName][key] = value
    print("SetObjStateNext after ", name, " ", MiscService:Table2JsonStr(obj))
end

function StartObjStateByName(obj, name, value)
    local state = GetObjState(obj, name)
    StartObjStateDirect(obj, state, value)
end

---开始状态,但有可能是重启状态
function StartObjStateDirect(obj, state, value)
    local childState = state.states[value]
    if childState.startTs == 0 then
        childState.startTs = GetGameTimeCur()
        childState.totalDelta = 0
        if childState.startFunc ~= nil then
            childState.startFunc(obj, childState)
        end
    end
    childState.cycleStartTs = GetGameTimeCur()
    childState.cycleDelta = 0
    childState.actionDelta = 0
    childState.count = childState.count + 1
    childState.endTs = 0
    if childState.cycleStartFunc ~= nil then
        childState.cycleStartFunc(obj, childState)
    end
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

---设置状态参数。startTs---(initDelay)[---cycleStartTs---(cycleTime)---cycleEndTs---(cycleDelay)]---endTs
---状态开始(调用startFunc),初始等待,周期开始(调用cycleStartFunc),持续期间调用updateFunc,等待totalTime或者numLimit之后,状态结束(调用endFunc)
function CheckSingleObjState(state, deltaTime, obj)
    --检查当前状态名称对应的状态
    if (state.cur ~= nil) and (state.cur ~= "") then
        local cs = state.states[state.cur]
        cs.totalDelta = cs.totalDelta + deltaTime
        cs.cycleDelta = cs.cycleDelta + deltaTime
        --未开始
        if cs.startTs == 0 then
        --已结束
        elseif cs.endTs ~= 0 then
        --判断结束
        elseif cs.totalTime ~= 0 and cs.totalDelta >= cs.totalTime then
            ObjStateEnd(obj, cs)
        elseif cs.numLimit ~= 0 and cs.count > cs.numLimit then
            ObjStateEnd(obj, cs)
        elseif cs.actionTs == 0 then
            local delay = cs.cycleDelay
            if cs.count == 1 then
                delay = cs.initDelay
            end
            if cs.cycleDelta >= delay then
                ObjStateAction(obj, cs)
            end
        elseif cs.actionTs > 0 then
            cs.actionDelta = cs.actionDelta + deltaTime
            if cs.cycleTime ~= 0 and cs.actionDelta >= cs.cycleTime then
                ObjStateCycleEnd(obj, cs)
            else
                ObjStateActionUpdate(obj, cs, deltaTime)
            end
        end
    end
    
    if state.states ~= nil then
        for key, childState in pairs(state.states) do
            CheckSingleObjState(childState, deltaTime, obj)
        end
    end
end

function ObjStateEnd(obj, state)
    state.endTs = GetGameTimeCur()
    if state.endFunc ~= nil then
        state.endFunc(obj, state)
    end
    UpdateObjStateNext(state, state.nextStatesEnd, obj)
end

function ObjStateAction(obj, state)
    state.actionTs = GetGameTimeCur()
    if state.actionFunc ~= nil then
        state.actionFunc(obj, state)
    end
end

function ObjStateCycleEnd(obj, state)
    UpdateObjStateNext(state, state.nextStates, obj)
end

function ObjStateActionUpdate(obj, state, deltaTime)
    if state.updateFunc ~= nil then
        state.updateFunc(obj, state, deltaTime)
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
function UpdateObjStateNext(stateArg, nextStates, obj)
    print("UpdateObjStateNext ", MiscService:Table2JsonStr(stateArg))
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

--每一帧都更新时间
function OnUpdateFrameTime()
    local state = GetTimeState()
    -- local state = clientTimeState
    -- if not isClient then
    --     state = serverTimeState
    -- end
    
    --gen delta
    OnUpdateTimeStateSingle(state)
end

--client 和 server的方法分别操作不同的数据,方便取值不同的数据
function OnUpdateFrame()
    local state = GetTimeState()
    --delta ready
    UpdateAllObjects(GetUpdateDeltaTime())
    CheckAllObjStates(state.deltaTime)
end

function InitTimeState()
    clientTimeState = GetTimeStateInit()
    serverTimeState = GetTimeStateInit()
    gameTimeState = GetTimeStateInit()
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
    -- print("PushAction ", doSelf, " ", toAllClients, " ", funcName)
    -- 预处理
    if dstId == toolCommonCfgs.serverPlayerId then
        dstId = nil
    end
    local msg = {funcName = funcName, funcArg = funcArg}
    --如果是toAllClients并且是单机,那么本机一定会执行,就不需要重复了
    if toAllClients and System:IsStandalone() and doSelf then
        DoAction(msg)
        return
    end

    if doSelf then
        DoAction(msg)
    end

    if toAllClients then
        -- if not System:IsStandalone() then
            System:SendToAllClients(MsgIds.commonAction, msg)
        -- end
    else
        if dstId == nil then
            System:SendToServer(MsgIds.commonAction, msg)
        else
            if System:IsServer() then
                System:SendToClient(dstId, MsgIds.commonAction, msg)
            else
                --需要从服务器转发
                SendTransActionToServer(funcName, funcArg, dstId)
            end
        end
    end

end

function SendTransActionToServer(funcName, funcArg, dstId)
    PushActionToServer(false, "TransActionToClient", {funcName=funcName, funcArg=funcArg, dstId = dstId})
end

function TransActionToClient(arg)
    if System:IsServer() then
        PushActionToPlayer(false, arg.funcName, arg.funcArg, arg.dstId)
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

function GetTimeState()
    -- if System:IsServer() or System:IsStandalone() then
    --     return serverTimeState
    -- else
    --     return clientTimeState
    -- end
    return gameTimeState
end

function GetUpdateDeltaTime()
    return GetTimeState().deltaTime
end

--返回运行的总时间长短,游戏暂停的时候这个值不会增长
function GetGameTimeCur()
    return GetTimeState().gameTime
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
    print("DoAction ", MiscService:Table2JsonStr(msg))
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

function GetObjById(id)
    return objectsAio[id]
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
    delay = math.max(0.01, delay)
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
    -- print("RunAllTimerTasks start ", groupName, " ", MiscService:Table2JsonStr(timerTaskState))
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
                -- print("RunTask start ", key)
                RunTask(task)
            end
        end
    end
end

function RunTask(task)
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
    if scaleNum ~= nil and scaleNum ~= 0 then
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
            

            local state = BuildElementState(srcTable.copyRootId)
            local toSetState = false
            if srcTable.dstPos ~= nil then
                toSetState = true
                SetElementStatePos(state, srcTable.dstPos)
            end

            if srcTable.dstScale ~= nil then
                ServerLog("copy ele set state dstScale ServerLog ", srcTable.copyRootId)
                SetElementStateDesc(state, "copy ele set state dstScale")
                toSetState = true
                if srcTable.dstScale.orgSize ~= nil then
                    SetElementStateScaleVec(state, GetScaleDstCalcXyz(srcTable.dstScale.orgSize, srcTable.dstScale.x, srcTable.dstScale.y, srcTable.dstScale.z))
                else
                    SetElementStateScaleNum(state, srcTable.dstScale.scaleNum)
                end
            end

            if toSetState then
                SyncElementState(state)
                --检查状态是否需要同步到远端
                if srcTable.replicates ~= nil and srcTable.postSetReplicates ~= nil then
                    --初始同步但是后续不要求同步,这种情况需要把状态远程同步给客户端
                    if srcTable.replicates and (not srcTable.postSetReplicates) then
                        SetElementStateDoneAction(state, "OnPosSync")
                        PushActionToClients(false, "SyncElementState", state)
                    end
                end
            end

            --
            if srcTable.postSetReplicates ~= nil then
                local stateRp = BuildElementState(srcTable.copyRootId)
                SetElementStateReplicates(stateRp, srcTable.postSetReplicates)
                SetElementStateEnableChildren(stateRp)
                SyncElementState(stateRp)
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
    print("SyncElementState ", state.eid, " ", Element:GetType(state.eid), " ", Element:GetPosition(state.eid), " ", MiscService:Table2JsonStr(state))
    
    
    if state.setChildren ~= nil then
        SyncElementStateAndChildrenById(state.eid, state)
    else
        SyncElementStateById(state.eid, state)
    end
end

--同步元件状态
function SyncElementStateById(elementId, state)
    print("SyncElementState ", MiscService:Table2JsonStr(state))
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
        if state.scale.scaleVec ~= nil then
            Element:SetScale(elementId, VectorFromTable(state.scale.scaleVec))
        else
            Element:SetScale(elementId, state.scale.scaleNum)
        end
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

function SetElementStateScaleVec(state, scaleVec)
    state.scale = {scaleVec = VectorToTable(scaleVec)}
end

function SetElementStateScaleNum(state, scaleNum)
    state.scale = {scaleNum = scaleNum}
end

function SetElementStateDesc(state, desc)
    state.desc = desc
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

function NewVectorTable(x, y, z)
    return {x=x, y=y, z=z}
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

function InactiveObj(obj)
    obj.active = false
end

function InactiveObjById(id)
    local obj = GetObjById(id)
    if obj ~= nil then
        InactiveObj(obj)
    end
end

--一般销毁
function CommonDestroy(deltaTime, obj)
    InactiveObj(obj)
    -- todo should use obj eid
    DestroyElementAndChildren(obj.id)
end

function GetElementPosString(eid)
    return VectorToString(Element:GetPosition(eid))
end

function VectorToString(vec)
    return MiscService:Table2JsonStr(VectorToTable(vec))
end

function SetCustomPropBool(eid, name, value)
    CustomProperty:SetCustomProperty(eid, name, CustomProperty.PROPERTY_TYPE.Bool, value)
end

function CheckCustomPropBoolHas(eid, name)
    local v = CustomProperty:GetCustomProperty(eid, name, CustomProperty.PROPERTY_TYPE.Bool)
    return (v ~= nil)
end

--需要只在客户端运行的用此方法判断
function CanRunOnlyOnClient()
    return System:IsStandalone() or System:IsClient()
end

--需要只在服务器运行的用此方法判断
function CanRunOnlyOnServer()
    return System:IsStandalone() or System:IsServer()
end


function NewMotionParam(id, objId, objGroup, objType, motionObj, objUpdateFunc, objDestroyFunc, totalTime, cycleTime,
    initialDelay, cycleNum, cycleDelay, actionFunc, updateFunc)
    return {id=id, objId=objId, objGroup=objGroup, objType=objType, motionObj=motionObj, objUpdateFunc=objUpdateFunc,
        objDestroyFunc=objDestroyFunc, totalTime=totalTime, cycleTime=cycleTime, initialDelay=initialDelay, cycleNum=cycleNum,
        cycleDelay=cycleDelay, actionFunc=actionFunc, updateFunc=updateFunc}
end


function BuildMotionObj(param)
    local totalTime = param.totalTime
    local cycleTime = param.cycleTime
    local obj = AddNewObj(param.objGroup, param.objType, param.objId, 0, param.objUpdateFunc, totalTime, param.objDestroyFunc)
    obj.motionObj = param.motionObj
    AddObjState(obj, "mu.move")
    SetObjState(obj, "mu.move", totalTime, cycleTime)
    SetObjStateFunc(obj, "mu.move", nil, nil, nil, param.actionFunc, param.updateFunc)
    if param.isBackAndForth then
        AddObjState(obj, "mu.moveBack")
        SetObjState(obj, "mu.moveBack", totalTime, cycleTime)
        SetObjStateNextCycle(obj, "mu.move", "mu", "moveBack")
        SetObjStateNextCycle(obj, "mu.moveBack", "mu", "move")
        SetObjStateFunc(obj, "mu.moveBack", nil, nil, nil, param.actionFunc, param.updateFunc)
    end
    
    StartObjStateByName(obj, "mu", "move")
    return obj
end

function AddMotionToElement(eid, name, motionType, motionVector, isIncrement, initialDelay, totalTime, cycleNum, cycleTime, cycleDelay, isBackAndForth)
    local id = string.format("%s-%s", eid, name)
    local motionObj = {id=id, eid=eid, name=name, type=motionType, vec=VectorToTable(motionVector)}
    local param = NewMotionParam(id, id, ObjGroups.MotionUnit, 0, motionObj, UpdateMotionUnit, DestroyMotionUnit,
        totalTime, cycleTime, initialDelay, cycleNum, cycleDelay, MotionObjAction, MotionObjUpdate)
    local obj = BuildMotionObj(param)
    return obj
end

function MotionObjUpdate(obj, state, deltaTime)
    -- print("MotionObjUpdate start ", MiscService:Table2JsonStr(obj))
    local motionObj = obj.motionObj
    -- print("MotionObjUpdatemotionObj ", MiscService:Table2JsonStr(motionObj.vec), " ", deltaTime)
    local vec = VectorFromTable(motionObj.vec)
    -- print("deltaTime is ", deltaTime)
    local multi = 1 * deltaTime
    if string.find(state.fullname, "moveBack") then
        multi = multi * -1
    end
    local diff = Engine.Vector(vec.X * multi, vec.Y * multi, vec.Z * multi)
    -- print("diff is ", MiscService:Table2JsonStr(VectorToTable(diff)))
    if motionObj.type == CfgTools.MotionUnit.Types.Pos then
        Element:SetPosition(motionObj.eid, Element:GetPosition(motionObj.eid) + diff, Element.COORDINATE.World)
    elseif motionObj.type == CfgTools.MotionUnit.Types.Scale then
        Element:SetScale(motionObj.eid, Element:GetScale(motionObj.eid) + diff)
    elseif motionObj.type == CfgTools.MotionUnit.Types.Rotate then
        local rot = Element:GetRotation(motionObj.eid) + diff
        Element:SetRotation(motionObj.eid, Engine.Vector(LimitRotateNum(rot.X), LimitRotateNum(rot.Y), LimitRotateNum(rot.Z)), Element.COORDINATE.World)
    end
    
end

function LimitRotateNum(num)
    -- print("LimitRotateNum a ", num)
    -- if num < 0 then
    --     num = 360 + num
    -- end
    -- if num > 180 then
    --     print("LimitRotateNum ", num)
    --     num = num - 180
    -- end
    return num
end

function MotionObjAction(obj, state)
    print("MotionObjAction start ", MiscService:Table2JsonStr(obj))
end

function UpdateMotionUnit()
end

function DestroyMotionUnit()
    
end

function RemoveMotionByEidAndName(eid, name)
    local id = string.format("%s-%s", eid, name)
    InactiveObjById(id)
end

function CopyTableByJson(table)
    return MiscService:JsonStr2Table(MiscService:Table2JsonStr(table))
end

function VectorPlus(vec, x, y, z)
    return vec + Engine.Vector(x, y, z)
end

function VectorTablePlus(tab, x, y, z)
    return {x = (tab.x + x), y = (tab.y + y), z = (tab.z + z)}
end

function Stringfy(value)
    return string.format("%s", value)
end

function GetIdFromPoolStringfy(poolName, startNum, incNum, poolSize, poolObj)
    return Stringfy(GetIdFromPool(poolName, startNum, incNum, poolSize, poolObj))
end

--从id池中拿取
function GetIdFromPool(poolName, startNum, incNum, poolSize, poolObj)
    local pool = toolIdPools[poolName]
    if poolObj ~= nil then
        if poolObj.idPools == nil then
            poolObj.idPools = {}
        end
        pool = poolObj.idPools[poolName]
    end
    if pool == nil then
        pool = {cur=startNum, size=poolSize, avaIds={}}
        toolIdPools[poolName] = pool
        pool.cur = pool.cur + 1
        pool.avaIds[Stringfy(pool.cur)] = {id = pool.cur, used=false}
    end
    local c = GetTablePairLen(pool.avaIds)
    if c < poolSize then
        for i = 0, (poolSize - c) do
            pool.cur = pool.cur + 1
            pool.avaIds[Stringfy(pool.cur)] = {id = pool.cur, used=false}
        end
    end
    
    --获取可用
    local idRes = nil
    -- local trashIds = {}
    for index, value in pairs(pool.avaIds) do
        if idRes == nil and value ~= nil then
            if value.used == false then
                value.used = true
                pool.avaIds[index] = nil
                idRes = value.id
            else
                -- table.insert(trashIds, index)
            end
        end
    end
    -- print("GetIdFromPool after count ", pool.cur)
    return idRes
end

function GetTablePairLen(tab)
    local c = 0
    for index, value in pairs(tab) do
        c = c + 1
    end
    return c
end

function IsStringEqual(a, b)
    return Stringfy(a) == Stringfy(b)
end

function GetLocalPlayerIdString()
    return Stringfy(GetLocalPlayerId())
end

function GetLocalPlayerId()
    if System:IsServer() and not System:IsStandalone() then
        return toolCommonCfgs.serverPlayerId
    end
    return Character:GetLocalPlayerId()
end

function CanRunOnce(obj, name)
    if obj.name ~= nil then
        return false
    end
    obj.name = true
    return true
end

function EnsureTableValue(tab, ...)
    local keys = {...}
    local parent = tab
    for index, key in ipairs(keys) do
        if parent[key] == nil then
            parent[key] = {}
        end
        parent = parent[key]
    end
    return parent
end

--深度拷贝
function CopyTableShallow(obj)
    return CopyTableWithoutKeyHandle({}, obj)
end

function CopyTableWithoutKeyHandle(param, obj)
    if type(obj) ~= "table" then
        return obj
    end
    --防止重复生成
    if param[obj] then
        return param[obj]
    end
    local res = {}
    for key, value in pairs(obj) do
        res[CopyTableWithoutKeyHandle(param, key)] = CopyTableWithoutKeyHandle(param, value)
    end
    param[obj] = res
    return res
end

--合并表,保留localTable中指定键名的数据
local function MergeTablesHandle(remoteTable, localTable, preserveKeys)
    -- 用于处理循环引用
    local lookup_table = {}
    preserveKeys = preserveKeys or {} -- 需要保留的本地数据键名列表，例如 {["config"] = true, ["userSettings"] = true}

    local function _merge(remote, localTbl)
        -- 如果远程数据不是表，直接返回远程数据（通常情况）
        if type(remote) ~= "table" then
            return remote
        end
        -- 如果本地数据不是表，或已处理过当前远程表（避免循环引用），则返回远程表的浅拷贝或自身引用
        if type(localTbl) ~= "table" or lookup_table[remote] then
            if lookup_table[remote] then
                return lookup_table[remote]
            end
            local shallowCopy = {}
            for k, v in pairs(remote) do
                shallowCopy[k] = v
            end
            return shallowCopy
        end

        local mergedTable = {}
        lookup_table[remote] = mergedTable -- 记录已处理，避免循环引用

        -- 首先，遍历远程表，这是数据的基础
        for key, remoteValue in pairs(remote) do
            local localValue = localTbl[key]

            -- 判断当前键是否在保留列表中，且本地数据中存在此键
            if preserveKeys[key] and localValue ~= nil then
                -- 如果本地数据中对应值也是表，则递归合并
                if type(remoteValue) == "table" and type(localValue) == "table" then
                    mergedTable[key] = _merge(remoteValue, localValue)
                else
                    -- 否则，使用本地数据的值
                    mergedTable[key] = localValue
                end
            else
                -- 不在保留列表的键，直接使用远程数据
                -- 如果远程数据的值是表，且本地对应值也是表，则递归合并（使用空的本地表，确保远端结构优先）
                if type(remoteValue) == "table" and type(localValue) == "table" then
                    mergedTable[key] = _merge(remoteValue, localValue)
                else
                    mergedTable[key] = remoteValue
                end
            end
        end

        -- 其次，遍历本地表，将远程表中不存在、但本地表中存在的键加入合并结果（可选逻辑）
        -- 注意：根据你的需求，你可能希望注释掉这部分，以确保结果严格基于远程表的结构
        for key, localValue in pairs(localTbl) do
            if mergedTable[key] == nil then
                mergedTable[key] = localValue
            end
        end

        -- -- 处理元表（可选，根据需求）
        -- local remoteMetatable = getmetatable(remote)
        -- if remoteMetatable then
        --     setmetatable(mergedTable, remoteMetatable)
        -- end

        return mergedTable
    end

    return _merge(remoteTable, localTable)
end

function MergeTables(remoteTable, localTable, preserveKeys)
    preserveKeys = preserveKeys or {}
    local keyMap = {}
    for index, value in ipairs(preserveKeys) do
        keyMap[value] = true
    end
    return MergeTablesHandle(remoteTable, localTable, keyMap)
end