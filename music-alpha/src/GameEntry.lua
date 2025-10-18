-- 脚本加载入口

Debug = true --debug模式，正式发布时请设为false

-- 网络协议
NetMsg = {
    SeverLog = 1000, -- 服务端日志输出

    S2C_ServerNtf = 1001,
    C2S_ClientReq = 1002,
    S2C_ServerAck = 1003,
    S2C_OnReconnected = 1004,
}

------------------------------------------------- Game Require ------------------------------------------------------
local GameServer = require "Server.GameServer"
local GameClient = require "Client.GameClient"

------------------------------------------------- Game Life ---------------------------------------------------------
-- 初始化
GameServer:Init()
GameClient:Init()

-- 客户端游戏更新
local function UpdateClient()
    GameClient:OnUpdate()
end

-- 服务端游戏更新
local function UpdateServer()
    GameServer:OnUpdate()
end

-- 脚本启动时调用
local function OnBeginPlay()
    -- 请注意 单机启动的游戏既是服务器端又是客户端 System:IsServer() 和 System:IsClient() 都返回 true

    -- 启动服务器
    if System:IsServer() then
        -- 服务端游戏开始入口
        GameServer:OnStart()

        -- 循环更新服务器
        local timeDelta = 0.1 -- 服务端每次刷新的时间间隔
        TimerManager:AddLoopTimer(timeDelta, UpdateServer)
    end

    -- 启动客户端
    if System:IsClient() then
        -- 客户端游戏开始入口
        GameClient:OnStart()
        
        -- 循环更新客户端
        local timeDelta = 0.02 -- 客户端每次刷新的时间间隔
        TimerManager:AddLoopTimer(timeDelta, UpdateClient)
    end
end

-- 脚本结束时调用
local function OnEndPlay()
    if System:IsServer() then
        GameServer:OnEnd()
    end

    if System:IsClient() then
        GameClient:OnEnd()
    end
end

-- 监听脚本启动事件
System:RegisterEvent(Events.ON_BEGIN_PLAY, OnBeginPlay)

-- 监听脚本结束事件
System:RegisterEvent(Events.ON_END_PLAY, OnEndPlay)