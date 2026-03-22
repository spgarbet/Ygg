  ------------------------------------------------------------------------------------------------------------------
 --
-- The earliest versions of Ygg had a single patchset file. 
-- If this file exists as configured by a user it is moved into a file called "Demo"
--
-- cfg fields: DATA_DIR, PATCHSETS_DIR,
local function migration1(cfg)

  local OLD_SAVE = cfg.DATA_DIR      .. "patches.txt"
  local NEW_SAVE = cfg.PATCHSETS_DIR .. "Demo.txt"

  -- Create the PATCHSET_DIR if it doesn't exist
  util.make_dir(cfg.PATCHSETS_DIR)

  -- Does the old save format exist?
  local old = io.open(OLD_SAVE, "r")
  if not old then return end
  old:close()

  -- If no newer save exists, move OLD to NEW
  local new = io.open(NEW_SAVE, "r")
  if not new then
    os.execute(string.format('mv "%s" "%s"', OLD_SAVE, NEW_SAVE))
    print("Ygg: migrated legacy patches to Demo.txt")
  else
    os.remove(OLD_SAVE)
    print("Ygg: removed legacy patches.txt")
  end
end  

return migration1
