--
-- map.lua — Table-based tile map with atmospheric rendering
-- '1' = solid block, '0' = air
-- Each tile is 32x32 pixels
--
local Map = {}

local TILE_SIZE = 32

-- 25 columns × 18 rows = 800×576
-- Arena-style room: floor, walls, and a few platforms
Map.tiles = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

Map.tileSize = TILE_SIZE

-- Pre-compute which tiles have open neighbors (for ambient occlusion)
Map._edgeCache = nil

function Map.load(world)
    Map.world = world
    Map._edgeCache = {}

    for row = 1, #Map.tiles do
        Map._edgeCache[row] = {}
        for col = 1, #Map.tiles[row] do
            if Map.tiles[row][col] == 1 then
                local x = (col - 1) * TILE_SIZE
                local y = (row - 1) * TILE_SIZE
                local tile = {type = "tile"}
                world:add(tile, x, y, TILE_SIZE, TILE_SIZE)

                -- Detect edges
                local above = (row > 1 and Map.tiles[row-1][col] == 0)
                local below = (row < #Map.tiles and Map.tiles[row+1][col] == 0)
                local left  = (col > 1 and Map.tiles[row][col-1] == 0)
                local right = (col < #Map.tiles[row] and Map.tiles[row][col+1] == 0)
                Map._edgeCache[row][col] = {
                    above = above, below = below,
                    left = left, right = right,
                    isEdge = above or below or left or right
                }
            end
        end
    end
end

function Map.draw()
    local T = TILE_SIZE

    for row = 1, #Map.tiles do
        for col = 1, #Map.tiles[row] do
            if Map.tiles[row][col] == 1 then
                local x = (col - 1) * T
                local y = (row - 1) * T
                local edge = Map._edgeCache[row] and Map._edgeCache[row][col]

                -- Base tile fill with subtle depth gradient
                if edge and edge.isEdge then
                    -- Edge tiles: slightly lighter (surface)
                    love.graphics.setColor(0.18, 0.18, 0.25)
                else
                    -- Interior tiles: darker
                    love.graphics.setColor(0.12, 0.12, 0.17)
                end
                love.graphics.rectangle("fill", x, y, T, T)

                -- Surface highlight on top edges
                if edge and edge.above then
                    love.graphics.setColor(0.28, 0.28, 0.38, 0.7)
                    love.graphics.rectangle("fill", x, y, T, 2)
                    -- Subtle grass/moss detail
                    love.graphics.setColor(0.2, 0.35, 0.3, 0.3)
                    for i = 0, T - 2, 4 do
                        local h = 1 + math.floor(math.sin(x + i * 1.3) * 2 + 2)
                        love.graphics.rectangle("fill", x + i, y, 2, h)
                    end
                end

                -- Ambient occlusion shadows on inner edges
                if edge then
                    love.graphics.setColor(0, 0, 0, 0.15)
                    if edge.above then
                        love.graphics.rectangle("fill", x, y + 2, T, 4)
                    end
                    if edge.below then
                        love.graphics.rectangle("fill", x, y + T - 6, T, 4)
                    end
                    if edge.left then
                        love.graphics.rectangle("fill", x, y, 4, T)
                    end
                    if edge.right then
                        love.graphics.rectangle("fill", x + T - 4, y, 4, T)
                    end
                end

                -- Subtle grid lines
                love.graphics.setColor(0.08, 0.08, 0.12, 0.4)
                love.graphics.rectangle("line", x, y, T, T)

                -- Random crack/texture detail on some tiles
                if (row * 7 + col * 13) % 5 == 0 then
                    love.graphics.setColor(0.1, 0.1, 0.14, 0.4)
                    love.graphics.line(
                        x + T * 0.2, y + T * 0.3,
                        x + T * 0.6, y + T * 0.7
                    )
                end
                if (row * 11 + col * 3) % 7 == 0 then
                    love.graphics.setColor(0.1, 0.1, 0.14, 0.3)
                    love.graphics.line(
                        x + T * 0.8, y + T * 0.1,
                        x + T * 0.4, y + T * 0.9
                    )
                end
            end
        end
    end
end

return Map
