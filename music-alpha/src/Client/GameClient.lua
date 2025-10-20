local GameClient = {}


function GameClient:Init()
    Log:PrintLog("[GameClient:Init]")
    
    -- 绑定网络协议
    System:BindNotify(NetMsg.SeverLog, self.OnSeverLog, self)
    System:BindNotify(NetMsg.S2C_ServerNtf, self.OnServerNtf, self)
    System:BindNotify(NetMsg.S2C_ServerAck, self.OnServerAck, self)
    System:BindNotify(NetMsg.S2C_OnReconnected, self.OnReconnected, self)
end

-- 客户端游戏开始时
function GameClient:OnStart()
    Log:PrintLog("[GameClient:OnStart]")

    InitMusicClient()
    TimerManager:AddTimer(1, PlaySfx, "starmantwo")
    TimerManager:AddTimer(11, PlaySfx, "ending")
    TimerManager:AddTimer(21, PlaySfx, "gameover")
    TimerManager:AddTimer(31, PlaySfx, "levelcomplete")
    -- TimerManager:AddTimer(15, PlayMusic, "undergroundremix", 2)
    
end

-- 游戏更新
function GameClient:OnUpdate()
end

-- 游戏结束
function GameClient:OnEnd()
    Log:PrintLog("[GameClient:OnEnd]")
end

-- 断线重连
function GameClient:OnReconnected(msgId, msg)
    Log:PrintLog("[GameClient:OnReconnected]", msg.text)
end

-- 服务端通过网络输出的日志
function GameClient:OnSeverLog(msgId, msg)
    if msg then
        Log:PrintLog("[GameClient:OnSeverLog]", msgId, table.unpack(msg))
    end
end

-- 收到服务端广播协议
function GameClient:OnServerNtf(msgId, msg)
    Log:PrintLog("[GameClient:OnServerNtf]", msg.text, "GameTime:", msg.time)

    if tonumber(msg.time) == 0 then
        -- 向服务端发送请求
        local msg = {
            text = "你好, 服务器!",
        }
        System:SendToServer(NetMsg.C2S_ClientReq, msg)
    end
end

-- 收到服务端回应协议
function GameClient:OnServerAck(msgId, msg)
    Log:PrintLog("[GameClient:OnServerAck]", msg.text)
end

return GameClient
