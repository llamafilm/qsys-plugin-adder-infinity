-- define global variables
BaseUrl = ''
Channels = {}
Receivers = {}
Token = ''


function UpdateControls()
  -- make a list of receiver names
  local rx_names = {}
  for _,rx in pairs(Receivers) do
    table.insert(rx_names, rx['rx_name'])
  end

  -- make a list of channel names
  local chan_names = {}
  for _,chan in pairs(Channels) do
    table.insert(chan_names, chan['c_name'])
  end

  for i=1,10 do
    Controls.Receiver[i].Choices = rx_names
    Controls.Channel[i].Choices = chan_names
    Controls.Mode[i].Choices = {"video-only", "shared", "exclusive", "private"}
    Controls.Mode[i].String = "shared"
  end
end -- end UpdateControls


function HandleGetDevices(tbl, code, data, err, headers)
  Receivers = {}
  if data ~= "" then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    -- read device names
    if XML ~= "" then
      local found = XML:find("devices")
      if found == nil then
        print(data)
        Controls.Status.Value = 2
      else
        Controls.Status.Value = 0
        for _,device in pairs(found) do -- iterate across each receiver
          if type(device) == 'table' then
            local rx_name, rx_id, c_name
            for _,prop in pairs(device) do -- iterate across each property of a receiver
              if prop[0] == 'd_name' then
                rx_name = prop[1]
              elseif prop[0] == 'd_id' then
                rx_id = prop[1]
              elseif prop[0] == 'c_name' then
                c_name = prop[1]
              end
            end
            table.insert(Receivers, {rx_name=rx_name, rx_id=rx_id, c_name=c_name})
          end
        end
      end
    end
  end
  GetChannels()
end -- end HandleGetDevices


function HandleGetChannels(tbl, code, data, err, headers)
  Channels = {}
  if data ~= "" then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    -- read device names and apply labels to UI
    if XML ~= "" then
      local found = XML:find("channels")
      if found == nil then
        print(data)
        Controls.Status.Value = 2
      else
        Controls.Status.Value = 0
        for _,chan in pairs(found) do -- iterate across each channel
          if type(chan) == 'table' then
            local c_name, c_id
            for _,prop in pairs(chan) do -- iterate across each property of a channel
              if prop[0] == 'c_name' then
                c_name = prop[1]
              elseif prop[0] == 'c_id' then
                c_id = prop[1]
              end
            end
            table.insert(Channels, {c_name=c_name, c_id=c_id})
          end
        end
      end
    end
  end
  UpdateControls()
end -- end handle_GetChannels


function GetDevices()
  local url = BaseUrl .. 'v=2&method=get_devices&device_type=rx&token=' .. Token
  HttpClient.Download { Url=url, Timeout=3, EventHandler=HandleGetDevices}
end  -- end GetDevices


function GetChannels()
  local url = BaseUrl .. 'v=2&method=get_channels&token=' .. Token
  HttpClient.Download { Url=url, Timeout=3, EventHandler=HandleGetChannels}
end -- end GetChannels


function HandleLogin(tbl, code, data, err, headers)
  if (data ~= "") and (code == 200) then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    -- extract API token from response
    if XML ~= "" then -- make sure the find string and XML var have data
      local found = XML:find("token") -- convert the found XML data to a string and assign to var found
      if found == nil then -- ensure found has data (nil means could not find string)
        print(data)
        Controls.Status.Value = 2
        Controls.Status.String = XML:find("msg")[1]
      else
        Controls.Status.Value = 0
        Token = found[1]
        GetDevices()
        return
        --print('API token: ' .. Token)
      end
    end
  else
    Controls.Status.String = string.format('HTTP %.0d', code)
  end
  Controls.Status.Value = 2 -- if anything above failed
end -- end HandleLogin


function Login()
  Controls.Status.Value = 5 -- display initializing status
  BaseUrl = 'http://' .. Controls.IPAddress.String .. '/api?'
  local url = BaseUrl .. 'v=1&method=login&username=' .. Controls.Username.String .. '&password=' .. Controls.Password.String
  HttpClient.Download { Url=url, Timeout=3, EventHandler=HandleLogin}
end -- end Login


function HandleConnectChannel(tbl, code, data, err, headers)
  if (data ~= "") and (code == 200) then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    if XML ~= "" then -- make sure the find string and XML var have data
      local found = XML:find("success") -- convert the found XML data to a string and assign to var found
      if found ~= nil then -- ensure found has data (nil means could not find string)
        if found[1] == "1" then
          Controls.Status.Value = 0
          return
        else
          print(XML:find("msg")[1])
        end
      end
    end
  end
  Controls.Status.Value = 1
  Login() --REH 1.3
end -- end HandleConnectChannel


function HandleDisconnectChannel(tbl, code, data, err, headers)
  if (data ~= "") and (code == 200) then -- make sure there is some response
    -- don't both parsing response.  It will show an error if Rx is already disconnected
    ConnectChannel()
  end
end -- end HandleDisconnectChannel


function ConnectChannel()
  local c_id, rx_id, mode_short

  -- find chan_id
  for _,chan in pairs(Channels) do
    if chan.c_name == Controls.Channel[button_pressed].String then
      c_id = chan.c_id
    end
  end

  -- find rx_id
  for _,rx in pairs(Receivers) do
     if rx.rx_name == Controls.Receiver[button_pressed].String then
      rx_id = rx.rx_id
    end
  end

  local mode = Controls.Mode[button_pressed].String
  if mode == 'video-only' then
    mode_short = 'v'
  elseif mode == 'shared' then
    mode_short = 's'
  elseif mode == 'exclusive' then
    mode_short = 'e'
  elseif mode == 'private' then
    mode_short = 'p'
  end

  local url = BaseUrl .. string.format('v=5&method=connect_channel&force=1&token=%s&c_id=%s&rx_id=%s&mode=%s', Token, c_id, rx_id, mode_short)
  HttpClient.Download { Url=url, Timeout=3, EventHandler=HandleConnectChannel}
end -- end ConnectChannel


function DisconnectChannel()
  local rx_id

  -- find rx_id
  for _,rx in pairs(Receivers) do
    if rx.rx_name == Controls.Receiver[button_pressed].String then
      rx_id = rx.rx_id
    end
  end

  local url = BaseUrl .. string.format('v=2&method=disconnect_channel&force=1&token=%s&rx_id=%s', Token, rx_id)
  HttpClient.Download { Url=url, Timeout=3, EventHandler=HandleDisconnectChannel}
end -- end DisconnectChannel

--REH 1.2
Controls.IPAddress.EventHandler = Login
Controls.Username.EventHandler = Login
Controls.Password.EventHandler = Login
--reh
Controls.Refresh.EventHandler = Login


--REH 1.3
AccessTokenRequestTimer = Timer.New()
function AccessTokenRequestTimerHandler(timer, count)
  print('Requesting new access token ...')
  Login()
end
AccessTokenRequestTimer.EventHandler = AccessTokenRequestTimerHandler
AccessTokenRequestTimer:Start(43200)  --Every 12Hrs
--reh


for i=1,10 do
  Controls.ConnectChannel[i].EventHandler = function()
    button_pressed=i
    -- disconnect first to avoid error if Rx in use by another user
    DisconnectChannel()
  end
end

-- code that runs on startup
print('hello world')
Login()
