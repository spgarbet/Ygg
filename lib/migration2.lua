  ------------------------------------------------------------------------------------------------------------------
 --
-- MPE settings were previously stored in a hand-rolled key=value text file
-- (mpe_settings.txt). This migration reads that file if it exists, pushes
-- the values into the registered params via params:set(), then deletes the
-- old file so it is not re-read on future boots.
--
-- After this runs, init() calls params:write(MPE_PSET) to persist the values
-- in the standard Norns pset format going forward.
--
-- cfg fields: DATA_DIR, mpe_mod_labels
--
local function migration2(cfg)

  local OLD_FILE = cfg.DATA_DIR .. "mpe_settings.txt"

  local f = io.open(OLD_FILE, "r")
  if not f then return end

  local raw = f:read("*all")
  f:close()

  if not raw or raw == "" then
    os.remove(OLD_FILE)
    return
  end

  for line in raw:gmatch("[^\n]+") do
    local key, value = line:match("^(.-)=(.+)$")
    if key and value then
      local num = tonumber(value)
      if key == "mpe_vibrato" and num then
        params:set("ygg_mpe_vibrato", math.floor(util.clamp(num, 0, 12)))
      elseif key == "mpe_bend" and num then
        params:set("ygg_mpe_bend", math.floor(util.clamp(num, 0, 24)))
      elseif key == "mpe_mod" and num then
        params:set("ygg_mpe_mod", math.floor(util.clamp(num, 1, #cfg.mpe_mod_labels)))
      elseif key == "mpe_press" and num then
        params:set("ygg_mpe_press", util.clamp(num, 0.0, 1.0))
      end
      -- current_patchset is intentionally skipped; handled separately
    end
  end

  os.remove(OLD_FILE)
  print("Ygg: migrated mpe_settings.txt to pset")
end

return migration2
