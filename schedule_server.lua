-- schedule_server.lua
-- Main schedule server with editable schedule and save functionality

local modem = peripheral.find("modem") -- Find attached ender modem
local channel = 5 -- Communication channel
modem.open(5) -- Prevent issues by opening channel 5 on the modem

-- Original train schedule (modifiable)
local active_schedule = {
    {name = "Industry Metro", arrival = "12:00", departure = "12:10", delayed = false},
    {name = "TGV to city", arrival = "12:20", departure = "12:30", delayed = true},
    {name = "S-Train to city", arrival = "12:40", departure = "12:50", delayed = false},
    {name = "Special service", arrival = "13:00", departure = "13:10", delayed = false}
}

-- Temporary schedule (for editing)
local temp_schedule = {}

-- Function to copy the active schedule to the temporary schedule for editing
local function copy_schedule(source, destination)
    destination = {}
    for _, train in ipairs(source) do
        table.insert(destination, {name = train.name, arrival = train.arrival, departure = train.departure, delayed = train.delayed})
    end
    return destination
end

-- Copy the active schedule to the temporary one to start
temp_schedule = copy_schedule(active_schedule, temp_schedule)

-- Function to display the current schedule
local function display_schedule(schedule)
    print("Current Schedule:")
    for i, train in ipairs(schedule) do
        print(i .. ". " .. train.name .. " Arr: " .. train.arrival .. " Dep: " .. train.departure .. " Delayed: " .. tostring(train.delayed))
    end
end

-- Function to modify a specific train's data
local function modify_train(schedule)
    display_schedule(schedule)
    print("Enter the number of the train you want to edit or 'cancel' to stop editing:")
    local input = read()

    if input == "cancel" then
        print("Editing cancelled.")
        return
    end

    local train_index = tonumber(input)
    if train_index and schedule[train_index] then
        print("Editing train: " .. schedule[train_index].name)

        print("Enter new train name (leave empty to keep current):")
        local new_name = read()
        if new_name ~= "" then
            schedule[train_index].name = new_name
        end

        print("Enter new arrival time (leave empty to keep current):")
        local new_arrival = read()
        if new_arrival ~= "" then
            schedule[train_index].arrival = new_arrival
        end

        print("Enter new departure time (leave empty to keep current):")
        local new_departure = read()
        if new_departure ~= "" then
            schedule[train_index].departure = new_departure
        end

        print("Is the train delayed? (yes/no):")
        local delayed_input = read()
        if delayed_input == "yes" then
            schedule[train_index].delayed = true
        elseif delayed_input == "no" then
            schedule[train_index].delayed = false
        end

        print("Train updated.")
    else
        print("Invalid train number.")
    end
end

-- Function to save the temporary schedule to the active schedule
local function save_schedule()
    active_schedule = copy_schedule(temp_schedule, active_schedule)
    print("Schedule saved successfully.")
end

-- Function to handle incoming requests from display computers
local function handle_request()
    while true do
        local event, side, channel_received, reply_channel, message, distance = os.pullEvent("modem_message")
        if channel_received == channel and message == "request_schedule" then
            modem.transmit(reply_channel, channel, active_schedule)
            print("Schedule sent to display.")
        end
    end
end

-- Function to start editing the schedule
local function edit_schedule()
    local is_editing = true
    while is_editing do
        print("\n1. Modify Train")
        print("2. Save Changes")
        print("3. Cancel Changes")
        print("4. Exit")

        local choice = read()

        if choice == "1" then
            modify_train(temp_schedule)
        elseif choice == "2" then
            save_schedule()
        elseif choice == "3" then
            temp_schedule = copy_schedule(active_schedule, temp_schedule) -- Reset temp schedule to active
            print("Changes cancelled. Schedule reset.")
        elseif choice == "4" then
            print("Exiting edit mode.")
            is_editing = false
        else
            print("Invalid option.")
        end
    end
end

-- Run the server
parallel.waitForAny(handle_request, edit_schedule)
