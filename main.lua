--
-- main.lua — Hollow Knight MVP entry point
--
local bump   = require("libs.bump")
local baton  = require("libs.baton")
local Timer  = require("libs.timer")
local Map    = require("map")
local Player = require("player")
local Enemy  = require("enemy")

-- Globals
local world
local player
local enemy
local input
local timer
local screenShake = { timer = 0, intensity = 0 }

function love.load()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create bump world (32px cell size matches tile size)
    world = bump.newWorld(32)

    -- Create timer
    timer = Timer.new()

    -- Setup input with baton
    input = baton.new({
        controls = {
            left   = {"key:left",  "key:a"},
            right  = {"key:right", "key:d"},
            up     = {"key:up",    "key:w"},
            down   = {"key:down",  "key:s"},
            jump   = {"key:space", "key:up", "key:w"},
            dash   = {"key:lshift", "key:rshift"},
            attack = {"key:x",     "key:j"},
        },
        pairs = {
            move = {"left", "right", "up", "down"},
        },
    })

    -- Load map (registers tiles with bump world)
    Map.load(world)

    -- Create player (spawn in open area, left side)
    player = Player.new(world, input, timer, 96, 448)

    -- Create enemy (spawn on right side, on the floor)
    enemy = Enemy.new(world, 580, 456)
end

function love.update(dt)
    -- Cap dt to prevent physics explosions
    dt = math.min(dt, 1/30)

    -- Screen shake countdown
    if screenShake.timer > 0 then
        screenShake.timer = screenShake.timer - dt
    end

    -- Update player (hit-stop is handled inside player:update)
    player:update(dt)

    -- Pass hit-stop to enemy too
    if player.hitStopTimer <= 0 then
        enemy:update(dt)
    end

    -- Timer
    timer:update(dt)

    -- Trigger screen shake on hit-stop
    if player.hitStopTimer > 0 and screenShake.timer <= 0 then
        screenShake.timer = 0.08
        screenShake.intensity = 3
    end
end

function love.draw()
    love.graphics.push()

    -- Apply screen shake
    if screenShake.timer > 0 then
        local sx = (math.random() - 0.5) * 2 * screenShake.intensity
        local sy = (math.random() - 0.5) * 2 * screenShake.intensity
        love.graphics.translate(sx, sy)
    end

    -- Draw background
    love.graphics.setColor(0.06, 0.06, 0.1)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Draw map
    Map.draw()

    -- Draw enemy
    enemy:draw()

    -- Draw player
    player:draw()

    love.graphics.pop()

    -- HUD
    drawHUD()
end

function drawHUD()
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("HOLLOW KNIGHT MVP", 10, 8)

    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.print("Move: WASD/Arrows | Jump: Space | Dash: Shift | Attack: X/J", 10, 578)

    -- Dash cooldown indicator
    if player.dashCoolTimer > 0 then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.print("DASH: recharging...", 650, 8)
    else
        love.graphics.setColor(0.4, 0.8, 1, 0.6)
        love.graphics.print("DASH: ready", 670, 8)
    end

    -- Enemy killed message
    if not enemy.alive then
        love.graphics.setColor(1, 0.8, 0.2, 0.8)
        love.graphics.printf("ENEMY DEFEATED", 0, 280, 800, "center")
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    -- Restart on R
    if key == "r" then
        love.load()
    end
end
