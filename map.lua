--
-- map.lua — Table-based tile map
-- '1' = solid block, '0' = air
-- Each tile is 32x32 pixels
--
local Map = {}

local TILE_SIZE = 32

-- 25 columns × 19 rows = 800×608 (fits 800×600 with slight bottom overflow)
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

function Map.load(world)
    Map.world = world
    for row = 1, #Map.tiles do
        for col = 1, #Map.tiles[row] do
            if Map.tiles[row][col] == 1 then
                local x = (col - 1) * TILE_SIZE
                local y = (row - 1) * TILE_SIZE
                local tile = {type = "tile"}
                world:add(tile, x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end
end

function Map.draw()
    love.graphics.setColor(0.15, 0.15, 0.2)
    for row = 1, #Map.tiles do
        for col = 1, #Map.tiles[row] do
            if Map.tiles[row][col] == 1 then
                local x = (col - 1) * TILE_SIZE
                local y = (row - 1) * TILE_SIZE
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end
    -- Subtle grid lines on solid tiles
    love.graphics.setColor(0.2, 0.2, 0.28)
    for row = 1, #Map.tiles do
        for col = 1, #Map.tiles[row] do
            if Map.tiles[row][col] == 1 then
                local x = (col - 1) * TILE_SIZE
                local y = (row - 1) * TILE_SIZE
                love.graphics.rectangle("line", x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end
end

return Map
