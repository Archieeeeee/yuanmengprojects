require("MainGame")

--初始化客户端
function InitGameClient()
    --初始化共有变量
    InitVars()
    --初始化客户端变量
    InitVarsClient()

    PreInitGameClient()
    InitClient()
    PostInitGameClient()
end

function PostInitGameClient()
    PostInitClient()

    PushActionToServer(false, "OnGameClientInited", {})
end

function OnGameClientInited()
    OnClientInited()
end

function PreInitGameClient()
    print("BindNotify PrepareClient")
    PreInitAll(true)
end

--初始化服务端
function InitGameServer()
    --初始化共有变量
    InitVars()
    --初始化服务器变量
    InitVarsServer()

    PreInitGameServer()
    InitServer()
    PostInitGameServer()
end

function PostInitGameServer()
    PostInitServer()
end

function PreInitGameServer()
    print("BindNotify PreInitGameServer")
    PreInitAll(false)
end

---客户端和服务端都必须初始化的
function PreInitAll(isClient)
    if isClient and System:IsStandalone() then
        return
    end
    ServerLog("PreInitAll start")
    BindNotifyAction()

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
end

function UpdateGameClient()
    -- OnUpdateFrame(true)
end

function UpdateGameServer()
    -- OnUpdateFrame(false)
end