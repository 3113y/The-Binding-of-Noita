-- Deer Entity State Machine Logic
-- 鹿实体状态机逻辑

local Deer = {}

-- 状态枚举
Deer.State = {
    STAND = "stand",
    WALK = "walk",
    RUN = "run",
    LOWER_HEAD = "lower_head",
    EAT = "eat",
    RAISE_HEAD = "raise_head",
    WAG_TAIL = "wag_tail",
    POOP = "poop",
    PARTY = "party",
    LIE_DOWN = "lie_down",
    SLEEP = "sleep",
    RISE_UP = "rise_up"
}

-- 动画名到状态的哈希映射
Deer.AnimToState = {
    ["stand"] = Deer.State.STAND,
    ["stand_l"] = Deer.State.STAND,
    ["walk"] = Deer.State.WALK,
    ["walk_l"] = Deer.State.WALK,
    ["run"] = Deer.State.RUN,
    ["run_l"] = Deer.State.RUN,
    ["lower_head"] = Deer.State.LOWER_HEAD,
    ["lower_head_l"] = Deer.State.LOWER_HEAD,
    ["eat"] = Deer.State.EAT,
    ["eat_l"] = Deer.State.EAT,
    ["raise_head"] = Deer.State.RAISE_HEAD,
    ["raise_head_l"] = Deer.State.RAISE_HEAD,
    ["wag_tail"] = Deer.State.WAG_TAIL,
    ["wag_tail_l"] = Deer.State.WAG_TAIL,
    ["poop"] = Deer.State.POOP,
    ["poop_l"] = Deer.State.POOP,
    ["party"] = Deer.State.PARTY,
    ["party_l"] = Deer.State.PARTY,
    ["lie_down"] = Deer.State.LIE_DOWN,
    ["lie_down_l"] = Deer.State.LIE_DOWN,
    ["sleep"] = Deer.State.SLEEP,
    ["sleep_l"] = Deer.State.SLEEP,
    ["rise_up"] = Deer.State.RISE_UP,
    ["rise_up_l"] = Deer.State.RISE_UP
}

-- 过渡状态（需要等待动画完成）
Deer.TransitionStates = {
    [Deer.State.LOWER_HEAD] = true,
    [Deer.State.RAISE_HEAD] = true,
    [Deer.State.LIE_DOWN] = true,
    [Deer.State.RISE_UP] = true
}

-- 实体数据存储（只存储必要的计时信息）
Deer.EntityData = {}

-- 初始化鹿实体
function Deer:Init(entity)
    local key = entity.InitSeed
    
    Deer.EntityData[key] = {
        stateTimer = 0,
        lastStateChangeFrame = 0
    }
    
    return Deer.EntityData[key]
end

-- 获取实体数据
function Deer:GetData(entity)
    local key = entity.InitSeed
    if not Deer.EntityData[key] then
        return Deer:Init(entity)
    end
    return Deer.EntityData[key]
end

-- 从动画获取当前状态
function Deer:GetCurrentState(entity)
    local animName = entity:GetSprite():GetAnimation()
    return Deer.AnimToState[animName] or Deer.State.STAND
end

-- 获取速度大小
function Deer:GetSpeed(entity)
    return entity.Velocity:Length()
end

-- 获取方向（1为右，-1为左）
function Deer:GetDirection(entity)
    if entity.Velocity.X > 0 then
        return 1
    elseif entity.Velocity.X < 0 then
        return -1
    else
        -- 速度为0时，通过当前动画判断
        local animName = entity:GetSprite():GetAnimation()
        return animName:match("_l$") and -1 or 1
    end
end

-- 播放动画（根据方向选择左右动画）
function Deer:PlayAnimation(entity, animName)
    local sprite = entity:GetSprite()
    local direction = Deer:GetDirection(entity)
    
    if direction < 0 then
        sprite:Play(animName .. "_l", false)
    else
        sprite:Play(animName, false)
    end
end

-- 检查是否可以切换状态
function Deer:CanChangeState(entity, data)
    local currentState = Deer:GetCurrentState(entity)
    
    -- 过渡状态必须等待动画完成
    if Deer.TransitionStates[currentState] then
        local sprite = entity:GetSprite()
        return sprite:IsFinished(sprite:GetAnimation())
    end
    
    -- 非过渡状态需要间隔至少60帧
    local currentFrame = Game():GetFrameCount()
    return (currentFrame - data.lastStateChangeFrame) >= 60
end

-- 状态转换函数
function Deer:ChangeState(entity, newState)
    local data = Deer:GetData(entity)
    local currentState = Deer:GetCurrentState(entity)
    
    if currentState == newState then
        return
    end
    
    if not Deer:CanChangeState(entity, data) then
        return
    end
    
    local exitFunc = Deer["Exit_" .. currentState]
    if exitFunc then
        exitFunc(self, entity, data)
    end
    
    data.stateTimer = 0
    data.lastStateChangeFrame = Game():GetFrameCount()
    
    local enterFunc = Deer["Enter_" .. newState]
    if enterFunc then
        enterFunc(self, entity, data)
    end
end

-- ============ 状态进入/退出函数 ============

-- Stand
function Deer:Enter_stand(entity, data)
    entity.Velocity = Vector(0, 0)
    Deer:PlayAnimation(entity, "stand")
end

function Deer:Update_stand(entity, data)
    local rand = math.random(1, 100)
    
    if rand <= 30 then
        Deer:ChangeState(entity, Deer.State.WALK)
    elseif rand <= 40 then
        Deer:ChangeState(entity, Deer.State.RUN)
    elseif rand <= 50 then
        Deer:ChangeState(entity, Deer.State.LOWER_HEAD)
    elseif rand <= 60 then
        Deer:ChangeState(entity, Deer.State.WAG_TAIL)
    elseif rand <= 70 then
        Deer:ChangeState(entity, Deer.State.POOP)
    elseif rand <= 80 then
        Deer:ChangeState(entity, Deer.State.PARTY)
    elseif rand <= 90 then
        Deer:ChangeState(entity, Deer.State.LIE_DOWN)
    end
end

-- Walk
function Deer:Enter_walk(entity, data)
    local speed = 0.001 + math.random() * 0.699
    local angle = math.random() * math.pi * 2
    entity.Velocity = Vector(math.cos(angle) * speed, math.sin(angle) * speed)
    Deer:PlayAnimation(entity, "walk")
end

function Deer:Update_walk(entity, data)
    local rand = math.random(1, 100)
    
    if rand <= 50 then
        Deer:ChangeState(entity, Deer.State.STAND)
    elseif rand <= 75 then
        Deer:ChangeState(entity, Deer.State.RUN)
    end
end

function Deer:Exit_walk(entity, data)
    entity.Velocity = Vector(0, 0)
end

-- Run
function Deer:Enter_run(entity, data)
    local speed = 0.7 + math.random() * 0.8
    local angle = math.random() * math.pi * 2
    entity.Velocity = Vector(math.cos(angle) * speed, math.sin(angle) * speed)
    Deer:PlayAnimation(entity, "run")
end

function Deer:Update_run(entity, data)
    local rand = math.random(1, 100)
    
    if rand <= 50 then
        Deer:ChangeState(entity, Deer.State.WALK)
    elseif rand <= 75 then
        Deer:ChangeState(entity, Deer.State.STAND)
    end
end

function Deer:Exit_run(entity, data)
    entity.Velocity = Vector(0, 0)
end

-- Lower Head
function Deer:Enter_lower_head(entity, data)
    entity.Velocity = Vector(0, 0)
    Deer:PlayAnimation(entity, "lower_head")
end

function Deer:Update_lower_head(entity, data)
    Deer:ChangeState(entity, Deer.State.EAT)
end

-- Eat
function Deer:Enter_eat(entity, data)
    Deer:PlayAnimation(entity, "eat")
end

function Deer:Update_eat(entity, data)
    local rand = math.random(1, 100)
    if rand <= 5 then
        Deer:ChangeState(entity, Deer.State.RAISE_HEAD)
    end
end

-- Raise Head
function Deer:Enter_raise_head(entity, data)
    Deer:PlayAnimation(entity, "raise_head")
end

function Deer:Update_raise_head(entity, data)
    Deer:ChangeState(entity, Deer.State.STAND)
end

-- Wag Tail
function Deer:Enter_wag_tail(entity, data)
    entity.Velocity = Vector(0, 0)
    Deer:PlayAnimation(entity, "wag_tail")
end

function Deer:Update_wag_tail(entity, data)
    local rand = math.random(1, 100)
    if rand <= 3 then
        Deer:ChangeState(entity, Deer.State.STAND)
    end
end

-- Poop
function Deer:Enter_poop(entity, data)
    entity.Velocity = Vector(0, 0)
    Deer:PlayAnimation(entity, "poop")
end

function Deer:Update_poop(entity, data)
    local rand = math.random(1, 100)
    if rand <= 2 then
        Deer:ChangeState(entity, Deer.State.STAND)
    end
end

-- Party
function Deer:Enter_party(entity, data)
    entity.Velocity = Vector(0, 0)
    Deer:PlayAnimation(entity, "party")
end

function Deer:Update_party(entity, data)
    local rand = math.random(1, 100)
    if rand <= 2 then
        Deer:ChangeState(entity, Deer.State.STAND)
    end
end

-- Lie Down
function Deer:Enter_lie_down(entity, data)
    entity.Velocity = Vector(0, 0)
    Deer:PlayAnimation(entity, "lie_down")
end

function Deer:Update_lie_down(entity, data)
    Deer:ChangeState(entity, Deer.State.SLEEP)
end

-- Sleep
function Deer:Enter_sleep(entity, data)
    Deer:PlayAnimation(entity, "sleep")
end

function Deer:Update_sleep(entity, data)
    local rand = math.random(1, 100)
    if rand <= 1 then
        Deer:ChangeState(entity, Deer.State.RISE_UP)
    end
end

-- Rise Up
function Deer:Enter_rise_up(entity, data)
    Deer:PlayAnimation(entity, "rise_up")
end

function Deer:Update_rise_up(entity, data)
    Deer:ChangeState(entity, Deer.State.STAND)
end

-- ============ 主更新函数（用于MC_NPC_UPDATE回调） ============

function Deer:Update(entity)
    local data = Deer:GetData(entity)
    
    data.stateTimer = data.stateTimer + 1
    
    local currentState = Deer:GetCurrentState(entity)
    local updateFunc = Deer["Update_" .. currentState]
    if updateFunc then
        updateFunc(self, entity, data)
    end
    
    -- 更新动画方向（如果速度改变）
    if Deer:GetSpeed(entity) > 0.01 then
        local sprite = entity:GetSprite()
        local currentAnim = sprite:GetAnimation()
        local currentDirection = Deer:GetDirection(entity)
        
        -- 检查动画方向是否匹配实际方向
        local isAnimLeft = currentAnim:match("_l$") ~= nil
        local shouldBeLeft = currentDirection < 0
        
        if isAnimLeft ~= shouldBeLeft then
            local baseName = currentAnim:gsub("_l$", "")
            if shouldBeLeft then
                sprite:Play(baseName .. "_l", false)
            else
                sprite:Play(baseName, false)
            end
        end
    end
end

-- ============ 清理函数 ============

function Deer:Remove(entity)
    local key = entity.InitSeed
    Deer.EntityData[key] = nil
end

return Deer
