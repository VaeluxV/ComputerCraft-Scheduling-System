-- schedule_server.lua
-- Main schedule server with editable schedule and save functionality

local modem = peripheral.find("modem") -- Find attached ender modem
local channel = 5 -- Communication channel

local schedule_file = "schedule.json" -- File to store schedule data

-- Open the modem on the server
modem.open(channel)
print("Server is running on channel " .. channel)

-- Function to load the schedule from the file
local function load_schedule()
    if fs.exists(schedule_file) then
        -- Read the file
        local file = fs.open(schedule_file, "r")
        local content = file.readAll()
        file.close()
        
        -- Decode the JSON data
        return textutils.unserializeJSON(content)
    else
        -- If file doesn't exist, create a default schedule
        print("Schedule file not found, creating default schedule...")
        local default_schedule = {
            {name = "Industry Metro", arrival = "12:00", departure = "12:10", delayed = false},
            {name = "TGV to city", arrival = "12:20", departure = "12:30", delayed = true},
            {name = "S-Train to city", arrival = "12:40", departure = "12:50", delayed = false},
            {name = "Special service", arrival = "13:00", departure = "13:10", delayed = false}
        }
        save_schedule(default_schedule) -- Save default schedule
        return default_schedule
    end
end

-- Function to save the schedule to the file
local function save_schedule(schedule)
    local file = fs.open(schedule_file, "w")
    file.write(textutils.serializeJSON(schedule))
    file.close()
    print("Schedule saved to file.")
end

-- Load the schedule from the file or create a default one
local active_schedule = load_schedule()

-- Function to handle incoming requests from display computers
local function handle_request()
    while true do
        local event, side, channel_received, reply_channel, message, distance = os.pullEvent("modem_message")
        
        print("Received message on channel " .. tostring(channel_received) .. ": " .. tostring(message))

        if channel_received == channel and message == "request_schedule" then
            -- Send back the active schedule
            modem.transmit(reply_channel, channel, active_schedule)
            print("Sent schedule to display on channel " .. tostring(reply_channel))
        else
            print("Received an unexpected message or on wrong channel.")
        end
    end
end

-- Command line interface to modify schedule
local function edit_schedule()
    while true do
        print("Edit schedule (1: Add Train, 2: Remove Train, 3: Save and Exit, 4: Exit without Saving)")
        local choice = tonumber(read())

        if choice == 1 then
            print("Enter train name:")
            local name = read()
            print("Enter arrival time (hh:mm):")
            local arrival = read()
            print("Enter departure time (hh:mm):")
            local departure = read()
            print("Is the train delayed? (yes/no)")
            local delayed_input = read()
            local delayed = (delayed_input == "yes")

            table.insert(active_schedule, {name = name, arrival = arrival, departure = departure, delayed = delayed})
            print("Train added.")
        elseif choice == 2 then
            print("Enter train number to remove:")
            for i, train in ipairs(active_schedule) do
                print(i .. ": " .. train.name)
            end
            local remove_index = tonumber(read())
            if remove_index and remove_index > 0 and remove_index <= #active_schedule then
                table.remove(active_schedule, remove_index)
                print("Train removed.")
            else
                print("Invalid index.")
            end
        elseif choice == 3 then
            -- Save the schedule to the file
            save_schedule(active_schedule)
            print("Schedule saved. Exiting.")
            break
        elseif choice == 4 then
            print("Exiting without saving.")
            break
        else
            print("Invalid choice. Please try again.")
        end
    end
end

-- Start the server and allow editing
parallel.waitForAny(handle_request, edit_schedule)
