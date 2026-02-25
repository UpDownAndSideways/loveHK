This is a high-level "Technical Blueprint" prompt. You can use this as a reference for yourself or feed it into an LLM to generate the boilerplate code.

I have balanced the **"Library-to-Internal (LI) Ratio"** to ensure you don't get bogged down in math but still own the "feel" of the character.

---

## The "Hollow Knight" MVP Blueprint

**Goal:** A single-room prototype with a player that can move, jump (variable height), dash, and slash a static enemy with hit-stop (freeze-frame) and knockback.

### 1. The LI Ratios (Library vs. Internal)

| System | Logic Type | Ratio (Lib:Int) | Recommended "Wheel" |
| --- | --- | --- | --- |
| **Physics/Collision** | Heavy Lift | **90:10** | `bump.lua` |
| **Map Loading** | Utility | **100:0** | `STI` (Simple Tiled Impl) |
| **Input/Control** | Utility | **80:20** | `baton` |
| **Animation** | Utility | **90:10** | `anim8` |
| **Player Logic** | **Core Gameplay** | **10:90** | *Your custom Lua scripts* |
| **Combat/Feel** | **Core Gameplay** | **0:100** | *Your custom Lua scripts* |

---

### 2. The Condensed MVP Prompt

> "Generate a Love2D project structure using **bump.lua** for collisions and **baton** for input.
> **The Player Controller must include:**
> * **Variable Jump:** Gravity increases if the jump button is released early.
> * **Coyote Time:** A 0.1s grace period to jump after leaving a ledge.
> * **Input Buffering:** A 0.1s window where a jump press is 'remembered' if hit just before landing.
> * **Dash:** A fixed-distance horizontal burst that ignores gravity.
> 
> 
> **The Combat System must include:**
> * **The Slash:** A temporary `bump` hitbox triggered by a keypress.
> * **Recoil:** If the Slash hits an object tagged 'enemy', the player is pushed back (or up, if down-slashing).
> * **Hit-Stop:** A global `timer` pause of 0.05s upon a successful hit to provide 'weight'.
> 
> 
> **The World:**
> * Use a basic table-based map (no STI yet for the raw MVP) where '1' is a solid block and '0' is air. Render these as simple `love.graphics.rectangle` calls."
> 
> 

---

### 3. Critical "Internal" Logic to Write Yourself

Since the LI ratio for **Player Logic** is 10:90, here is the snippet of "Internal" code you must handle to get that *Hollow Knight* snappiness:

```lua
-- Inside your player:update(dt)
-- VARIABLE JUMP LOGIC
if not input:down('jump') and self.velocity.y < 0 then
    -- If moving up but button released, fall faster (The 'Short Hop')
    self.velocity.y = self.velocity.y + (self.gravity * 3 * dt)
end

-- HIT-STOP LOGIC (The "Juice")
function triggerHitStop(duration)
    self.isPaused = true
    timer.after(duration, function() self.isPaused = false end)
end

```

### 4. Why these ratios?

* **Collision (90:10):** Writing a tile-based collision system that doesn't "snag" on floor cracks takes weeks. `bump.lua` solves it in seconds.
* **Combat (0:100):** *Hollow Knight's* combat is entirely about pixel-perfect feel. If you use a library for this, it will feel generic. You need to manually code the `x` and `y` offsets of the nail slash to make it feel right.
