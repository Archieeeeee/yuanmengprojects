require("YmUtils")

---@class TimeCfg 时间配置类
---@field initDelay number
---@field totalTime number
---@field cycleTime number
---@field cycleDelay number
---@field numLimit number
local TimeCfg = {initDelay=0, totalTime=0, cycleTime=0, cycleDelay=0, numLimit=0}
TimeCfg.__index = TimeCfg

---创建时间配置类
---@param initDelay number
---@param totalTime number
---@param cycleTime number
---@param cycleDelay number
---@param numLimit number
---@return TimeCfg
function TimeCfg:new(initDelay, totalTime, cycleTime, cycleDelay, numLimit)
    local res = setmetatable({}, TimeCfg)
    res.initDelay = initDelay
    res.totalTime = totalTime
    res.cycleTime = cycleTime
    res.cycleDelay = cycleDelay
    res.numLimit = numLimit
    return res
end

---@class FuncCfg
---@field startFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@field endFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@field cycleStartFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@field actionStartFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@field actionUpdateFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
local FuncCfg = {startFunc=nil, endFunc=nil, cycleStartFunc=nil, actionStartFunc=nil, actionUpdateFunc=nil}
FuncCfg.__index = FuncCfg

---创建
---@param startFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@param endFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@param cycleStartFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@param actionStartFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@param actionUpdateFunc nil | fun(obj: Object, state: ObjState, deltaTime: number)
---@return FuncCfg
function FuncCfg:new(startFunc, endFunc, cycleStartFunc, actionStartFunc, actionUpdateFunc)
    local res = setmetatable({}, FuncCfg)
    res.startFunc = startFunc
    res.endFunc = endFunc
    res.cycleStartFunc = cycleStartFunc
    res.actionStartFunc = actionStartFunc
    res.actionUpdateFunc = actionUpdateFunc
    return res
end

---@class ObjState 状态类
---@field startTs number?
---@field endTs number?
---@field name string
local ObjState = {name="", timeCfg=nil, funcCfg=nil, count=0}
ObjState.__index = ObjState

---创建
---@param name any
---@return ObjState
function ObjState:new(name)
    local res = setmetatable({startTs=0, endTs=0, actionTs=0, totalDelta=0, cycleDelta=0, actionDelta=0, cycleStartTs=0, cycleEndTs=0}, ObjState)
    res.name = name
    return res
end

--设置时间参数
function ObjState:setTimeCfg(timeCfg)
    self.timeCfg = timeCfg
    return self
end

--设置时间节点的回调函数
---@param funcCfg FuncCfg?
---@return ObjState
function ObjState:setFunc(funcCfg)
    self.funcCfg = funcCfg
    return self
end

function ObjState:start(deltaTime, obj)
    local cs = self
    if cs.startTs == 0 then
        cs.startTs = GetGameTimeCur()
        cs.totalDelta = 0
        if self.funcCfg and self.funcCfg.startFunc then
            self.funcCfg.startFunc(obj, self, deltaTime)
        end
    end

    cs.cycleStartTs = GetGameTimeCur()
    cs.cycleDelta = 0
    cs.actionDelta = 0
    cs.count = cs.count + 1
    cs.cycleEndTs = 0
    if self.funcCfg and self.funcCfg.cycleStartFunc then
        self.funcCfg.cycleStartFunc(obj, self, deltaTime)
    end
end

---更新
---@param deltaTime number
---@param obj Object
function ObjState:update(deltaTime, obj)
    local cs = self
    local tc = self.timeCfg
    if tc then
        --未开始
        if cs.startTs == 0 then
            return
        end
        --已结束
        if cs.endTs ~= 0 then
            return
        end
        --开始过但是超时判断结束
        if cs.startTs > 0 and tc.totalTime ~= 0 and cs.totalDelta >= tc.totalTime then
            self:endState(obj, deltaTime)
            return
        end
        --开始过但是超过循环次数判断结束
        if cs.startTs > 0 and tc.numLimit ~= 0 and cs.count > tc.numLimit then
            self:endState(obj, deltaTime)
            return
        end

        --检查是否需要开始action
        if cs.actionTs == 0 then
            local delay = tc.cycleDelay
            if cs.count == 1 then
                delay = tc.initDelay
            end
            if cs.cycleDelta >= delay then
                self:actionStart(obj, deltaTime)
            end
        end
        --检查action结束
        if cs.actionTs > 0 then
            if tc.cycleTime ~= 0 and cs.actionDelta >= tc.cycleTime then
                self:cycleEnd(obj, deltaTime)
            else
                self:actionUpdate(obj, deltaTime)
            end
        end
    end
    cs.totalDelta = cs.totalDelta + deltaTime
    cs.cycleDelta = cs.cycleDelta + deltaTime
end

function ObjState:endState(obj, deltaTime)
    self.endTs = GetGameTimeCur()
    self.cycleEndTs = GetGameTimeCur()
    if self.funcCfg and self.funcCfg.endFunc then
        self.funcCfg.endFunc(obj, self, deltaTime)
    end
end

function ObjState:cycleEnd(obj, deltaTime)
    self.cycleEndTs = GetGameTimeCur()
end

function ObjState:actionStart(obj, deltaTime)
    self.actionTs = GetGameTimeCur()
    if self.funcCfg and self.funcCfg.actionStartFunc then
        self.funcCfg.actionStartFunc(obj, self, deltaTime)
    end
end

function ObjState:actionUpdate(obj, deltaTime)
    if self.funcCfg and self.funcCfg.actionUpdateFunc then
        self.funcCfg.actionUpdateFunc(obj, self, deltaTime)
    end
    self.actionDelta = self.actionDelta + deltaTime
end

--状态机
---@class StateMachine
---@field state ObjState
---@field nextState ObjState
---@field conditionFunc fun(state:ObjState, nextState:ObjState, deltaTime:number, obj: Object):boolean
local StateMachine = {}
StateMachine.__index = StateMachine

---创建状态机
---@param state ObjState
---@param nextState ObjState
---@param conditionFunc fun(state:ObjState, nextState:ObjState, deltaTime:number, obj: Object):boolean
---@return StateMachine
function StateMachine:new(state, nextState, conditionFunc)
    local res = setmetatable({}, StateMachine)
    res.state = state
    res.nextState = nextState
    res.conditionFunc = conditionFunc
    return res
end

---更新
---@param deltaTime any
---@param obj Object
function StateMachine:update(deltaTime, obj)
    if self.conditionFunc(self.state, self.nextState, deltaTime, obj) then
        self.state:endState(obj, deltaTime)
        self.nextState:start(deltaTime, obj)
    end
end

--普通时间状态机
---@class StateMachineTime
-- local StateMachineTime = setmetatable({}, StateMachine)
-- StateMachineTime.__index = StateMachineTime

local StateMachineTime = {}

function StateMachineTime:new(state, nextState)
    local sm = StateMachine:new(state, nextState, function(stateA, nextStateA, deltaTime, obj)
        if stateA.timeCfg ~= nil then
            return stateA.cycleEndTs > 0
        end
        return false
    end)
    -- setmetatable(sm, sm)
    return sm
end


--对象类
---@class Object
---@field states table<string, ObjState>
---@field stateMachines table<string, StateMachine>
---@field id any
---@field group any
---@field typeName any
---@field active boolean
---@field updateFunc nil | fun(deltaTime: number, obj: Object)
---@field destoryFunc nil | fun(obj: Object)
local Object = {}
Object.__index = Object

---创建
---@param id any
---@param group any
---@param typeName any
---@return Object
function Object:new(id, group, typeName)
    local res = setmetatable({states={}, stateMachines={}, active=true, id=id,
        group=tostring(group), typeName=tostring(typeName)}, Object)
    res:reset()
    return res
end

---设置回调
---@param updateFunc nil | fun(deltaTime: number, obj: Object)
---@param destroyFunc nil | fun(obj: Object)
---@return Object
function Object:setFunc(updateFunc, destroyFunc)
    self.updateFunc = updateFunc
    self.destoryFunc = destroyFunc
    return self
end

function Object:reset()
    self.states = {}
    self.stateMachines = {}
    return self
end

function Object:update(deltaTime)
    if self.updateFunc then
        self.updateFunc(deltaTime, self)
    end
    --更新状态
    for key, state in pairs(self.states) do
        state:update(deltaTime, self)
    end
    --更新状态机
    for key, sm in pairs(self.stateMachines) do
        printEz("updatestateMachines", sm.state.name)
        sm:update(deltaTime, self)
    end
end

function Object:destory()
    if self.destoryFunc then
        self.destoryFunc(self)
    end
end

---添加状态机
---@param sm StateMachine
---@param name string
---@return Object
function Object:addStateMachine(sm, name)
    self.stateMachines[name] = sm
    return self
end

---添加状态
---@param state ObjState
---@return Object
function Object:addState(state)
    self.states[state.name] = state
    state:start(0, self)
    return self
end

---添加状态
---@param name string
---@param timeCfg TimeCfg?
---@param funcCfg FuncCfg?
---@return Object
function Object:addStateFull(name, timeCfg, funcCfg)
    local state = ObjState:new(name):setTimeCfg(timeCfg):setFunc(funcCfg)
    state:start(0, self)
    self.states[name] = state
    return self
end

---对象池类
---@class ObjectPool
---@field group any
---@field typeName any
---@field pools Object[]
local ObjectPool = {pools={}}
ObjectPool.__index = ObjectPool

---创建
---@param group any
---@param typeName any
---@return ObjectPool
function ObjectPool:new(group, typeName)
    local res = setmetatable({pools={}, group=tostring(group), typeName=tostring(typeName)}, ObjectPool)
    return res
end

---回收对象
---@param obj Object
function ObjectPool:recycle(obj)
    obj:reset()
    table.insert(self.pools, obj)
    return self
end

---获取对象
---@return Object
function ObjectPool:fetch()
    if #self.pools > 0 then
        local obj = table.remove(self.pools)
        obj.active = true
        return obj
    end
    local obj = Object:new(nil, self.group, self.typeName)
    return obj
end


--对象管理类
---@class ObjectManager
---@field objectsAio table<any, Object>
---@field objectPools table
local ObjectManager = {objectsAio={}}
ObjectManager.__index = ObjectManager

---创建
---@return ObjectManager
function ObjectManager:new()
    local res = setmetatable({objectsAio={}, objectPools={}}, ObjectManager)
    return res
end

---获得对应类别的对象池
---@param group any
---@param typeName any
---@return ObjectPool
function ObjectManager:getPool(group, typeName)
    group = tostring(group)
    typeName = tostring(typeName)
    local groupPools = EnsureTableValue(self.objectPools, group)
    local pool = groupPools[typeName]
    if pool ~= nil then
        return pool
    end
    pool = ObjectPool:new(group, typeName)
    groupPools[typeName] = pool
    return pool
end

---添加对象
---@return Object
function ObjectManager:addObj(id, group, typeName)
    local pool = self:getPool(group, typeName)
    local obj = pool:fetch()
    obj.id = id

    self.objectsAio[obj.id] = obj
    return obj
end


---移除
---@param obj Object
---@return ObjectManager
function ObjectManager:removeObj(obj)
    obj:destory()
    local pool = self:getPool(obj.group, obj.typeName)
    pool:recycle(obj)
    return self
end

function ObjectManager:update(deltaTime)
    for id, obj in pairs(self.objectsAio) do
        if obj.active then
            obj:update(deltaTime)
            
        else
            self:removeObj(obj)
        end
    end
end


return {ObjectManager = ObjectManager, Object=Object, ObjState=ObjState, TimeCfg=TimeCfg, FuncCfg=FuncCfg, StateMachine=StateMachine,
StateMachineTime=StateMachineTime}