-- schedule_display.lua
-- Display train schedules on the monitor

local modem = peripheral.find("modem") -- Find attached ender modem
local monitor = peripheral.find("monitor") -- Find attached advanced monitor
local channel = 5 -- Communication channel

-- Check if the modem and monitor are found
if not modem then
    print("Modem not found. Please ensure an ender modem is attached.")
    return
end

if not monitor then
    print("Monitor not found. Please ensure an advanced monitor is attached.")
    return
end

modem.open(channel) -- Open the modem to the correct channel
print("Display computer is ready on channel " .. channel) -- DEBUG

-- Monitor settings
monitor.setTextScale(1) -- Set text scale for fitting content on the screen

-- Display settings
local title = "Train Arrivals & Departures"
local row_colors = { colors.white, colors.lightBlue }
local text_color = colors.black
local delayed_color = colors.red
local title_color = colors.black
local title_bg_color = colors.lightGray

-- Function to clear and reset the monitor
local function clear_monitor()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

-- Function to draw a title in bold and centered
local function draw_title()
    local monitor_width, _ = monitor.getSize()
    local title_length = #title
    local start_x = math.floor((monitor_width - title_length) / 2) -- Center the title

    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(title_bg_color)
    monitor.setTextColor(title_color)
    monitor.clearLine()
    monitor.setCursorPos(start_x, 1)
    monitor.write(title)
end

-- Function to scroll the train name if it is too long
local function scroll_text(text, width, scroll_offset)
    if #text <= width then
        return text
    else
        return text:sub(scroll_offset, scroll_offset + width - 1)
    end
end

-- Function to align text with a fixed width
local function align_text(text, width)
    return text .. string.rep(" ", width - #text) -- Adds padding to align text
end

-- Function to display the schedule
local function display_schedule(schedule)
    local monitor_width, monitor_height = monitor.getSize()

    -- Title row
    draw_title()

    -- Define column widths for alignment
    local train_column_width = monitor_width - 18 -- Space for name (remaining space)
    local time_column_width = 8 -- Space for arrival and departure times

    -- Loop through each train schedule and display
    for i, train in ipairs(schedule) do
        local line_num = i + 1 -- Start displaying from the second line (after the title)

        -- Scroll train name if it is too long
        local train_name = scroll_text(train.name, train_column_width, (os.clock() % (#train.name - train_column_width + 11)))

        -- Align arrival and departure times
        local arrival_time = align_text(train.arrival, time_column_width)
        local departure_time = align_text(train.departure, time_column_width)

        -- Build the full display line
        local display_line = train_name .. " Arr: " .. arrival_time .. " Dep: " .. departure_time

        -- Set alternating background colors
        local background_color = row_colors[(i % #row_colors) + 1]
        monitor.setBackgroundColor(background_color)

        -- Check if the train is delayed and set text color
        if train.delayed then
            monitor.setTextColor(delayed_color)
        else
            monitor.setTextColor(text_color)
        end

        -- Display the line
        monitor.setCursorPos(1, line_num)
        monitor.clearLine()
        monitor.write(display_line)
    end
end

-- Function to request the schedule from the server
local function request_schedule()
    print("Requesting schedule...") -- DEBUG: Print to verify request is sent
    modem.transmit(channel, channel, "request_schedule") -- Request schedule from server

    -- Wait for a modem message event
    local event, side, channel_received, reply_channel, message, distance = os.pullEvent("modem_message")

    -- DEBUG: Print to verify message received
    print("Message received on channel: " .. tostring(channel_received))

    -- Check if the received message is on the correct channel
    if channel_received == channel then
        print("Schedule received from server.") -- DEBUG: Print to verify
        return message
    else
        print("Received message on wrong channel.") -- DEBUG: Print for wrong channel
        return nil
    end
end

-- Main loop to continuously update the display
while true do
    local schedule = request_schedule() -- Request the schedule from the server

    -- Display schedule if it was successfully received
    if schedule then
        display_schedule(schedule)
    else
        print("Failed to retrieve schedule. Retrying in 5 seconds...") -- DEBUG: Show failure
    end

    sleep(5) -- Refresh every 5 seconds for testing (can be adjusted)
end
