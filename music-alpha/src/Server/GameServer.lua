require("MainGame")

local GameServer = {
    StartTime = 0, --开始时间
    GameTime = 0, --游戏时间
    LastUpdateTs = 0
}

-- 服务端日志输出，可以选择是否发送给客户端由客户端进行输出，方便联网调试
local function ServerLog(...)
    Log:PrintLog(...)

    if Debug then
        -- 将服务端日志发送至客户端
        System:SendToAllClients(
            NetMsg.SeverLog,
            {...}
        )
    end
end

function GameServer:Init()
    ServerLog("[GameServer:Init]")

    -- 绑定网络协议
    System:BindNotify(NetMsg.C2S_ClientReq, self.OnClientReq, self)

    -- 断线重连时，同步当前游戏状态给客户端
    System:RegisterEvent(Events.ON_PLAYER_RECONNECTED, self.OnReconnected, self)
    RegisterEventsServer()
end

-- 游戏启动时
function GameServer:OnStart()
    ServerLog("[GameServer:OnStart]")

    InitServer()

    if not System:IsStandalone() then
        InitMusic()    
    end
    
    local eventId = System:RegisterEvent(Events.ON_PLAYER_TOUCH_ELEMENT, OnCharacterTouchUnit)
    print("register eid ", eventId)
    

    self.StartTime = TimerManager:GetTimeSeconds()
    self.GameTime = 0

    -- 当前登录的所有玩家ID
    local playerIds = Character:GetAllPlayerIds()
    for _, v in ipairs(playerIds) do
        Log:PrintLog("player", v)
        local msg = {
            text = "游戏开始了！",
            time = self.GameTime,
        }
        System:SendToClient(v, NetMsg.S2C_ServerNtf, msg)
    end
end

-- 游戏结束时
function GameServer:OnEnd()
    ServerLog("[GameServer:OnEnd]")
end

-- 游戏更新
function GameServer:OnUpdate()
    -- 当前游戏总时间
    self.GameTime = TimerManager:GetTimeSeconds() - self.StartTime
    OnUpdateFrame(false)
    UpdateAllObjStates(GetUpdateDeltaTime())

    --每10秒给客户端发送一次广播
    self.ntfCount = self.ntfCount or 0
    if math.floor(self.GameTime/10) > self.ntfCount then
        self.ntfCount = self.ntfCount + 1

        local msg = {
            text = "你好, 我是服务器!",
            time = self.GameTime,
        }
        System:SendToAllClients(NetMsg.S2C_ServerNtf, msg)
    end
end

-- 断线重连
function GameServer:OnReconnected(playerId, levelId)
    Log:PrintLog("[GameServer:OnReconnected]", playerId, levelId)
    local msg = {
        text = "游戏进行中！",
        time = self.GameTime,
    }
    System:SendToClient(playerId, NetMsg.S2C_OnReconnected, msg)
end

function GameServer:OnClientReq(msgId, msg, playerId)
    Log:PrintLog("[GameServer:OnClientReq]", playerId, msg.text)

    local msg = {
        text = "你好, 客户端!",
    }
    System:SendToClient(playerId, NetMsg.S2C_ServerAck, msg)
end

return GameServer
