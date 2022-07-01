-- Basic configuration parsing API. Mostly just unserializes tables. --

local cfg = {}

function cfg.load(file)
  checkArg(1, file, "string")
  print("config: loading " .. file)
  local handle, err = io.open(file, "r")
  if not handle then
    return false, err
  end
  local data = handle:readAll()
  handle:close()

  local ok, err = load("return " .. data, "=config.load(" .. file .. ")", "bt", _G)
  if not ok then
    print(ok, err)
    return false, err
  end
  local s,r = ok()
  if not s then
    return {}
  end
  return s or {}
end

function cfg.save(config, file)
  checkArg(1, config, "table")
  checkArg(2, file, "string")
  local handle, err = io.open(file, "w")
  if not handle then return false, err, print(err) end
  handle:write(table.serialize(config))
  handle:close()
end

return cfg
