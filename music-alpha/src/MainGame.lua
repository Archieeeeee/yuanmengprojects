require("YmMusicTools")
require("YmTools")

local platformId = 229
local msgIdBlockState = 100115
posOrg = Engine.Vector(0, 0, 0)

local typeObjs = {boss = 1000, blockUnknown=101, brick=103, tetrisBlock=2001, dropEffect=2003}
local cfgAirWallId = 1105000000000074
local cfgElements = {}
local protos = {}
local cfgCopyProps = {"debris", "isPart", "brow", "bcol"}
local cfgDataNames = {"ymAnimes"}
local haohaoyaId = 327
animeDemo = {cur=0, lastName=nil, lastPlay=0, lastCount=0}
ymAnimes = {}
local elesInScene = {airwall=331, cube=381, brick=334, frameBoard=531, cubeGlass=541, cubeBlackWhite=570, boxFramed=561,
     woodBox=560, buyi=559, floorBox=562, dianban=630, boxElec=563, cubeBlackWhiteW=548, towerCeil=608, cyberBox=556,
     woodBoxB=618, cheese=613, effGoldAir=735}
-- local tetrisBoard = {parts={}, columnHeights={}}
cfgTetrisBlock_1_1 = {parts={{1,1,0,0}, {0,1,1,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=1, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_2_1 = {parts={{0,1,1,0}, {1,1,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=2, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_3_1 = {parts={{1,1,1,0}, {0,1,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=3, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_4_1 = {parts={{1,1,1,1}, {0,0,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=4, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_5_1 = {parts={{1,1,0,0}, {1,1,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=5, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_6_1 = {parts={{1,1,1,0}, {1,0,0,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=6, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
cfgTetrisBlock_7_1 = {parts={{1,1,1,0}, {0,0,1,0},  {0,0,0,0}, {0,0,0,0}}, cfg={type=7, morph=1, nextMorph=2, rotate={x=0, y=0, z=90}}}
-- cfgTetrisBlock_1_2 = {parts={{0,0,0,0}, {0,1,0,0}, {1,1,0,0}, {1,0,0,0}}, cfg={type=1, morph=2, nextMorph=1, entityDiffRow=1, entityDiffCol=0, rotate={x=90, y=0, z=90}}}
local cfgTetris = {blockSize=100, dropSpeed=100, board={rowNum=20, colNum=10, posTab={x=150, y=1850, z=4400}}, matchIdStart=0,
    skins={default="default"}, dropSpeedUncontrollable=3000, skinName="cyberBox"}
-- local tetrisPlayerData = {dropSpeed=100, dropBlocks={}, boardPosTab=nil}
local players = {}
--服务端只负责记录
local tetrisMatchsServer = {}
--数据端记录数据
local tetrisMatchs = {}
--从远端同步的数据和自身数据,并不是对局数据集
local tetrisMatchsLocal = {}
local varPool = {mergeActions={}}
local tetrisDataLocal = {blockProtos={itself={}, preview={}}}
local testObj = {id=0, texts={}, delays={}}
local constantTetris = {matchActions={StartTetrisMatchClient="StartTetrisMatchClient", NewTetrisMatchData="NewTetrisMatchData", MergeTetrisBlockResOnClient="MergeTetrisBlockResOnClient"},
    genBlockStratTypes={Seven="Seven", Thirteen="Thirteen", RandomEach="RandomEach"}}
local uiConstants = {skinMenu=104701, skinGrid=104998, skinList=104705, skinItem=105198, skinNameItem=105043}
local blockSkins = {}


function CallbackCharCreated(playerId)
    local pos = Element:GetPosition(platformId)
    Character:SetPosition(playerId, pos + Engine.Vector(0, 0, 500))

    Character:SetAttributeEnabled(playerId, Character.ATTR_ENABLE.CanMove, false)
    Character:SetAttributeEnabled(playerId, Character.ATTR_ENABLE.CanJump, false)
    Character:SetAttributeEnabled(playerId, Character.ATTR_ENABLE.MeshVisibility, false)
end

function ClientInit()
    TimerManager:AddTimer(6, function ()
        InitUI()
    end)
end

function ServerInit()
    RegisterEventsServer()
end

function InitClientOnStart()
    InitMusicClient()
end

function GamePreInitAll()
    RegisterEventsAll()

    -- AddTimerTask(TaskNames.task1s, "GenTetrisDropBlock", 2, 1, GenTetrisDropBlock)
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
    -- TimerManager:AddLoopTimer(6, DoTestQuest)
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
    cfgElements.woodBox = {id=1108006001001028, size=Engine.Vector(1.17,1.17,1.17)}
    cfgElements.floorBox = {id=1102015001001063, size=Engine.Vector(4,4,4)}
    cfgElements.dianban = {id=1108006001001155, size=Engine.Vector(1.53,1.53,0.03)}
    cfgElements.boxElec = {id=1108006001001185, size=Engine.Vector(1.77, 1.77, 1.77)}
    cfgElements.towerCeil = {id=1102015001003956, size=Engine.Vector(0.5, 0.5, 0.47)}
    cfgElements.cyberBox = {id=1101002001002002, size=Engine.Vector(3, 3, 3)}
    cfgElements.woodBoxB = {id=1102015001002498, size=Engine.Vector(2, 2, 1.5)}
    cfgElements.cheese = {id=1102015001002933, size=Engine.Vector(0.99, 0.98, 0.98)}
    cfgElements.effLiquidLight = {id=1102015001001251, size=Engine.Vector(1.2, 1.2, 6)}
    cfgElements.effGoldAir = {id=1102015001003330, size=Engine.Vector(4, 4, 15.01)}
    cfgElements.effAurora = {id=1102004001001001, size=Engine.Vector(3, 10, 5.51)}

    --将大小换算成厘米
    for key, value in pairs(cfgElements) do
        value.size = VectorTableEnsure(VectorScale(value.size, 100))
    end

    blockSkins.floorBox = {name="floorBox", eid=elesInScene.floorBox, orgSize=cfgElements.floorBox.size}
    blockSkins.cyberBox = {name="cyberBox", eid=elesInScene.cyberBox, orgSize=cfgElements.cyberBox.size}
    blockSkins.boxElec = {name="boxElec", eid=elesInScene.boxElec, orgSize=cfgElements.boxElec.size}
    blockSkins.boxFramed = {name="boxFramed", eid=elesInScene.boxFramed, orgSize=cfgElements.cube.size}
    blockSkins.woodBox = {name="woodBox", eid=elesInScene.woodBox, orgSize=cfgElements.woodBox.size}
    blockSkins.woodBoxB = {name="woodBoxB", eid=elesInScene.woodBoxB, orgSize=cfgElements.woodBoxB.size}

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
                if block.active and IsBlockPlayerSelf(block) and block.localData and block.localData.entityReady
                and block.localData.objUpdated and block.localData.controllable then
                    return block
                end
            end
        end
    end
    return nil
end

function GetTetrisDroppingBlocks(matchId)
    local match = tetrisMatchsLocal[matchId]
    local res = {}
    if not match then
        return res
    end
    for key, player in pairs(match.players) do
        for key, block in pairs(player.dropBlocks) do
            if block.active and block.localData and block.localData.entityReady and block.localData.controllable then
                table.insert(res, block)
            end
        end
    end
    return res
end

--数据端合并之后检查是否需要生成新的方块
function CheckAndGenTetrisDropBlockForPlayer(match, playerId)
    local playerData = match.players[playerId]
    local blocks = playerData.dropBlocks
    local res = {}
    -- printEz("CheckAndGenTetrisDropBlockForPlayer", GetTablePairLen(blocks))
    if GetTablePairLen(blocks) >= 5 then
        return res
    end
    res.newBlocks = {matchId=match.id}
    local cfg = {lastBlock=nil, newBlocks={}, playerData=playerData}
    if playerData.lastBlockId then
        cfg.lastBlock = blocks[playerData.lastBlockId]
    end
    GenTetrisDropBlockDataSide(cfg, match, playerId, constantTetris.genBlockStratTypes.Seven, 1)
    EnsureTableValue(res, "newBlocks", "players")[playerId] = cfg.newBlocks
    -- Log:PrintTable(res)
    printEz("CheckAndGenTetrisDropBlockForPlayer done", MiscService:Table2JsonStr(res))
    return res
end

--按组策略生成
function GenTetrisDropBlockDataSide(cfg, match, playerId, genGroup, groupNum)
    for i = 1, groupNum, 1 do
        GenTetrisDropBlockDataSideGroup(cfg, match, playerId, genGroup)
    end
end

--生成单个组
function GenTetrisDropBlockDataSideGroup(cfg, match, playerId, genGroup)
    if genGroup == constantTetris.genBlockStratTypes.Seven then
        cfg.types = {}
        --利用键值对,7种乱序
        for i = 1, 7, 1 do
            table.insert(cfg.types, i)
        end
        tableShuffle(cfg.types)
        printEz("GenTetrisDropBlockDataSideGroup", MiscService:Table2JsonStr(cfg.types))
        for i = 1, 7, 1 do
            local newBlock = GenTetrisDropBlockDataSideSingle(cfg, match, playerId, genGroup, i)
        end
    end
end
--生成组里的单个
function GenTetrisDropBlockDataSideSingle(cfg, match, playerId, genGroup, index)
    local lastBlock = cfg.lastBlock
    local id = nil
    if lastBlock then
        id = lastBlock.nid
    else
        id = GetIdFromPoolStringfy("dropBlockId", 0, 1, 10, nil)
    end
    local nid = GetIdFromPoolStringfy("dropBlockId", 0, 1, 10, nil)
    local blockType = 1
    if genGroup == constantTetris.genBlockStratTypes.Seven then
        blockType = cfg.types[index]
    end
    --t:类型, m:变形, nid:下一个的id, c:列
    local column = math.random(1, cfgTetris.board.colNum / 2)
    local newBlock = {t=blockType, m=1, id=id, nid=nid, c=column}
    cfg.lastBlock = newBlock
    table.insert(cfg.newBlocks, newBlock)
    cfg.playerData.dropBlocks[id] = newBlock
    cfg.playerData.lastBlockId = id
    return newBlock
end

--检查活跃对局
function GenTetrisDropBlock()
    -- ServerLog("GenTetrisDropBlock ", MiscService:Table2JsonStr(tetrisMatchs))
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

function GenSingleTetrisDropBlock(newBlocks, playerId, cfg)
    local block = NewTetrisBlock(cfg.t, cfg.m, cfg.c)
    block.id = cfg.id
    block.nid = cfg.nid
    local match = tetrisMatchsLocal[newBlocks.matchId]
    block.matchId = match.id
    block.playerId = playerId
    block.objId = string.format("tblock-%s-%s-%s", match.id, playerId, block.id)
    -- block.objId = block.id
    printEz("GenSingleTetrisDropBlock ", block.objId)
    block.dropSpeed = match.dropSpeed
    --init postab
    local board = match.board
    local posSrc = VectorFromTable(board.boardPosTab)
    local dropHigh = (GetTetrisBoardRowNum(board) + 2) * cfgTetris.blockSize
    posSrc = VectorPlus(posSrc, 0, 0, dropHigh)
    posSrc.X = GetTetrisBlockPosX(block, board.boardPosTab)
    block.posTabInit = VectorToTable(posSrc)
    block.posTab = CopyTableByJson(block.posTabInit)
    block.localData.mposTab = NewVectorTableCopy(block.posTab)
    block.localData.mrotateTab = NewVectorTableCopy(block.blockCfg.rotate)

    EnsureTableValue(match, "players", playerId, "dropBlocks")[block.id] = block
    
    -- local action = NewTetrisAction(match, player, block, "NewTetrisBlockEntity")
    -- SendTetrisActionToMatchPlayers(action)
    return block
end

--查找长宽用于旋转
function InitTetrisBlockCfg(blockCfg)
    local rowLen = 0
    local colLen = 0
    for row = 1, #blockCfg.parts, 1 do
        for col = 1, #blockCfg.parts[1], 1 do
            if blockCfg.parts[row][col] ~= 0 then
                rowLen = math.max(rowLen, row)
                colLen = math.max(colLen, col)
            end
        end
    end
    blockCfg.cfg.rowLen = rowLen
    blockCfg.cfg.colLen = colLen
end

function InitTetrisData()
    --生成配置变量
    for type = 1, 7, 1 do
        local blockCfg = GetTetrisBlockCfg(type, 1)
        InitTetrisBlockCfg(blockCfg)
        GenTetrisBlockCfgByRotateMulti(blockCfg, 3)
        -- GenTetrisBlockCfgByRotateMulti(blockCfg, 1)
    end
    --初始化方块配置
    for type = 1, 7 do
        for morph = 1, 4 do
            local cfgBlock = GetTetrisBlockCfg(type, morph)
            if cfgBlock ~= nil then
                -- InitTetrisBlockCfgEntityDiff(cfgBlock)
                InitTetrisBlockCfgCol(cfgBlock)
            end
        end
    end
    --生成方块原型
    for key, value in pairs(blockSkins) do
        PrepareTetrisBlockProtos(value)
    end
end

function PrepareTetrisBlockProtos(skin)
    for type = 1, 7, 1 do
        local cfgBlock = GetTetrisBlockCfg(type, 1)
        local posTab = VectorTablePlus(cfgTetris.board.posTab, type * 55 * cfgTetris.blockSize, -500, 0)
        printEz("PrepareTetrisBlockProtos", type, MiscService:Table2JsonStr(cfgTetris.board.posTab))
        printEz("PrepareTetrisBlockProtos vvv", type, MiscService:Table2JsonStr(posTab))
        InitTetrisBlockEntityProto(cfgBlock, skin, posTab)
    end
end

--旋转可接受1或3
function GenTetrisBlockCfgByRotateMulti(blockCfg, num)
    for i = 1, num, 1 do
        blockCfg = GenTetrisBlockCfgByRotate(blockCfg)
    end
    --将最后一个的下一个置为1
    blockCfg.cfg.nextMorph = 1
end


--获取方块组件对应的本地实体化信息,逆时针反推
function GetTetrisBlockPartLocalData(block, partRow, partCol)
    -- local row = partRow + block.blockCfg.entityDiffRow
    -- local col = partCol + block.blockCfg.entityDiffCol
    local row = partRow
    local col = partCol
    local calcRow = row
    local calcCol = col
    if block.blockCfg.morph ~= 1 then
        for i = block.blockCfg.morph, 2, -1 do
            local blockCfgPrevious = GetTetrisBlockCfg(block.blockCfg.type, i - 1)
            local colNum = blockCfgPrevious.cfg.colLen
            col = colNum + 1 - calcRow
            row = calcCol
            -- printEz("GetTetrisBlockPartLocalData morph", i, colNum, calcRow, calcCol, row, col)
            calcCol = col
            calcRow = row
        end
    end
    -- local rowData = block.localData.parts[Stringfy(row + block.blockCfg.entityDiffRow)]
    -- if rowData == nil then
    --     return nil
    -- end
    -- return rowData[Stringfy(col + block.blockCfg.entityDiffCol)]
    printEz("GetTetrisBlockPartLocalData", partRow, partCol, row, col)
    local res = block.localData.parts[Stringfy(row)][Stringfy(col)]
    if not res then
        print("error GetTetrisBlockPartLocalData ")
    end
    print("GetTetrisBlockPartLocalData res ", MiscService:Table2JsonStr(res))
    return res
end

--获取方块组件对应的本地实体化信息,逆时针反推
-- function GetTetrisBlockPartLocalData(block, partRow, partCol)
--     local colNum = #block.blockParts[1]
--     local row = partRow + block.blockCfg.entityDiffRow
--     local col = partCol + block.blockCfg.entityDiffCol
--     local calcRow = row
--     local calcCol = col
--     if block.blockCfg.morph ~= 1 then
--         for i = block.blockCfg.morph, 2, -1 do
--             col = colNum + 1 - calcRow
--             row = calcCol
--             calcCol = col
--             calcRow = row
--         end
--     end
--     -- local rowData = block.localData.parts[Stringfy(row + block.blockCfg.entityDiffRow)]
--     -- if rowData == nil then
--     --     return nil
--     -- end
--     -- return rowData[Stringfy(col + block.blockCfg.entityDiffCol)]
--     printEz("GetTetrisBlockPartLocalData", partRow, partCol, row, col)
--     local res = block.localData.parts[Stringfy(row)][Stringfy(col)]
--     if not res then
--         print("error GetTetrisBlockPartLocalData ")
--     end
--     print("GetTetrisBlockPartLocalData res ", MiscService:Table2JsonStr(res))
--     return res
-- end

--以方块的中心顺时针旋转90度
function GenTetrisBlockCfgByRotate(blockCfg)
    local parts = blockCfg.parts
    local copyCfg = CopyTableByJson(blockCfg)
    copyCfg.cfg.rowLen = blockCfg.cfg.colLen
    copyCfg.cfg.colLen = blockCfg.cfg.rowLen
    local rowNum = blockCfg.cfg.rowLen
    local colNum = blockCfg.cfg.colLen
    --填充0
    for row = 1, #parts do
        for col = 1, #parts[1] do
            copyCfg.parts[row][col] = 0
        end
    end
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
    -- if copyCfg.cfg.rotate.x == (-270) then
    --     copyCfg.cfg.rotate.x = 90
    -- end
    local varName = GetTetrisBlockCfgVarName(copyCfg.cfg.type, copyCfg.cfg.morph)
    _G[varName] = copyCfg
    print("GenTetrisBlockCfgByRotate ", MiscService:Table2JsonStr(copyCfg))
    return copyCfg
end

-- --去除底部空白行和左边空白列,并记录位移数据
-- function InitTetrisBlockCfgEntityDiff(cfgBlock)
--     if cfgBlock.cfg.morph == 1 then
--         return
--     end
--     local rowNum = #cfgBlock.parts
--     local colNum = #cfgBlock.parts[1]
--     local minRow = rowNum
--     local minCol = colNum
--     for row = 1, rowNum do
--         for col = 1, colNum do
--             if cfgBlock.parts[row][col] ~= 0 then
--                 minRow = math.min(row, minRow)
--                 minCol = math.min(col, minCol)
--             end
--         end
--     end
--     minRow = (minRow - 1)
--     minCol = (minCol - 1)
--     cfgBlock.cfg.entityDiffRow = minRow
--     cfgBlock.cfg.entityDiffCol = minCol
--     --重新赋值
--     local copyBlock = CopyTableByJson(cfgBlock)
--     for row = 1, rowNum do
--         for col = 1, colNum do
--             if row + minRow <= rowNum and col + minCol <= colNum then
--                 cfgBlock.parts[row][col] = copyBlock.parts[row + minRow][col + minCol]
--             else
--                 cfgBlock.parts[row][col] = 0
--             end
--         end
--     end
--     print("InitTetrisBlockCfgEntityDiff ", MiscService:Table2JsonStr(cfgBlock))
-- end

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

function NewBoardPartGetInit(isClient)
    if isClient then
        return {v=0, localData={}}
    end
    return {v=0}
end

---初始化单个棋盘
function InitTetrisBoard(board, rowNum, columnNum)
    for i = 1, rowNum do
        local row = {}
        for j = 1, columnNum do
            table.insert(row, NewBoardPartGetInit(false))
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
function NewTetrisBlock(type, morph, column)
    local id = GetIdFromPoolStringfy("dropBlockId", 0, 1, 10, nil)
    local block = {id=id, active=true, dropInited=false, solidet=false, localData={parts={}, preParts={}, controllable=true}}
    SetTetrisBlockCfg(block, type, morph)
    -- block.curColumn = math.floor(cfgTetris.board.colNum / 2)
    block.curColumn = column
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
    return boardPosTab.x + (block.curColumn - 1) * cfgTetris.blockSize
end

--发送同步
function SendSyncTetrisMatchDataToPlayers(syncFuncName, match, block, excludeBlockPlayer)
    local action = nil
    if excludeBlockPlayer then
        action = NewTetrisActionExcludeBlockPlayer(match, nil, block, "SyncTetrisMatchData")
    else
        action = NewTetrisAction(match, nil, block, "SyncTetrisMatchData")
    end
    action.syncFuncName = syncFuncName
    SendTetrisActionToMatchPlayers(action)
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
    --创建localData
    local board = action.match.board
    for index, rowVal in ipairs(board.parts) do
        for index, value in ipairs(rowVal) do
            value.localData = {}
        end
    end
    --创建方块
    GenNewTetrisBlocksLocal(action, true)
end

--更新对局但不包括玩家信息
function SyncTetrisMatchDataUpdateMatchNoPlayerData(action)
    local matchLocal = tetrisMatchsLocal[action.match.id]
    action.match.players = matchLocal.players
    action.match.solidetBlocks = matchLocal.solidetBlocks
    action.match.board = MergeTables(action.match.board, matchLocal.board, {"localData"})
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
    if blockLocal == nil or blockLocal.mergeDone then
        printEz("SyncTetrisMatchDataUpdateBlock blockLocal nil or mergeDone ", action.block.objId)
        return
    end
    print("SyncTetrisMatchDataUpdateBlockblockLocal")
    action.block.localData = blockLocal.localData
    --posTab永远用本地的,因为包含高度数据
    --远端也需要同步
    -- action.block.posTab = blockLocal.posTab

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
    InitTetrisBlockEntity(GetTetrisLocalBlock(action.block), GetMatchLocalByBlock(action.block))
end

function GetTetrisBoardRowNum(board)
    return board.rowNum
end

function GetTetrisBoardColNum(board)
    return board.colNum
end

function GetTetrisBlockPosTab(board, blockRow, blockCol)
    return VectorTablePlus(board.boardPosTab, (blockCol - 1) * cfgTetris.blockSize, 0, (blockRow - 1) * cfgTetris.blockSize)
end

function NewInitTetrisBlockEntityParam()
    return {blockTotalNum=1, doneNum=0, postDone=false}
end

---方块实体化,包括本体实体和预览实体
function InitTetrisBlockEntity(block, match)
    local res = NewInitTetrisBlockEntityParam()
    --先计算需要生成几个
    if IsBlockPlayerSelf(block) then
        --预览加本体
        res.blockTotalNum = 2
    end

    if IsBlockPlayerSelf(block) then
        InitTetrisBlockEntitySingle(block, match, true, res)
    end
    InitTetrisBlockEntitySingle(block, match, false, res)
end

function InitTetrisBlockEntitySingle(block, match, isPreview, res)
    --用于检测实体完成
    local data = tetrisDataLocal.blockProtos.itself
    if isPreview then
        data = tetrisDataLocal.blockProtos.preview
    end
    local prepare = res.prepare
    local skinData = GetBlockSkinData(isPreview, cfgTetris.skinName, block.blockCfg.type)
    local peid = skinData.eid
    local posTab = block.posTab
    if isPreview then
        posTab = CalcTetrisBlockPreviewPos(block, match.board)
    elseif prepare then
        posTab = prepare.posTab
    end
    local blockCenterPosTab = GetTetrisBlockCenterPosTab(block, posTab)
    -- printEz("InitTetrisBlockEntitySingle aaa")
    local awCallback = function (awId)
        res.doneNum = res.doneNum + 1
        if prepare then
            EnsureTableValue(block.localData, "prepare").awId = awId
        else
            if not isPreview then
                block.localData.awId = awId
            else
                block.localData.preAwId = awId
            end

            UpdateTetrisBlockLocalDataParts(block, awId, isPreview)
            if not res.postDone and res.doneNum == res.blockTotalNum then
                -- printEz("InitTetrisBlockEntitySingle AddNewObjADAD aaa", isPreview)
                res.postDone = true
                -- printEz("InitTetrisBlockEntitySingle AddNewObjADAD")
                local obj = AddNewObj(0, typeObjs.tetrisBlock, block.objId, 0.01, UpdateTetrisDropBlock, 9999, CommonDestroy)
                obj.block = block
                SyncMoveTetrisDropBlock(block)
                TimerManager:AddFrame(1, function ()
                    block.localData.entityReady = true
                end)
            end
        end
        
    end
    CopyElementAndChildrenFull(peid, cfgCopyProps, awCallback, false,
        VectorFromTable(blockCenterPosTab), false, nil,
        nil, nil, nil, BuildElementStateEzNoPhyNoColli(0), BuildElementStateEzNoPhyNoColli(0))
end

function UpdateTetrisBlockLocalDataParts(block, awId, isPreview)
    local eids = Element:GetChildElementsFromElement(awId)
    -- printEz("UpdateTetrisBlockLocalDataParts aaa", awId)

    if eids then
        for index, cid in ipairs(eids) do
            if CheckCustomPropBoolHas(cid, "isPart") then
                local row = GetCustomPropNumber(cid, "brow")
                local col = GetCustomPropNumber(cid, "bcol")
                -- printEz("UpdateTetrisBlockLocalDataParts ", isPreview)
                if isPreview then
                    EnsureTableValue(block.localData.preParts, Stringfy(row), Stringfy(col)).eid = cid
                else
                    EnsureTableValue(block.localData.parts, Stringfy(row), Stringfy(col)).eid = cid
                end
            end
        end
    end
end


---方块实体化,包括本体实体和预览实体
function InitTetrisBlockEntityProto(blockCfg, skin, posTab)
    --如果使用空气墙,位置需要偏移
    local cfgItself = {isProto=true, posTab = posTab, skin = skin, isPreview=false, partNum=0, usingAirwall=false, partEid=skin.eid, orgSize = skin.orgSize, size=NewVectorTable(cfgTetris.blockSize, cfgTetris.blockSize, cfgTetris.blockSize)}
    local cfgPreview = {isProto=true, posTab = posTab, skin = skin, isPreview=true, partNum=0, usingAirwall=true, partEid=elesInScene.dianban, orgSize = cfgElements.airWall.size, size=NewVectorTable(cfgTetris.blockSize, cfgTetris.blockSize, cfgTetris.blockSize)}
    CreateTetrisBlockEntitySingle(blockCfg, cfgItself)
    CreateTetrisBlockEntitySingle(blockCfg, cfgPreview)
end

function GetBlockSkinData(isPreview, skinName, type)
    local data = tetrisDataLocal.blockProtos.itself
    if isPreview then
        data = tetrisDataLocal.blockProtos.preview
    end
    local skinData = EnsureTableValue(data, skinName, Stringfy(type))
    return skinData
end

function CreateTetrisBlockEntitySingle(blockCfg, cfg)
    --用于检测实体完成
    local posTab = cfg.posTab
    local blockCenterPosTab = GetTetrisBlockCenterPosTabFull(blockCfg, posTab)
    printEz("InitTetrisBlockEntityProtoSingle", blockCfg.cfg.type, MiscService:Table2JsonStr(blockCenterPosTab))
    
    --原点创建父节点
    local awCallback = function (awId)
        if cfg.isProto then
            local data = tetrisDataLocal.blockProtos.itself
            if cfg.isPreview then
                data = tetrisDataLocal.blockProtos.preview
            end
            local skinData = GetBlockSkinData(cfg.isPreview, cfg.skin.name, blockCfg.cfg.type)
            skinData.eid = awId
        end

        if cfg.callbackFunc then
            cfg.callbackFunc(awId)
        end
        
        --棋盘行高加2
        for rowIdx, row in ipairs(blockCfg.parts) do
            for colIdx, val in ipairs(row) do
                if val ~= 0 then
                    -- local bpos = VectorTablePlus(posTab, (colIdx - 0.5)* cfgTetris.blockSize, 0, (rowIdx - 1) * cfgTetris.blockSize)
                    -- if cfg.usingAirwall then
                    --     bpos = VectorTablePlus(bpos, 0, 0, cfgTetris.blockSize / 2)
                    -- end
                    AddPartEntityToTetrisBlock(blockCfg, cfg, awId, rowIdx, colIdx)
                end
            end
        end
    end
    CopyElementAndChildrenFull(elesInScene.airwall, cfgCopyProps, awCallback, false,
        VectorFromTable(blockCenterPosTab), false, nil,
        cfgElements.airWall.size, Engine.Vector(100, 100, 100),  nil, nil, nil)
end

---给方块创建四个部件 为了方便旋转,将组件绑定到空气墙上,空气墙放在格子中心
function AddPartEntityToTetrisBlock(blockCfg, cfg, awId, row, col)
    printEz("AddPartEntityToTetrisBlock", blockCfg.cfg.type, row, col)
    local awPos = VectorTablePlus(cfg.posTab, (col - 0.5)* cfgTetris.blockSize, 0, (row - 0.5) * cfgTetris.blockSize)
    local callback = function (eid)
        Element:BindingToElement(eid, awId)
        SetCustomPropBool(eid, "isPart", true)
        SetCustomPropNumber(eid, "brow", row)
        SetCustomPropNumber(eid, "bcol", col)
        AddPartEntityToPartParent(blockCfg, cfg, eid, row, col)
    end
    CopyElementAndChildrenFull(elesInScene.airwall, cfgCopyProps, callback, false,
        VectorFromTable(awPos), false, nil,
        cfgElements.airWall.size, NewVectorTable(100, 100, 100), nil, nil, nil)
end

function AddPartEntityToPartParent(blockCfg, cfg, pid, row, col)
    printEz("AddPartEntityToPartParent", blockCfg.cfg.type, row, col)
    local bpos = VectorTablePlus(cfg.posTab, (col - 0.5)* cfgTetris.blockSize, 0, (row - 1) * cfgTetris.blockSize)
    if cfg.usingAirwall then
        bpos = VectorTablePlus(bpos, 0, 0, cfgTetris.blockSize / 2)
    end
    local callback = function (eid)
        Element:BindingToElement(eid, pid)
    end
    CopyElementAndChildrenFull(cfg.partEid, cfgCopyProps, callback, false,
        VectorFromTable(bpos), false, nil,
        cfg.orgSize, cfg.size, nil, nil, nil)
end

---给方块创建四个部件 为了方便旋转,将组件绑定到空气墙上,空气墙放在格子中心
-- function AddPartEntityToTetrisBlockOld(block, cfg, awId, bpos, row, col)
--     local callback = function (eid)
--         Element:BindingToElement(eid, awId)
--         if not isPreview then
--             EnsureTableValue(block.localData.parts, Stringfy(row), Stringfy(col)).eid = eid
--         else
--             EnsureTableValue(block.localData.preParts, Stringfy(row), Stringfy(col)).eid = eid
--         end
--         param.partNum = param.partNum + 1
--         if (res.itself.partNum + res.preview.partNum == res.partTotal) and (not res.done) then
--             res.done = true
--             -- PushActionToClients(true, "SyncMoveTetrisDropBlock", block)
--             SyncMoveTetrisDropBlock(block)
--             TimerManager:AddFrame(1, function ()
--                 block.localData.entityReady = true
--             end)
--         end
--     end
--     -- CopyElementAndChildrenServerEzScale(elesInScene.cube, cfgCopyProps, callback, bpos, cfgElements.cube.size,
--     --     cfgTetris.blockSize, cfgTetris.blockSize, cfgTetris.blockSize, nil)
--     CopyElementAndChildrenFull(param.partEid, cfgCopyProps, callback, false,
--         bpos, false, nil,
--         param.orgSize, param.size.x, param.size.y, param.size.z, nil)        
-- end

---开始下落
function SyncMoveTetrisDropBlock(block)
    -- AddMotionToElement(block.awId, "drop", CfgTools.MotionUnit.Types.Pos, Engine.Vector(0,0, -1 * tetrisPlayerData.dropSpeed), false, 0, 999, 0, 0, 0, false)
    local id = string.format("%s-%s", block.localData.awId, "drop")
    local motionObj = {block=block}
    local param = NewMotionParam(id, id, ObjGroups.MotionUnit, 0, motionObj, UpdateMotionUnit, DestroyMotionUnit,
        999, 0, 0, 0, 0, nil, TetrisBlockDropMotionUpdate, nil)
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
    local dropSpeed = block.dropSpeed
    if not block.localData.controllable then
        dropSpeed = cfgTetris.dropSpeedUncontrollable
    end
    -- print("TetrisBlockDropMotionUpdate block ", MiscService:Table2JsonStr(block))
    local x = GetTetrisBlockPosX(block, match.board.boardPosTab)
    local z = (block.posTab.z - dropSpeed * deltaTime)
    --todo 999
    --检查是否超出了最低行
    -- local curRow = CalcTetrisBlockCurRow(block.posTab, match.board)
    -- local botRow = CalcTetrisBlockBottomRow(block, match.board, curRow)
    -- local botZ = match.board.boardPosTab.z + (botRow - 1) * cfgTetris.blockSize
    -- -xxx
    -- printEz("ControlTetrisBlockToBottombotz", curRow, botRow, MiscService:Table2JsonStr(block.posTab),
    --     MiscService:Table2JsonStr(block.localData.mposTab), botZ, dropSpeed * deltaTime)
    -- if (block.posTab.z - dropSpeed * deltaTime * 2) <= botZ then
    --     ControlTetrisBlockToBottom(block, match, botRow)
    --     return
    -- end
    if true or state.totalDelta < 18 then
        block.posTab = NewVectorTable(x, block.posTab.y, z)
    end
    --通过中间值mposTab缓动
    local speedVec = NewVectorTable(math.max(dropSpeed, 1000), 0, 0)
    local motionObj = {isSyncDstDone=false, objDestroyFunc=nil, eleMotionType=CfgTools.MotionUnit.Types.Pos, dstVec=nil, dstObj=block,
    dstVecName="posTab", curObj=block.localData, curVecName="mposTab", speedVec=speedVec, postUpdateFunc=nil}
    -- MotionUpdatePosTab(deltaTime, block, "posTab", block.localData, "mposTab", math.max(block.dropSpeed, 1000))
    MotionVecUpdate({motionObj=motionObj}, nil, deltaTime)
    MotionUpdateTetrisRotate(block, deltaTime)
    UpdateTetrisBlockPreview(block, match)
    SyncTetrisBlockEntityStateWithData(block, block.localData.mposTab, block.localData.mrotateTab, false)
end

function CalcTetrisBlockPreviewPos(block, board)
    local blockRow = CalcTetrisBlockCurRow(block.posTab, board)
    local botRow = CalcTetrisBlockBottomRow(block, board, blockRow)
    local posTab = GetTetrisBlockPosTab(board, botRow, block.curColumn)
    -- posTab = VectorTablePlus(posTab, 0, -200, 0)
    return posTab
end

function UpdateTetrisBlockPreview(block, match)
    if not IsBlockPlayerSelf(block) then
        return
    end
    local posTab = CalcTetrisBlockPreviewPos(block, match.board)
    SyncTetrisBlockEntityStateWithData(block, posTab, block.blockCfg.rotate, true)
end

function MotionUpdatePosTab(deltaTime, dstPosObj, dstPosVarName, curPosObj, curPosVarName, speed)
    local posTab = dstPosObj[dstPosVarName]
    local mposTab = curPosObj[curPosVarName]
    if IsVectorTableEqual(posTab, mposTab) then
        return
    end
    -- if true then
    --     block.localData.mposTab = posTab
    --     return
    -- end
    -- local speed = 900
    local moveDistance = speed * deltaTime
    local distance = UMath:GetDistance(VectorFromTable(posTab), VectorFromTable(mposTab))
    -- printEz("MotionUpdateTetrisPosTab xx", moveDistance, distance)
    --移动距离超过两者间距
    if moveDistance >= distance then
        -- printEz("MotionUpdateTetrisPosTab no need motion")
        curPosObj[curPosVarName] = NewVectorTableCopy(posTab)
        return
    end
    -- local speed = 50
    -- printEz("MotionUpdateTetrisPosTab", MiscService:Table2JsonStr(posTab), MiscService:Table2JsonStr(mposTab))
    local diffTotal = VectorTableMinus(posTab, mposTab.x, mposTab.y, mposTab.z)
    -- local diff = VectorTableScale(VectorToTable(UMath:GetNormalize(VectorFromTable(diffTotal))), speed * deltaTime)
    local diff = VectorTableScale(diffTotal, moveDistance / distance)
    mposTab = VectorTablePlus(mposTab, diff.x, diff.y, diff.z)
    curPosObj[curPosVarName] = mposTab
end

function MotionUpdateTetrisRotate(block, deltaTime)
    -- 0 -90 -180 -270
    local mrot = block.localData.mrotateTab.x
    local rot = block.blockCfg.rotate.x
    local totalDiff = rot - mrot
    if mrot == rot or (math.abs(totalDiff) % 360) == 0 then
        return
    end
    -- if true then
    --     block.localData.mrotateTab = block.blockCfg.rotate
    --     return
    -- end
    local rotateSpeed = 540
    local moveRot = rotateSpeed * deltaTime
    if moveRot >= math.abs(totalDiff) then
        block.localData.mrotateTab = NewVectorTableCopy(block.blockCfg.rotate)
        if block.localData.mrotateTab.x == -270 then
            printEz("MotionUpdateTetrisRotate reset")
            block.localData.mrotateTab.x = 90
        end
        return
    end
    -- local norm = UMath:GetNormalize(VectorFromTable(totalDiff))
    -- mrot = VectorTablePlusTable(mrot, VectorTableScale(VectorToTable(norm), moveRot))
    local multi = 1
    if totalDiff < 0 then
        multi = -1
    end
    mrot = mrot + (moveRot * multi)
    block.localData.mrotateTab = NewVectorTable(mrot, block.blockCfg.rotate.y, block.blockCfg.rotate.z)
end

-- function GetTetrisBlockCenterPosTabOld(block, posTab)
--     local rowNum = #block.blockParts
--     local colNum = #block.blockParts[1]
--     return VectorTablePlus(posTab, colNum/2 * cfgTetris.blockSize, 0, rowNum/2 * cfgTetris.blockSize)
-- end

function GetTetrisBlockCenterPosTab(block, posTab)
    local rowNum = block.blockCfg.rowLen
    local colNum = block.blockCfg.colLen
    return VectorTablePlus(posTab, colNum/2 * cfgTetris.blockSize, 0, rowNum/2 * cfgTetris.blockSize)
end

function GetTetrisBlockCenterPosTabFull(blockCfg, posTab)
    local rowNum = blockCfg.cfg.rowLen
    local colNum = blockCfg.cfg.colLen
    return VectorTablePlus(posTab, colNum/2 * cfgTetris.blockSize, 0, rowNum/2 * cfgTetris.blockSize)
end

function GetTetrisBlockEntityPosTab(block, posTab)
    local blockCenterPosTab = GetTetrisBlockCenterPosTab(block, posTab)
    -- return VectorTablePlus(blockCenterPosTab, -1 * block.blockCfg.entityDiffCol * cfgTetris.blockSize, 0, -1 * block.blockCfg.entityDiffRow * cfgTetris.blockSize)
    return blockCenterPosTab
end

--把方块数据同步到外观
function SyncTetrisBlockEntityStateWithData(block, posTab, rotateTab, isPreview)
    local eid = block.localData.awId
    if isPreview then
        eid = block.localData.preAwId
    end
    Element:SetPosition(eid, VectorFromTable(GetTetrisBlockEntityPosTab(block, posTab)), Element.COORDINATE.World)
    Element:SetRotation(eid, VectorFromTable(rotateTab), Element.COORDINATE.World)
end

function SetTetrisCameraWatchBoard(match)
    -- if 1 == 1 then
    --     return
    -- end
    
    -- if 1 == 1 then
    --     return
    -- end
    
    local board = match.board
    local useVertical = true
    useVertical = false

    Camera:SetOrthographic(true)
    if useVertical then
        Camera:SetOrthographicWidth(cfgTetris.blockSize * board.rowNum)
    else
        Camera:SetOrthographicWidth(cfgTetris.blockSize * board.rowNum * 2)
    end
    
    
    local posTab = VectorTablePlus(board.boardPosTab, cfgTetris.blockSize * board.colNum / 2, 2000, cfgTetris.blockSize * board.rowNum / 2)
    -- local posTab = VectorTablePlus(board.boardPosTab, cfgTetris.blockSize * board.colNum / 2, 2000, cfgTetris.blockSize * board.rowNum)
    if useVertical then
        -- posTab = VectorTablePlus(posTab, 0, 0, -500)
    end
    Camera:SetPosition(VectorFromTable(posTab))
    Camera:SetCameraFOV(100)
    -- Camera:SetProperty(Camera.PROPERTY.MinPitch, 0)
    -- Camera:SetProperty(Camera.PROPERTY.MaxPitch, 0)
    Camera:SetProperty(Camera.PROPERTY.ArmLength, 1000)
    Camera:LockPitch(0)
    Camera:LockYaw(-90)

    -- SkyBox:SetDirectionalLightIntensity(0)
    -- SkyBox:SetSkylightIntensityScale(1)
    -- SkyBox:SetDirectionalLightPitch(0)
    -- SkyBox:SetDirectionalLightYaw(-90)
    -- SkyBox:SetSkyBoxRotation(90)

    if useVertical then
        Setting:SwitchToVerticalScreen(true)
    end
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
    -- printEz("UpdateTetrisDropBlock aaa")
    local block = GetTetrisLocalBlock(obj.block)
    if block == nil or block.solidet == true then
        InactiveObj(obj)
        return
    end
    if block.localData.entityReady == nil then
        return
    end
    CheckTetrisBlockState(block, obj)
    --标记为执行过
    block.localData.objUpdated = true
end

function CalcTetrisBlockCurRow(blockPosTab, board)
    return (blockPosTab.z - board.boardPosTab.z) / cfgTetris.blockSize
end

---todo
function CheckTetrisBlockState(block, obj)
    -- print("CheckTetrisBlockState block ", MiscService:Table2JsonStr(block))
    local match = GetMatchLocalByBlock(block)
    local board = match.board
    block.curRow = CalcTetrisBlockCurRow(block.posTab, board)
    UI:SetText({102139}, MiscService:Table2JsonStr({block.curRow}))
    if block.curRow < -8 then
        block.active = false
        printEz("CheckTetrisBlockState CommonDestroy ", obj.id)
        CommonDestroy(0, obj)
        return
    end
    --客户端都会检查,但只有本人才会发送合并请求
    -- if IsBlockPlayerSelf(block) then
    -- end
    CheckTetrisBlockMerge(match, block, obj, false)
end

function CheckTetrisBoardIsOverlap(blockRow, blockColumn, board, rowNum, colNum, blockParts)
    -- print("CheckTetrisBoardIsOverlap ", " ", blockRow, " ", blockColumn, " ",
    -- MiscService:Table2JsonStr(board), " ", rowNum, " ", colNum, " ", MiscService:Table2JsonStr(blockParts))
    local isOverlap = false
    if blockRow < 1 then
        isOverlap = true
    end
    for col = 1, colNum do
        for row = 1, rowNum do
            if isOverlap == false then
                local boardRow = board.parts[row + blockRow - 1]
                if boardRow ~= nil then
                    local boardVal = boardRow[col + blockColumn - 1]
                    if boardVal ~= nil and boardVal.v ~=0 and blockParts[row][col] ~= 0 then
                        isOverlap = true
                    end
                end
            end
        end
    end
    return isOverlap
end

---是否重叠,不重叠返回true
function CheckTetrisBlockMerge(match, block, obj, isTest)
    -- print("CheckTetrisBlockMerge ", MiscService:Table2JsonStr(block))
    -- print("CheckTetrisBlockMerge board ", MiscService:Table2JsonStr(board))
    local board = match.board
    local blockColumn = block.curColumn
    local blockRowInt = math.ceil(block.curRow)
    --检查是否开始下落了,因为刚生成时位置可能在棋盘底部
    if blockRowInt > board.rowNum then
        block.dropInited = true
    end
    if block.dropInited == false then
        return false
    end
    --用于检查的行数,当接近下一行时允许提前计算下落到下一行的状态
    local blockRow = blockRowInt
    if 1 - blockRowInt + block.curRow < (1.0 / 29) then
        blockRow = (blockRowInt - 1)
    end
    local blockParts = block.blockParts
    local colNum = #blockParts[1]
    local rowNum = #blockParts
    -- print("CheckTetrisBlockMerge blockRowCur ", blockRowCur)
    --是否会重叠
    local isOverlap = CheckTetrisBoardIsOverlap(blockRow, blockColumn, board, rowNum, colNum, blockParts)
    if isTest then
        return (not isOverlap)
    end
    if isOverlap == false then
        return true
    end
    -- printEz("CheckTetrisBoardIsOverlaptrue need merge", blockRow, blockColumn, MiscService:Table2JsonStr(board))
    local mergeRow = (blockRow + 1)
    block.mergeRow = mergeRow
    SolidifyTetrisBlockSimulateAll(block, mergeRow, blockColumn, match)
end

function SolidifyTetrisBlockSimulateAll(block, mergeRow, blockColumn, match)
    -- tetrisMatchsLocal[block.matchId].players[block.playerId].dropBlocks[block.id] = nil
    SolidifyTetrisBlockSimulate(block, mergeRow, blockColumn, match)
    --如果重叠进行合并, 合并到上一行的位置
    if IsBlockPlayerSelf(block) then
        SendTetrisActionToDataSide(NewTetrisAction(match, nil, block, "MergeTetrisBlockData"))
    end
end

--客户端固化,方块固化但不分解,数据合并到本地
function SolidifyTetrisBlockSimulate(block, mergeRow, blockColumn, match)
    DestroyTetrisBlockPreview(block)
    SolidifyTetrisBlock(block, mergeRow, blockColumn, match.board)
    --合并但不消除
    MergeTetrisBlockToBoard(match, block, true)
end

function DestroyTetrisBlockPreview(block)
    if block.localData.preAwId then
        DestroyElementAndChildren(block.localData.preAwId)
    end
end

function CreateEffectOnTetrisBlock(block, match, botRow)
    -- local effect =  Particle:PlayOnActor(110, block.localData.awId, true, 999)
    -- printEz("CreateEffectOnTetrisBlock", effect)
    -- Particle:SetParticleScale(effect, Engine.Vector(10, 10, 10))
    -- Particle:SetParticleVisible(effect, true)
    -- Particle:SetParticleRotation(effect, Engine.Vector(180, 0, 0))
    -- Particle:SetParticlePosition(effect, Engine.Vector(500, 0, 0))
    local pos = GetTetrisBlockEntityPosTab(block, block.posTab)
    -- local pos = VectorTablePlus(match.board.boardPosTab, 0, 20, cfgTetris.blockSize * match.board.rowNum)
    pos = VectorTablePlus(pos, 0, 300, 0)
    local newPosTab = GetTetrisBlockPosTab(match.board, botRow, block.curColumn)
    local dstPos = GetTetrisBlockEntityPosTab(block, newPosTab)
    -- local dstPos = VectorTablePlus(match.board.boardPosTab, 0, 20, 0)
    -- pos = VectorTablePlus(match.board.boardPosTab, 0, 0, 0)
    local height = cfgTetris.blockSize * (block.blockCfg.rowLen + math.ceil(block.curRow) - botRow)
    local size = NewVectorTable(cfgTetris.blockSize * (block.blockCfg.colLen + 0), cfgTetris.blockSize * 3, height)
    local scale = GetScaleDstCalcXyz(cfgElements.effAurora.size, size.x, size.y, size.z)
    local dstScale = GetScaleDstCalcXyz(cfgElements.effAurora.size, size.x, size.y, 1)
    local effId = Particle:PlayAtPosition(76, VectorFromTable(pos), 1, false, 999)
    Particle:SetParticleRotation(effId, Engine.Vector(0, 0, 0))
    Particle:SetParticleScale(effId, VectorFromTable(scale))
    printEz("CreateEffectOnTetrisBlock", effId)
    local downTime = 0.2
    local scaleTime = 0.2
    local obj = AddNewObj(0, typeObjs.dropEffect, effId, 0.01, nil, downTime + scaleTime + 1, nil)
    local downName = "move.down"
    local scaleName = "move.scale"
    -- obj.effObj = {effId=effId, posTab=pos, speedDown= -1 * size.z / downTime, scale=VectorToTable(scale), speedScale=(dstScale.Z - scale.Z)/scaleTime}
    obj.effObj = {effId = effId, curPos=pos, dstPos=dstPos, curScale=VectorToTable(scale), dstScale=VectorToTable(dstScale)}
    local motionObjDown = BuildMotionObjVecDst(dstPos, nil, nil, obj.effObj, "curPos", downTime, 
    SyncEffectStateTetrisFastDown, SyncEffectStateTetrisFastDown)
    AddObjState(obj, downName)
    SetObjState(obj, downName, downTime, 0, 0)
    SetObjStateFunc(obj, downName, nil, MotionVecStateEnd, nil, nil, MotionVecUpdate)
    SetObjStateMotionObj(obj, downName, motionObjDown)
    -- SetObjStateNextEnd(obj, downName, "move", "scale")

    -- local motionObjScale = BuildMotionObjVecDst(dstScale, nil, nil, obj.effObj, "curScale", scaleTime, 
    -- SyncEffectStateTetrisFastDown, SyncEffectStateTetrisFastDown)
    -- AddObjState(obj, scaleName)
    -- SetObjState(obj, scaleName, scaleTime, 0, 0)
    -- SetObjStateMotionObj(obj, scaleName, motionObjScale)
    -- SetObjStateFunc(obj, scaleName, nil, MotionVecStateEnd, nil, nil, MotionVecUpdate)

    StartObjStateByName(obj, "move", "down")
    -- local callback = function (eid)
    --     printEz("CreateEffectOnTetrisBlock", eid)
    -- end
    -- CopyElementAndChildrenServerEzScale(elesInScene.effGoldAir, cfgCopyProps, callback, VectorFromTable(pos),
    -- cfgElements.effGoldAir.size, scale.X, scale.Y, scale.Z, nil)
end

function SyncEffectStateTetrisFastDown(objParent, state, deltaTime, res)
     local obj = objParent.effObj
    local effId = obj.effId
    -- local motionObj = GetMotionObjFromParent(objParent, state)
    printEz("SyncEffectPosTetrisFastDown", deltaTime, MiscService:Table2JsonStr(state), MiscService:Table2JsonStr(res))
    if state.fullname == "objStates.move.down" then
        Particle:SetParticlePosition(effId, VectorFromTable(VectorTablePlus(obj.curPos, 0, 0, -50)))
        -- Particle:SetParticleColor(effId, 1, "#00000000")
        -- Particle:SetParticleColor(effId, 2, "#00000000")
        -- Particle:SetParticleColor(effId, 3, "#00000000")
        -- Particle:SetParticleColor(effId, 4, "#00000000")
    elseif state.fullname == "objStates.move.scale" then
        -- printEz("UpdateEffectTetrisFastDown", MiscService:Table2JsonStr(state))
        Particle:SetParticleScale(effId, VectorFromTable(obj.curScale))
        
    end
    if res and res.stateEnd then
        -- TimerManager:AddTimer(1, function ()
        --     Particle:StopParticle(effId)
        -- end)
        Particle:StopParticle(effId)
    end
end

function RemoveTetrisBlockData(block, matches)
    matches[block.matchId].players[block.playerId].dropBlocks[block.id] = nil
end

function MergeTetrisBlockData(action)
    action.genId = GetIdFromPoolStringfy("MergeTetrisBlockData", 0, 1, 5, nil)
    action.genTs = GetGameTimeCur()
    varPool.mergeActions[action.genId] = action
end

--检查队列
function MergeTetrisBlockDataTask()
    if varPool.mergeActionsDoing then
        return
    end
    varPool.mergeActionsDoing = true
    --按顺序执行
    local actionsCopy = CopyTableShallow(varPool.mergeActions)
    local vals = {}
    for key, action in pairs(actionsCopy) do
        table.insert(vals, action)
    end
    table.sort(vals, function(a, b)
        return a.genTs < b.genTs
    end)
    for index, action in ipairs(vals) do
        MergeTetrisBlockDataHandle(action)
        varPool.mergeActions[action.genId] = nil
    end
    varPool.mergeActionsDoing = false
end

--客户端模拟合并
function MergeTetrisBlockToBoard(match, block, isClient)
    local mergeRow = block.mergeRow
    local blockParts = block.blockParts
    local colNum = #blockParts[1]
    local rowNum = #blockParts
    local board = match.board
    local blockColumn = block.curColumn
    for i = 1, rowNum do
        for j = 1, colNum do
            if blockParts[i][j] ~= 0 then
                local boardRow = mergeRow + i - 1
                if boardRow > board.rowNum then
                    print("mergeRow too high, probably to fail")
                    return false
                end
                local boardPart = board.parts[boardRow][j + blockColumn - 1]
                boardPart.v = 1
                if not isClient then
                    --xxx
                    -- boardPart.bid = block.objId
                    -- boardPart.bRow = i
                    -- boardPart.bCol = j
                    -- boardPart.morph = block.blockCfg.morph
                end
            end
        end
    end
    --重新计算棋盘每一列的最高行
    CalcTetrisBoardColumnHeights(board)
    return true
end

--这是在数据端执行的
function MergeTetrisBlockDataHandle(action)
    local block = action.block
    local mergeRow = block.mergeRow
    local blockParts = block.blockParts
    local colNum = #blockParts[1]
    local rowNum = #blockParts
    local match = tetrisMatchs[block.matchId]
    local board = match.board
    local blockColumn = block.curColumn
    --先检查是否可合并,不能直接返回
    RemoveTetrisBlockData(block, tetrisMatchs)
    if CheckTetrisBoardIsOverlap(mergeRow, blockColumn, board, rowNum, colNum, blockParts) then
        ServerLog("MergeTetrisBlockDataHandle isoverlap true, cant merge")
        --数据端移除掉落方块
        local resAction = NewTetrisAction(match, nil, block, "MergeTetrisBlockResOnClient")
        resAction.mergeFail = true
        SendTetrisActionToMatchPlayers(resAction)
        return
    end
    
    --移除前检查是否需要生成新的方块
    local genRes = CheckAndGenTetrisDropBlockForPlayer(match, block.playerId)
    --数据端移除掉落方块
    printEz("isOverlap mergeRow ", mergeRow, " ", blockColumn)
    --合并到棋盘
    local mergeRes = MergeTetrisBlockToBoard(match, block, false)
    if not mergeRes then
        MatchFailOnDataSide(match)
        return
    end
    
    --消除前的数据需要传给客户端先合并,记录方块组件的数据
    local boardBeforeDrop = CopyTableShallow(match.board)
    --数据端不需要保留方块数据
    -- PushTetrisSolidetBlock(block, tetrisMatchs)
    --消除检查
    local fullLineRes = CheckTetrisBoardFullLine(match, block)
    -- SendSyncTetrisMatchDataToPlayers("SyncTetrisMatchDataUpdateMatchNoPlayerData", match, nil, false)
    print("MergeTetrisBlockDataHandle server ", MiscService:Table2JsonStr(tetrisMatchs[block.matchId].board))
    local resAction = NewTetrisAction(match, nil, block, "MergeTetrisBlockResOnClient")
    resAction.boardBeforeDrop = boardBeforeDrop
    resAction.fullLineRes = fullLineRes
    
    if genRes.newBlocks then
        resAction.newBlocks = genRes.newBlocks
    end
    SendTetrisActionToMatchPlayers(resAction)
end

function CalcTetrisBoardColumnHeights(board)
    for col = 1, board.colNum do
        local found = false
        board.columnHeights[col] = 0
        for row = board.rowNum, 1, -1 do
            if found == false and board.parts[row][col].v ~= 0 then
                found = true
                board.columnHeights[col] = row
            end
        end
    end
end

--检查行满可消除
function CheckTetrisBoardFullLine(match, block)
    local res = {}
    local fullRows = {}
    --一共消除了几行
    local fullNum = 0
    --记录消除后每一行需要下降几行
    local rowDropNum = {}
    for row, rows in ipairs(match.board.parts) do
        local rowFull = true
        for col, value in ipairs(rows) do
            if rowFull and value.v == 0 then
                rowFull = false
            end
        end
        if rowFull then
            fullNum = fullNum + 1
            fullRows[Stringfy(row)] = {row=row}
        end
        rowDropNum[Stringfy(row)] = fullNum
    end
    -- ServerLog("CheckTetrisBoardFullLine ", MiscService:Table2JsonStr(fullRows), " ",
    --     MiscService:Table2JsonStr(rowDropNum), " ", MiscService:Table2JsonStr(match.board))
    if fullNum == 0 then
        return res
    end
    --将数据返回给客户端使用
    res.fullRows = fullRows
    res.fullNum = fullNum
    res.rowDropNum = rowDropNum
    --重新赋值
    TetrisBoardLineDrop(match, fullRows, fullNum, rowDropNum, false, block)
    CalcTetrisBoardColumnHeights(match.board)
    -- ServerLog("CheckTetrisBoardFullLinedone ", fullNum, " ", MiscService:Table2JsonStr(match.board))
    return res
end

--获取拆解后的组件相对于postab的偏移
function GetTetrisBoardPartDiffSolidet(part)
    local pos = NewVectorTable(cfgTetris.blockSize / 2, 0, 0)
    if part.morph == 1 then
        return pos
    end
    for i = part.morph, 2, -1 do
        pos = NewVectorTable(pos.z, 0, cfgTetris.blockSize - pos.x)
    end
    return pos
end

-- --计算棋盘组件位置
-- function CalcTetrisBoardPartPosOld(board, part, newRowAfterDrop, col)
--     --先计算组件的左下角
--     local pos = NewVectorTable(board.boardPosTab.x + (col - 1) * cfgTetris.blockSize, board.boardPosTab.y, board.boardPosTab.z + (newRowAfterDrop - 1) * cfgTetris.blockSize)
--     local posDiff1 = NewVectorTable(cfgTetris.blockSize / 2, 0, 0)
--     local posDiff2 = GetTetrisBoardPartDiffSolidet(part)
--     local posFinal = VectorTablePlus(pos, posDiff2.x, posDiff2.y, posDiff2.z)
--     -- print("CalcTetrisBoardPartPos ", MiscService:Table2JsonStr(pos), " ", MiscService:Table2JsonStr(posDiff2), " ", MiscService:Table2JsonStr(posFinal))
--     Element:SetPosition(part.localData.eid, VectorFromTable(posFinal), Element.COORDINATE.World)
-- end

--计算棋盘组件位置
function CalcTetrisBoardPartPos(board, part, row, col)
    --先计算组件的左下角
    local pos = NewVectorTable(board.boardPosTab.x + (col - 1) * cfgTetris.blockSize, board.boardPosTab.y, board.boardPosTab.z + (row - 1) * cfgTetris.blockSize)
    local posFinal = VectorTablePlus(pos, cfgTetris.blockSize / 2, 0, cfgTetris.blockSize / 2)
    -- print("CalcTetrisBoardPartPos ", MiscService:Table2JsonStr(pos), " ", MiscService:Table2JsonStr(posDiff2), " ", MiscService:Table2JsonStr(posFinal))
    return posFinal
end

--客户端掉落
function TetrisBoardLineDrop(match, fullRows, fullNum, rowDropNum, isClient, block)
    --重新赋值
    local boardCopy = CopyTableShallow(match.board)
    local dropParts = {}
    --非消除行下移
    for row = 1, match.board.rowNum do
        local toRemove = fullRows[Stringfy(row)] ~= nil
        local newRowAfterDrop = row - rowDropNum[Stringfy(row)]
        --处理数据
        if not toRemove then
            local rowValue = boardCopy.parts[row]
            match.board.parts[newRowAfterDrop] = rowValue
        end
        --处理客户端实体
        if isClient then
            for col = 1, boardCopy.colNum do
                local part = boardCopy.parts[row][col]
                if part.v ~= 0 then
                    local eid = part.localData.eid
                    if not toRemove then
                        --下移动作
                        if newRowAfterDrop ~= row then
                            local oldPos = CalcTetrisBoardPartPos(boardCopy, part, row, col)
                            local newPos = CalcTetrisBoardPartPos(boardCopy, part, newRowAfterDrop, col)
                            table.insert(dropParts, {eid=eid, mposTab=oldPos, posTab=newPos})
                            -- Element:SetPosition(eid, VectorFromTable(newPos), Element.COORDINATE.World)
                        end
                    else
                        local scaleVec = GetScaleDstCalcXyz(cfgElements.woodBoxB.size, 1, 1, 1)
                        printEz("dropRemovedropRemove", MiscService:Table2JsonStr(VectorToTable(scaleVec)))
                        AddMotionToElementOneTime(eid, "dropRemove", CfgTools.MotionUnit.Types.Scale, VectorToTable(scaleVec),
                        nil, 0, 0.3)
                        -- AddMotionToElement(eid, "dropRemove", CfgTools.MotionUnit.Types.Pos, Engine.Vector(800,0,0), 0, 0,
                        -- 2, 0, 0, 0, 0)
                        --消除动作
                        TimerManager:AddTimer(2, function ()
                            DestroyElementAndChildren(eid)
                        end)
                    end
                end
            end
        end
    end
    --填充空白行
    for row = 1, fullNum do
        for col = 1, match.board.colNum do
            match.board.parts[match.board.rowNum - row + 1][col] = NewBoardPartGetInit(isClient)
        end
    end
    --掉落缓动
    if isClient then
        AddMotionToTetrisDropLines(dropParts, fullNum, math.max(block.dropSpeed + 50, 400))
    end
end

function AddMotionToTetrisDropLines(dropParts, fullNum, speed)
    local id = GetNewMotionId("tetrisLineDrop")
    local motionObj = {dropParts=dropParts, speed=speed}
    --保证完整掉落
    local delay = 0.3
    local totalTime = cfgTetris.blockSize * (fullNum + 1) / speed
    totalTime = totalTime + delay
    local param = NewMotionParam(id, id, ObjGroups.MotionUnit, 0, motionObj, UpdateMotionUnit, DestroyMotionUnit,
        totalTime, 0, delay, 0, 0, nil, TetrisBlockPartDropMotionUpdate, nil)
    local obj = BuildMotionObj(param)
end

function TetrisBlockPartDropMotionUpdate(obj, state, deltaTime)
    -- printEz("TetrisBlockPartDropMotionUpdate", MiscService:Table2JsonStr(obj))
    local dropParts = obj.motionObj.dropParts
    local speed = obj.motionObj.speed
    -- local i = 0
    for index, value in ipairs(dropParts) do
        -- i = i + 1
        -- if i == 1 then
        --     printEz("TetrisBlockPartDropMotionUpdate aa", MiscService:Table2JsonStr(value))
        -- end
        if not value.done then
            if IsVectorTableEqual(value.posTab, value.mposTab) then
                value.done = true
            else
                MotionUpdatePosTab(deltaTime, value, "posTab", value, "mposTab", speed)
            end
            Element:SetPosition(value.eid, VectorFromTable(value.mposTab), Element.COORDINATE.World)
        end
        
        -- if i == 1 then
        --     printEz("TetrisBlockPartDropMotionUpdate 11bb", MiscService:Table2JsonStr(value))
        -- end
    end
end

--在客户端处理合并结果,包括合并失败和合并成功。成功的情况需要推送是否有消除,合并和消除后的最新棋盘情况
function MergeTetrisBlockResOnClient(action)
    local block = action.block
    --先合并到本地,因为这是合并结果,是最终状态
    local blockLocal = GetTetrisLocalBlock(block)
    if not IsBlockPlayerSelf(block) then
        SyncTetrisMatchDataUpdateBlock(action)
        blockLocal = GetTetrisLocalBlock(block)
    end
    blockLocal.mergeDone = true
    GenNewTetrisBlocksLocal(action, false)
    -- local blockLocal = RemoveTetrisSolidetBlock(block, tetrisMatchsLocal, action.mergeFail)
    if action.mergeFail then
        print("MergeTetrisBlockResOnClient mergeFail")
        --仍然需要同步棋盘数据,因为本地数据已错误
        SyncTetrisMatchDataUpdateMatchNoPlayerData(action)
        HandleTetrisBlockMergeFailed(blockLocal, true)
        FindNextDropBlockToBoard(blockLocal, nil)
        return
    end
    local matchLocal = GetMatchLocalByBlock(block)
    --先固化方块拆解到棋盘
    print("SolidifyTetrisBlockConfirmbefore is ", MiscService:Table2JsonStr(matchLocal.board))
    matchLocal.board = MergeTables(action.boardBeforeDrop, matchLocal.board, {"localData"})
    SolidifyTetrisBlockConfirm(blockLocal, matchLocal.board)
    print("SolidifyTetrisBlockConfirmafter is ", MiscService:Table2JsonStr(matchLocal.board))
    --客户端执行掉落
    -- local matchLocalCopy = CopyTableWithoutKey(matchLocal, nil)
    if action.fullLineRes and action.fullLineRes.fullRows then
        TetrisBoardLineDrop(matchLocal, action.fullLineRes.fullRows, action.fullLineRes.fullNum, action.fullLineRes.rowDropNum, true, block)
    end
    print("SolidifyTetrisBlockConfirm CCC is ", MiscService:Table2JsonStr(matchLocal.board))
    --合并掉落后数据
    SyncTetrisMatchDataUpdateMatchNoPlayerData(action)
    print("MergeTetrisBlockDataHandle client ", MiscService:Table2JsonStr(GetMatchLocalByBlock(block).board))
    RemoveTetrisBlockData(blockLocal, tetrisMatchsLocal)
    FindNextDropBlockToBoard(blockLocal, nil)
end

function FindNextDropBlock(match, playerId, nid)
    local block = match.players[playerId].dropBlocks[nid]
    if not block then
        printEz("FindNextDropBlock error cant find")
    end
    return block
end

--将下一个方块移动到棋盘
function FindNextDropBlockToBoard(blockCur, block)
    -- printEz("FindNextDropBlockToBoard start")
    local match = nil
    if blockCur ~= nil then
        match = tetrisMatchsLocal[blockCur.matchId]
        block = FindNextDropBlock(match, blockCur.playerId, blockCur.nid)
    else
        match = tetrisMatchsLocal[block.matchId]
    end
    if match == nil then
        return
    end
    if block == nil then
        return
    end
    printEz("FindNextDropBlockToBoard block", block.id, block.blockCfg.type, block.blockCfg.morph, MiscService:Table2JsonStr(block))
    local prepare = block.localData.prepare
    --销毁准备预览
    if prepare then
        --销毁
        DestroyElementAndChildren(prepare.awId)
    end
    --实体化
    InitTetrisBlockEntity(block, match)
    --生成准备预览
    if IsBlockPlayerSelf(block) then
        local blockPrevious = block
        for i = 1, 2, 1 do
            blockPrevious = PrepareDropBlock(blockPrevious, match, i)
        end
    end
end

--生成准备预览
function PrepareDropBlock(blockCur, match, index)
    local block = FindNextDropBlock(match, blockCur.playerId, blockCur.nid)
    local prepare = block.localData.prepare
    --棋盘顶
    local posTab = VectorTablePlus(match.board.boardPosTab, cfgTetris.blockSize * match.board.colNum, 0, cfgTetris.blockSize * match.board.rowNum)
    posTab = VectorTablePlus(posTab, cfgTetris.blockSize * 3, 0, -1 * cfgTetris.blockSize * 3)
    posTab = VectorTablePlus(posTab, -1 * block.blockCfg.colLen / 2 * cfgTetris.blockSize, 0, -1 * (index - 1) * 4 * cfgTetris.blockSize)
    -- printEz("PrepareDropBlock", block.id, block.blockCfg.type, block.blockCfg.morph, MiscService:Table2JsonStr(posTab), MiscService:Table2JsonStr(block))
    if not prepare then
        -- printEz("PrepareDropBlock not prepare", block.id, block.blockCfg.type, block.blockCfg.morph, MiscService:Table2JsonStr(block))
        local res = NewInitTetrisBlockEntityParam()
        res.prepare = {posTab=posTab}
        InitTetrisBlockEntitySingle(block, match, false, res)
    else
        posTab = GetTetrisBlockCenterPosTab(block, posTab)
        -- printEz("PrepareDropBlock setpos", block.id, MiscService:Table2JsonStr(posTab), prepare.awId, block.blockCfg.type, block.blockCfg.morph, MiscService:Table2JsonStr(block))
        -- printEz("PrepareDropBlock setpos curpos", block.id, MiscService:Table2JsonStr(VectorToTable(Element:GetPosition(prepare.awId))) )
        --设置位置
        Element:SetPosition(prepare.awId, VectorFromTable(posTab), Element.COORDINATE.World)
    end
    return block
end

function SolidifyTetrisBlockAction(action)
    local match = GetMatchLocalByBlock(action.block)
    local block = GetTetrisLocalBlock(action.block)
    if block ~= nil then
        SolidifyTetrisBlock(block, action.block.mergeRow, action.block.curColumn, match.board)
    end
end

function PushTetrisSolidetBlock(block, matches)
    EnsureTableValue(matches, block.matchId, "solidetBlocks")[block.objId] = block
end

function HandleTetrisBlockMergeFailed(block, destroyEntity)
    if destroyEntity then
        -- for row, rowData in pairs(block.localData.parts) do
        --     for col, value in pairs(rowData) do
        --         print("RemoveTetrisSolidetBlock destroyEntity ", value.eid)
        --         Element:Destroy(value.eid)
        --     end
        -- end
        DestroyElementAndChildren(block.localData.awId)
    end
end

-- function RemoveTetrisSolidetBlock(block, matches, destroyEntity)
--     local blockLocal = matches[block.matchId].solidetBlocks[block.objId]
--     if blockLocal == nil then
--         printEz("RemoveTetrisSolidetBlock blockLocal nil")
--         return
--     end
--     matches[block.matchId].solidetBlocks[block.objId] = nil
--     HandleTetrisBlockMergeFailed(block, destroyEntity)
--     return blockLocal
-- end

function SolidifyTetrisBlockEntity(block, posTabSrc)
    block.posTab = NewVectorTable(GetTetrisBlockPosX(block, posTabSrc), posTabSrc.y, posTabSrc.z + (block.curRow -1) * cfgTetris.blockSize)
    SyncTetrisBlockEntityStateWithData(block, block.posTab, block.blockCfg.rotate, false)
end

--固化方块停止移动,这是在每个客户端执行的
function SolidifyTetrisBlock(block, row, column, board)
    -- 不删除而是标记失效,等数据端处理完成后还需要用到储存的本地实体化数据
    -- PushTetrisSolidetBlock(block, tetrisMatchsLocal)
    RemoveBlockObjAndMotion(block)
    block.active = false
    block.solidet = true
    block.curRow = row
    block.curColumn = column
    local posTabSrc = board.boardPosTab
    SolidifyTetrisBlockEntity(block, posTabSrc)
end

--拆解方块固化到棋盘
function SolidifyTetrisBlockConfirm(block, board)
    print("SolidifyTetrisBlockConfirm ", MiscService:Table2JsonStr(board))
    --仍然需要重新固化一遍
    SolidifyTetrisBlock(block, block.curRow, block.curColumn, board)
    for row, rows in pairs(block.blockParts) do
        for col, val in pairs(rows) do
            if val ~= 0 then
                local localVal = GetTetrisBlockPartLocalData(block, row, col)
                Element:UnBinding(localVal.eid)
                local brow = row + block.curRow - 1
                local bcol = col + block.curColumn - 1
                print("SolidifyTetrisBlockConfirm unbind ", brow, " ", bcol, " ", MiscService:Table2JsonStr(localVal))
                board.parts[brow][bcol].localData.eid = localVal.eid
            end
        end
    end
    DestroyElementAndChildren(block.localData.awId)
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

function GetTetrisBlockColumnOnBoard(block, col)
    return col + block.curColumn - 1
end

function GetTetrisBlockRowOnBoard(blockRow, row)
    return row + blockRow - 1
end

--计算棋盘某一列某一行以下的最高行
function GetTetrisBoardColumnHeight(board, col, maxRow)
    if maxRow < 1 then
        return 0
    end
    for row = maxRow, 1, -1 do
        local rp = board.parts[row]
        if rp ~= nil and rp[col] ~= nil and rp[col].v ~= 0 then
            return row
        end
    end
    return 0
end

-- --计算方块最低下降到哪一行,采用不冲突算法
-- function CalcTetrisBlockBottomRow(block, board, blockRow)
--     local blockParts = block.blockParts
--     local colNum = #blockParts[1]
--     local rowNum = #blockParts
--     blockRow = math.ceil(blockRow)
--     if blockRow <= 1 then
--         return 1
--     end
--     -- if blockRow < 1 then
--     --     printEz("CalcTetrisBlockBottomRow error", blockRow)
--     --     return 1
--     -- end
--     for row = 1, blockRow do
--         if not CheckTetrisBoardIsOverlap(row, block.curColumn, board, rowNum, colNum, blockParts) then
--             return row
--         end
--     end
--     printEz("CalcTetrisBlockBottomRow error final", blockRow, MiscService:Table2JsonStr(block))
--     return blockRow
-- end

--计算方块最低下降到哪一行,采用分析每一列最低行算法
function CalcTetrisBlockBottomRow(block, board, blockRow)
    local blockParts = block.blockParts
    local botRow = 1 - #blockParts
    blockRow = math.ceil(blockRow)
    for col = 1, block.blockCfg.colLen do
        --当前列的最低有效值的行
        local botRowCurCol = nil
        for row = 1, block.blockCfg.rowLen do
            if botRowCurCol == nil and blockParts[row][col] ~=0 then
                botRowCurCol = row
            end
        end
        if botRowCurCol ~= nil then
            local boardCol = GetTetrisBlockColumnOnBoard(block, col)
            if boardCol <= board.colNum then
                -- printEz("CalcTetrisBlockBottomRow", boardCol, botRowCurCol, blockRow)
                local colHeight = GetTetrisBoardColumnHeight(board, boardCol, GetTetrisBlockRowOnBoard(botRowCurCol, blockRow))
                botRowCurCol = colHeight + 2 - botRowCurCol
                botRow = math.max(botRow, botRowCurCol)
            end
        end
    end
    -- print("CalcTetrisBlockBottomRow", botRow, MiscService:Table2JsonStr(block))
    return botRow
end

function ControlTetrisBlockToBottom(block, match, botRow)
    local blockCopy = CopyTableShallow(block)
    block.curRow = botRow
    block.mergeRow = block.curRow
    SolidifyTetrisBlockSimulateAll(block, block.curRow, block.curColumn, match)
    -- TimerManager:AddTimer(5, function ()
    --     CreateEffectOnTetrisBlock(blockCopy, match, botRow)
    -- end)
    CreateEffectOnTetrisBlock(blockCopy, match, botRow)
    
end

--玩家控制方块
function ControlActionTetrisBlockLocal(isRotate, isMoveLeft, isMoveDown, isFastMoveDown)
    local block = GetTetrisControlBlock()
    local res = {success=false, block=nil}
    if block == nil then
        return res
    end
    -- if isFastMoveDown then
    --     block.localData.controllable = false
    -- end
    local match = GetMatchLocalByBlock(block)
    --移动到底
    if isFastMoveDown then
        local curRow = CalcTetrisBlockCurRow(block.posTab, match.board)
        local botRow = CalcTetrisBlockBottomRow(block, match.board, curRow)
        ControlTetrisBlockToBottom(block, match, botRow)
        return res
    end
    --下移
    if isMoveDown then
        local curRow = CalcTetrisBlockCurRow(block.posTab, match.board)
        local botRow = CalcTetrisBlockBottomRow(block, match.board, curRow)
        local posTab = VectorTablePlus(block.posTab, 0, 0, -cfgTetris.blockSize)
        local curRowAfterDown = CalcTetrisBlockCurRow(posTab, match.board)
        if curRowAfterDown <= botRow then
            ControlTetrisBlockToBottom(block, match, botRow)
            return res
        else
            res.success = true
            block.posTab = posTab
            SendSyncTetrisMatchDataToPlayers("SyncTetrisMatchDataUpdateBlock", match, block, true)
            return res
        end
    end
    local testBlock = CopyTableByJson(block)
    if isRotate then
        SetTetrisBlockCfg(testBlock, testBlock.blockCfg.type, testBlock.blockCfg.nextMorph)
    end
    local colDiff = 0
    if isMoveLeft == true then
        colDiff = -1
    elseif isMoveLeft == false then
        colDiff = 1
    end
    GetTetrisBlockColumnNotOverBoard(testBlock, colDiff, match)
    -- print("ControlActionTetrisDropBlock ", MiscService:Table2JsonStr(testBlock))
    local notOverlap = CheckTetrisBlockMerge(match, testBlock, nil, true)
    if not notOverlap then
        return res
    end
    --不重叠但是移动情况方块状态未产生变化
    if isMoveLeft == true or isMoveLeft == false then
        if block.curColumn == testBlock.curColumn then
            return res
        end
    end
    
    res.success = true
    block.blockParts = testBlock.blockParts
    block.blockCfg = testBlock.blockCfg
    block.curColumn = testBlock.curColumn
    SendSyncTetrisMatchDataToPlayers("SyncTetrisMatchDataUpdateBlock", match, block, true)
    return res
end

function StartTetrisMatchAll()
    StartTetrisMatch(players)
end

--开始一场对局
function StartTetrisMatch(players)
    ServerLog("StartTetrisMatch start")
    local id = GetIdFromPoolStringfy("tetrisMatchId", cfgTetris.matchIdStart, 1, 10, nil)
    -- local boardPosTab=VectorToTable(VectorPlus(posOrg, 0, 0, 0))
    local boardPosTab = NewVectorTableCopy(cfgTetris.board.posTab)
    local match = {id=id, players={}, dropSpeed=cfgTetris.dropSpeed, boardPosTab=boardPosTab, active=true}
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
    local newAction = NewTetrisAction(match, nil, nil, "StartTetrisMatchClient")
    local newBlockRes = GenTetrisDropBlockForNewMatch(match)
    newAction.newBlocks = newBlockRes
    -- printEz("NewTetrisMatchData", MiscService:Table2JsonStr(newBlockRes))
    SendTetrisActionToMatchPlayers(newAction)
end

function GenTetrisDropBlockForNewMatch(match)
    local newBlockRes = {matchId=match.id, players={}}
    for playerId, value in pairs(match.players) do
        local res = CheckAndGenTetrisDropBlockForPlayer(match, playerId)
        newBlockRes.players[playerId] = res.newBlocks.players[playerId]
    end
    return newBlockRes
end

function StartTetrisMatchClient(action)
    SyncTetrisMatchDataNewMatch(action)
    InitTetrisBoardEntity(action)
    SetTetrisCameraWatchBoard(action.match)
end

--检查数据端发来的新方块
function GenNewTetrisBlocksLocal(action, startDrop)
    if not action.newBlocks then
        return
    end
    printEz("GenNewTetrisBlocksLocal", MiscService:Table2JsonStr(action.newBlocks))
    --用数据生成新方块并添加到本地
    local prepareBlocks = {}
    for playerId, playerData in pairs(action.newBlocks.players) do
        for index, cfg in ipairs(playerData) do
            local block = GenSingleTetrisDropBlock(action.newBlocks, playerId, cfg)
            if index == 1 then
                --开始掉落
                table.insert(prepareBlocks, block)
            end
        end
    end
    if startDrop then
        TimerManager:AddTimer(1, function ()
            for index, block in ipairs(prepareBlocks) do
                FindNextDropBlockToBoard(nil, block)
            end
        end)
    end
    --xxx
end

function InitTetrisBoardEntity(action)
    local board = action.match.board
    
    local posTab = VectorTablePlus(board.boardPosTab, cfgTetris.blockSize * cfgTetris.board.colNum / 2, 0, 0)
    -- CopyElementAndChildrenServerEzScale(elesInScene.frameBoard, cfgCopyProps, callback, VectorFromTable(posTab),
    -- cfgElements.cube.size, cfgTetris.blockSize * cfgTetris.board.colNum, cfgTetris.blockSize, cfgTetris.blockSize * cfgTetris.board.rowNum, nil)
    local sizeTab = NewVectorTable(cfgTetris.blockSize * cfgTetris.board.colNum, cfgTetris.blockSize, cfgTetris.blockSize * cfgTetris.board.rowNum)
    -- posTab = VectorTablePlus(posTab, 0, -20, 0)
    -- sizeTab = VectorTablePlus(sizeTab, 10, 0, 0)

    -- posTab = VectorTablePlus(posTab, 0, 0, -170)
    -- sizeTab = VectorTablePlus(sizeTab, 0, 0, 0)

    posTab = VectorTablePlus(posTab, 0, -20, 0)
    sizeTab = VectorTablePlus(sizeTab, 0, 0, 0)

    local callback = function (eid)
        -- local spline = Element:AddSpline(VectorFromTable(board.boardPosTab), Engine.Vector(0, 0, 0), Engine.Vector(1,1,1), eid)
        -- Element:UpdateSplinePoints(spline, {VectorFromTable(board.boardPosTab), VectorFromTable(VectorTablePlus(posTab, 900, 0, -0))})
    end
    CopyElementAndChildrenFull(elesInScene.cubeBlackWhiteW, cfgCopyProps, callback, false,
        VectorFromTable(posTab), false, nil,
        cfgElements.cube.size, sizeTab, nil, BuildElementStateEzNoPhyNoColli(0), BuildElementStateEzNoPhyNoColli(0))


end

function SendTetrisActionToMatchPlayers(action)
    SendTetrisActionToPlayers(action, action.match.players)
end

function NewTetrisAction(match, player, block, funcName)
    if match == nil then
        printEz("NewTetrisAction error match param nil ", funcName)
    end
    local action = {match=match, player=player, block=block, funcName=funcName}
    return action
end

function NewTetrisActionExcludeBlockPlayer(match, player, block, funcName)
    local action = {match=match, player=player, block=block, funcName=funcName, excludeBlockPlayer=true}
    return action
end


function IsTetrisMatchSinglePlayer(match)
    return GetTablePairLen(match.players) == 1
end


function SendTetrisActionToPlayers(action, players)
    --不用判断方块的情况
    if action.block == nil then
        for key, player in pairs(players) do
            SendTetrisActionToSinglePlayer(action, player.id)
        end
        return
    end
    
    --需要排除方块所有者的情况
    for key, player in pairs(players) do
        if action.excludeBlockPlayer ~= nil then
            if not IsStringEqual(player.id, action.block.playerId) then
                SendTetrisActionToSinglePlayer(action, player.id)
            end
        else
            SendTetrisActionToSinglePlayer(action, player.id)
        end
    end
end

function SendTetrisActionToSinglePlayer(action, playerId)
    printEz("SendTetrisActionToSinglePlayer ", action.funcName, " ", playerId, " ", GetLocalPlayerId())
    --必须复制一遍防止单机模式时对象重用
    action = CopyTableShallowWithoutKey(action, "localData")
    --处理不需要发送match数据的情况
    if constantTetris.matchActions[action.funcName] == nil then
        action.match = nil
    end
    if IsStringEqual(playerId, GetLocalPlayerId()) then
        TetrisAction({action=action})
    else
        PushActionToPlayer(false, "TetrisAction", {action=action}, UMath:StringToNumber(playerId))
    end
end

function TetrisAction(actionObj)
    local action = actionObj.action
    printEz("TetrisActionAct ", MiscService:Table2JsonStr(actionObj))
    _G[action.funcName](action)
end

function SendTetrisActionToAll(match, action)
    PushActionToClients()
end

--发往数据端
function SendTetrisActionToDataSide(action)
    printEz("SendTetrisActionToDataSide ", MiscService:Table2JsonStr(action))
    local dataPlayerId = GetTetrisMatchDataSidePlayerId(action.match)
    SendTetrisActionToSinglePlayer(action, dataPlayerId)
end

function SendTetrisActionToServerSide(action)
    printEz("SendTetrisActionToServerSide ", MiscService:Table2JsonStr(action))
    SendTetrisActionToSinglePlayer(action, toolCommonCfgs.serverPlayerId)
end


--获取数据端的玩家id。 -1表示服务端
function GetTetrisMatchDataSidePlayerId(match)
    if System:IsStandalone() then
        return GetLocalPlayerId()
    end
    if true then
        return toolCommonCfgs.serverPlayerId
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
    SetObjState(obj, "move.toMove", 0, 5, 0)
    AddObjState(obj, "move.toAttack")
    SetObjState(obj, "move.toAttack", 0, 5, 0)
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
    false, nil, cfgElements.airWall.size, Engine.Vector(198, 198, 100),
    nil, nil, nil)

    
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
    false, nil, cfgElements.cube.size, Engine.Vector(100, 200, 100),
    nil, nil, nil)

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
    false, nil, nil, nil, nil, nil, nil)
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
        SetObjState(obj, "move.toMove",  90, 0, 0)
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
    true, false, nil, nil, nil, nil, nil)
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
            SetObjState(obj, "move.toMove", 90, 0, 0)
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

function TetrisMatchFailServer(action)
    TimerManager:AddTimer(30, function ()
        tetrisMatchsServer[action.matchRes.matchId] = nil
    end)
end

function MatchFailOnDataSide(match)
    --数据端
    TimerManager:AddTimer(30, function ()
        tetrisMatchs[match.id] = nil
    end)
    --服务器端
    local matchRes = {matchId=match.id, matchFail=true}
    local serverAction = NewTetrisAction(match, nil, nil, "TetrisMatchFailServer")
    serverAction.matchRes = matchRes
    SendTetrisActionToServerSide(serverAction)
    --客户端
    local clientAction = NewTetrisAction(match, nil, nil, "TetrisMatchFailClient")
    clientAction.matchRes = matchRes
    SendTetrisActionToMatchPlayers(clientAction)
end

function RemoveBlockObjAndMotion(block)
    InactiveObjById(block.objId)
    RemoveMotionByEidAndName(block.localData.awId, "drop")
end

function TetrisMatchFailClient(action)
    local matchRes = action.matchRes
    local matchId = matchRes.matchId
    TimerManager:AddTimer(30, function ()
        tetrisMatchsLocal[matchId] = nil
    end)
    local match = tetrisMatchsLocal[matchId]
    local blocks = GetTetrisDroppingBlocks()
    for index, block in ipairs(blocks) do
        DestroyTetrisBlockPreview(block)
        block.active = false
        RemoveBlockObjAndMotion(block)
    end
end

function RegisterEventsAll()
    System:RegisterEvent(Events.ON_CHARACTER_CREATED, CallbackCharCreated)
    System:RegisterEvent(Events.ON_ELEMENT_TOUCH_PLAYER, CallbackPlayerTouchEle)

    System:RegisterEvent(Events.ON_BUTTON_PRESSED, ButtonPressed)
    System:RegisterEvent(Events.ON_PLAYER_ENTER, OnPlayerEnter)
    System:RegisterEvent(Events.ON_PLAYER_LEAVE, OnPlayerLeave)
    System:RegisterEvent(Events.ON_PLAYER_JOIN_MIDWAY, OnPlayerJoinMidway)
end

function DoTest()
    -- if 1 == 1 then
    --     return
    -- end
    local obja = {3, "aaa", [5]=888, m=3, ab={3,89}, as={3, {2, 1, 0}}, atp={a=3, ab="hhsdq", c={2, "ss"}}}
    local objb = {3, "aaa", [5]=888, m="dqk2888", ab={3,89}, as={3, {2, 1, 0}}, atp={a=3, ab="akdhk2", c={2, "ss"}}}
    local objaCopy = MergeTables(obja, objb, {"ab"})
    print("DoTest 1")
    Log:PrintTable(objaCopy)
    objaCopy = MergeTables(obja, objb, {"m", "ab"})
    print("DoTest 2")
    Log:PrintTable(objaCopy)

end

function DoTestQuest()
    printEz("DoTestAnswer start", testObj.id)
    testObj.delays[Stringfy(testObj.id)] = {start=GetGameTimeCur()}
    SendTransActionToServer("DoTestAnswer", testObj, GetLocalPlayerId())
end

function DoTestAnswer(msg)
    local delay = GetGameTimeCur() - testObj.delays[Stringfy(msg.id)].start
    printEz("DoTestAnswer end", msg.id, delay, GetTablePairLen(msg.texts))
    testObj.id = testObj.id + 1
    table.insert(testObj.texts, MiscService:Table2JsonStr(testObj))
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
        ControlActionTetrisBlockLocal(true, nil, nil, nil)
    elseif item == 103375 then
        ControlActionTetrisBlockLocal(nil, false, nil, nil)
    elseif item == 103376 then
        ControlActionTetrisBlockLocal(nil, true, nil, nil)
    elseif item == 104477 then
        ControlActionTetrisBlockLocal(nil, nil, true, nil)
    elseif item == 104480 then
        ControlActionTetrisBlockLocal(nil, nil, nil, true)
    elseif item == uiConstants.skinMenu then
        ShowSkins()
    else
        -- TestRotateBlock()      
    end
    
end

function ShowSkins()
    printEz("ShowSkins")
    UI:SetVisibility({uiConstants.skinGrid}, true)
end

function InitUI()
    -- local newItem = UI:DuplicateWidget(uiConstants.skinItem, 200, 200)
    -- UI:SetText({newItem}, "测试一下ooo")
    -- UI:AddToScrollView(uiConstants.skinList, {newItem})

    local skinGrid = uiConstants.skinGrid
    --设置可见否则不能初始化
    UI:SetVisibility({skinGrid}, true)
    --设置不可见来隐藏列表
    UI:SetVisibility({skinGrid}, false)
    local skinData = {}
    for key, value in pairs(blockSkins) do
        table.insert(skinData, value)
    end
    local idList = UI:InitListView(skinGrid, skinData)
    -- UI:UpdateListViewItem(uiConstants.skinGrid, 1, {showText="aaadsqsda"})
    local skinListSetCallback = function (listViewId, itemId, itemData)
        local nameItem = UI:GetListViewItemUID(listViewId, itemId, uiConstants.skinNameItem)
        UI:SetText({nameItem}, itemData.name)
        printEz("skinListSetCallback", listViewId, itemId, MiscService:Table2JsonStr(itemData), nameItem)
    end
    UI:SetListViewItemSetCall(skinGrid, skinListSetCallback)
    local skinListChangeCallback = function(listViewId, itemId, itemData, value)
        printEz("skinListChangeCallback", MiscService:Table2JsonStr(itemData), value)
        if value then
            cfgTetris.skinName = itemData.name
        end
    end
    UI:SetListViewItemSelectionChangeCall(skinGrid, skinListChangeCallback)
    printEz("InitUI", MiscService:Table2JsonStr(idList), UI:GetUIName(skinGrid))
end