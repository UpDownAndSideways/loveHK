--
-- particles.lua — Particle effects manager for visual juice
--
local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.systems = {}

    ---------------------------------------------------------
    -- DUST PARTICLES (jump / land / run)
    ---------------------------------------------------------
    local dustImg = Particles._createCircleImage(3)
    self.dustSystem = love.graphics.newParticleSystem(dustImg, 64)
    self.dustSystem:setParticleLifetime(0.2, 0.5)
    self.dustSystem:setEmissionRate(0)
    self.dustSystem:setSizes(0.8, 0.3)
    self.dustSystem:setColors(
        0.7, 0.7, 0.8, 0.6,
        0.5, 0.5, 0.6, 0
    )
    self.dustSystem:setSpeed(20, 80)
    self.dustSystem:setLinearAcceleration(-20, -40, 20, -10)
    self.dustSystem:setSpread(math.pi * 0.8)
    self.dustSystem:setDirection(-math.pi / 2) -- upward
    table.insert(self.systems, self.dustSystem)

    ---------------------------------------------------------
    -- IMPACT SPARKS (combat hit)
    ---------------------------------------------------------
    local sparkImg = Particles._createCircleImage(2)
    self.sparkSystem = love.graphics.newParticleSystem(sparkImg, 48)
    self.sparkSystem:setParticleLifetime(0.1, 0.35)
    self.sparkSystem:setEmissionRate(0)
    self.sparkSystem:setSizes(1.2, 0.2)
    self.sparkSystem:setColors(
        1, 1, 1, 1,
        0.8, 0.9, 1, 0.6,
        0.4, 0.5, 0.8, 0
    )
    self.sparkSystem:setSpeed(100, 300)
    self.sparkSystem:setLinearAcceleration(-50, -50, 50, 50)
    self.sparkSystem:setSpread(math.pi * 2)
    table.insert(self.systems, self.sparkSystem)

    ---------------------------------------------------------
    -- DASH TRAIL (ghost after-image particles)
    ---------------------------------------------------------
    local trailImg = Particles._createRectImage(6, 16)
    self.dashSystem = love.graphics.newParticleSystem(trailImg, 32)
    self.dashSystem:setParticleLifetime(0.08, 0.25)
    self.dashSystem:setEmissionRate(0)
    self.dashSystem:setSizes(1.0, 0.3)
    self.dashSystem:setColors(
        0.5, 0.7, 1, 0.6,
        0.3, 0.4, 0.8, 0
    )
    self.dashSystem:setSpeed(5, 20)
    self.dashSystem:setSpread(math.pi * 0.3)
    table.insert(self.systems, self.dashSystem)

    ---------------------------------------------------------
    -- AMBIENT DUST (floating motes in the air)
    ---------------------------------------------------------
    local moteImg = Particles._createCircleImage(2)
    self.ambientSystem = love.graphics.newParticleSystem(moteImg, 80)
    self.ambientSystem:setParticleLifetime(3, 7)
    self.ambientSystem:setEmissionRate(5)
    self.ambientSystem:setEmissionArea("uniform", 420, 300)
    self.ambientSystem:setSizes(0.3, 0.6, 0.3)
    self.ambientSystem:setColors(
        0.6, 0.6, 0.8, 0,
        0.6, 0.6, 0.8, 0.25,
        0.6, 0.6, 0.8, 0.25,
        0.6, 0.6, 0.8, 0
    )
    self.ambientSystem:setSpeed(3, 12)
    self.ambientSystem:setLinearAcceleration(-2, -5, 2, 2)
    self.ambientSystem:setDirection(-math.pi / 2)
    self.ambientSystem:setSpread(math.pi * 0.6)
    self.ambientSystem:setPosition(400, 300)
    table.insert(self.systems, self.ambientSystem)

    ---------------------------------------------------------
    -- SLASH ARC (white swoosh particles along the arc)
    ---------------------------------------------------------
    local arcImg = Particles._createCircleImage(2)
    self.slashSystem = love.graphics.newParticleSystem(arcImg, 32)
    self.slashSystem:setParticleLifetime(0.05, 0.15)
    self.slashSystem:setEmissionRate(0)
    self.slashSystem:setSizes(1.5, 0.4)
    self.slashSystem:setColors(
        1, 1, 1, 0.9,
        0.8, 0.85, 1, 0
    )
    self.slashSystem:setSpeed(40, 120)
    self.slashSystem:setSpread(math.pi * 0.5)
    table.insert(self.systems, self.slashSystem)

    return self
end

-- Helper: create a small filled circle image for particles
function Particles._createCircleImage(radius)
    local size = radius * 2 + 2
    local canvas = love.graphics.newCanvas(size, size)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", size / 2, size / 2, radius)
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

-- Helper: create a small filled rectangle image for dash trail
function Particles._createRectImage(w, h)
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

function Particles:update(dt)
    for _, sys in ipairs(self.systems) do
        sys:update(dt)
    end
end

---------------------------------------------------------
-- Emission triggers
---------------------------------------------------------

function Particles:emitDust(x, y, count)
    self.dustSystem:setPosition(x, y)
    self.dustSystem:emit(count or 6)
end

function Particles:emitLandDust(x, y)
    self.dustSystem:setPosition(x, y)
    self.dustSystem:setDirection(-math.pi / 2)
    self.dustSystem:setSpread(math.pi * 0.9)
    self.dustSystem:setSpeed(30, 100)
    self.dustSystem:emit(10)
    -- Reset
    self.dustSystem:setSpeed(20, 80)
    self.dustSystem:setSpread(math.pi * 0.8)
end

function Particles:emitRunDust(x, y, facing)
    self.dustSystem:setPosition(x, y)
    -- Emit behind the player
    self.dustSystem:setDirection(facing == 1 and math.pi or 0)
    self.dustSystem:setSpread(math.pi * 0.4)
    self.dustSystem:setSpeed(15, 50)
    self.dustSystem:emit(2)
    -- Reset
    self.dustSystem:setDirection(-math.pi / 2)
    self.dustSystem:setSpeed(20, 80)
    self.dustSystem:setSpread(math.pi * 0.8)
end

function Particles:emitSparks(x, y, count)
    self.sparkSystem:setPosition(x, y)
    self.sparkSystem:emit(count or 12)
end

function Particles:emitDashTrail(x, y, facing)
    self.dashSystem:setPosition(x, y)
    self.dashSystem:setDirection(facing == 1 and math.pi or 0)
    self.dashSystem:emit(3)
end

function Particles:emitSlashArc(x, y, dirX, dirY)
    self.slashSystem:setPosition(x, y)
    local angle = math.atan2(dirY, dirX)
    self.slashSystem:setDirection(angle)
    self.slashSystem:emit(8)
end

function Particles:draw()
    love.graphics.setColor(1, 1, 1, 1)
    for _, sys in ipairs(self.systems) do
        love.graphics.draw(sys)
    end
end

return Particles
