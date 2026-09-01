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

-- 实体数据存储
Deer.EntityData = {}

-- 获取实体数据
function Deer:GetData(entity)
    local key = entity.InitSeed
    if not Deer.EntityData[key] then
        Deer.EntityData[key] = { 
            stateTimer = 0, 
            targetAngle = 0,
            stateCooldown = 0  -- 状态转换冷却
        }
    end
    return Deer.EntityData[key]
end

-- 从动画获取当前状态
function Deer:GetCurrentState(entity)
    local animName = entity:GetSprite():GetAnimation()
    return Deer.AnimToState[animName] or Deer.State.STAND
end

-- 播放动画（根据方向选择左右动画）
function Deer:PlayAnimation(entity, animName)
    local sprite = entity:GetSprite()
    local vx = entity.Velocity.X
    
    if vx < 0 or (vx == 0 and sprite:GetAnimation():match("_l$")) then
        sprite:Play(animName .. "_l", false)
    else
        sprite:Play(animName, false)
    end
end

-- 状态转换函数
function Deer:ChangeState(entity, newState)
    local data = Deer:GetData(entity)
    local currentState = Deer:GetCurrentState(entity)
    
    if currentState == newState then
        return
    end
    
    -- 只有切换到walk或run时才检查冷却
    if (newState == Deer.State.WALK or newState == Deer.State.RUN) and data.stateCooldown > 0 then
        return
    end
    
    -- 过渡状态必须等待动画完成
    if Deer.TransitionStates[currentState] then
        local sprite = entity:GetSprite()
        if not sprite:IsFinished(sprite:GetAnimation()) then
            return
        end
    end
    
    data.stateTimer = 0
    
    -- 只在切换到walk或run时设置冷却
    if newState == Deer.State.WALK or newState == Deer.State.RUN then
        data.stateCooldown = 60
    end
    
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
    local speed = entity.Velocity:Length()
    
    -- 只有速度足够低才能切换到移动状态
    if speed < 0.2 then
        if rand <= 45 then
            Deer:ChangeState(entity, Deer.State.WALK)
        elseif rand <= 60 then
            Deer:ChangeState(entity, Deer.State.RUN)
        elseif rand <= 65 then
            Deer:ChangeState(entity, Deer.State.LOWER_HEAD)
        elseif rand <= 70 then
            Deer:ChangeState(entity, Deer.State.WAG_TAIL)
        elseif rand <= 80 then
            Deer:ChangeState(entity, Deer.State.POOP)
        elseif rand <= 82 then
            Deer:ChangeState(entity, Deer.State.PARTY)
        elseif rand <= 87 then
            Deer:ChangeState(entity, Deer.State.LIE_DOWN)
        end
    end
end

-- Walk
function Deer:Enter_walk(entity, data)
    local angle = math.random(0,360)
    data.targetAngle = angle
    entity.Velocity = Vector.FromAngle(angle) * 1.2
    Deer:PlayAnimation(entity, "walk")
end

function Deer:Update_walk(entity, data)
    -- 在目标角度上加上小的随机修正
    local angleCorrection = (math.random() - 0.5) * 0.2
    data.targetAngle = data.targetAngle + angleCorrection
    local targetVelocity = Vector.FromAngle(data.targetAngle) * 1.2
    entity.Velocity = entity.Velocity * 0.8 + targetVelocity * 0.1
    
    -- 需要至少移动60帧（1秒）才能切换状态
    if data.stateTimer < 60 then
        return
    end
    
    local rand = math.random(1, 100)
    
    if rand <= 2 and entity.Velocity:Length() < 0.2 then
        Deer:ChangeState(entity, Deer.State.STAND)
    elseif rand <= 30 then
        Deer:ChangeState(entity, Deer.State.RUN)
    end
end

-- Run
function Deer:Enter_run(entity, data)
    local angle = math.random(0,360)
    data.targetAngle = angle
    entity.Velocity = Vector.FromAngle(angle) * 2.2
    Deer:PlayAnimation(entity, "run")
end

function Deer:Update_run(entity, data)
    -- 在目标角度上加上小的随机修正
    local angleCorrection = (math.random() - 0.5)
    data.targetAngle = data.targetAngle + angleCorrection
    local targetVelocity = Vector.FromAngle(data.targetAngle) * 2.2
    entity.Velocity = entity.Velocity * 0.8 + targetVelocity * 0.1

    -- 需要至少移动60帧（1秒）才能切换状态
    if data.stateTimer < 60 then
        return
    end

    local rand = math.random(1, 100)
  
    if rand <= 25 then
        Deer:ChangeState(entity, Deer.State.WALK)
    elseif rand <= 28 then
        Deer:ChangeState(entity, Deer.State.STAND)
    end
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
    
    -- 更新冷却时间
    if data.stateCooldown > 0 then
        data.stateCooldown = data.stateCooldown - 1
    end
    
    local currentState = Deer:GetCurrentState(entity)
    
    local updateFunc = Deer["Update_" .. currentState]
    if updateFunc then
        updateFunc(self, entity, data)
    end
    
    -- 更新动画方向
    if entity.Velocity:Length() > 0.01 then
        local sprite = entity:GetSprite()
        local currentAnim = sprite:GetAnimation()
        local isAnimLeft = currentAnim:match("_l$") ~= nil
        local shouldBeLeft = entity.Velocity.X < 0
        
        if isAnimLeft ~= shouldBeLeft then
            local baseName = currentAnim:gsub("_l$", "")
            sprite:Play(shouldBeLeft and (baseName .. "_l") or baseName, false)
        end
    end
    local entities = Isaac.GetRoomEntities()
    for _, entitynpc in pairs(entities) do
        if entitynpc:IsEnemy() and entitynpc.Type ~= TBoN.Entity.Table.Info.Type.Deer then
            entitynpc.Target = entity
        end
    end
end

-- ============ 清理函数 ============

function Deer:Remove(entity)
    local key = entity.InitSeed
    Deer.EntityData[key] = nil
end

return Deer
