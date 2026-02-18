-- Ygg C11 Chord Stepper
-- K3: Next Step

engine.name = 'Ygg'

local notes = {48, 52, 55, 58, 60, 64, 66}  -- C11 chord (C, E, G, Bb, C, E, F#)
local step = 0
local tree

function init()
  -- Initialize engine parameters
  engine.attack(10.0)
  engine.release(3.0)
  engine.hold(0.0)
  engine.harmonics(0.5)
  engine.mod_depth(0.3)
  engine.routing(0)
  
  tree = screen.load_png(_path.code .. "ygg/img/tree.png")
  assert(tree, "tree.png failed to load")
end

function key(n, z)
  if n == 3 and z == 1 then
    -- Turn off previous note
    if step < 0 then
      engine.note_off(notes[step+#notes+1])
    else
      engine.note_on(notes[step+1], 80)
    end
    
    -- Advance step
    step = step + 1
    if step >= #notes then
      step = -#notes
    end
    
    redraw()
  end
end

function redraw()
  screen.clear()
  screen.display_image(tree, 64, 0)
  screen.level(15)
  screen.move(2, 32)
  screen.text("K3: Next Step")
  screen.update()
end