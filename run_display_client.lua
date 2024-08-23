-- URL of the Lua script
local url = "https://raw.githubusercontent.com/VaeluxV/ComputerCraft-Scheduling-System/main/schedule_display.lua"

-- Function to download a file from a URL
local function downloadFile(url)
    local response, err = http.get(url)
    if not response then
        print("Error fetching file: " .. (err or "Unknown error"))
        return nil
    end
    return response
end

-- Function to run the downloaded Lua script
local function runScript(url)
    local response = downloadFile(url)
    if response then
        local script = response.readAll()
        response.close()
        
        -- Load and run the script
        local func, loadErr = load(script)
        if func then
            func()
        else
            print("Error loading script: " .. (loadErr or "Unknown error"))
        end
    end
end

-- Execute the script from the URL
runScript(url)
