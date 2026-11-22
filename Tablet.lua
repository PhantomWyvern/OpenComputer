--1.0.1
local component = require("component")
local event = require("event")
local term = require("term")
local serialization = require("serialization")

local PORT = 42

local modem
for address in component.list("modem") do
    local candidate = component.proxy(address)
    if candidate and candidate.isWireless() then
        modem = candidate
        break
    end
end

if not modem then
    print("No wireless network card / modem found.")
    return
end

modem.open(PORT)

local function draw(data)
    term.clear()
    print("== ENERGY MONITOR ==")
    print("Stored: " .. tostring(data.stored) .. " / " .. tostring(data.maximum))
    print("Charge: " .. tostring(data.percentage) .. "%")
    print("Input:  " .. tostring(data.input) .. "  (" .. tostring(data.input_rate) .. ")")
    print("Output: " .. tostring(data.output) .. "  (" .. tostring(data.output_rate) .. ")")
    print("Cap:    " .. tostring(data.cap))
    print(tostring(data.time))
    print("")
    print("Press any key/touch to exit.")
end

term.clear()
print("Waiting for energy data on port " .. PORT .. "...")
print("Press any key/touch to exit.")

while true do
    local e = table.pack(event.pull())
    if e[1] == "key_down" or e[1] == "touch" then
        break
    elseif e[1] == "modem_message" and e[4] == PORT and e[6] then
        local ok, data = pcall(serialization.unserialize, e[6])
        if ok and type(data) == "table" then
            draw(data)
        end
    end
end

term.clear()
print("Energy monitor stopped.")
