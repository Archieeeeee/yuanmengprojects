local GameClient = {}

local music1="{\"tracks\":[{\"notes\":[],\"noteMap\":{},\"cueNoteIdx\":0,\"programNum\":0,\"volume\":-1,\"channelIndex\":0,\"trackIndex\":0},{\"notes\":[{\"note\":60,\"tickOn\":0,\"tickOff\":220,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":60,\"tickOn\":220,\"tickOff\":440,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":67,\"tickOn\":440,\"tickOff\":660,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":67,\"tickOn\":660,\"tickOff\":880,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":69,\"tickOn\":880,\"tickOff\":1100,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":69,\"tickOn\":1100,\"tickOff\":1320,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":67,\"tickOn\":1320,\"tickOff\":1760,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":65,\"tickOn\":1760,\"tickOff\":1980,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":65,\"tickOn\":1980,\"tickOff\":2200,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":64,\"tickOn\":2200,\"tickOff\":2420,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":64,\"tickOn\":2420,\"tickOff\":2640,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":62,\"tickOn\":2640,\"tickOff\":2860,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":62,\"tickOn\":2860,\"tickOff\":3080,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0},{\"note\":60,\"tickOn\":3080,\"tickOff\":3520,\"programNum\":0,\"velocityOn\":80,\"velocityOff\":0,\"channelIndex\":0}],\"noteMap\":{},\"cueNoteIdx\":0,\"programNum\":0,\"volume\":-1,\"channelIndex\":0,\"trackIndex\":1}],\"cuePosMs\":0,\"timePerBitMs\":5.0,\"tempo\":500000,\"numerator\":4,\"denominator\":2,\"metronomeClicks\":24,\"notatedNum\":8,\"theTPQNorPPQ\":220}"
local note1 = {note=700092, tick=10, delta=200}
local playStatus = {cuePosMs=0}
local midiAio1 = {}

local track1 = {notes={note1}, cueNoteIdx=1}

function playSingleNote(midiAio, note)
    print("playSingleNote 1", MiscService:Table2JsonStr(note))

    -- TimerManager:AddTimer(2, Audio:PlaySFXAudio2D(note.note,2,100,0))
    local durationNote = (note.tickOff - note.tickOn) * midiAio.timePerBitMs / 1000.0
    Audio:PlaySFXAudio2D(note.note + 500001, durationNote, 100, 0)
end

function checkAllTracks(midiAio)
    print("checkAllTracks 1", MiscService:Table2JsonStr(track))
    if midiAio.cuePosMs == 0 then
        midiAio.cuePosMs = TimerManager:GetClock()
    end

    for j=1,#midiAio.tracks do
        local track = midiAio.tracks[j]

        for i=track.cueNoteIdx + 1, #track.notes do
            local note = track.notes[i]
            local playStartedDelta = TimerManager:GetClock() - midiAio.cuePosMs
            local noteStartDelta = note.tickOn * midiAio.timePerBitMs;
            local startDelay = noteStartDelta - playStartedDelta
            if startDelay < 10000 then
                track.cueNoteIdx=track.cueNoteIdx + 1
                TimerManager:AddTimer(startDelay / 1000.0, playSingleNote, midiAio, note)
                -- playSingleNote(midiAio, note)
            end
           
        end

    end
    
end

function playNotes(midiAio)
    -- body
    print("playNotes start1 ", midiAio.tracks[1])
    
    print("playNotes start ", midiAio.cuePosMs)
    TimerManager:AddLoopTimer(3,checkAllTracks,midiAio)
end

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

    midiAio1 = MiscService:JsonStr2Table(music1)
    TimerManager:AddTimer(5,playNotes,midiAio1)
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
