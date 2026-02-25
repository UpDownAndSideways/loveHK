--
-- enemy.lua — Enemy with enhanced visuals: glow, pulse, death particles
--
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(world, x, y, particles)
    local self = setmetatable({}, Enemy)

    self.world = world
    self.type = "enemy"
    self.particles = particles

    -- Dimensions
    self.w = 32
    self.h = 40

    -- Position & velocity
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0

    -- Stats
    self.maxHP = 3
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

    -- Breathing / idle pulse
    self.breathTimer = math.random() * math.pi * 2
    self.breathSpeed = 2

    -- Glow
    self.glowRadius = 0
    self.glowAlpha = 0

    -- Death animation
    self.deathTimer = 0
    self.deathDuration = 0.5
    self.dyingPhase = false

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
    self.glowRadius = 20
    self.glowAlpha = 0.4

    -- Knockback from slash direction
    local kb = 200
    self.vx = slashDir.x * kb
    if slashDir.y ~= 0 then
        self.vy = slashDir.y * kb * 0.5
    end

    if self.hp <= 0 then
        self.hp = 0
        self.dyingPhase = true
        self.deathTimer = self.deathDuration
        -- Death burst particles
        if self.particles then
            self.particles:emitSparks(
                self.x + self.w / 2,
                self.y + self.h / 2,
                24
            )
        end
    end
end

function Enemy:update(dt)
    if not self.alive and not self.dyingPhase then return end

    -- Death animation
    if self.dyingPhase then
        self.deathTimer = self.deathTimer - dt
        if self.deathTimer <= 0 then
            self.dyingPhase = false
            self.alive = false
            if self.world:hasItem(self) then
                self.world:remove(self)
            end
        end
        return
    end

    -- Flash timer
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end

    -- Shake timer
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
    end

    -- Glow fade
    if self.glowRadius > 0 then
        self.glowRadius = self.glowRadius - dt * 40
        self.glowAlpha = self.glowAlpha - dt * 0.8
        if self.glowRadius < 0 then self.glowRadius = 0 end
        if self.glowAlpha < 0 then self.glowAlpha = 0 end
    end

    -- Breathing pulse
    self.breathTimer = self.breathTimer + dt * self.breathSpeed

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
    if not self.alive and not self.dyingPhase then return end

    -- Death fade
    local deathAlpha = 1
    if self.dyingPhase then
        deathAlpha = self.deathTimer / self.deathDuration
    end

    -- Shake offset
    local ox, oy = 0, 0
    if self.shakeTimer > 0 then
        ox = (math.random() - 0.5) * 2 * self.shakeIntensity
        oy = (math.random() - 0.5) * 2 * self.shakeIntensity
    end

    -- Breathing scale
    local breathScale = 1 + math.sin(self.breathTimer) * 0.02
    local cx = self.x + self.w / 2
    local cy = self.y + self.h

    love.graphics.push()
    love.graphics.translate(cx + ox, cy + oy)
    love.graphics.scale(breathScale, breathScale)
    love.graphics.translate(-cx, -cy)

    -- Red glow behind enemy (when hit)
    if self.glowRadius > 0 and self.glowAlpha > 0 then
        love.graphics.setColor(1, 0.3, 0.2, self.glowAlpha * deathAlpha)
        love.graphics.circle("fill",
            self.x + self.w / 2,
            self.y + self.h / 2,
            self.glowRadius
        )
    end

    -- Ambient glow (subtle)
    love.graphics.setColor(0.8, 0.15, 0.1, 0.08 * deathAlpha)
    love.graphics.circle("fill",
        self.x + self.w / 2,
        self.y + self.h / 2,
        30
    )

    -- Body
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1, deathAlpha)
    else
        love.graphics.setColor(
            self.color[1], self.color[2], self.color[3],
            deathAlpha
        )
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Body detail: darker inner area
    love.graphics.setColor(0, 0, 0, 0.15 * deathAlpha)
    love.graphics.rectangle("fill", self.x + 3, self.y + 3, self.w - 6, self.h - 6)

    -- Outline
    love.graphics.setColor(1, 0.3, 0.3, 0.6 * deathAlpha)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    -- Horns/spikes
    love.graphics.setColor(
        self.color[1] * 0.8, self.color[2] * 0.8, self.color[3] * 0.8,
        deathAlpha
    )
    -- Left spike
    love.graphics.polygon("fill",
        self.x + 4, self.y,
        self.x + 8, self.y,
        self.x + 2, self.y - 10
    )
    -- Right spike
    love.graphics.polygon("fill",
        self.x + self.w - 8, self.y,
        self.x + self.w - 4, self.y,
        self.x + self.w - 2, self.y - 10
    )

    -- Eyes
    if not self.dyingPhase then
        love.graphics.setColor(1, 0.9, 0.3, 0.9 * deathAlpha)
        love.graphics.circle("fill", self.x + 10, self.y + 14, 3)
        love.graphics.circle("fill", self.x + 22, self.y + 14, 3)
        -- Eye pupils
        love.graphics.setColor(0.1, 0.05, 0.05, deathAlpha)
        love.graphics.circle("fill", self.x + 10, self.y + 14, 1.5)
        love.graphics.circle("fill", self.x + 22, self.y + 14, 1.5)
    else
        -- X eyes when dying
        love.graphics.setColor(1, 0.9, 0.3, deathAlpha * 0.6)
        local ex1, ey1 = self.x + 10, self.y + 14
        love.graphics.line(ex1 - 2, ey1 - 2, ex1 + 2, ey1 + 2)
        love.graphics.line(ex1 + 2, ey1 - 2, ex1 - 2, ey1 + 2)
        local ex2 = self.x + 22
        love.graphics.line(ex2 - 2, ey1 - 2, ex2 + 2, ey1 + 2)
        love.graphics.line(ex2 + 2, ey1 - 2, ex2 - 2, ey1 + 2)
    end

    love.graphics.pop()

    -- HP Bar (drawn outside transform)
    if self.alive or self.dyingPhase then
        local barX = self.x + self.w / 2 - self.hpBarWidth / 2
        local barY = self.y - 16

        -- Bar background
        love.graphics.setColor(0.1, 0.1, 0.1, 0.7 * deathAlpha)
        love.graphics.rectangle("fill", barX - 1, barY - 1, self.hpBarWidth + 2, 7)

        -- HP fill
        local hpRatio = self.hp / self.maxHP
        -- Color transitions from green to red based on HP
        local r = 1 - hpRatio * 0.5
        local g = hpRatio * 0.7
        love.graphics.setColor(r, g, 0.1, 0.8 * deathAlpha)
        love.graphics.rectangle("fill", barX, barY, self.hpBarWidth * hpRatio, 5)

        -- Bar outline
        love.graphics.setColor(0.6, 0.6, 0.6, 0.3 * deathAlpha)
        love.graphics.rectangle("line", barX, barY, self.hpBarWidth, 5)
    end
end

return Enemy
