
require("YmMusicTools")

--游戏运行时间,如果游戏暂停了这个时间不会增加
local RunningTime = 0
local MsgIdGameAction = 100244
local clientTimeState = {}
local serverTimeState = {}

local timerTaskState = {groupName = {taskName = {initTs=0, initDelay=0, delay=3, lastRunTs=0, count=0, active=true, func=nil}}}
-- local testStates = {{idle={startTs=12345, endTs=27382}}, {move={startTs=12345, endTs=27382}}}
local objStates = {[27007]={id=27007, state="move", states={{idle={startTs=12345, endTs=27382}}, {move={startTs=12345, endTs=27382}}} }}

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
    
    OnUpdateTimeStateSingle(state)
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

function AddNewObjState(groupType, type, id, updateDur, updateFunc)
    local obj = {id=id, group=groupType, type=type, updateDur=updateDur, updateFunc=updateFunc, lastUpdateTs=0, active=true, createTs=GetGameTimeCur(), state="init", states={}}
    objStates[id] = obj
    return obj
end

function UpdateAllObjStates(deltaTime)
    for id, obj in pairs(objStates) do
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