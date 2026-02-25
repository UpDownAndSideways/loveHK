--
-- timer.lua — Minimal timer utility for delayed callbacks
--
local Timer = {}
Timer.__index = Timer

function Timer.new()
    return setmetatable({ entries = {} }, Timer)
end

function Timer:after(delay, callback)
    table.insert(self.entries, { remaining = delay, callback = callback })
end

function Timer:update(dt)
    local i = 1
    while i <= #self.entries do
        local e = self.entries[i]
        e.remaining = e.remaining - dt
        if e.remaining <= 0 then
            e.callback()
            table.remove(self.entries, i)
        else
            i = i + 1
        end
    end
end

function Timer:clear()
    self.entries = {}
end

return Timer
