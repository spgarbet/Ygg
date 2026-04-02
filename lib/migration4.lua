  ----------------------------------------------------------------------------
 --
-- MPE configuration used to be global and is now being stored as part of
-- each patchset.
--
-- Any existing MPE configuration is moved into all patchset directories.
--
-- cfg fields: PATCHSETS_DIR
-- cfg fields: DATA_DIR
--
local function migration4(cfg)

  local dir      = cfg.PATCHSETS_DIR
  local MPE_PSET = cfg.DATA_DIR   .. "mpe_settings.pset"

  -- If mpe_settings.pset doesn't exist, then exit
  local p = io.popen(MPE_PSET)
  if not p then return else p:close() end

  -- Find all patchset directories
  local p = io.popen('find "' .. dir .. '" -maxdepth 1 -mindepth 1 -type d 2>/dev/null')
  if p then
    for fpath in p:lines() do
      local name = fpath:match("([^/]+)$")
      if name then
        os.execute(string.format('cp "%s" "%s"', MPE_PSET, fpath .. "/mpe_settings.pset"))
      end
    end
    p:close()
  end

  os.remove(MPE_PSET)
end

return migration4
