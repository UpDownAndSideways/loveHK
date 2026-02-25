--
-- main.lua — Hollow Knight MVP entry point (full visual fidelity)
--
local bump      = require("libs.bump")
local baton     = require("libs.baton")
local Timer     = require("libs.timer")
local Map       = require("map")
local Player    = require("player")
local Enemy     = require("enemy")
local Particles = require("particles")

-- Globals
local world
local player
local enemy
local input
local timer
local particles
local screenShake = { timer = 0, intensity = 0 }
local gameTime = 0

-- Vignette canvas (pre-rendered once)
local vignetteCanvas

-- Parallax background layers (procedurally generated)
local bgLayers = {}

function love.load()
    love.graphics.setBackgroundColor(0.04, 0.04, 0.08)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create bump world (32px cell size matches tile size)
    world = bump.newWorld(32)

    -- Create timer
    timer = Timer.new()

    -- Create particle system
    particles = Particles.new()

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
    player = Player.new(world, input, timer, 96, 448, particles)

    -- Create enemy (spawn on right side, on the floor)
    enemy = Enemy.new(world, 580, 456, particles)

    -- Generate vignette
    vignetteCanvas = generateVignette()

    -- Generate parallax background layers
    bgLayers = generateBackgroundLayers()

    gameTime = 0
end

function love.update(dt)
    -- Cap dt to prevent physics explosions
    dt = math.min(dt, 1/30)
    gameTime = gameTime + dt

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

    -- Update particles
    particles:update(dt)

    -- Timer
    timer:update(dt)

    -- Trigger screen shake on hit-stop
    if player.hitStopTimer > 0 and screenShake.timer <= 0 then
        screenShake.timer = 0.1
        screenShake.intensity = 4
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

    -------------------------------------------------------
    -- BACKGROUND
    -------------------------------------------------------
    drawBackground()

    -------------------------------------------------------
    -- AMBIENT PARTICLES (behind everything)
    -------------------------------------------------------
    particles:draw()

    -------------------------------------------------------
    -- MAP
    -------------------------------------------------------
    Map.draw()

    -------------------------------------------------------
    -- ENEMY
    -------------------------------------------------------
    enemy:draw()

    -------------------------------------------------------
    -- PLAYER
    -------------------------------------------------------
    player:draw()

    love.graphics.pop()

    -------------------------------------------------------
    -- VIGNETTE OVERLAY
    -------------------------------------------------------
    if vignetteCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode("multiply", "premultiplied")
        love.graphics.draw(vignetteCanvas)
        love.graphics.setBlendMode("alpha")
    end

    -------------------------------------------------------
    -- HUD
    -------------------------------------------------------
    drawHUD()
end

-------------------------------------------------------
-- PARALLAX BACKGROUND
-------------------------------------------------------
function generateBackgroundLayers()
    local layers = {}

    -- Far layer: deep cavern silhouettes
    local far = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(far)
    love.graphics.clear(0, 0, 0, 0)

    -- Distant stalactites
    love.graphics.setColor(0.06, 0.06, 0.1, 0.8)
    for i = 0, 12 do
        local bx = i * 70 + math.sin(i * 2.3) * 30
        local bw = 15 + math.sin(i * 1.7) * 10
        local bh = 40 + math.sin(i * 3.1) * 25
        love.graphics.polygon("fill",
            bx, 0,
            bx + bw, 0,
            bx + bw / 2, bh
        )
    end

    -- Distant stalagmites (from bottom)
    love.graphics.setColor(0.07, 0.07, 0.11, 0.7)
    for i = 0, 10 do
        local bx = i * 80 + 20 + math.sin(i * 1.9) * 25
        local bw = 20 + math.sin(i * 2.7) * 12
        local bh = 50 + math.sin(i * 1.3) * 30
        love.graphics.polygon("fill",
            bx, 600,
            bx + bw, 600,
            bx + bw / 2, 600 - bh
        )
    end

    -- Dim background pillars
    love.graphics.setColor(0.05, 0.05, 0.09, 0.5)
    for i = 0, 5 do
        local px = 60 + i * 150 + math.sin(i * 3) * 30
        local pw = 25 + math.sin(i * 2) * 10
        love.graphics.rectangle("fill", px, 50, pw, 500)
    end

    love.graphics.setCanvas()
    table.insert(layers, { canvas = far, scrollFactor = 0.1 })

    -- Mid layer: closer details
    local mid = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(mid)
    love.graphics.clear(0, 0, 0, 0)

    -- Mid-range rock formations
    love.graphics.setColor(0.08, 0.08, 0.13, 0.6)
    for i = 0, 8 do
        local bx = i * 100 + math.sin(i * 1.5) * 40
        local bw = 30 + math.sin(i * 2.1) * 15
        local bh = 30 + math.sin(i * 2.8) * 20
        love.graphics.polygon("fill",
            bx, 0,
            bx + bw, 0,
            bx + bw * 0.7, bh,
            bx + bw * 0.3, bh * 0.8
        )
    end

    -- Hanging vines / tendrils
    love.graphics.setColor(0.1, 0.15, 0.12, 0.25)
    for i = 0, 15 do
        local vx = i * 55 + math.sin(i * 3.2) * 20
        local vh = 20 + math.sin(i * 1.7) * 15
        love.graphics.setLineWidth(1)
        love.graphics.line(vx, 0, vx + math.sin(i) * 5, vh)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setCanvas()
    table.insert(layers, { canvas = mid, scrollFactor = 0.3 })

    return layers
end

function drawBackground()
    -- Base gradient
    local gradSteps = 12
    for i = 0, gradSteps - 1 do
        local t = i / gradSteps
        local y = t * 600
        local h = 600 / gradSteps + 1
        -- Dark blue at top, slightly warmer dark at bottom
        local r = 0.03 + t * 0.04
        local g = 0.03 + t * 0.03
        local b = 0.06 + t * 0.04
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", 0, y, 800, h)
    end

    -- Subtle pulsing fog
    local fogAlpha = 0.03 + math.sin(gameTime * 0.5) * 0.015
    love.graphics.setColor(0.15, 0.15, 0.25, fogAlpha)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Draw parallax layers
    for _, layer in ipairs(bgLayers) do
        love.graphics.setColor(1, 1, 1, 1)
        -- Slight horizontal parallax based on player position
        local offsetX = -(player.x - 400) * layer.scrollFactor * 0.05
        -- Slight vertical bob
        local offsetY = math.sin(gameTime * 0.3 + layer.scrollFactor * 5) * 2
        love.graphics.draw(layer.canvas, offsetX, offsetY)
    end
end

-------------------------------------------------------
-- VIGNETTE (pre-rendered radial gradient)
-------------------------------------------------------
function generateVignette()
    local canvas = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 1, 1, 1) -- start white (multiply mode)

    -- Draw radial darkening from edges
    local cx, cy = 400, 300
    local maxRadius = 500
    local steps = 40

    for i = steps, 0, -1 do
        local t = i / steps
        local radius = t * maxRadius
        -- At the edge (t=1): dark. At center (t=0): bright
        local brightness = 1
        if t > 0.5 then
            brightness = 1.0 - ((t - 0.5) / 0.5) * 0.7
        end
        love.graphics.setColor(brightness, brightness, brightness * 1.05, 1)
        love.graphics.circle("fill", cx, cy, radius)
    end

    love.graphics.setCanvas()
    return canvas
end

-------------------------------------------------------
-- HUD
-------------------------------------------------------
function drawHUD()
    -- Title
    love.graphics.setColor(0.7, 0.75, 0.9, 0.5)
    love.graphics.print("HOLLOW KNIGHT MVP", 10, 8)

    -- Controls
    love.graphics.setColor(0.5, 0.5, 0.6, 0.35)
    love.graphics.print("Move: WASD/Arrows | Jump: Space | Dash: Shift | Attack: X/J", 10, 578)

    -- Dash cooldown indicator
    if player.dashCoolTimer > 0 then
        local ratio = 1 - (player.dashCoolTimer / player.dashCooldown)
        love.graphics.setColor(0.3, 0.3, 0.4, 0.4)
        love.graphics.rectangle("fill", 730, 8, 60, 6)
        love.graphics.setColor(0.4, 0.7, 1, 0.6)
        love.graphics.rectangle("fill", 730, 8, 60 * ratio, 6)
        love.graphics.setColor(0.5, 0.6, 0.7, 0.4)
        love.graphics.print("DASH", 738, 16)
    else
        love.graphics.setColor(0.4, 0.8, 1, 0.5)
        love.graphics.print("DASH ●", 738, 8)
    end

    -- Enemy killed message
    if not enemy.alive then
        local pulse = 0.5 + math.sin(gameTime * 3) * 0.3
        love.graphics.setColor(1, 0.85, 0.3, pulse)
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
