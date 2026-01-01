require("MainGame")

local shareActionState = {}

--初始化客户端
function InitGameClient()
    PreInitAll(true)
    ClientInit()
end

function StartGameClient()
    --初始化共有变量
    InitVarsOnStart()
    --初始化客户端变量
    InitVarsClientOnStart()

    PreInitGameClientOnStart()
    InitClientOnStart()
    PostInitGameClientOnStart()
end

function InitVarsOnStart()
    if not CanRunOnce(shareActionState, "InitVarsOnStart") then
        return
    end
    GameInitVarsOnStart()
end

function PostInitGameClientOnStart()
    PostInitClientOnStart()

    PushActionToServer(false, "OnGameClientStarted", {})
end

function OnGameClientStarted()
    OnClientStarted()
end

function PreInitGameClientOnStart()
    print("BindNotify PrepareClient")
    PreInitAllOnStart(true)
end

--初始化服务端
function InitGameServer()
    PreInitAll(false)
    ServerInit()
end

function StartGameServer()
    --初始化共有变量
    InitVarsOnStart()
    --初始化服务器变量
    InitVarsServerOnStart()

    PreInitGameServerOnStart()
    InitServerOnStart()
    PostInitGameServerOnStart()
end

function PostInitGameServerOnStart()
    PostInitServerOnStart()
end

function PreInitGameServerOnStart()
    print("BindNotify PreInitGameServer")
    PreInitAllOnStart(false)
end

function PreInitAll(isClient)
    if not CanRunOnce(shareActionState, "PreInitAll") then
        return
    end

    InitTimeState()

    TimerManager:AddLoopFrame(0, OnUpdateFrameTime)

    --添加定时任务的检查任务,后续可调用AddTimerTask
    --每一帧都检查的定时任务: delay为0
    -- 每隔1秒检查的定时任务
    AddLoopTimerWithInit(0, 0, RunAllTimerTasks, TaskNames.task1s)
    AddTimerTask(TaskNames.task1s, "CheckTempPosSynced", 0, 5, CheckTempPosSynced)
    AddTimerTask(TaskNames.task1s, "DebugAnaObjects", 0, 10, DebugAnaObjects)
    --每一帧都检查的定时任务: delay为0
    -- AddLoopTimerWithInit(0, 0, RunAllTimerTasks, TaskNames.taskFrame)
    AddTimerTask(TaskNames.task1s, "OnUpdateFrame", 0, 0, OnUpdateFrame)

    GameInitVars()
    BindNotifyAction()
    GamePreInitAll()
end

---客户端和服务端都必须初始化的
function PreInitAllOnStart(isClient)
    if not CanRunOnce(shareActionState, "PreInitAllOnStart") then
        return
    end
    ServerLog("PreInitAllOnStart start")

    
end

function UpdateGameClient()
    -- OnUpdateFrame(true)
end

function UpdateGameServer()
    -- OnUpdateFrame(false)
end