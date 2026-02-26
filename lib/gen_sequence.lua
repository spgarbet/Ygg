  ---------------------------------------------------------------------------
 --
-- lib/gen_sequence.lua
-- Randomly generated harmonic sequence using Sequins
-- Parameters: seed (number), tonic (midi note number), scale (string)
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

-- Scales that work with gen_sequence's 7-degree chord-building logic.
-- Keys match MusicUtil.SCALES names exactly.
local SCALES =
{
  ["Major"]            = {0, 2, 4, 5, 7, 9, 11},
  ["Natural Minor"]    = {0, 2, 3, 5, 7, 8, 10},
  ["Dorian"]           = {0, 2, 3, 5, 7, 9, 10},
  ["Phrygian"]         = {0, 1, 3, 5, 7, 8, 10},
  ["Lydian"]           = {0, 2, 4, 6, 7, 9, 11},
  ["Mixolydian"]       = {0, 2, 4, 5, 7, 9, 10},
  ["Locrian"]          = {0, 1, 3, 5, 6, 8, 10},
  ["Whole Tone"]       = {0, 2, 4, 6, 8, 10, 12},
  ["Harmonic Minor"]   = {0, 2, 3, 5, 7, 8, 11},
  ["Melodic Minor"]    = {0, 2, 3, 5, 7, 9, 11},
  ["Double Harmonic"]  = {0, 1, 4, 5, 7, 8, 11},
  ["Hungarian Minor"]  = {0, 2, 3, 6, 7, 8, 11},
  ["Prometheus"]       = {0, 2, 4, 6, 9, 10, 12},
  ["Enigmatic"]        = {0, 1, 4, 6, 8, 10, 11},
  ["Bhairav"]          = {0, 1, 4, 5, 7, 8, 11},
}

-- Each voicing is exactly 8 intervals so the permutation always has 8 slots.
local CHORD_INTERVALS =
{
  I =
  {
    0,   -- root
    4,   -- major 3rd
    7,   -- perfect 5th
    11,  -- major 7th
    14,  -- 9th
    18,  -- #11th (Lydian colour)
    21,  -- 13th
    24,  -- root + 2 octaves
  },
  II =
  {
    0,   -- chord root (scale degree 2, offset applied below)
    3,   -- minor 3rd
    7,   -- perfect 5th
    10,  -- minor 7th
    14,  -- 9th
    17,  -- 11th
    20,  -- minor 13th
    24,  -- root + 2 octaves
  },
  V6 =
  {
    4,   -- major 3rd in the bass
    7,   -- perfect 5th
    10,  -- minor 7th (dominant)
    12,  -- chord root
    14,  -- 9th
    18,  -- #11th (Lydian dominant)
    21,  -- 13th
    24,  -- root + 2 octaves
  },
}

local function random_permutation(n)
  local t = {}
  for i = 1, n do t[i] = i end
  for i = n, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

local function reorder(t, perm)
  local out = {}
  for i = 1, #perm do out[i] = t[perm[i]] end
  return out
end

local function slice(t, a, b)
  local out = {}
  for i = a, b do table.insert(out, t[i]) end
  return out
end

local function rep(t, n)
  local out = {}
  for _ = 1, n do
    for _, v in ipairs(t) do table.insert(out, v) end
  end
  return out
end

local function concat(...)
  local out = {}
  for _, t in ipairs({...}) do
    for _, v in ipairs(t) do table.insert(out, v) end
  end
  return out
end

local function build_voicing(tonic, root_offset, intervals)
  local notes = {}
  for i, interval in ipairs(intervals) do
    notes[i] = tonic + root_offset + interval
  end
  return notes
end

local function build_velocities(centre, perm)
  local raw = {}
  for i = 1, 8 do
    raw[i] = math.max(1, math.min(127, centre + math.random(-15, 15)))
  end
  return reorder(raw, perm)
end

local function gen_sequence(seed, tonic, scale_name, attack_time)
  math.randomseed(seed)

  local scale = SCALES[scale_name]
  if not scale then
    print("Unknown scale: " .. tostring(scale_name))
    return nil
  end

  local root_I   = scale[1]
  local root_II  = scale[2]
  local root_V   = scale[5] - 12
  local root_VI  = scale[6]
  local root_III = scale[3]

  local I_raw   = build_voicing(tonic, root_I,   CHORD_INTERVALS.I)
  local II_raw  = build_voicing(tonic, root_II,  CHORD_INTERVALS.II)
  local V6_raw  = build_voicing(tonic, root_V,   CHORD_INTERVALS.V6)
  local VI_raw  = build_voicing(tonic, root_VI,  CHORD_INTERVALS.I)
  local III_raw = build_voicing(tonic, root_III, CHORD_INTERVALS.I)

  local perm = random_permutation(8)
  local I   = reorder(I_raw,   perm)
  local II  = reorder(II_raw,  perm)
  local V6  = reorder(V6_raw,  perm)
  local VI  = reorder(VI_raw,  perm)
  local III = reorder(III_raw, perm)

  -- Pick random slice start (1..5 so that slice+3 <= 8)
  -- Must be defined before VI_slice/III_slice reference it
  local s = math.random(1, 5)

  local I_slice   = slice(I,   s, s + 3)
  local V6_slice  = slice(V6,  s, s + 3)
  local VI_slice  = slice(VI,  s, s + 3)
  local III_slice = slice(III, s, s + 3)

  local total_time = attack_time * 8
  local pts = {}
  for i = 1, 7 do pts[i] = math.random() * total_time end
  table.sort(pts)

  local wait = {}
  local prev = 0
  for i = 1, 7 do
    wait[i] = pts[i] - prev
    prev     = pts[i]
  end
  wait[8] = total_time - prev

  local wait_slice_halved = {}
  for i = s, s + 3 do
    table.insert(wait_slice_halved, wait[i] / 2)
  end

  local note_stack = concat(
    I,
    V6,
    I_slice,
    VI_slice,
    V6_slice,
    III_slice,
    II,
    V6,
    I
  )

  local time_stack = concat(
    wait,
    wait,
    rep(wait_slice_halved, 4),
    wait,
    wait,
    rep({1}, 8)
  )

  local vel_I_a  = build_velocities(60, perm)
  local vel_V6_a = build_velocities(75, perm)
  local vel_Is1  = build_velocities(40, perm)
  local vel_Is2  = build_velocities(55, perm)
  local vel_V6s1 = build_velocities(65, perm)
  local vel_V6s2 = build_velocities(55, perm)
  local vel_II   = build_velocities(55, perm)
  local vel_V6_b = build_velocities(80, perm)
  local vel_I_b  = build_velocities(40, perm)

  local vel_stack = concat(
    vel_I_a,
    vel_V6_a,
    slice(vel_Is1,  s, s + 3),
    slice(vel_Is2,  s, s + 3),
    slice(vel_V6s1, s, s + 3),
    slice(vel_V6s2, s, s + 3),
    vel_II,
    vel_V6_b,
    vel_I_b
  )

  assert(#note_stack == 56, "note stack length: " .. #note_stack)
  assert(#time_stack == 56, "time stack length: " .. #time_stack)
  assert(#vel_stack  == 56, "vel stack length: "  .. #vel_stack)

  return { notes = note_stack, times = time_stack, velocities = vel_stack }
end

local scale_names = {}
for name, _ in pairs(SCALES) do
  scale_names[#scale_names + 1] = name
end
table.sort(scale_names)

return
{
  generate    = gen_sequence,
  scale_names = scale_names,
}
