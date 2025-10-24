
require("YmMusicTools")

--游戏运行时间,如果游戏暂停了这个时间不会增加
local RunningTime = 0
local MsgIdGameAction = 100244
local clientTimeState = {}
local serverTimeState = {}

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
    System:BindNotify(MsgIdGameAction, function(msgId, msg)
        DoAction(msg)
    end)
end

function PushAction(doSelf, funcName, funcArg)
    -- local funcName = debug.getinfo(func, "n").name
    local msg = {funcName = funcName, funcArg = funcArg}
    if not System:IsStandalone() then
        System:SendToAllClients(MsgIdGameAction, msg)
    end
    
    if doSelf then
        DoAction(msg)
    end
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
    print("DoAction ", MiscService:Table2JsonStr(msg))
    _G[msg.funcName](msg.funcArg)
end

function AddNewObj(groupType, type, id, updateDur, updateFunc)
    local obj = {id=id, group=groupType, type=type, updateDur=updateDur, updateFunc=updateFunc, lastUpdateTs=0, active=true, createTs=GetGameTimeCur(), states={}}
    AddObjState(obj, nil)
    objectsAio[id] = obj
    return obj
end

function UpdateAllObjStates(deltaTime)
    for id, obj in pairs(objectsAio) do
        local timeCur = GetGameTimeCur()
        -- print("UpdateAllObjStates ", timeCur, " ", MiscService:Table2JsonStr(obj))
        if not obj.active then
        elseif (timeCur - obj.lastUpdateTs) < obj.updateDur then
        elseif obj.updateFunc ~= nil then
            -- print("UpdateAllObjStates updateFunc", MiscService:Table2JsonStr(obj))
            obj.lastUpdateTs = timeCur
            obj.updateFunc(deltaTime, obj)
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