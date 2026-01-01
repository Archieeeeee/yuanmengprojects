require("YmMusicTools")
require("YmTools")

local platformId = 229
local msgIdBlockState = 100115
posOrg = Engine.Vector(0, 0, 0)

local typeObjs = {boss = 1000, blockUnknown=101, brick=103, tetrisBlock=2001}
local cfgAirWallId = 1105000000000074
local cfgElements = {}
local protos = {}
local cfgCopyProps = {"debris"}
local cfgDataNames = {"ymAnimes"}
local haohaoyaId = 327
animeDemo = {cur=0, lastName=nil, lastPlay=0, lastCount=0}
ymAnimes = {}
local elesInScene = {airwall=331, cube=381, brick=334, frameBoard=531}
-- local tetrisBoard = {parts={}, columnHeights={}}
cfgTetrisBlock_1_1 = {parts={{1,1,0,0}, {0,1,1,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=1, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_2_1 = {parts={{0,1,1,0}, {1,1,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=2, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_3_1 = {parts={{1,1,1,0}, {0,1,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=3, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_4_1 = {parts={{1,1,1,1}, {0,0,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=4, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_5_1 = {parts={{1,1,0,0}, {1,1,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=5, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_6_1 = {parts={{1,1,1,0}, {1,0,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=6, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_7_1 = {parts={{1,1,1,0}, {0,0,1,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=7, morph=1, nextMorph=2, entityDiffRow=0, entityDiffCol=0, rotate={x=0, y=0, z=90}}}
-- cfgTetrisBlock_1_2 = {parts={{0,0,0,0}, {0,1,0,0}, {1,1,0,0}, {1,0,0,0}}, cfg={type=1, morph=2, nextMorph=1, entityDiffRow=1, entityDiffCol=0, rotate={x=90, y=0, z=90}}}
local cfgTetris = {blockSize=100, board={rowNum=20, colNum=10}, matchIdStart=0}
-- local tetrisPlayerData = {dropSpeed=100, dropBlocks={}, boardPosTab=nil}
local players = {}
--服务端只负责记录
local tetrisMatchsServer = {}
--数据端记录数据
local tetrisMatchs = {}
--从远端同步的数据和自身数据,并不是对局数据集
local tetrisMatchsLocal = {}
local varPool = {mergeActions={}}


function CallbackCharCreated(playerId)
    local pos = Element:GetPosition(platformId)
    Character:SetPosition(playerId, pos + Engine.Vector(0, 0, 500))
end

function ClientInit()
end

function ServerInit()
    RegisterEventsServer()
end

function InitClientOnStart()
    InitMusicClient()
end

function GamePreInitAll()
    RegisterEventsAll()

    AddTimerTask(TaskNames.task1s, "GenTetrisDropBlock", 2, 3, GenTetrisDropBlock)
    AddTimerTask(TaskNames.task1s, "MergeTetrisBlockDataTask", 0, 0.01, MergeTetrisBlockDataTask)
end

function InitServerOnStart() 
    -- RegisterEventsServer()
    -- TimerManager:AddTimer(UMath:GetRandomInt(1,10), PlaySfx, "levelcomplete")
    InitBlockProto()
    PushActionToClients(true, "SyncInit", {})

    InitServerTimers()

    if not System:IsStandalone() then
        InitMusic()
    end

end

function InitVarsClientOnStart()
    
end

function InitVarsServerOnStart()
    
end

function PostInitClientOnStart()
    
end

function PostInitServerOnStart()
end

function OnClientStarted()
    Creature:SetScale(haohaoyaId, 3)
end

function GameInitVars()
    ServerLog("GameInitVars")

    cfgElements.airWall = {id=1105000000000074, size=Engine.Vector(5,5,3)}
    cfgElements.cube = {id=1101002001034000, size=Engine.Vector(1,1,1)}
    cfgElements.cubeNight = {id=1101002001105000, size=Engine.Vector(1,1,1)}

    posOrg = Element:GetPosition(platformId)
    LoadGlobalVarsFromData(cfgDataNames)
    print("animeData sss ", MiscService:Table2JsonStr(ymAnimes))
    -- print("animeData aaa ", MiscService:Table2JsonStr(animeData))
    -- print("animeData bbb ", animeData.m)
    -- for index, value in ipairs(animeData.animeList) do
    --     print("animeData index ", value.name)
    -- end
    -- print("animeData ", animeData)

    -- local varMsg = BuildSyncVarMsg()
    -- PushSyncVar(varMsg, "posOrg", posOrg)
    -- PushSyncVar(varMsg, "ymAnimes", ymAnimes)
    -- PushActionToClients(false, "SyncGlobalVars", varMsg)

    InitTetrisData()
end

function GameInitVarsOnStart()
end

function PlayAnime()
    print("PlayAnime start")

    if LoopTimerCanRun(animeDemo, "lastPlay", 5) then
        animeDemo.cur = animeDemo.cur + 1
        if animeDemo.cur > #ymAnimes.animeList then
            animeDemo.cur = 1
        end
        PushGlobalVarSingle("animeDemo", animeDemo)
        PushActionToClients(true, "SyncPlayAnime", {})
    end

    if LoopTimerCanRun(animeDemo, "lastCount", 1) then
        PushGlobalVarSingle("animeDemo", animeDemo)
        PushActionToClients(true, "SyncPlayAnimeUI", {})
    end

end

function SyncPlayAnime()
    if animeDemo.cur ~= 0 then
        -- print("PlayAnime will play aaa", MiscService:Table2JsonStr(ymAnimes))
        -- print("PlayAnime will play bbb", MiscService:Table2JsonStr(animeDemo))
        -- print("PlayAnime will play ", ymAnimes.animeList[animeDemo.cur].v)
        -- PlaySfx("oneup", 0, 0.8)
        PlayThenStopAnim(0, Animation.PLAYER_TYPE.Creature, haohaoyaId, ymAnimes.animeList[animeDemo.cur].v, Animation.PART_NAME.FullBody, 4.5, 0.2)
    end
end

function SyncPlayAnimeUI()
    print("SyncPlayAnime start ", MiscService:Table2JsonStr(animeDemo))
    local nextCur = animeDemo.cur + 1
    if nextCur > #ymAnimes.animeList then
        nextCur = 1
    end

    local cd = math.ceil(5 - GetGameTimeCur() + animeDemo.lastPlay)
    if animeDemo.cur ~= 0 then
        UI:SetText({101432}, UMath:NumberToString(cd))
        UI:SetText({101433}, string.format("正在播放: %s", ymAnimes.animeList[animeDemo.cur].n))
        UI:SetText({101211}, string.format("下一个: %s", ymAnimes.animeList[nextCur].n))
    end
end

function InitServerTimers() 
    -- TimerManager:AddLoopTimer(5, GenBlock)
    if false then
        AddTimerTask(TaskNames.task1s, "genBlock", 2, 10, GenBlock)
        AddTimerTask(TaskNames.task1s, "genBoss", 2, 30, GenBoss)
        AddTimerTask(TaskNames.task1s, "GenBlockBall", 2, 10, GenBlockBall)
        AddTimerTask(TaskNames.task1s, "playAnime", 3, 0.9, PlayAnime)
    end
    AddTimerTask(TaskNames.task1s, "StartTetrisMatchAll", 3, 9999, StartTetrisMatchAll)
    -- AddTimerTask("1sTasks", "sfxTest", 3, 60, function ()
    --     PlaySfx("starmantwo")
    -- end)
end


function GetActiveDropBlock(blocks)
    for key, block in pairs(blocks) do
        if block.active then
            return block
        end
    end
    return nil
end

function GetTetrisControlBlock()
    for key, match in pairs(tetrisMatchsLocal) do
        for key, player in pairs(match.players) do
            for key, block in pairs(player.dropBlocks) do
                if block.active and IsBlockPlayerSelf(block) then
                    return block
                end
            end
        end
    end
    return nil
end

--检查活跃对局
function GenTetrisDropBlock()
    ServerLog("GenTetrisDropBlock ", MiscService:Table2JsonStr(tetrisMatchs))
    for key, match in pairs(tetrisMatchs) do
        if match.active == true then
            for key, player in pairs(match.players) do
                if GetActiveDropBlock(player.dropBlocks) == nil then
                    GenSingleTetrisDropBlock(match, player)
                end
            end
        end
    end
end

function GenSingleTetrisDropBlock(match, player)
    local block = NewTetrisBlock(math.random(1, 7), 1)
    block.matchId = match.id
    block.playerId = player.id
    block.objId = string.format("tblock-%s-%s-%s", match.id, player.id, block.id)
    ServerLog("GenSingleTetrisDropBlock ", block.objId)
    block.dropSpeed = match.dropSpeed
    --init postab
    local board = match.board
    local posSrc = VectorFromTable(board.boardPosTab)
    local dropHigh = (GetTetrisBoardRowNum(board) + 2) * cfgTetris.blockSize
    posSrc = VectorPlus(posSrc, 0, 0, dropHigh)
    posSrc.X = GetTetrisBlockPosX(block, board.boardPosTab)
    block.posTabInit = VectorToTable(posSrc)
    block.posTab = CopyTableByJson(block.posTabInit)

    player.dropBlocks[block.id] = block
    
    local action = NewTetrisAction(match, player, block, "NewTetrisBlockEntity")
    SendTetrisActionToMatchPlayers(action)
end

function InitTetrisData()
    --生成配置变量
    for type = 1, 7, 1 do
        local varName = GetTetrisBlockCfgVarName(type, 1)
        GenTetrisBlockCfgByRotateMulti(_G[varName], 3)
    end
    --初始化方块配置
    for type = 1, 7 do
        for morph = 1, 4 do
            local cfgBlock = GetTetrisBlockCfg(type, morph)
            if cfgBlock ~= nil then
                InitTetrisBlockCfgEntityDiff(cfgBlock)
                InitTetrisBlockCfgCol(cfgBlock)
            end
        end
    end
end

function GenTetrisBlockCfgByRotateMulti(blockCfg, num)
    for i = 1, num, 1 do
        blockCfg = GenTetrisBlockCfgByRotate(blockCfg)
    end
end

--以方块的中心顺时针旋转90度
function GenTetrisBlockCfgByRotate(blockCfg)
    local parts = blockCfg.parts
    local copyCfg = CopyTableByJson(blockCfg)
    local rowNum = #parts
    local colNum = #parts[1]
    for row = 1, rowNum do
        for col = 1, colNum do
            copyCfg.parts[colNum - col + 1][row] = parts[row][col]
        end
    end
    copyCfg.cfg.nextMorph = blockCfg.cfg.nextMorph + 1
    if copyCfg.cfg.nextMorph > 4 then
        copyCfg.cfg.nextMorph = 1
    end
    copyCfg.cfg.morph = blockCfg.cfg.nextMorph
    copyCfg.cfg.rotate.x = copyCfg.cfg.rotate.x - 90
    if copyCfg.cfg.rotate.x == (-270) then
        copyCfg.cfg.rotate.x = 90
    end
    local varName = GetTetrisBlockCfgVarName(copyCfg.cfg.type, copyCfg.cfg.morph)
    _G[varName] = copyCfg
    print("GenTetrisBlockCfgByRotate ", MiscService:Table2JsonStr(copyCfg))
    return copyCfg
end

--去除底部空白行和左边空白列,并记录位移数据
function InitTetrisBlockCfgEntityDiff(cfgBlock)
    if cfgBlock.cfg.morph == 1 then
        return
    end
    local rowNum = #cfgBlock.parts
    local colNum = #cfgBlock.parts[1]
    local minRow = rowNum
    local minCol = colNum
    for row = 1, rowNum do
        for col = 1, colNum do
            if cfgBlock.parts[row][col] ~= 0 then
                minRow = math.min(row, minRow)
                minCol = math.min(col, minCol)
            end
        end
    end
    minRow = (minRow - 1)
    minCol = (minCol - 1)
    cfgBlock.cfg.entityDiffRow = minRow
    cfgBlock.cfg.entityDiffCol = minCol
    --重新赋值
    local copyBlock = CopyTableByJson(cfgBlock)
    for row = 1, rowNum do
        for col = 1, colNum do
            if row + minRow <= rowNum and col + minCol <= colNum then
                cfgBlock.parts[row][col] = copyBlock.parts[row + minRow][col + minCol]
            else
                cfgBlock.parts[row][col] = 0
            end
        end
    end
    print("InitTetrisBlockCfgEntityDiff ", MiscService:Table2JsonStr(cfgBlock))
end

function InitTetrisBlockCfgCol(cfgBlock)
    --找出最左和最右端
    local parts = cfgBlock.parts
    local colStart = #parts[1]
    local colEnd = 1
    --遍历每一列
    for col = 1, #parts[1] do
        --该列是否发现有值
        local colFound = false
        for row = 1, #parts do
            if colFound == false and parts[row][col] ~= 0 then
                colFound = true
                colStart = math.min(colStart, col)
                colEnd = math.max(colEnd, col)
            end
        end
    end
    cfgBlock.cfg.colStart = colStart
    cfgBlock.cfg.colEnd = colEnd
end

---初始化单个棋盘
function InitTetrisBoard(board, rowNum, columnNum)
    for i = 1, rowNum do
        local row = {}
        for j = 1, columnNum do
            table.insert(row, 0)
        end
        table.insert(board.parts, row)
    end
    for j = 1, columnNum do
        table.insert(board.columnHeights, 0)
    end
    board.rowNum = rowNum
    board.colNum = columnNum
end

---新建方块
function NewTetrisBlock(type, morph)
    local id = GetIdFromPoolStringfy("dropBlockId", 0, 1, 10, nil)
    local block = {id=id, active=true, dropInited=false, solidet=false, localData={}}
    SetTetrisBlockCfg(block, type, morph)
    -- block.curColumn = math.floor(cfgTetris.board.colNum / 2)
    block.curColumn = math.random(1, cfgTetris.board.colNum - 4)
    return block
end

function GetTetrisBlockCfgVarName(type, morph)
    local varName = string.format("cfgTetrisBlock_%s_%s", type, morph)
    -- print("SetTetrisBlockCfg varName ", varName)
    return varName
end

function GetTetrisBlockCfg(type, morph)
    local varName = GetTetrisBlockCfgVarName(type, morph)
    local cfgBlock = _G[varName]
    return cfgBlock
end

function SetTetrisBlockCfg(block, type, morph)
    local cfgBlock = GetTetrisBlockCfg(type, morph)
    block.blockParts = CopyTableByJson(cfgBlock.parts)
    block.blockCfg = cfgBlock.cfg
    -- print("SetTetrisBlockCfg block ", MiscService:Table2JsonStr(block))
end

function GetTetrisBlockPosX(block, boardPosTab)
    return boardPosTab.x + block.curColumn * cfgTetris.blockSize
end

--发送同步
function SendSyncTetrisMatchDataToPlayers(syncFuncName, match, block, excludeBlockPlayer)
    local action = NewTetrisAction(match, nil, block, "SyncTetrisMatchData")
    action.syncFuncName = syncFuncName
    for key, player in pairs(match.players) do
        if excludeBlockPlayer then
            if not IsStringEqual(player.id, block.playerId) then
                SendTetrisActionToSinglePlayer(action, player.id)
            end
        else
            SendTetrisActionToSinglePlayer(action, player.id)
        end
    end
end

function IsBlockPlayerSelf(block)
    return IsStringEqual(block.playerId, GetLocalPlayerIdString())
end

function SyncTetrisMatchData(action)
    print("SyncTetrisMatchData ", action.syncFuncName)
    _G[action.syncFuncName](action)
end

function SyncTetrisMatchDataNewMatch(action)
    tetrisMatchsLocal[action.match.id] = action.match
end

--更新对局但不包括玩家信息
function SyncTetrisMatchDataUpdateMatchNoPlayerData(action)
    local matchLocal = tetrisMatchsLocal[action.match.id]
    action.match.players = matchLocal.players
    tetrisMatchsLocal[action.match.id] = action.match
end

function SyncTetrisMatchDataNewBlock(action)
    local block = action.block
    local matchLocal = GetMatchLocalByBlock(block)
    matchLocal.players[block.playerId].dropBlocks[block.id] = block
end

function SyncTetrisMatchDataUpdateBlock(action)
    if IsStringEqual(action.block.playerId, GetLocalPlayerId()) then
        print("error SyncTetrisMatchDataUpdateBlock should not update self")
        return
    end
    local blockLocal = GetTetrisLocalBlock(action.block)
    if blockLocal ~= nil then
        print("SyncTetrisMatchDataUpdateBlockblockLocal")
        action.block.localData = blockLocal.localData
        --posTab永远用本地的,因为包含高度数据
        action.block.posTab = blockLocal.posTab
    end

    --最后当作新的赋值
    SyncTetrisMatchDataNewBlock(action)
end

-- function SyncTetrisMatchData(action)
--     local matchLocal = tetrisMatchsLocal[action.match.id]
--     if matchLocal == nil then
--         tetrisMatchsLocal[action.match.id] = action.match
--         return
--     end
--     local matchRemote = CopyTableByJson(action.match)
--     local matchLocalBak = CopyTableByJson(matchLocal)
    
--     --赋值本地数据
--     for playerId, player in pairs(matchRemote.players) do
--         --如果本地方块数据有值并且远端是本人的数据,那么恢复为本地数据
--         local playerLocal = matchLocalBak.players[player.id]
--         local isToRestoreBlocks = (GetTablePairLen(playerLocal.dropBlocks) ~= 0) and (IsStringEqual(player.id, GetLocalPlayerId()))
--         if isToRestoreBlocks then
--             player.dropBlocks = playerLocal.dropBlocks
--         else
--             --对于用了远端的数据,也要保留本地数据
--             for key, block in pairs(player.dropBlocks) do
--                 local blockLocal = playerLocal.dropBlocks[block.id]
--                 if blockLocal ~= nil then
--                     block.localData = blockLocal.localData
--                     --posTab永远用本地的,因为包含高度数据
--                     block.posTab = blockLocal.posTab
--                     -- --本人的方块用本地数据
--                     -- if IsBlockPlayerSelf(block) then
--                     --     block.curColumn = blockLocal.curColumn
--                     --     block.curRow = blockLocal.curRow
--                     -- end
--                 end
--             end
--         end
--     end
--     tetrisMatchsLocal[action.match.id] = matchRemote
-- end

function GetTetrisBlockByBlock(block, matchs)
    local match = matchs[block.matchId]
    if match ~= nil then
        return match.players[block.playerId].dropBlocks[block.id]
    end
    return nil
end

function GetTetrisLocalBlock(block)
    return GetTetrisBlockByBlock(block, tetrisMatchsLocal)
end

function NewTetrisBlockEntity(action)
    SyncTetrisMatchDataNewBlock(action)
    InitTetrisBlockEntity(GetTetrisLocalBlock(action.block), action.match)
end

function GetTetrisBoardRowNum(board)
    return board.rowNum
end

function GetTetrisBoardColNum(board)
    return board.colNum
end

---方块实体化
function InitTetrisBlockEntity(block, match)
    print("InitTetrisBlockEntitystart ", block.objId)
    local blockCenterPosTab = GetTetrisBlockCenterPosTab(block)
    -- local posSrc = posOrg + Engine.Vector(-300, 0, 1300)
    --原点创建父节点
    local awCallback = function (awId)
        block.localData.awId = awId
        local obj = AddNewObj(0, typeObjs.tetrisBlock, block.objId, 0.01, UpdateTetrisDropBlock, 9999, CommonDestroy)
        obj.block = block
        local partIdx = 0
        --棋盘行高加2
        for rowIdx, row in ipairs(block.blockParts) do
            for colIdx, val in ipairs(row) do
                if val ~= 0 then
                    --从中心点开始
                    partIdx = partIdx + 1
                    local bpos = VectorTablePlus(block.posTab, (colIdx - 0.5)* cfgTetris.blockSize, 0, (rowIdx - 1) * cfgTetris.blockSize)
                    AddPartEntityToTetrisBlock(block, partIdx, awId, VectorFromTable(bpos))
                end
            end
        end
    end
    CopyElementAndChildrenFull(elesInScene.airwall, cfgCopyProps, awCallback, false,
        VectorFromTable(blockCenterPosTab), false, nil,
        cfgElements.airWall.size, 100, 100, 100, nil)
    -- CopyElementAndChildrenServerEzScale(elesInScene.airwall, cfgCopyProps, awCallback, VectorFromTable(blockCenterPosTab), cfgElements.airWall.size, 100, 100, 100, nil)
end

---给方块创建四个部件
function AddPartEntityToTetrisBlock(block, partIdx, awId, bpos)
    local callback = function (eid)
        Element:BindingToElement(eid, awId)
        if partIdx == 4 then
            -- PushActionToClients(true, "SyncMoveTetrisDropBlock", block)
            SyncMoveTetrisDropBlock(block)
            block.localData.entityReady = true
        end
    end
    -- CopyElementAndChildrenServerEzScale(elesInScene.cube, cfgCopyProps, callback, bpos, cfgElements.cube.size,
    --     cfgTetris.blockSize, cfgTetris.blockSize, cfgTetris.blockSize, nil)
    CopyElementAndChildrenFull(elesInScene.cube, cfgCopyProps, callback, false,
        bpos, false, nil,
        cfgElements.cube.size, cfgTetris.blockSize, cfgTetris.blockSize, cfgTetris.blockSize, nil)        
end

---开始下落
function SyncMoveTetrisDropBlock(block)
    -- AddMotionToElement(block.awId, "drop", CfgTools.MotionUnit.Types.Pos, Engine.Vector(0,0, -1 * tetrisPlayerData.dropSpeed), false, 0, 999, 0, 0, 0, false)
    local id = string.format("%s-%s", block.localData.awId, "drop")
    local motionObj = {block=block}
    local param = NewMotionParam(id, id, ObjGroups.MotionUnit, 0, motionObj, UpdateMotionUnit, DestroyMotionUnit,
        999, 0, 0, 0, 0, nil, TetrisBlockDropMotionUpdate)
    local obj = BuildMotionObj(param)
end

function GetMatchLocalByBlock(block)
    return tetrisMatchsLocal[block.matchId]
end

function TetrisBlockDropMotionUpdate(obj, state, deltaTime)
    local block = GetTetrisLocalBlock(obj.motionObj.block)
    local match = GetMatchLocalByBlock(block)
    if block.solidet then
        return
    end
    -- print("TetrisBlockDropMotionUpdate block ", MiscService:Table2JsonStr(block))
    local x = GetTetrisBlockPosX(block, match.board.boardPosTab)
    local z = (block.posTab.z - block.dropSpeed * deltaTime)
    --todo 999
    if true or state.totalDelta < 18 then
        block.posTab =  NewVectorTable(x, block.posTab.y, z)
    end
    SyncTetrisBlockEntityStateWithData(block)
end

function GetTetrisBlockCenterPosTab(block)
    local rowNum = #block.blockParts
    local colNum = #block.blockParts[1]
    return VectorTablePlus(block.posTab, colNum/2 * cfgTetris.blockSize, 0, rowNum/2 * cfgTetris.blockSize)
end

function GetTetrisBlockEntityPosTab(block)
    local blockCenterPosTab = GetTetrisBlockCenterPosTab(block)
    return VectorTablePlus(blockCenterPosTab, -1 * block.blockCfg.entityDiffCol * cfgTetris.blockSize, 0, -1 * block.blockCfg.entityDiffRow * cfgTetris.blockSize)
    -- return blockCenterPosTab
end

--把方块数据同步到外观
function SyncTetrisBlockEntityStateWithData(block)
    Element:SetPosition(block.localData.awId, VectorFromTable(GetTetrisBlockEntityPosTab(block)), Element.COORDINATE.World)
    Element:SetRotation(block.localData.awId, VectorFromTable(block.blockCfg.rotate), Element.COORDINATE.World)
end

function TestRotateBlock()
    local block = GetActiveDropBlock(tetrisPlayerData)
    if block == nil then
        return
    end
    if block.testId ~= nil then
        block.testRot = block.testRot + 90
        if block.testRot == 360 then
            block.testRot = 0
        end
        print("TestRotateBlock ", block.testRotrot)
        Element:SetRotation(block.testId, Engine.Vector(block.testRot, block.blockCfg.rotate.y, block.blockCfg.rotate.z), "WorldCoordinate")
        return
    end
    local callback = function (eid)
        block.testId = eid
        block.testRot = block.blockCfg.rotate.x
    end
    CopyElementAndChildrenServerEz(block.awId, cfgCopyProps, callback, 
    Element:GetPosition(block.awId) + Engine.Vector(cfgTetris.blockSize * 4, 0, 0))
end

function UpdateTetrisDropBlock(deltaTime, obj)
    local block = GetTetrisLocalBlock(obj.block)
    if block == nil or block.solidet == true then
        InactiveObj(obj)
        return
    end
    if block.localData.entityReady == nil then
        return
    end
    CheckTetrisBlockState(block, obj)
end

---todo
function CheckTetrisBlockState(block, obj)
    -- print("CheckTetrisBlockState block ", MiscService:Table2JsonStr(block))
    local match = GetMatchLocalByBlock(block)
    local board = match.board
    block.curRow = (block.posTab.z - board.boardPosTab.z) / cfgTetris.blockSize
    UI:SetText({102139}, MiscService:Table2JsonStr({block.curRow}))
    if block.curRow < -8 then
        block.active = false
        ServerLog("CheckTetrisBlockState CommonDestroy ", obj.id)
        CommonDestroy(0, obj)
        return
    end
    if IsBlockPlayerSelf(block) then
        CheckTetrisBlockMerge(match, block, obj, false)
    end
end

---是否重叠,不重叠返回true
function CheckTetrisBlockMerge(match, block, obj, isTest)
    -- print("CheckTetrisBlockMerge ", MiscService:Table2JsonStr(block))
    -- print("CheckTetrisBlockMerge board ", MiscService:Table2JsonStr(board))
    local board = match.board
    local blockColumn = block.curColumn
    local blockRowCur = math.floor(block.curRow)
    --检查是否开始下落了,因为刚生成时位置可能在棋盘底部
    if blockRowCur > board.rowNum then
        block.dropInited = true
    end
    if block.dropInited == false then
        return false
    end
    --用于检查的行数,当接近下一行时允许提前计算下落到下一行的状态
    local blockRow = blockRowCur
    if block.curRow - blockRowCur < (1.0 / 29) then
        blockRow = (blockRowCur - 1)
    end
    local blockParts = block.blockParts
    local colNum = #blockParts[1]
    local rowNum = #blockParts
    -- print("CheckTetrisBlockMerge blockRowCur ", blockRowCur)
    --是否会重叠
    local isOverlap = false
    if blockRow < 1 then
        isOverlap = true
    end
    for col = 1, colNum do
        for row = 1, rowNum do
            if isOverlap == false then
                local boardRow = board.parts[row + blockRow]
                if boardRow ~= nil then
                    local boardVal = boardRow[col + blockColumn]
                    if boardVal ~= nil and boardVal ~=0 and blockParts[row][col] ~= 0 then
                        isOverlap = true
                    end
                end
            end
        end
    end
    if isTest then
        return (not isOverlap)
    end
    if isOverlap == false then
        return true
    end
    local mergeRow = (blockRow + 1)
    block.mergeRow = mergeRow
    -- tetrisMatchsLocal[block.matchId].players[block.playerId].dropBlocks[block.id] = nil
    SolidifyTetrisBlock(block, mergeRow, blockColumn, board)
    --如果重叠进行合并, 合并到上一行的位置
    SendTetrisActionToDataSide(NewTetrisAction(match, nil, block, "MergeTetrisBlockData"))
end

function RemoveTetrisBlockData(block)
    tetrisMatchs[block.matchId].players[block.playerId].dropBlocks[block.id] = nil
end

function MergeTetrisBlockData(action)
    action.genId = GetIdFromPoolStringfy("MergeTetrisBlockData", 0, 1, 5, nil)
    action.genTs = GetGameTimeCur()
    varPool.mergeActions[action.genId] = action
end

--检查队列
function MergeTetrisBlockDataTask()
    local actionRes = nil
    for key, action in pairs(varPool.mergeActions) do
        if action.inAction == nil then
            if actionRes == nil or action.genTs < actionRes.genTs then
                actionRes = action
            end
        end
    end
    if actionRes ~= nil then
        actionRes.inAction = true
        varPool.mergeActions[actionRes.genId] = nil
        MergeTetrisBlockDataHandle(actionRes)
    end
end

function MergeTetrisBlockDataHandle(action)
    local block = action.block
    local mergeRow = block.mergeRow
    local blockParts = block.blockParts
    local colNum = #blockParts[1]
    local rowNum = #blockParts
    local match = tetrisMatchs[block.matchId]
    local board = match.board
    local blockColumn = block.curColumn
    
    RemoveTetrisBlockData(block)
    ServerLog("isOverlap mergeRow ", mergeRow, " ", blockColumn)
    for i = 1, rowNum do
        for j = 1, colNum do
            if blockParts[i][j] ~= 0 then
                local boardRow = mergeRow + i
                if boardRow > #board.parts then
                    print("mergeRow too high, probably to fail")
                    return false
                end
                board.parts[boardRow][j + blockColumn] = 1
            end
        end
    end
    --重新计算棋盘每一列的最高行
    for col = 1, #board.parts[1] do
        local found = false
        for row = #board.parts, 1, -1 do
            if found == false and board.parts[row][col] ~= 0 then
                found = true
                board.columnHeights[col] = row
            end
        end
    end
    SendSyncTetrisMatchDataToPlayers("SyncTetrisMatchDataUpdateMatchNoPlayerData", match, nil, false)
    SendTetrisActionToMatchPlayers(NewTetrisAction(match, nil, block, "SolidifyTetrisBlockAction"))
end

function SolidifyTetrisBlockAction(action)
    local match = GetMatchLocalByBlock(action.block)
    local block = GetTetrisLocalBlock(action.block)
    if block ~= nil then
        SolidifyTetrisBlock(block, action.block.mergeRow, action.block.curColumn, match.board)
    end
end

--固化方块
function SolidifyTetrisBlock(block, row, column, board)
    tetrisMatchsLocal[block.matchId].players[block.playerId].dropBlocks[block.id] = nil
    RemoveMotionByEidAndName(block.localData.awId, "drop")
    block.solidet = true
    block.curRow = row
    block.curColumn = column
    local posTabSrc = board.boardPosTab
    block.posTab = NewVectorTable(GetTetrisBlockPosX(block, posTabSrc), posTabSrc.y, posTabSrc.z + block.curRow * cfgTetris.blockSize)
    SyncTetrisBlockEntityStateWithData(block)
end

--设置curColumn,保证不会方块不会超出棋盘
function GetTetrisBlockColumnNotOverBoard(block, diffDesire, match)
    --找出最左和最右的可用值
    local minCol = (1 - block.blockCfg.colStart + 1)
    local maxCol = (match.board.colNum - block.blockCfg.colEnd + 1)
    local col = block.curColumn + diffDesire
    if col > maxCol then
        col = maxCol
    end
    if col < minCol then
        col = minCol
    end
    block.curColumn = col
    return col
end

function ControlActionTetrisDropBlock(isRotate, isMoveLeft)
    local block = GetTetrisControlBlock()
    if block == nil then
        return
    end
    local match = GetMatchLocalByBlock(block)
    local testBlock = CopyTableByJson(block)
    if isRotate then
        SetTetrisBlockCfg(testBlock, testBlock.blockCfg.type, testBlock.blockCfg.nextMorph)
    end
    local colDiff = 0
    if isRotate == false then
        if isMoveLeft then
            colDiff = -1
        else
            colDiff = 1
        end
    end
    GetTetrisBlockColumnNotOverBoard(testBlock, colDiff, match)
    -- print("ControlActionTetrisDropBlock ", MiscService:Table2JsonStr(testBlock))
    local notOverlap = CheckTetrisBlockMerge(match, testBlock, nil, true)
    if notOverlap == true then
        block.blockParts = testBlock.blockParts
        block.blockCfg = testBlock.blockCfg
        block.curColumn = testBlock.curColumn
        SendSyncTetrisMatchDataToPlayers("SyncTetrisMatchDataUpdateBlock", match, block, true)
    end
end

function StartTetrisMatchAll()
    StartTetrisMatch(players)
end

--开始一场对局
function StartTetrisMatch(players)
    ServerLog("StartTetrisMatch start")
    local id = GetIdFromPoolStringfy("tetrisMatchId", cfgTetris.matchIdStart, 1, 10, nil)
    local boardPosTab=VectorToTable(VectorPlus(posOrg, 0, 0, 0))
    local match = {id=id, players={}, dropSpeed=100, boardPosTab=boardPosTab, active=true}
    tetrisMatchsServer[id] = match
    for index, player in pairs(players) do
        match.players[player.id] = {id=player.id, dropBlocks={}}
    end
    --通知数据端生成棋盘
    ServerLog("StartTetrisMatch done ", id)
    local action = NewTetrisAction(CopyTableByJson(match), nil, nil, "NewTetrisMatchData")
    SendTetrisActionToDataSide(action)
end

function NewTetrisMatchData(action)
    local match = action.match
    tetrisMatchs[match.id] = match
    local board = {parts={}, columnHeights={}, matchId=match.id, boardPosTab=match.boardPosTab}
    InitTetrisBoard(board, cfgTetris.board.rowNum, cfgTetris.board.colNum)
    match.board = board
    SendSyncTetrisMatchDataToPlayers("SyncTetrisMatchDataNewMatch", match, nil, false)
    local newAction = NewTetrisAction(match, nil, nil, "InitTetrisBoardEntity")
    print("SendTetrisActionToMatchPlayers newAction ", newAction.funcName)
    SendTetrisActionToMatchPlayers(newAction)
end

function InitTetrisBoardEntity(action)
    local callback = function ()
    end
    local posTab = VectorTablePlus(action.match.board.boardPosTab, cfgTetris.blockSize + cfgTetris.blockSize * cfgTetris.board.colNum / 2, 0, 0)
    -- CopyElementAndChildrenServerEzScale(elesInScene.frameBoard, cfgCopyProps, callback, VectorFromTable(posTab),
    -- cfgElements.cube.size, cfgTetris.blockSize * cfgTetris.board.colNum, cfgTetris.blockSize, cfgTetris.blockSize * cfgTetris.board.rowNum, nil)
    CopyElementAndChildrenFull(elesInScene.frameBoard, cfgCopyProps, callback, false,
        VectorFromTable(posTab), false, nil,
        cfgElements.cube.size, cfgTetris.blockSize * cfgTetris.board.colNum, cfgTetris.blockSize, cfgTetris.blockSize * cfgTetris.board.rowNum, nil)
end

function SendTetrisActionToMatchPlayers(action)
    SendTetrisActionToPlayers(action, action.match.players)
end

function NewTetrisAction(match, player, block, funcName)
    local action = {match=match, player=player, block=block, funcName=funcName}
    return action
end


function IsTetrisMatchSinglePlayer(match)
    return GetTablePairLen(match.players) == 1
end


function SendTetrisActionToPlayers(action, players)
    for key, player in pairs(players) do
        SendTetrisActionToSinglePlayer(action, player.id)
    end
end

function SendTetrisActionToSinglePlayer(action, playerId)
    ServerLog("SendTetrisActionToSinglePlayer ", action.funcName, " ", playerId, " ", GetLocalPlayerId())
    if IsStringEqual(playerId, GetLocalPlayerId()) then
        TetrisAction({action=action})
    else
        PushActionToPlayer(false, "TetrisAction", {action=action}, UMath:StringToNumber(playerId))
    end
end

function TetrisAction(actionObj)
    local action = actionObj.action
    ServerLog("TetrisActionAct ", MiscService:Table2JsonStr(actionObj))
    _G[action.funcName](action)
end

function SendTetrisActionToAll(match, action)
    PushActionToClients()
end

--发往数据端
function SendTetrisActionToDataSide(action)
    ServerLog("SendTetrisActionToDataSide ", MiscService:Table2JsonStr(action))
    local dataPlayerId = GetTetrisMatchDataSidePlayerId(action.match)
    SendTetrisActionToSinglePlayer(action, dataPlayerId)
end


--获取数据端的玩家id。 -1表示服务端
function GetTetrisMatchDataSidePlayerId(match)
    if true then
        return -1
    end
    if System:IsStandalone() then
        return -1
    end
    --单人模式
    if IsTetrisMatchSinglePlayer(match) then
        for key, player in pairs(match.players) do
            return player.id
        end
    end
    return -1
end


function UpdateBossSync(msg)
    local cid = msg.obj.id
    if msg.action == "attack" then
        PlayThenStopAnim(1, Animation.PLAYER_TYPE.Creature, cid, "SpearStartAttack", Animation.PART_NAME.FullBody, 1.7, 0.2)
        PlayThenStopAnim(2, Animation.PLAYER_TYPE.Creature, cid, "SpearAttack", Animation.PART_NAME.FullBody, 2.7, 0.2)
        -- local player = Character:GetLocalPlayerId()
        -- Character:GrabTarget(player, cid)
    elseif msg.action == "move" then
        PlayThenStopAnim(0, Animation.PLAYER_TYPE.Creature, cid, "SitIdle", Animation.PART_NAME.FullBody, 4, 0.2)
        -- Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "SitIdle", Animation.PART_NAME.FullBody)
    end
end

function SyncMoveBlock(msg)
    -- Element:SetReplicates(msg.id, false)
    local eid = msg.obj.id;
    print("SyncMoveBlock ", msg.pos.x)
    -- Element:SetPosition(eid, VectorFromTable(msg.pos), Element.COORDINATE.World)
    -- TimerManager:AddTimer(1, function ()
    -- end)
    if msg.obj.wm then
        Element:LinearMotion(eid, Engine.Vector(-1, 0, 0), 500, 0, 500, 999)
    end
    -- local pos = Element:GetPosition(msg.id)
    -- Element:MoveTo(msg.id, pos + Engine.Vector(-2000, 0, 0), 2, Element.CURVE.linear, nil)
end

function StartMoveBlock(obj, state)
    local bid = obj.id
    print("UpdateBlock toMove")
        
    if obj.wm then
        
    end
    -- SetElementReplicatesAndChildren(bid, false)
    local pos = VectorToTable(Element:GetPosition(bid))
    PushActionToClients(true, "SyncMoveBlock", {pos = pos, obj=obj})
    -- Element:EnableMotionUnitByIndex(bid, 1, true)
    -- PushActionToClients(true, "SyncUpdateBlockPos", {eid=bid})
    -- PushActionToClients(true, "SyncStartUpdateBlockTimer", {eid=bid})
end

function UpdateBlock(deltaTime, obj)
    local bid = obj.id
    -- if not CheckObjPosSynced(bid) then
    --     return
    -- end

    -- Element:SetPosition(bid, Element:GetPosition(bid) + Engine.Vector(-500 * GetUpdateDeltaTime(), 0, 0), Element.COORDINATE.World)
end


function SyncStartUpdateBlockTimer(msg)
    AddTimerTask(TaskNames.taskFrame, "SyncUpdateBlockPos", 0, 0, SyncUpdateBlockPos)
end

function SyncUpdateBlockPos(msg)
    local bid = msg.eid
    Element:SetPosition(bid, Element:GetPosition(bid) + Engine.Vector(-500 * GetUpdateDeltaTime(), 0, 0), Element.COORDINATE.World)
end


function StartMoveBoss(obj, state)
    if state.dir == nil then
        state.dir = false
    end
    state.dir = (not state.dir)
    local diff = -300
    if state.dir then
        diff = (-1 * diff)
    end
    PushActionToClients(true, "UpdateBossSync", {action="move", obj=obj})
    
    Creature:SetTargetPointMove(cid, posOrg + Engine.Vector(diff, 0, 200), 1)
end

function StartAttackBoss(obj, state)
    -- TimerManager:AddTimer(1, function ()
    --     Animation:PlayAnim(Animation.PLAYER_TYPE.Creature, cid, "CommonFallBackLoop", Animation.PART_NAME.FullBody)
    -- end)
    PushActionToClients(true, "UpdateBossSync", {action="attack", obj=obj})
end

function UpdateBoss(deltaTime, obj)
    -- print("UpdateBoss ", MiscService:Table2JsonStr(obj))
    local cid = obj.id
end

function PostGenBoss(msg)
    print("PostGenBoss")
    local cid = msg.cid
end

function GenBoss()
    local pos = posOrg + Engine.Vector(500,0,1000)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001034000, GenBossAfterPlatform, pos, Engine.Rotator(0,0,0), Engine.Vector(20,5,1), true)
    Element:SpawnElement(Element.SPAWN_SOURCE.Scene, 251, function ()
        
    end, pos, Engine.Rotator(0,0,0), Engine.Vector(1,1,1), true)
end

function DestroyBoss(deltaTime, obj)
    -- 投掷物
    Element:Destroy(obj.bindEid)
    -- 角色
    Creature:Destroy(obj.id)
    -- 平台
    Element:Destroy(obj.pid)
    
end

function DestroyBlock(deltaTime, obj)
    -- print("DestroyBlock start")
    DestroyElementAndChildren(obj.id)
end

function BindSpearToBoss(msg)
    Element:BindingToCharacterOrNPC(msg.eid, msg.cid, Character.SOCKET_NAME.Prop_R, Character.SOCKET_MODE.SnapToTarget)
end

function GenBossAfterPlatform(pid)
    local pos = Element:GetPosition(pid)
    local cid = Creature:SpawnCreature(1114000000000002, pos + Engine.Vector(0, 0, 200), Engine.Vector(0,0,0), 1)
    local obj = AddNewObj(0, typeObjs.boss, cid, 1, UpdateBoss, 29, DestroyBoss)
    obj.pid = pid

    AddObjState(obj, "move.toMove")
    SetObjState(obj, "move.toMove", 0, 5)
    AddObjState(obj, "move.toAttack")
    SetObjState(obj, "move.toAttack", 0, 5)
    SetObjStateNextCycle(obj, "move.toMove", "move", "toAttack")
    SetObjStateNextCycle(obj, "move.toAttack", "move", "toMove")
    SetObjStateFunc(obj, "move.toMove", nil, nil, StartMoveBoss, nil, nil)
    SetObjStateFunc(obj, "move.toAttack", nil, nil, StartAttackBoss, nil, nil)
    StartObjStateByName(obj, "move", "toMove")

    print("GenBoss after ", MiscService:Table2JsonStr(obj))

    local callback = function (eid)
        local state = BuildElementState(eid)
        obj.bindEid = eid
        SetElementStatePhy(state, false, false, false)
        SetElementStateColli(state, false)
        PushActionToClients(true, "SyncElementState", state)
        PushActionToClients(true, "BindSpearToBoss", {eid=eid, cid=cid})
    end

    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001034000, callback, pos, Engine.Rotator(0,0,0), Engine.Vector(1,1,1), true)

    -- TimerManager:AddTimer(3,function ()
    --     CheckAllObjStates(0.1)
    -- end)
    
    -- TimerManager:AddTimer(2,function ()
    --     -- Creature:SetCreatureGravityInfluence(cid, false)
    --     Creature:SetPosition(cid, Creature:GetPosition(cid))
    --     -- UpdateAllObjStates(GetUpdateDeltaTime())
    -- end)
    
    -- PushActionToClients(true, "PostGenBoss", {cid = cid})
end

function BuildBlockState(elementId, color1)
    local state = BuildElementState(elementId)
    SetElementStateColor(state, 1, color1)
    SetElementStatePhy(state, true, true, true)
    SetElementStateColli(state, true)
    SetElementStateMass(state, 20)
    -- print("BuildBlockState ", MiscService:Table2JsonStr(state))
    return state
end

function GenAirWall(callback)
    -- local genPos = posFarthest
    local genPos = posOrg
    local awCallback = function (awId)
        callback(awId)
    end

    -- SetElementReplicatesAndChildren(337, false)
    -- 337  331
    CopyElementAndChildrenFull(331, cfgCopyProps, awCallback, true, genPos,
    false, nil, cfgElements.airWall.size,
    198, 198, 100, nil)

    
    -- CopyElementAndChildrenFull(341, cfgCopyProps, function ()
    -- end, true, genPos,
    -- false, true, cfgElements.airWall.size,
    -- 100, 100, 500, nil)
end

--缩放元件位置由于需要同步,如果在同步之前绑定则会出问题,所以组装元件需要关闭同步,组装完成后再打开
function GenBrickDebris(pid, locX, locY, done)
    -- local pos = posFarthest + Engine.Vector(locX * 100, 0, locY * 100 + 10)
    local pos = posOrg + Engine.Vector(locX * 100, 0, locY * 100 + 10)
    local callback = function (eid)
        ServerLog("GenBrickDebris ", eid, " ", pid, " ", GetElementPosString(eid), " ", VectorToString(posOrg))
        SetCustomPropBool(eid, "debris", true)
        TimerManager:AddTimer(0, function ()
            Element:BindingToElement(eid, pid)
        end)
        -- Element:BindingToElement(eid, pid)
        -- Element:SetPosition(pid, posOrg + Engine.Vector(0, 0, 300), Element.COORDINATE.World)
        if done then
            TimerManager:AddTimer(8, function ()
                -- Element:SetReplicates(pid, true)
                -- SetElementReplicatesAndChildren(pid, true)
            end)
        end
    end
    -- CopyElementAndChildrenFull(elesInScene.brick, cfgCopyProps, callback, true, pos,
    -- false, nil, cfgElements.cube.size,
    -- 100, 200, 100, nil)

    -- elesInScene.brick 341
    CopyElementAndChildrenFull(elesInScene.brick, cfgCopyProps, callback, true, pos,
    false, nil, cfgElements.cube.size,
    100, 200, 100, nil)

    -- CopyElementAndChildrenFull(341, cfgCopyProps, callback, true, pos,
    -- false, true, cfgElements.cube.size,
    -- 100, 500, 100, nil)
end

--准备砖头类型原型,同步是可以的,因为没有后续缩放调整等
function PrepareBrick()
    local callback = function (eid)
        elesInScene.brick = eid
        InitProtoBrick()
    end
    local pos = posOrg + Engine.Vector(0, 0, 1200)
    -- SpawnElementToScene(1101002001038000, posFarthest, callback, cfgElements.cube.size, 100, 100, 100)
    -- SetElementReplicatesAndChildren(334, false)
    CopyElementAndChildrenFull(334, cfgCopyProps, callback, true, pos,
    false, nil, nil,
    0, 0, 0, nil)
end

--生成砖头
function InitProtoBrick()
    local callback = function (awId)
        protos.blockBrick.id = awId
        -- TimerManager:AddTimer(1, function ()
        --     GenBrickDebris(awId, 0, 0)
        -- end)
        GenBrickDebris(awId, 0, 0, false)
        GenBrickDebris(awId, 0, 1, false)
        GenBrickDebris(awId, 1, 0, false)
        GenBrickDebris(awId, 1, 1, true)
    end
    GenAirWall(callback)
end


function CopyTest()
    --346 353
    local id = 353
    CopyElementAndChildrenServerEz(id, cfgCopyProps, function ()
        
    end, Element:GetPosition(id) + Engine.Vector(0, 900, 0))


    --360
    id=360
    CopyElementAndChildrenServerEz(id, cfgCopyProps, function ()
        
    end, Element:GetPosition(id) + Engine.Vector(0, 900, 0))

    GenBrickTest()
end

function GenBrickTestContinue(pid)
    local pos = posOrg + Engine.Vector(0, 0, 600)
    --生成一个方块
    local cubeCallback = function (eid)
        Element:BindingToElement(eid, pid)
        local cb = function ()
            
        end
        -- Element:SpawnElement(Element.SPAWN_SOURCE.Scene, eid, cb, pos + Engine.Vector(0, 0, 500), Element:GetRotation(eid), Element:GetScale(eid), true)
        CopyElementAndChildrenServerEz(pid, cfgCopyProps, cb, pos + Engine.Vector(0, 0, 700))
    end
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.cube.id, cubeCallback, pos, Engine.Rotator(0,0,0), Engine.Vector(3, 6, 3), true)
end

function GenBrickTest()
    --生成底座
    local pos = posOrg + Engine.Vector(0, 0, 500)
    local callback = function (eid)
        GenBrickTestContinue(eid)
    end
    --331 airwall  356 螺旋
    local id = 353
    -- Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.airWall.id, callback, pos, Engine.Rotator(0,0,0), Engine.Vector(2, 2, 1), true)
    Element:SpawnElement(Element.SPAWN_SOURCE.Scene, id, callback, pos, Element:GetRotation(id) + Engine.Vector(0,0,0), Element:GetScale(id) + Engine.Vector(0,0,0), true)
end

function InitBlockProto()
    
    protos.blockUnknown = {}
    protos.blockUnknownMotion = {}
    protos.blockBrick = {}
    InitProtoBlockUnknown(false)
    InitProtoBlockUnknown(true)
    PrepareBrick()
    -- CopyTest()
    
end

function SyncInit()
    
end

function GenBlock()
    local rd = UMath:GetRandomInt(1,2)
    if rd == 1 then
        GenBlockUnknown(false)
        GenBlockUnknown(true)
    elseif rd == 2 then
        GenBlockBrick()
    end
end

function StartMoveBrick(obj, state)
    local pos = VectorToTable(Element:GetPosition(obj.id))
    PushActionToClients(true, "SyncMoveBrick", {pos = pos, obj=obj})
    -- Element:EnableMotionUnitByIndex(bid, 1, true)
    -- PushActionToClients(true, "SyncUpdateBlockPos", {eid=bid})
    -- PushActionToClients(true, "SyncStartUpdateBlockTimer", {eid=bid})
end

function UpdateBrick(deltaTime, obj)
    local pos = Element:GetPosition(obj.id)
    -- Element:SetPosition(obj.id, pos + Engine.Vector(deltaTime*100, 0, 0), Element.COORDINATE.World)
    -- Element:SetPosition(obj.id, posOrg + Engine.Vector(0, 0, 800), Element.COORDINATE.World)
end

function SyncMoveBrick(msg)
    -- Element:LinearMotion(msg.obj.id, Engine.Vector(-1, 0, 0), 500, 0, 500, 999)
    -- AddMotionToElement(msg.obj.id, "move", CfgTools.MotionUnit.Types.Pos, Engine.Vector(-500,0,0), false, 0, 999, 0, 0, 0, false)
    -- AddMotionToElement(msg.obj.id, "scale", CfgTools.MotionUnit.Types.Scale, Engine.Vector(1,1,1), false, 0, 5, 0, 0.2, 0, true)
    AddMotionToElement(msg.obj.id, "rotate", CfgTools.MotionUnit.Types.Rotate, Engine.Vector(30,0,30), false, 0, 999, 0, 0, 0, true)
end


function GenBlockBrick()
    ServerLog("GenBlockBrick startsss ")
    print("GenBlockBrick start")
    local pos = posOrg + Engine.Vector(0, -200, 550)
    local callback = function (eid)
        local obj = AddNewObj(0, typeObjs.brick, eid, 0, UpdateBrick, 17, CommonDestroy)
        AddObjState(obj, "move.toMove")
        SetObjState(obj, "move.toMove",  90, 0)
        SetObjStateFunc(obj, "move.toMove", nil, nil, StartMoveBrick, nil, nil)
        local children = Element:GetChildElementsFromElement(obj.id)
        obj.bricks = {}
        for index, cid in ipairs(children) do
            if CheckCustomPropBoolHas(cid, "debris") then
                table.insert(obj.bricks, cid)
            end
        end
        StartObjStateByName(obj, "move", "toMove")
    end
    -- CopyElementAndChildrenServerEz(protos.blockBrick.id, cfgCopyProps, callback, pos)
    CopyElementAndChildrenFull(protos.blockBrick.id, cfgCopyProps, callback, true, pos,
    true, false,
    nil, 0, 0, 0, nil)
end

function GenBlockUnknown(withMotion)
    print("GenBlockUnknown start")
    local callback = function (eid)
        print("GenBlockUnknown done", eid)
        
        -- Element:SetPosition(eid, pos, Element.COORDINATE.World)
        local obj = AddNewObj(0, typeObjs.blockUnknown, eid, 0, UpdateBlock, 15, DestroyBlock)
        obj.cid = Element:GetChildElementsFromElement(eid)[1]
        local state = BuildElementState(obj.cid)
        if withMotion then
            obj.wm = false
            SetElementStateColor(state, 1, "#2222FF")
        else
            obj.wm = true
            SetElementStateColor(state, 1, "#FF2222")
        end
        PushActionToClients(true, "SyncElementState", state)

        if withMotion then
            AddObjState(obj, "move.toMove")
            SetObjState(obj, "move.toMove", 90, 0)
            SetObjStateFunc(obj, "move.toMove", nil, nil, StartMoveBlock, nil, nil)
            StartObjStateByName(obj, "move", "toMove")
        else
            PushActionToClients(true, "AddMotionToBlock", obj)
        end
    end
    local pos = posOrg + Engine.Vector(0, -200, 650)
    if withMotion then
        pos = posOrg + Engine.Vector(0, 300, 650)
        CopyElementAndChildrenServerEz(protos.blockUnknown.id, cfgCopyProps, callback, pos)
    else
        CopyElementAndChildrenServerEz(protos.blockUnknownMotion.id, cfgCopyProps, callback, pos)
    end
    
    -- CopyElementAndChildrenServerEz(277, cfgCopyProps, callback)
end

function AddMotionToBlock(obj)
    AddMotionToElement(obj.id, "mutest", CfgTools.MotionUnit.Types.Pos, Engine.Vector(300,0,0), false, 0, 20, 0, 3, 0, true)
end

function InitProtoBlockUnknown(withMotion)
    local genPos = posFarthest
    local awCallback = function (awId)
        -- Element:SetPosition(awId, genPos, Element.COORDINATE.World)
        SetElementScaleDstXyz(awId, cfgElements.airWall.size, 198, 198, 100)
        if withMotion then
            protos.blockUnknown.id = awId
        else
            protos.blockUnknownMotion.id = awId
        end
        local cubeScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 2.0), cfgElements.cube.size)
        local cubeCallback = function (cubeId)
            Element:SetMask(cubeId, 1)
            Element:BindingToElement(cubeId,awId)
            print("InitProtoBlockUnknown done ", awId)
            -- Element:SetPosition(awId,posOrg + Engine.Vector(0,0, 1800), Element.COORDINATE.World)
        end
        Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.cube.id, cubeCallback, genPos + Engine.Vector(0, 0, 10), Engine.Rotator(0,0,0), cubeScale, true)
    end
    -- local awScale = GetScaleDstCalc(Engine.Vector(2.0, 2.0, 1.0), cfgElements.airWall.size)
    -- Element:SpawnElement(Element.SPAWN_SOURCE.Config, cfgElements.airWall.id, awCallback, genPos, Engine.Rotator(0,0,0), awScale, true)
    if withMotion then
        CopyElementAndChildrenServerEz(291, cfgCopyProps, awCallback, genPos)
    else
        CopyElementAndChildrenServerEz(331, cfgCopyProps, awCallback, genPos)
    end
    
    -- CopyElementAndChildrenServerEz(303, cfgCopyProps, awCallback)
end

function GenBlockBall() 
    local callback = function(elementId)
        ServerLog("GenBlock res ", elementId)
        local color = getRandomColorRGBA()
        local state = BuildBlockState(elementId, color)
        PushActionToClients(true, "SyncElementState", state)
        -- System:SendToAllClients(msgIdBlockState, state)
        -- SyncElementState(state)
        Element:DestroyByTime(elementId, 15)

        -- CustomProperty:SetCustomProperty(elementId, "musicVec", CustomProperty.PROPERTY_TYPE.Vector, Engine.Vector(0, trackIdx, noteIdx))
    end
    local pos = Element:GetPosition(platformId)
    Element:SpawnElement(Element.SPAWN_SOURCE.Config, 1101002001037010, callback, pos + Engine.Vector(1500, 0, 1500), Engine.Rotator(0,0,0), Engine.Vector(1, 1, 1), true)
end

function TouchBrick(obj)
    -- local children = Element:GetChildElementsFromElement(obj.id)
    -- for index, cid in ipairs(children) do
    --     if CheckCustomPropBoolHas(cid, "debris") then
    --         -- Element:UnBinding(cid)
    --         ServerLog("SyncTouchBrick SetReplicates ", cid)
    --         -- Element:SetReplicates(cid, false)
    --     end
    -- end
    -- SyncTouchBrick({obj = obj, server = true})

    -- UnbindBricks({obj = obj, server = true})
    -- PushActionToClients(false, "PhyBricks", {obj = obj, server = false})
    -- -- ReplicateBricks({obj = obj, server = true})
    -- TimerManager:AddTimer(0.3, function ()
    --     -- ReplicateBricks({obj = obj, server = true})
    -- end)
    
    -- TimerManager:AddTimer(0.6, function ()
    --     -- PushActionToClients(false, "SyncTouchBrick", {obj = obj, server = false})
    -- end)

    PushActionToClients(true, "SyncTouchBrick", {obj = obj, server = false})
end

function UnbindBricks(param)
    local obj = param.obj
    for index, cid in ipairs(obj.bricks) do
        if param.server then
            Element:UnBinding(cid)
            -- TimerManager:AddTimer(0.3, function ()
            --     ServerLog("SyncTouchBrick SetReplicates ", cid)
            --     Element:SetReplicates(cid, false)
            -- end)
        end
        local state = BuildElementState(cid)
        SetElementStatePhy(state, true, false, false)
        SyncElementState(state)
        Element:DestroyByTime(cid, 3)
    end
    CommonDestroy(0, obj)
end

function ReplicateBricks(param)
    local obj = param.obj
    for index, cid in ipairs(obj.bricks) do
        ServerLog("SyncTouchBrick SetReplicates ", cid)
        Element:SetReplicates(cid, false)
    end
end

function PhyBricks(param)
    local obj = param.obj
    for index, cid in ipairs(obj.bricks) do
        local state = BuildElementState(cid)
        SetElementStatePhy(state, true, false, false)
        SyncElementState(state)
    end
    
end

function SyncTouchBrick(param)
    local obj = param.obj
    for index, cid in ipairs(obj.bricks) do
        Element:UnBinding(cid)
        -- if param.server then
        --     Element:UnBinding(cid)
        --     -- TimerManager:AddTimer(0.3, function ()
        --     --     ServerLog("SyncTouchBrick SetReplicates ", cid)
        --     --     Element:SetReplicates(cid, false)
        --     -- end)
        -- end
        local state = BuildElementState(cid)
        SetElementStatePhy(state, true, false, false)
        -- SetElementStateColli(state, true)
        -- TimerManager:AddTimer(0.2, function ()
        --     Element:AddForce(cid, Engine.Vector(0, 0, -1950))
        -- end)
        TimerManager:AddTimer(0.3, function ()
            Element:SetEnableCollision(cid, false)
            -- Element:ScaleTo(cid, Engine.Vector(0.2, 0.2, 0.2), 0.5, Element.CURVE.linear)
        end)
        SyncElementState(state)
        if CanRunOnlyOnServer() then
            ServerLog("CanRunOnlyOnServer AddForce")
            Element:AddForce(cid, Engine.Vector(0, 0, 950))
        end
        Element:DestroyByTime(cid, 3)
    end
    CommonDestroy(0, obj)
    
end

function CallbackPlayerTouchEle(eid, player)
    print("CallbackPlayerTouchEle ", characterId, " ", eid)
    local obj = GetObject(eid)
    if obj == nil then
        return
    end
    if obj.type == typeObjs.brick then
        TouchBrick(obj)
    end
end

function RegisterEventsServer() 
end

function RegisterEventsAll()
    System:RegisterEvent(Events.ON_CHARACTER_CREATED, CallbackCharCreated)
    System:RegisterEvent(Events.ON_ELEMENT_TOUCH_PLAYER, CallbackPlayerTouchEle)

    System:RegisterEvent(Events.ON_BUTTON_PRESSED, ButtonPressed)
    System:RegisterEvent(Events.ON_PLAYER_ENTER, OnPlayerEnter)
    System:RegisterEvent(Events.ON_PLAYER_LEAVE, OnPlayerLeave)
    System:RegisterEvent(Events.ON_PLAYER_JOIN_MIDWAY, OnPlayerJoinMidway)
end

function OnPlayerEnter(playerId)
    playerId = Stringfy(playerId)
    players[playerId] = {id=playerId}
end

function OnPlayerLeave(playerId)
    playerId = Stringfy(playerId)
    players[playerId] = nil
end

function OnPlayerJoinMidway(playerId, levelId)
    playerId = Stringfy(playerId)
    players[playerId] = {id=playerId}
end

function ButtonPressed(item)
    print("ButtonPressed ", item)
    if item == 102778 then
        ControlActionTetrisDropBlock(true, false)
    elseif item == 103375 then
        ControlActionTetrisDropBlock(false, false)
    elseif item == 103376 then
        ControlActionTetrisDropBlock(false, true)
    elseif item == 104477 then
        TestRotateBlock()      
    end
end