require("MainGame")

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

    AddLoopTimerWithInit(0, 1, RunAllTimerTasks, "1sTasks")
end

function UpdateGameClient()
    OnUpdateFrame(true)
end

function UpdateGameServer()
    OnUpdateFrame(false)
end