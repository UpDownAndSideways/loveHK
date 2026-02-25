--
-- player.lua — Player controller with Hollow Knight-style movement and combat
--
local Player = {}
Player.__index = Player

function Player.new(world, input, timer, x, y)
    local self = setmetatable({}, Player)

    self.world = world
    self.input = input
    self.timer = timer

    -- Dimensions
    self.w = 20
    self.h = 32

    -- Position & velocity
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0

    -- Movement tuning
    self.moveSpeed    = 320     -- max horizontal speed
    self.accel        = 1800    -- ground acceleration
    self.airAccel     = 1700    -- air acceleration
    self.friction     = 3200    -- ground friction (deceleration)
    self.airFriction  = 3200     -- air friction

    -- Gravity & jump tuning
    self.gravity      = 2200
    self.jumpStrength = -720    -- initial jump velocity
    self.maxFallSpeed = 600
    self.shortHopMultiplier = 3 -- gravity multiplier on early release

    -- Coyote time & input buffering
    self.coyoteTime      = 0.1
    self.coyoteTimer     = 0
    self.jumpBufferTime  = 0.1
    self.jumpBufferTimer = 0

    -- Grounded state
    self.grounded = false

    -- Facing direction (1 = right, -1 = left)
    self.facing = 1

    -- Dash
    self.dashSpeed     = 500
    self.dashDuration  = 0.15
    self.dashCooldown  = 0.5
    self.dashTimer     = 0      -- remaining dash time
    self.dashCoolTimer = 0      -- remaining cooldown
    self.isDashing     = false

    -- Invincibility flash during dash
    self.iFrames       = 0
    self.flashTimer    = 0

    -- Attack / Slash
    self.attackCooldown  = 0.3
    self.attackCoolTimer = 0
    self.slashDuration   = 0.1
    self.slashTimer      = 0
    self.slashActive     = false
    self.slashHitbox     = nil  -- bump item for the slash
    self.slashDir        = {x = 1, y = 0} -- direction of current slash

    -- Hit-stop (global freeze frame)
    self.hitStopTimer = 0

    -- Recoil
    self.recoilVx = 0
    self.recoilVy = 0
    self.recoilTimer = 0

    -- Visual
    self.color = {0.85, 0.85, 0.95}
    self.slashColor = {1, 1, 1, 0.8}

    -- Register with bump
    world:add(self, self.x, self.y, self.w, self.h)

    return self
end

-- Collision filter: slide on tiles, cross through enemies
function Player.collisionFilter(item, other)
    if other.type == "tile" then
        return "slide"
    elseif other.type == "enemy" then
        return "cross"
    end
    return nil
end

function Player:update(dt)
    -- Hit-stop: freeze everything
    if self.hitStopTimer > 0 then
        self.hitStopTimer = self.hitStopTimer - dt
        return
    end

    local input = self.input
    input:update()

    -- Recoil countdown
    if self.recoilTimer > 0 then
        self.recoilTimer = self.recoilTimer - dt
        if self.recoilTimer <= 0 then
            self.recoilVx = 0
            self.recoilVy = 0
        end
    end

    -- Dash cooldown
    if self.dashCoolTimer > 0 then
        self.dashCoolTimer = self.dashCoolTimer - dt
    end

    -- iFrames countdown
    if self.iFrames > 0 then
        self.iFrames = self.iFrames - dt
        self.flashTimer = self.flashTimer + dt
    end

    -- Attack cooldown
    if self.attackCoolTimer > 0 then
        self.attackCoolTimer = self.attackCoolTimer - dt
    end

    -------------------------------------------------------
    -- DASH LOGIC
    -------------------------------------------------------
    if self.isDashing then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.isDashing = false
            self.vx = self.facing * self.moveSpeed * 0.5 -- exit momentum
            self.vy = 0
        else
            -- During dash: fixed horizontal, zero vertical (ignore gravity)
            self.vx = self.facing * self.dashSpeed
            self.vy = 0
        end
    else
        -- Start dash
        if input:pressed('dash') and self.dashCoolTimer <= 0 then
            self.isDashing = true
            self.dashTimer = self.dashDuration
            self.dashCoolTimer = self.dashCooldown
            self.iFrames = self.dashDuration
            self.flashTimer = 0
            self.vx = self.facing * self.dashSpeed
            self.vy = 0
        end
    end

    -------------------------------------------------------
    -- HORIZONTAL MOVEMENT (skip if dashing)
    -------------------------------------------------------
    if not self.isDashing then
        local moveX = 0
        if input:down('right') then moveX = moveX + 1 end
        if input:down('left')  then moveX = moveX - 1 end

        if moveX ~= 0 then
            self.facing = moveX
            local accel = self.grounded and self.accel or self.airAccel
            self.vx = self.vx + moveX * accel * dt
            -- Clamp
            if self.vx >  self.moveSpeed then self.vx =  self.moveSpeed end
            if self.vx < -self.moveSpeed then self.vx = -self.moveSpeed end
        else
            -- Apply friction
            local fric = self.grounded and self.friction or self.airFriction
            if self.vx > 0 then
                self.vx = math.max(0, self.vx - fric * dt)
            elseif self.vx < 0 then
                self.vx = math.min(0, self.vx + fric * dt)
            end
        end
    end

    -------------------------------------------------------
    -- GRAVITY & VARIABLE JUMP (skip if dashing)
    -------------------------------------------------------
    if not self.isDashing then
        local grav = self.gravity
        -- SHORT HOP: if rising and jump released, increase gravity
        if not input:down('jump') and self.vy < 0 then
            grav = grav * self.shortHopMultiplier
        end
        self.vy = self.vy + grav * dt
        -- Cap fall speed
        if self.vy > self.maxFallSpeed then
            self.vy = self.maxFallSpeed
        end
    end

    -------------------------------------------------------
    -- COYOTE TIME
    -------------------------------------------------------
    if self.grounded then
        self.coyoteTimer = self.coyoteTime
    else
        self.coyoteTimer = self.coyoteTimer - dt
    end

    -------------------------------------------------------
    -- INPUT BUFFERING
    -------------------------------------------------------
    if input:pressed('jump') then
        self.jumpBufferTimer = self.jumpBufferTime
    else
        self.jumpBufferTimer = self.jumpBufferTimer - dt
    end

    -------------------------------------------------------
    -- JUMP EXECUTION
    -------------------------------------------------------
    if self.jumpBufferTimer > 0 and self.coyoteTimer > 0 and not self.isDashing then
        self.vy = self.jumpStrength
        self.jumpBufferTimer = 0
        self.coyoteTimer = 0
        self.grounded = false
    end

    -------------------------------------------------------
    -- APPLY RECOIL
    -------------------------------------------------------
    local totalVx = self.vx + self.recoilVx
    local totalVy = self.vy + self.recoilVy

    -------------------------------------------------------
    -- MOVE VIA BUMP
    -------------------------------------------------------
    local goalX = self.x + totalVx * dt
    local goalY = self.y + totalVy * dt

    local actualX, actualY, cols, len = self.world:move(
        self, goalX, goalY, Player.collisionFilter
    )

    self.x = actualX
    self.y = actualY

    -- Ground detection from collisions
    self.grounded = false
    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            self.grounded = true
            self.vy = 0
        end
        if col.normal.y == 1 then
            -- Bonked head on ceiling
            self.vy = 0
        end
        if col.normal.x ~= 0 then
            self.vx = 0
        end
    end

    -------------------------------------------------------
    -- ATTACK / SLASH
    -------------------------------------------------------
    if input:pressed('attack') and self.attackCoolTimer <= 0 and not self.isDashing then
        self:startSlash()
    end

    -- Update slash hitbox lifetime
    if self.slashActive then
        self.slashTimer = self.slashTimer - dt
        if self.slashTimer <= 0 then
            self:endSlash()
        end
    end

    -- Timer updates
    self.timer:update(dt)
end

function Player:startSlash()
    self.attackCoolTimer = self.attackCooldown
    self.slashActive = true
    self.slashTimer = self.slashDuration

    -- Determine slash direction based on held keys
    local slashW, slashH, slashX, slashY
    if self.input:down('up') then
        -- Slash up
        self.slashDir = {x = 0, y = -1}
        slashW = 30
        slashH = 24
        slashX = self.x + self.w / 2 - slashW / 2
        slashY = self.y - slashH
    elseif self.input:down('down') and not self.grounded then
        -- Slash down (only in air)
        self.slashDir = {x = 0, y = 1}
        slashW = 30
        slashH = 24
        slashX = self.x + self.w / 2 - slashW / 2
        slashY = self.y + self.h
    else
        -- Slash horizontal (facing direction)
        self.slashDir = {x = self.facing, y = 0}
        slashW = 32
        slashH = 20
        if self.facing == 1 then
            slashX = self.x + self.w
        else
            slashX = self.x - slashW
        end
        slashY = self.y + self.h / 2 - slashH / 2
    end

    self.slashHitbox = {
        type = "slash",
        owner = self,
        dir = self.slashDir,
        x = slashX, y = slashY,
        w = slashW, h = slashH,
    }
    self.world:add(self.slashHitbox, slashX, slashY, slashW, slashH)

    -- Query for enemies in the slash area
    local items, len = self.world:queryRect(slashX, slashY, slashW, slashH, function(item)
        return item.type == "enemy"
    end)

    for i = 1, len do
        local enemy = items[i]
        if enemy.onHit then
            enemy:onHit(self.slashDir, 1)
        end
        -- Recoil player away from enemy (or up if down-slashing)
        self:applyRecoil(self.slashDir)
        -- Hit-stop
        self:triggerHitStop(0.05)
    end
end

function Player:endSlash()
    if self.slashHitbox and self.world:hasItem(self.slashHitbox) then
        self.world:remove(self.slashHitbox)
    end
    self.slashHitbox = nil
    self.slashActive = false
end

function Player:applyRecoil(slashDir)
    local recoilStrength = 250
    if slashDir.y == 1 then
        -- Down-slash: pogo bounce upward
        self.vy = -350
        self.recoilVy = 0
        self.recoilVx = 0
    elseif slashDir.y == -1 then
        -- Up-slash: slight downward push
        self.recoilVy = recoilStrength * 0.3
        self.recoilVx = 0
    else
        -- Horizontal slash: push player away
        self.recoilVx = -slashDir.x * recoilStrength
        self.recoilVy = 0
    end
    self.recoilTimer = 0.15
end

function Player:triggerHitStop(duration)
    self.hitStopTimer = duration
end

function Player:draw()
    -- Flash effect during iFrames
    if self.iFrames > 0 then
        if math.floor(self.flashTimer * 30) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.3)
        else
            love.graphics.setColor(self.color)
        end
    else
        love.graphics.setColor(self.color)
    end

    -- Draw player body
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Draw player outline
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    -- Draw eyes (facing direction indicator)
    love.graphics.setColor(0.2, 0.2, 0.3)
    local eyeX = self.x + self.w / 2 + self.facing * 3
    local eyeY = self.y + 8
    love.graphics.rectangle("fill", eyeX - 2, eyeY, 4, 4)

    -- Draw slash hitbox
    if self.slashActive and self.slashHitbox then
        local s = self.slashHitbox
        -- White arc/rectangle for the slash
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.rectangle("fill", s.x, s.y, s.w, s.h)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", s.x, s.y, s.w, s.h)
    end
end

return Player
