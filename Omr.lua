-- Ygg C11 Chord Stepper
-- E2: Move Left/Right  E3: Move Up/Down  K3: Next Step

engine.name = 'Ygg'

local notes = {48, 52, 55, 58, 60, 64, 66}  -- C11 chord (C, E, G, Bb, C, E, F#)
local step = 0
local tree

-- Main logo lattice coordinates
local COLS = 2
local ROWS = 4
local grid_x = {15, 48, 17, 46, 17, 46, 24, 38}
local grid_y = { 9,  9, 22, 22, 39, 39, 53, 53}

-- Current lattice position (col and row, 1-indexed)
local col = 1
local row = 1

-- Blink state
local blink = false
local blink_timer

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

  -- Start blink metro
  blink_timer = metro.init(
    function()
      blink = not blink
      redraw()
    end,
    0.4,
    -1
  )
  blink_timer:start()
end

function key(n, z)
  if n == 3 and z == 1 then
    -- Turn off previous note
    if step < 0 then
      engine.note_off(notes[step + #notes + 1])
    else
      engine.note_on(notes[step + 1], 80)
    end

    -- Advance step
    step = step + 1
    if step >= #notes then
      step = -#notes
    end

    redraw()
  end
end

function enc(n, d)
  if n == 2 then
    -- E2: move left/right (columns), no wrap
    col = util.clamp(col + (d > 0 and 1 or -1), 1, COLS)
    redraw()
  elseif n == 3 then
    -- E3: move up/down (rows), no wrap
    row = util.clamp(row - (d > 0 and 1 or -1), 1, ROWS)
    redraw()
  end
end

local function draw_star(x, y)
  -- Draw 4 lines through center: horizontal, vertical, and two diagonals
  local s = 5
  screen.move(x - s, y)
  screen.line(x + s, y)
  screen.stroke()

  screen.move(x, y - s)
  screen.line(x, y + s)
  screen.stroke()

  local d = 3
  screen.move(x - d, y - d)
  screen.line(x + d, y + d)
  screen.stroke()

  screen.move(x + d, y - d)
  screen.line(x - d, y + d)
  screen.stroke()
end

function redraw()
  screen.clear()
  screen.display_image(tree, 64, 0)

  -- Draw blinking star at current position
  local i  = (row-1)*COLS+col
  local sx = grid_x[i] + 64
  local sy = grid_y[i]

  if blink then
    screen.level(1)
    screen.circle(sx, sy, 4)
    screen.fill()
    screen.level(15)
  else
    screen.level(1)
  end
  draw_star(sx, sy)

  -- Left half label
  screen.level(15)
  screen.move(2, 22)
  screen.text("K3: Notes")
  screen.move(2, 32)
  screen.text("E2: Left/Right")
  screen.move(2, 42)
  screen.text("E3: Up/Down")

  screen.update()
end
