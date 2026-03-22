  ------------------------------------------------------------------------------------------------------------------
 --
-- MPE settings were previously stored in a hand-rolled key=value text file
-- (mpe_settings.txt). This migration reads that file if it exists, pushes
-- the values into mpe_params, writes the pset and current_patchset.txt,
-- then deletes the old file so it is not re-read on future boots.
--
-- cfg fields: DATA_DIR, mpe_mod_labels, mpe_params, MPE_PSET, PATCHSET_FILE
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
        cfg.mpe_params:set("ygg_mpe_vibrato", math.floor(util.clamp(num, 0, 12)))
      elseif key == "mpe_bend" and num then
        cfg.mpe_params:set("ygg_mpe_bend", math.floor(util.clamp(num, 0, 24)))
      elseif key == "mpe_mod" and num then
        cfg.mpe_params:set("ygg_mpe_mod", math.floor(util.clamp(num, 1, #cfg.mpe_mod_labels)))
      elseif key == "mpe_press" and num then
        cfg.mpe_params:set("ygg_mpe_press", util.clamp(num, 0.0, 1.0))
      elseif key == "current_patchset" then
        local pf = io.open(cfg.PATCHSET_FILE, "w")
        if pf then
          pf:write(value)
          pf:close()
        end
      end
    end
  end

  os.remove(OLD_FILE)
  cfg.mpe_params:write(cfg.MPE_PSET)
  print("Ygg: migrated mpe_settings.txt to pset")
end

return migration2
