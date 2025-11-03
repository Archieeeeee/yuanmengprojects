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
    BindNotifyAction()
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
    BindNotifyAction()

    --添加定时任务的检查任务,后续可调用AddTimerTask
    --每隔1秒检查的定时任务
    AddLoopTimerWithInit(0, 1, RunAllTimerTasks, TaskNames.task1s)
    --每一帧都检查的定时任务: delay为0
    AddLoopTimerWithInit(0, 0, RunAllTimerTasks, TaskNames.taskFrame)
end

function UpdateGameClient()
    OnUpdateFrame(true)
end

function UpdateGameServer()
    OnUpdateFrame(false)
end