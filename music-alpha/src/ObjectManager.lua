require("YmUtils")

---@class TimeCfg 时间配置类
local TimeCfg = {totalTime=nil, cycleTime=nil, initDelay=nil, numLimit=nil}
TimeCfg.__index = TimeCfg

---创建时间配置类
---@param initDelay number?
---@param totalTime number?
---@param cycleTime number?
---@param numLimit number?
---@return TimeCfg
function TimeCfg:new(initDelay, totalTime, cycleTime, numLimit)
    local res = setmetatable({}, TimeCfg)
    res.initDelay = initDelay
    res.totalTime = totalTime
    res.cycleTime = cycleTime
    res.numLimit = numLimit
    return res
end

---@class FuncCfg
local FuncCfg = {startFunc=nil, endFunc=nil, cycleStartFunc=nil, actionStartFunc=nil, actionUpdateFunc=nil}
FuncCfg.__index = FuncCfg

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
local ObjState = {name="", timeCfg=nil, funcCfg=nil}
ObjState.__index = ObjState

---创建
---@param name any
---@return ObjState
function ObjState:new(name)
    local res = setmetatable({}, ObjState)
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

--状态机
---@class StateMachine
local StateMachine = {state=nil, nextState=nil, conditionFunc=nil}
StateMachine.__index = StateMachine

---创建状态机
---@param state ObjState
---@param nextState ObjState
---@param conditionFunc function(ObjState, ObjState, number)
---@return StateMachine
function StateMachine:new(state, nextState, conditionFunc)
    local res = setmetatable({}, StateMachine)
    res.state = state
    res.nextState = nextState
    res.conditionFunc = conditionFunc
    return res
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
    local res = setmetatable({states={}, active=true, id=id, group=tostring(group), typeName=tostring(typeName)}, Object)
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
end

function Object:destory()
    if self.destoryFunc then
        self.destoryFunc(self)
    end
end


---添加状态
---@param name string
---@param timeCfg TimeCfg?
---@param funcCfg FuncCfg?
---@return Object
function Object:addState(name, timeCfg, funcCfg)
    self.states[name] = ObjState:new(name):setTimeCfg(timeCfg):setFunc(funcCfg)
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


return {ObjectManager = ObjectManager, Object=Object, ObjState=ObjState, TimeCfg=TimeCfg, FuncCfg=FuncCfg, StateMachine=StateMachine}