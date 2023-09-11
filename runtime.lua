function dump(o, indent)
  if indent == nil then indent = 0 end
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '\n' .. string.rep(' ', indent)  .. '['..k..'] = ' .. dump(v, indent+2) .. ', '
    end
    return s .. ' }'
  else
    return tostring(o)
  end
end -- end dump

function update_presets()
  for i=1,#Controls.PresetTrigger,1 do
    Controls.PresetTrigger[i].Legend = ''
  end
  for i=1,#presets,1 do
    Controls.PresetTrigger[i].Legend = presets[i].cp_name
  end

  -- disable buttons for presets that don't exist
  for i=1,#Controls.PresetTrigger do
    if i > preset_count then
      Controls.PresetTrigger[i].IsDisabled = true
    else
      Controls.PresetTrigger[i].IsDisabled = false
    end
  end
end --end update_presets


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
    Controls.Mode[i].Choices = {"v", "s", "e", "p"}
    Controls.Mode[i].String = "s"
  end
end -- end update_controls


function handle_get_presets(tbl, code, data, err, headers)
  presets = {}

  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
  if data ~= "" then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    -- read preset names and apply labels to UI
    if XML ~= "" then
      local found = XML:find("connection_presets")
      if found == nil then
        print(data)
        Controls.Status.Value = 2
      else
        Controls.Status.Value = 0
        preset_count = #found
        print("Preset count: ", preset_count)
        for k,v in pairs(found) do -- iterate across each preset
          if type(v) == 'table' then
            for k2,v2 in pairs(v) do -- iterate across each property of a preset
              if v2[0] == 'cp_name' then
                cp_name = v2[1]
              elseif v2[0] == 'cp_id' then
                cp_id = v2[1]
              elseif v2[0] == 'cp_active' then
                cp_active = v2[1]
              end
            end
            table.insert(presets, {cp_id=cp_id, cp_name=cp_name, cp_active=cp_active})
          end
        end
      end
    end
  end
  update_presets()
end -- end handle_get_presets


function handle_get_devices(tbl, code, data, err, headers)
  receivers = {}
  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
  if data ~= "" then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    -- read device names and apply labels to UI
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
--print(dump(receivers))
  get_channels()
end -- end handle_get_devices


function handle_get_channels(tbl, code, data, err, headers)
  channels = {}
  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
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


function get_presets()
  url = base_url .. 'v=1&method=get_presets&token=' .. token
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_get_presets}
end -- end get_presets


function get_channels()
  url = base_url .. 'v=2&method=get_channels&token=' .. token
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_get_channels}
end -- end get_channels


function handle_login(tbl, code, data, err, headers)
  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
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


function handle_connect_preset(tbl, code, data, err, headers)
  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
  if (data ~= "") and (code == 200) then -- make sure there is some response
    XML = xml.eval(data) -- encode input string to lua table and assign to var XML

    if XML ~= "" then -- make sure the find string and XML var have data
      local found = XML:find("success") -- convert the found XML data to a string and assign to var found
      if found ~= nil then -- ensure found has data (nil means could not find string)
        if found[1] == "1" then
          Controls.Status.Value = 0
          return
        end
      end
    end
  end
  Controls.Status.Value = 1
  print(data)
  print("Connecting preset failed")
end -- end handle_connect_preset


function connect_preset(i)
  url = base_url .. 'v=5&method=connect_preset&force=1&token=' .. token .. '&id=' .. presets[i].cp_id
  HttpClient.Download { Url=url, Timeout=3, EventHandler=handle_connect_preset}
end -- end connect_preset


function handle_connect_channel(tbl, code, data, err, headers)
  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
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
  print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ) )
  if (data ~= "") and (code == 200) then -- make sure there is some response
    -- don't both parsing response.  It will show an error if Rx is already disconnected
    connect_channel(i)
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

  url = base_url .. string.format('v=5&method=connect_channel&force=1&token=%s&c_id=%s&rx_id=%s&mode=%s', token, c_id, rx_id, mode)
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
 
print('hello world')
login()

Controls.Refresh.EventHandler = login
for i=1,10 do
  Controls.ConnectChannel[i].EventHandler = function()
    button_pressed=i
    disconnect_channel()
  end
end