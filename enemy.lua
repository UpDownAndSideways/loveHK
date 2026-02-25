--
-- enemy.lua — Static enemy that takes damage, flashes, and has knockback
--
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(world, x, y)
    local self = setmetatable({}, Enemy)

    self.world = world
    self.type = "enemy"

    -- Dimensions
    self.w = 32
    self.h = 40

    -- Position & velocity
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0

    -- Stats
    self.maxHP = 5
    self.hp = self.maxHP
    self.alive = true

    -- Knockback
    self.knockbackFriction = 800
    self.gravity = 1200
    self.maxFallSpeed = 600

    -- Flash on hit
    self.flashTimer = 0
    self.flashDuration = 0.12

    -- Shake on hit
    self.shakeTimer = 0
    self.shakeDuration = 0.1
    self.shakeIntensity = 3

    -- Visual
    self.color = {0.8, 0.25, 0.25}
    self.hpBarWidth = 40

    -- Register with bump
    world:add(self, self.x, self.y, self.w, self.h)

    return self
end

function Enemy.collisionFilter(item, other)
    if other.type == "tile" then
        return "slide"
    end
    return nil
end

function Enemy:onHit(slashDir, damage)
    if not self.alive then return end

    self.hp = self.hp - (damage or 1)
    self.flashTimer = self.flashDuration
    self.shakeTimer = self.shakeDuration

    -- Knockback from slash direction
    local kb = 200
    self.vx = slashDir.x * kb
    if slashDir.y ~= 0 then
        self.vy = slashDir.y * kb * 0.5
    end

    if self.hp <= 0 then
        self.hp = 0
        self.alive = false
    end
end

function Enemy:update(dt)
    if not self.alive then return end

    -- Flash timer
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end

    -- Shake timer
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
    end

    -- Apply gravity
    self.vy = self.vy + self.gravity * dt
    if self.vy > self.maxFallSpeed then
        self.vy = self.maxFallSpeed
    end

    -- Apply knockback friction
    if self.vx > 0 then
        self.vx = math.max(0, self.vx - self.knockbackFriction * dt)
    elseif self.vx < 0 then
        self.vx = math.min(0, self.vx + self.knockbackFriction * dt)
    end

    -- Move via bump
    local goalX = self.x + self.vx * dt
    local goalY = self.y + self.vy * dt

    local actualX, actualY, cols, len = self.world:move(
        self, goalX, goalY, Enemy.collisionFilter
    )

    self.x = actualX
    self.y = actualY

    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            self.vy = 0
        end
        if col.normal.y == 1 then
            self.vy = 0
        end
        if col.normal.x ~= 0 then
            self.vx = 0
        end
    end
end

function Enemy:draw()
    if not self.alive then return end

    -- Shake offset
    local ox, oy = 0, 0
    if self.shakeTimer > 0 then
        ox = (math.random() - 0.5) * 2 * self.shakeIntensity
        oy = (math.random() - 0.5) * 2 * self.shakeIntensity
    end

    -- Body
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(self.color)
    end
    love.graphics.rectangle("fill", self.x + ox, self.y + oy, self.w, self.h)

    -- Outline
    love.graphics.setColor(1, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", self.x + ox, self.y + oy, self.w, self.h)

    -- Eyes
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", self.x + ox + 8, self.y + oy + 10, 5, 5)
    love.graphics.rectangle("fill", self.x + ox + 19, self.y + oy + 10, 5, 5)

    -- HP Bar background
    local barX = self.x + self.w / 2 - self.hpBarWidth / 2
    local barY = self.y - 12
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, barY, self.hpBarWidth, 5)

    -- HP Bar fill
    local hpRatio = self.hp / self.maxHP
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, barY, self.hpBarWidth * hpRatio, 5)

    -- HP Bar outline
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", barX, barY, self.hpBarWidth, 5)
end

return Enemy
