-- setup Debug print
DebugTx, DebugRx, DebugFunction = false, false, false
DebugPrint = Properties['Debug Print'].Value
if DebugPrint == 'Tx/Rx' then
  DebugTx, DebugRx = true, true
elseif DebugPrint == 'Tx' then
  DebugTx = true
elseif DebugPrint == 'Rx' then
  DebugRx = true
elseif DebugPrint == 'Function Calls' then
  DebugFunction = true
elseif DebugPrint == 'All' then
  DebugTx, DebugRx, DebugFunction = true, true, true
end

-- define global variables
ActionQueue = {}
BaseUrl = ''
Channels = {}
LoginAttempts = 0
Receivers = {}
Token = ''


function UpdateControls()
  -- make a list of receiver names
  local rx_names = {}
  for _,rx in pairs(Receivers) do
    table.insert(rx_names, rx.name)
  end

  -- make a list of channel names
  local chan_names = {}
  for _,chan in pairs(Channels) do
    table.insert(chan_names, chan.name)
  end

  for i=1,10 do
    Controls.Receiver[i].Choices = rx_names
    Controls.Channel[i].Choices = chan_names
    Controls.Mode[i].Choices = {"video-only", "shared", "exclusive", "private"}
    Controls.Mode[i].String = "shared"
  end
end -- end UpdateControls


function GetReceivers()
  if DebugFunction then print("Refreshing receivers...") end
  local url = BaseUrl .. 'v=2&method=get_devices&device_type=rx&token=' .. Token
  HttpClient.Download { Url=url, Timeout=1, EventHandler=HandleHttpResponse}
end  -- end GetReceivers


function GetChannels()
  if DebugFunction then print("Refreshing channels...") end
  local url = BaseUrl .. 'v=2&method=get_channels&token=' .. Token
  HttpClient.Download { Url=url, Timeout=1, EventHandler=HandleHttpResponse}
end -- end GetChannels


function Login()
  if Controls.IPAddress.String == '' then
    Controls.Status.Value = 4 -- missing
    return
  end

  if DebugFunction then print("Refreshing auth token...") end
  Controls.Status.Value = 5 -- initializing
  Controls.Status.String = "Refreshing auth token"
  BaseUrl = 'http://' .. Controls.IPAddress.String .. '/api?'
  local url = BaseUrl .. 'v=1&method=login&username=' .. Controls.Username.String .. '&password=' .. Controls.Password.String
  HttpClient.Download { Url=url, Timeout=1, EventHandler=HandleHttpResponse}
end -- end Login


function HandleHttpResponse(tbl, code, data, err, headers)
  -- handle all HTTP responses and call other functions based on the API method

  if DebugRx then print(string.format("HTTP response from '%s': Return Code=%i; Error=%s; Data=%s", tbl.Url, code, err or "None", data or "None")) end
  if code ~= 200 then
    Controls.Status.Value = 2
    if code == 0 then
      Controls.Status.String = err
    else
      Controls.Status.String = string.format('HTTP %i: %s', code, err)
    end
    return
  end

  -- parse XML response string to lua table
  local ok, response = pcall(function()
    return xml.eval(data)
  end)

  local match = response:find('success')

  if not (ok and match) then
    Controls.Status.Value = 2
    Controls.Status.String = "Failed to parse XML response"
    return
  end

  local success = response:find('success')[1]
  if success == '0' then
    local msg = response:find('msg')[1]
    Controls.Status.Value = 2
    Controls.Status.String = msg

    -- retry login if the token is expired
    if msg == 'Login required' then
      if DebugFunction then print("Refreshing auth token...") end
      Login()
    else
      return
    end
  end

  Controls.Status.Value = 0
  local method = tbl.Url:match("method=([^&]+)")

  if (method == 'login') then
    OnLogin(response)
  elseif method == 'get_devices' then
    OnGetReceivers(response)
  elseif method == 'get_channels' then
    OnGetChannels(response)
  elseif method == 'disconnect_channel' then
    if DebugFunction then print("Disconnected!") end
  elseif method == 'connect_channel' then
    if DebugFunction then print("Connected!") end
  else
    Controls.Status.Value = 1
    Controls.Status.String = string.format("Unknown method: %s", method)
  end
end -- end HandleHttpResponse


-- extract API token from response
function OnLogin(response)
  Token = response:find("token")[1]
  --print('API token: ' .. Token)
  GetReceivers()
  GetChannels()
end -- end OnLogin


-- refresh global Channels table
function OnGetChannels(response)
  Channels = {}

  local channels = response:find("channels")
  for _,chan in pairs(channels) do -- iterate across each channel
    if type(chan) == 'table' then
      local c_name, c_id
      for _,prop in pairs(chan) do -- iterate across each property of a channel
        if prop[0] == 'c_name' then
          c_name = prop[1]
        elseif prop[0] == 'c_id' then
          c_id = prop[1]
        end
      end
      table.insert(Channels, {name=c_name, id=c_id})
    end
  end
  if DebugFunction then print(string.format("Got %i channels", #Channels)) end
  UpdateControls()
end -- end OnGetChannels


-- refresh global Receivers table
function OnGetReceivers(response)
  Receivers = {}

  local devices = response:find("devices")
  for _,device in pairs(devices) do -- iterate across each receiver
    if type(device) == 'table' then
      local rx_name, rx_id, rx_username
      for _,prop in pairs(device) do -- iterate across each property of a receiver
        if prop[0] == 'd_name' then
          rx_name = prop[1]
        elseif prop[0] == 'd_id' then
          rx_id = prop[1]
        elseif prop[0] == 'u_username' then
          rx_username = prop[1]
        end
      end
      table.insert(Receivers, {name=rx_name, id=rx_id, username=rx_username})
    end
  end
  if DebugFunction then print(string.format("Got %i receivers", #Receivers)) end

  -- Run the next action in the queue. If multiple buttons are pushed simultaneously,
  -- the responses may come out of order. So then we'll make the connections out of
  -- order, but that shouldn't be a problem.
  if #ActionQueue > 0 then
    local action = table.remove(ActionQueue, 1)
    action()
  end
end -- end OnGetReceivers

function ConnectChannel(button_pressed)
  -- find channel by name
  local chan
  for _,channel in pairs(Channels) do
    if channel.name == Controls.Channel[button_pressed].String then
      chan = channel
      break
    end
  end

  -- find receiver by name
  local rx
  for _,receiver in pairs(Receivers) do
     if receiver.name == Controls.Receiver[button_pressed].String then
      rx = receiver
      break
    end
  end

  if DebugFunction then print(string.format("Connecting channel '%s' to receiver '%s'", chan.name, rx.name)) end

  -- if Rx is in use by another user, we have to disconnect it first
  if rx.username ~= nil and rx.username ~= Controls.Username.String then
    if DebugFunction then print(string.format("Receiver is in use by %s.", rx.username)) end
    DisconnectChannel(button_pressed)
  end

  local mode = Controls.Mode[button_pressed].String:sub(1,1)
  local url = string.format(
    '%sv=5&method=connect_channel&force=1&token=%s&c_id=%s&rx_id=%s&mode=%s',
    BaseUrl, Token, chan.id, rx.id, mode
  )
  HttpClient.Download { Url=url, Timeout=1, EventHandler=HandleHttpResponse}
end -- end ConnectChannel


function DisconnectChannel(button_pressed)
  -- find receiver by name
  local rx
  for _,receiver in pairs(Receivers) do
    if receiver.name == Controls.Receiver[button_pressed].String then
      rx = receiver
    end
  end

  if DebugFunction then print(string.format("Disconnecting receiver '%s'", rx.name)) end

  local url = string.format(
    '%sv=2&method=disconnect_channel&force=1&token=%s&rx_id=%s',
    BaseUrl, Token, rx.id
  )
  HttpClient.Download { Url=url, Timeout=1, EventHandler=HandleHttpResponse}
end -- end DisconnectChannel


Controls.IPAddress.EventHandler = Login
Controls.Username.EventHandler = Login
Controls.Password.EventHandler = Login

for i=1,10 do
  Controls.ConnectChannel[i].EventHandler = function()
    -- refresh devices first to ensure username is current
    -- add global callback to the queue so it runs after devices are refreshed
    if Controls.Channel[i].String ~= '' and Controls.Receiver[i].String ~= '' then
      table.insert(ActionQueue, function() ConnectChannel(i) end)
      GetReceivers()
    end
  end
end

-- code that runs on startup
print('hello world')
Login()
