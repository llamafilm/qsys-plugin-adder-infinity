--debug mode
--layout["code"]={PrettyName="code",Style="None"}

local CurrentPage = PageNames[props["page_index"].Value]
if CurrentPage == "Control" then
  -- x,y cartesian coordinates
  local y = 16
  local gutter = 86

  -- button horiz/vert dimensions
  local button_h = 80
  local button_v = 40

  table.insert(graphics,
  {
  Type = "Header",
  Text = "Connection Status",
  Position = { 0, y },
  Size = { button_h*10,16 }
  })

  y = y+32

  table.insert(graphics,
    {
    Type = "Text",
    HTextAlign = "Right",
    Text = "IP address",
    Position = { 0, y },
    Size = { 76,16 }
    })

  layout['IPAddress'] =
    {
    PrettyName = 'AIM IP address',
    Position = {gutter,y},
    Size = { 180,16 },        
    }

  layout['Refresh'] =
    {
    PrettyName = 'Refresh Connection',
    Position = {gutter+180,y},
    Size = { 36,16 },
    Margin = 0,        
    }

  table.insert(graphics,
    {
    Type = "Text",
    HTextAlign = "Right",
    Text = "Status",
    Position = { gutter+180+36, y },
    Size = { 76,16 }
    })

  layout['Status'] =
    {
    PrettyName = 'Status',
    Position = {gutter+180+36+86,y},
    Size = { 220,16 },        
    }

  y = y+16

table.insert(graphics,
  {
  Type = "Text",
  HTextAlign = "Right",
  Text = "Username",
  Position = { 0, y },
  Size = { 76,16 }
  })

layout['Username'] =
  {
  PrettyName = 'Username',
  Position = {gutter,y},
  Size = { 180,16 },        
  }

y = y+16

table.insert(graphics,
  {
  Type = "Text",
  HTextAlign = "Right",
  Text = "Password",
  Position = { 0, y },
  Size = { 76,16 }
  })

layout['Password'] =
  {
  PrettyName = 'Password',
  Position = {gutter,y},
  Size = { 180,16 },        
  }

  y = y+48

  table.insert(graphics,
      {
      Type = "Header",
      Text = "Channel Connect Buttons",
      HTextAlign = "Center",
      Position = { 0, y },
      Size = { button_h*10,16 }
      })

  y = y+32

  for i=1,10 do
    layout['Channel ' .. i] =
    {
      Position = {i*button_h-button_h, y},
      Size = {button_h, 16},
      Style = "ComboBox"
    }
    layout['Receiver ' .. i] =
    {
      Position = {i*button_h-button_h, y+16},
      Size = {button_h, 16},
      Style = "ComboBox"
    }
    layout['Mode ' .. i] =
    {
      Position = {i*button_h-button_h, y+32},
      Size = {button_h, 16},
      Style = "ComboBox"
    }
    layout['ConnectChannel ' .. i] =
    {
      Position = {i*button_h-button_h, y+48},
      Size = {button_h, 40}
    }
  end
--[[
  -- layout max 10 buttons per row
  local num_rows = math.ceil(max_presets / 10)
  for row=0,num_rows-1 do
    for col = 1,10 do
      local preset = row*10 + col
      if preset > max_presets then break end
      layout['PresetTrigger '.. preset] = 
        {
        PrettyName = string.format("Preset~%i", preset),
        Position = { col*button_h-button_h, y},
        Style = 'Button',
        Size = { button_h, button_v },
        }  
    end
    y = y + 45 -- move down to next row
  end
  ]]
end 