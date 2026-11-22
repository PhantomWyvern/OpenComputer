--1.0.5
local component = require("component")

local PORT = 42
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

local stored_text = formatEnergy(stored)
local maximum_text = formatEnergy(maximum)
local input_text = formatEnergy(input)
local output_text = formatEnergy(output)
local cap_text = formatEnergy(cap)
local percentage = maximum > 0 and (stored / maximum) * 100 or 0
local percentage_text = string.format("%.2f", percentage)
local time_text = "N/A"

if maximum > 0 then
    local space_left = maximum - stored
    local profit = input - output
    if profit > 0 then
        time_text = "Full in " .. formatTime((space_left / profit) / 20)
    else
        time_text = "Empty in " .. formatTime((stored / math.abs(profit)) / 20)
    end
end

print("Stored: ", stored_text)
print("Maximum: ", maximum_text)
print("Input: ", input_text .. "/t")
print("Output: ", output_text .. "/t")
print("Transfer Cap: ", cap_text)
if maximum > 0 then
    print("percentage: ", percentage_text .. "%")
    print(time_text)
end

local ok, serialization = pcall(require, "serialization")
if ok then
    local modem
    for address in component.list("modem") do
        local candidate = component.proxy(address)
        if candidate and candidate.isWireless() then
            modem = candidate
            break
        end
    end
    if modem then
        pcall(function()
            if modem.getStrength() == 0 then
                modem.setStrength(400)
            end
        end)
        modem.broadcast(PORT, serialization.serialize({
            stored = stored_text,
            maximum = maximum_text,
            cap = cap_text,
            percentage = percentage_text,
            input = input_text .. "/t",
            output = output_text .. "/t",
            input_rate = formatEnergy(input * 20) .. "/s",
            output_rate = formatEnergy(output * 20) .. "/s",
            time = time_text,
        }))
    end
end