---@class TimeCfg 时间配置类
local TimeCfg = {totalTime=nil, cycleTime=nil, initDelay=nil, numLimit=nil}

---创建时间配置类
---@param initDelay number?
---@param totalTime number?
---@param cycleTime number?
---@param numLimit number?
---@return TimeCfg
function TimeCfg:new(initDelay, totalTime, cycleTime, numLimit)
    self.initDelay = initDelay
    self.totalTime = totalTime
    self.cycleTime = cycleTime
    self.numLimit = numLimit
    return self
end

---@class FuncCfg
local FuncCfg = {startFunc=nil, endFunc=nil, cycleStartFunc=nil, actionStartFunc=nil, actionUpdateFunc=nil}

function FuncCfg:new(startFunc, endFunc, cycleStartFunc, actionStartFunc, actionUpdateFunc)
    self.startFunc = startFunc
    self.endFunc = endFunc
    self.cycleStartFunc = cycleStartFunc
    self.actionStartFunc = actionStartFunc
    self.actionUpdateFunc = actionUpdateFunc
    return self
end

---@class ObjState 状态类
local ObjState = {name="", timeCfg=nil, funcCfg=nil}
ObjState.__index = ObjState

function ObjState:new(name)
    local res = {}
    res.name = name
    setmetatable(res, ObjState)
    return res
end

--设置时间参数
function ObjState:SetTimeCfg(timeCfg)
    self.timeCfg = timeCfg
    return self
end

--设置时间节点的回调函数
---comment
---@param funcCfg FuncCfg
---@return ObjState
function ObjState:SetFunc(funcCfg)
    self.funcCfg = funcCfg
    return self
end

--状态机
---@class StateMachine
local StateMachine = {state=nil, nextState=nil, conditionFunc=nil}

---创建状态机
---@param state ObjState
---@param nextState ObjState
---@param conditionFunc function(ObjState, ObjState, number)
---@return StateMachine
function StateMachine:new(state, nextState, conditionFunc)
    self.state = state
    self.nextState = nextState
    self.conditionFunc = conditionFunc
    return self
end

--对象类
---@class Object
local Object = {states={}, id=nil, group=nil, type=nil}
Object.__index = Object

---comment
---@param id string
---@param group number|string
---@param type number|string
---@return Object
function Object:new(id, group, type)
    local obj = {}
    obj.id = id
    obj.group = group
    obj.type = type
    setmetatable(obj, Object)
    return obj
end

-- setmetatable(Object, Object)

---comment
---@param name string
---@param timeCfg TimeCfg
---@param funcCfg FuncCfg
---@return Object
function Object:AddState(name, timeCfg, funcCfg)
    self.states[name] = ObjState:new(name):SetTimeCfg(timeCfg):SetFunc(funcCfg)
    return self
end

--对象管理类
local ObjectManager = {objectsAio={}}

function ObjectManager:AddObj(obj)
    self.objectsAio[obj.id] = obj
    return self
end


return {ObjectManager = ObjectManager, Object=Object, ObjState=ObjState, TimeCfg=TimeCfg, FuncCfg=FuncCfg}