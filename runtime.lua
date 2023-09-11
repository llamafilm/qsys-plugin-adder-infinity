function update_controls()
  -- make a list of receiver names
  rx_names = {}
  for k,v in pairs(receivers) do
    table.insert(rx_names, v['rx_name'])
  end

  -- make a list of channel names
  chan_names = {}
  for k,v in pairs(channels) do
    table.insert(chan_names, v['c_name'])
  end

  for i=1,10 do
    Controls.Receiver[i].Choices = rx_names
    Controls.Channel[i].Choices = chan_names
    Controls.Mode[i].Choices = {"video-only", "shared", "exclusive", "private"}
    Controls.Mode[i].String = "shared"
  end
end -- end update_controls


function handle_get_devices(tbl, code, data, err, headers)
  receivers = {}
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
        for k,v in pairs(found) do -- iterate across each receiver
          if type(v) == 'table' then
            for k2,v2 in pairs(v) do -- iterate across each property of a receiver
              if v2[0] == 'd_name' then
                rx_name = v2[1]
              elseif v2[0] == 'd_id' then
                rx_id = v2[1]
              elseif v2[0] == 'c_name' then
                c_name = v2[1]
              end
            end
            table.insert(receivers, {rx_name=rx_name, rx_id=rx_id, c_name=c_name})
          end
        end
      end
    end
  end
  get_channels()
end -- end handle_get_devices


function handle_get_channels(tbl, code, data, err, headers)
  channels = {}
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
        for k,v in pairs(found) do -- iterate across each channel
          if type(v) == 'table' then
            for k2,v2 in pairs(v) do -- iterate across each property of a channel
              if v2[0] == 'c_name' then
                c_name = v2[1]
              elseif v2[0] == 'c_id' then
                c_id = v2[1]
              end
            end
            table.insert(channels, {c_name=c_name, c_id=c_id})
          end
        end
      end
    end
  end
  update_controls()
end -- end handle_get_channels


function get_devices()
  url = base_url .. 'v=2&method=get_devices&device_type=rx&token=' .. token
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_get_devices}
end  -- end get_devices


function get_channels()
  url = base_url .. 'v=2&method=get_channels&token=' .. token
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_get_channels}
end -- end get_channels


function handle_login(tbl, code, data, err, headers)
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
        token = found[1]
        get_devices()
        return
        --print('API token: ' .. token)
      end
    end
  else
    Controls.Status.String = string.format('HTTP %.0d', code)
  end
  Controls.Status.Value = 2 -- if anything above failed
end -- end handle_login


function login()
  Controls.Status.Value = 5 -- display initializing status
  base_url = 'http://' .. Controls.IPAddress.String .. '/api?'
  url = base_url .. 'v=1&method=login&username=' .. Controls.Username.String .. '&password=' .. Controls.Password.String
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_login}
end -- end login


function handle_connect_channel(tbl, code, data, err, headers)
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
end -- end handle_connect_channel


function handle_disconnect_channel(tbl, code, data, err, headers)
  if (data ~= "") and (code == 200) then -- make sure there is some response
    -- don't both parsing response.  It will show an error if Rx is already disconnected
    connect_channel()
  end
end -- end handle_disconnect_channel


function connect_channel()
  -- find chan_id
  for k,v in pairs(channels) do
    if v.c_name == Controls.Channel[button_pressed].String then
      c_id = v.c_id
    end
  end
  
  -- find rx_id
  for k,v in pairs(receivers) do
     if v.rx_name == Controls.Receiver[button_pressed].String then
      rx_id = v.rx_id
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

  url = base_url .. string.format('v=5&method=connect_channel&force=1&token=%s&c_id=%s&rx_id=%s&mode=%s', token, c_id, rx_id, mode_short)
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_connect_channel}
end -- end connect_channel


function disconnect_channel()
  -- disconnect first to avoid error if Rx in use by another user

  -- find rx_id
  for k,v in pairs(receivers) do
     if v.rx_name == Controls.Receiver[button_pressed].String then
      rx_id = v.rx_id
    end
  end

  url = base_url .. string.format('v=2&method=disconnect_channel&force=1&token=%s&rx_id=%s', token, rx_id)
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_disconnect_channel}
end -- end disconnect_channel


Controls.Refresh.EventHandler = login
for i=1,10 do
  Controls.ConnectChannel[i].EventHandler = function()
    button_pressed=i
    disconnect_channel()
  end
end

-- code that runs on startup
print('hello world')
login()
