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
---comment
---@param funcCfg FuncCfg
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
---@field states table
---@field id any
---@field group any
---@field type any
local Object = {}
Object.__index = Object

---创建
---@param id any
---@param group any
---@param type any
---@return Object
function Object:new(id, group, type)
    local res = setmetatable({states={}}, Object)
    res.id = id
    res.group = group
    res.type = type
    return res
end

-- setmetatable(Object, Object)

---comment
---@param name string
---@param timeCfg TimeCfg?
---@param funcCfg FuncCfg?
---@return Object
function Object:addState(name, timeCfg, funcCfg)
    self.states[name] = ObjState:new(name):setTimeCfg(timeCfg):setFunc(funcCfg)
    return self
end

--对象管理类
---@class ObjectManager
local ObjectManager = {objectsAio={}}
ObjectManager.__index = ObjectManager

---comment
---@return ObjectManager
function ObjectManager:new()
    local res = setmetatable({objectsAio={}}, ObjectManager)
    return res
end

function ObjectManager:addObj(obj)
    self.objectsAio[obj.id] = obj
    return self
end


return {ObjectManager = ObjectManager, Object=Object, ObjState=ObjState, TimeCfg=TimeCfg, FuncCfg=FuncCfg}