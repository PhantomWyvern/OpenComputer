--1.0.4
local component = require("component")
--for address, kind in component.list("induction_matrix") do
    --print("found: ", address, kind)
    --for name in pairs(componnet.methods(address)) do
        --print(name)
    --end
--end

for address in component.list("induction_matrix") do
    stored = component.invoke(address, "getEnergy")
    maximum = component.invoke(address, "getMaxEnergy")
    input = component.invoke(address, "getInput")
    output = component.invoke(address, "getOutput")
    cap = component.invoke(address, "getTransferCap")
end

function formatEnergy(energy)
    local suffixes = {"", "K", "M", "G", "T", "P", "E"}
    local suffixIndex = 1
    if energy <= 1 then return "0J" end
    while energy >= 1000 do
        energy = energy / 1000
        suffixIndex = suffixIndex + 1
    end
    local formatted = string.format("%.1f", energy)
    if string.sub(formatted, -2) == ".0" then
        formatted = string.sub(formatted, 1, -3)
    end
    return formatted .. suffixes[suffixIndex] .. "J"
end

function formatTime(seconds)
    if seconds ~= seconds or seconds == math.huge or seconds == -math.huge then
        return "infinite"
    end
    if seconds > 604800 then return "> 1 week" end
    if seconds < 0 then seconds = 0 end
    local total = math.floor(seconds)
    local days = math.floor(total / 86400)
    local hours = math.floor((total % 86400) / 3600)
    local minutes = math.floor((total % 3600) / 60)
    local secs = math.floor(total % 60)
    return string.format("%dd:%dh:%dm:%ds", days, hours, minutes, secs)
end

print("Stored: ", formatEnergy(stored))
print("Maximum: ", formatEnergy(maximum))
--print("Input: ", formatEnergy(input))
--print("Output: ", formatEnergy(output))
print("Transfer Cap: ", formatEnergy(cap))

if maximum > 0 then
    print("percentage: ", string.format("%.2f", (stored / maximum) * 100) .. "%")
    space_left = (maximum - stored)
    profit = (input - output)
    if profit > 0 then
        print("Time to full: ", formatTime((space_left / profit) / 20))
    else
        print("Time to empty: ", formatTime((stored / math.abs(profit)) / 20))
    end
end