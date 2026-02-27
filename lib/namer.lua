  -----------------------------------------------------------------------------
 -- 
-- namer.lua
-- A reusable name-entry screen for Norns.
-- Usage:
--   local namer = include("namer")
--   namer.on_done   = function(name) ... end
--   namer.on_cancel = function() ... end
--   namer.activate()
-- Then delegate enc/key/redraw to namer while it is active.
--
-- Copyright (C) 2026 Shawn Garbett
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local namer = {}

  -----------------------------------------------------------------------------
 --
-- Configuration 
--
local MAX_NAME_LEN  = 12
local COLS          = 16  -- characters per row in the grid
local ROWS_VISIBLE  = 4   -- grid rows shown on screen

-- The character set: A-Z, a-z, 0-9, _ -
local CHARSET = {}
do
  for i = 65, 90  do table.insert(CHARSET, string.char(i)) end  -- A-Z
  for i = 97, 122 do table.insert(CHARSET, string.char(i)) end  -- a-z
  for i = 48, 57  do table.insert(CHARSET, string.char(i)) end  -- 0-9
  table.insert(CHARSET, "_")
  table.insert(CHARSET, "-")
end

-- Total grid dimensions
local TOTAL_COLS = COLS
local TOTAL_ROWS = math.ceil(#CHARSET / COLS)  -- 8 rows for 64 chars

-- STATE
local name        = ""
local cursor_row  = 0   -- 0 = header row (OK), 1..TOTAL_ROWS = grid
local cursor_col  = 1   -- 1-indexed, only meaningful when cursor_row >= 1
local scroll_row  = 0   -- topmost visible grid row (0 = header visible)

-- Public callbacks (assign before activating) 

namer.on_done   = nil
namer.on_cancel = nil

  -----------------------------------------------------------------------------
 --
-- Helpers
--
local function char_at(row, col)
  local idx = (row - 1) * COLS + col
  return CHARSET[idx]
end

local function current_char()
  if cursor_row == 0 then return nil end
  return char_at(cursor_row, cursor_col)
end

local function on_ok_row()
  return cursor_row == 0
end

  -----------------------------------------------------------------------------
 --
-- Exports
--
function namer.activate()
  name       = ""
  cursor_row = 1
  cursor_col = 1
  scroll_row = 1
end

function namer.enc(n, d)
  if n == 2 then
    -- E2: scroll vertically (down = positive d)
    if d > 0 then
      -- move down
      if cursor_row == 0 then
        -- leave header, enter grid at top
        cursor_row = scroll_row
      else
        cursor_row = math.min(cursor_row + 1, TOTAL_ROWS)
        -- clamp col to valid chars on this row
        local last_in_row = 0
        for c = 1, COLS do
          if char_at(cursor_row, c) then last_in_row = c end
        end
        cursor_col = math.min(cursor_col, last_in_row)
      end
    else
      -- move up
      if cursor_row <= 1 then
        cursor_row = 0  -- move to header (OK)
      else
        cursor_row = cursor_row - 1
      end
    end

    -- adjust scroll so cursor is visible
    if cursor_row == 0 then
      -- header is always visible; no scroll adjustment needed
    else
      if cursor_row < scroll_row then
        scroll_row = cursor_row
      elseif cursor_row > scroll_row + ROWS_VISIBLE - 1 then
        scroll_row = cursor_row - ROWS_VISIBLE + 1
      end
    end

  elseif n == 3 then
    -- E3: scroll horizontally (right = positive d)
    if cursor_row >= 1 then
      cursor_col = math.max(1, math.min(COLS, cursor_col + d))
      -- clamp to existing char
      while cursor_col > 1 and not char_at(cursor_row, cursor_col) do
        cursor_col = cursor_col - 1
      end
    end
  end
end

function namer.key(n, z)
  if z ~= 1 then return end  -- act on press only

  if n == 3 then
    if on_ok_row() then
      -- confirm
      if namer.on_done then namer.on_done(name) end
    else
      local ch = current_char()
      if ch and #name < MAX_NAME_LEN then
        name = name .. ch
      end
    end

  elseif n == 2 then
    if #name > 0 then
      name = string.sub(name, 1, #name - 1)
    else
      if namer.on_cancel then namer.on_cancel() end
    end
  end
end

function namer.draw_screen()
  screen.clear()
  screen.aa(0)
  screen.font_face(0)
  screen.font_size(8)

  -- Name (top-left)
  screen.level(15)
  local display_name = #name > 0 and name or "_"
  screen.move(0, 8)
  screen.text(display_name)

  -- OK (top-right), highlight when cursor is on header
  screen.level(on_ok_row() and 15 or 5)
  screen.move(110, 8)
  screen.text("OK")

  -- Divider
  screen.level(2)
  screen.move(0, 11)
  screen.line(128, 11)
  screen.stroke()

  -- Character grid
  local cell_w =  8  -- pixel width per cell
  local cell_h = 10  -- pixel height per cell
  local grid_y = 23  -- top of grid area (one cell_h below divider)

  for r_offset = 0, ROWS_VISIBLE - 1 do
    local row = scroll_row + r_offset
    if row > TOTAL_ROWS then break end

    for col = 1, COLS do
      local ch = char_at(row, col)
      if ch then
        local x = (col - 1) * cell_w
        local y = grid_y + r_offset * cell_h

        local is_selected = (row == cursor_row and col == cursor_col
                              and not on_ok_row())

        if is_selected then
          -- draw highlight box
          screen.level(4)
          screen.rect(x - 1, y - 7, cell_w - 1, cell_h)
          screen.fill()
          screen.level(15)
        else
          screen.level(6)
        end

        screen.move(x + 1, y)
        screen.text(ch)
      end
    end
  end

  screen.update()
end

return namer

  ---------------------------------------------------------------------------
 --
-- EXAMPLE script: myproject.lua
--
-- local namer = include("lib/namer")
--
-- local naming_active = false
-- 
-- function init()
--   namer.on_done = function(result)
--     naming_active = false
--     print("name chosen: " .. result)
--     -- resume normal operation here
--   end
-- 
--   namer.on_cancel = function()
--     naming_active = false
--     print("naming cancelled")
--   end
-- 
--   naming_active = true
--   namer.activate()
--  
--   -- Other init here
--
-- end
-- 
-- function enc(n, d)
--   if naming_active then namer.enc(n, d) else
--     -- normal enc handling
--   end
-- end
-- 
-- function key(n, z)
--   if naming_active then namer.key(n, z) else
--     -- normal key handling
--   end
-- end
-- 
-- function redraw()
--   if naming_active then namer.draw_screen() else
--     -- normal redraw
--   end
-- end
