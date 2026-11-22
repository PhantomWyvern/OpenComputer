--Credit to mikeywhiston for the original code (slightly modified for my use, no i wont explain it)
local shell = require("shell")
local fs = require("filesystem")
local computer = require("computer")

local temp_path = shell.resolve("temp.lua")
local temp2_path = shell.resolve("temp2.lua")
local function compare_version_strings(v1, v2) --v1 is old, v2 is github version
  if not v1 or not v2 then return false end
  local split1, split2 = {}, {}
  for v in v1:gmatch('([0-9]+)%.?') do
    split1[#split1 + 1] = tonumber(v)
  end
  for v in v2:gmatch('([0-9]+)%.?') do
    split2[#split2 + 1] = tonumber(v)
  end

  for i, v1 in ipairs(split1) do
    local v2 = split2[i]
    if v2 and v1 > v2 then return true end
  end
  return false
end

function split_by_char(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end

local function parse_version(line)
    if not line then return nil end
    return line:match('^%-%-%s*([0-9%.]+)')
end

local function get_current_version()
    local ok, version = pcall(function()
        local file = io.open(temp_path, 'r') --changed from startup.lua
        if not file then return nil end
        local line = file:readLine()
        file:close()
        return parse_version(line)
    end)
    if ok and version then return version end
    return "0"
end

local function fetch_current_version()
    local internet = require("internet")
    local url = "https://raw.githubusercontent.com/PhantomWyvern/OpenComputer/main/Energy.lua" --change filename to correct pc filepath
    local ok, resp = pcall(internet.request, url)
    if not ok then
        error(resp)
    end
    local content = ""
    for chunk in resp do
        content = content .. chunk
    end
    if fs.exists(temp2_path) then -- changed from temp.lua
        fs.remove(temp2_path) -- changed from temp.lua
    end
    local file = io.open(temp2_path, 'w') -- changed from temp.lua
    if not file then
        error("could not open " .. temp2_path .. " for writing")
    end
    file:write(content)
    file:close()
end

local function read_temp_version()
    local ok, version = pcall(function()
        local file = io.open(temp2_path, 'r') -- changed from temp.lua
        if not file then return nil end
        local line = file:readLine()
        file:close()
        return parse_version(line)
    end)
    if ok and version then return version end
    return "0"
end

local function replace_current_file()
    fs.remove(temp_path) -- changed from startup.lua
    fs.rename(temp2_path, temp_path)  -- changed from both
    computer.shutdown(true)
end

local thread = require("thread")
if fs.exists(temp_path) then
    thread.create(function()
        local ok, run_err = shell.execute(temp_path)
        if not ok then
            print("temp.lua error: " .. tostring(run_err))
        end
    end):detach()
end
while true do
    print('CHECKING SOURCE CONTROL ...')
    fetch_current_version()
    print(get_current_version())
    print(read_temp_version())
    if compare_version_strings(read_temp_version(), get_current_version()) == true then
        print('REBOOTING TO APPLY CHANGES')
        replace_current_file()
    else
        print('UP TO DATE')
    end
    os.sleep(3)
end
