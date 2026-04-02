  ----------------------------------------------------------------------------
 --
-- Patchsets were previously stored as a single flat file per named set
-- (e.g. patchsets/Demo.txt) containing all 8 slots as "slot,key=value" lines.
--
-- The new format is a directory per named set containing 8 individual pset
-- files (1.pset ... 8.pset) in standard Norns "key: value" format, one per
-- slot. This allows each slot to be read and written independently via
-- ParamSet:read() / ParamSet:write().
--
-- This migration scans PATCHSETS_DIR for *.txt files, converts each one to
-- the new directory format, then removes the old .txt file. It is idempotent
-- — if the target directory already exists for a given name, that name is
-- skipped entirely.
--
-- cfg fields: PATCHSETS_DIR
--
local function migration3(cfg)

  local dir = cfg.PATCHSETS_DIR

  -- Find only .txt files directly in PATCHSETS_DIR (not recursing into subdirs)
  local p = io.popen('find "' .. dir .. '" -maxdepth 1 -name "*.txt" 2>/dev/null')
  if not p then return end

  local txt_files = {}
  for fpath in p:lines() do
    -- Extract just the base name without extension
    local name = fpath:match("([^/]+)%.txt$")
    if name then
      txt_files[#txt_files + 1] = { name = name, path = fpath }
    end
  end
  p:close()

  if #txt_files == 0 then return end

  for _, entry in ipairs(txt_files) do
    local name     = entry.name
    local old_path = entry.path
    local new_dir  = dir .. name .. "/"

    -- Skip if target directory already exists
    local check = io.popen('[ -d "' .. new_dir .. '" ] && echo yes || echo no')
    local exists = check and check:read("*l") or "no"
    if check then check:close() end

    if exists == "yes" then
      print("Ygg: migration3 skipping '" .. name .. "' (directory already exists)")
    else
      -- Parse old flat file into 8 slot tables
      local f = io.open(old_path, "r")
      if not f then
        print("Ygg: migration3 could not open " .. old_path)
      else
        local raw = f:read("*all")
        f:close()

        local slots = {}
        for i = 1, 8 do slots[i] = {} end

        for line in raw:gmatch("[^\n]+") do
          local slot, key, value = line:match("^(%d+),(.-)=(.+)$")
          if slot and key and value then
            slot = tonumber(slot)
            local num = tonumber(value)
            slots[slot][key] = num ~= nil and num or value
          end
        end

        -- Create the new directory
        os.execute(string.format('mkdir -p "%s"', new_dir))

        -- Write one pset file per slot in "key: value" format
        local all_ok = true
        for slot = 1, 8 do
          local pset_path = new_dir .. slot .. ".pset"
          local pf = io.open(pset_path, "w")
          if pf then
            for key, value in pairs(slots[slot]) do
              pf:write(key .. ": " .. tostring(value) .. "\n")
            end
            pf:close()
          else
            print("Ygg: migration3 could not write " .. pset_path)
            all_ok = false
          end
        end

        -- Only remove old file if all slots written successfully
        if all_ok then
          os.remove(old_path)
          print("Ygg: migration3 converted '" .. name .. "' to directory format")
        else
          print("Ygg: migration3 INCOMPLETE for '" .. name .. "' — old file retained")
        end
      end
    end
  end
end

return migration3
