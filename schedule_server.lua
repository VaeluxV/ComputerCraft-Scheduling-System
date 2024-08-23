-- schedule_server.lua
-- Main schedule server with editable schedule and save functionality

local modem = peripheral.find("modem") -- Find attached ender modem
local channel = 5 -- Communication channel

-- Open the modem on the server
modem.open(channel)
print("Server is running on channel " .. channel) -- DEBUG: To show the server is ready

-- Original train schedule (modifiable)
local active_schedule = {
    {name = "Industry Metro", arrival = "12:00", departure = "12:10", delayed = false},
    {name = "TGV to city", arrival = "12:20", departure = "12:30", delayed = true},
    {name = "S-Train to city", arrival = "12:40", departure = "12:50", delayed = false},
    {name = "Special service", arrival = "13:00", departure = "13:10", delayed = false}
}

-- Function to handle incoming requests from display computers
local function handle_request()
    while true do
        local event, side, channel_received, reply_channel, message, distance = os.pullEvent("modem_message")
        
        -- DEBUG: Show that a message was received
        print("Received message on channel " .. tostring(channel_received) .. ": " .. tostring(message))

        if channel_received == channel and message == "request_schedule" then
            -- Send back the active schedule
            modem.transmit(reply_channel, channel, active_schedule)
            print("Sent schedule to display on channel " .. tostring(reply_channel)) -- DEBUG: Confirm transmission
        else
            print("Received an unexpected message or on wrong channel.")
        end
    end
end

-- Run the server
handle_request()
