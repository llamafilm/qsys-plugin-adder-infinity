table.insert (ctrls,
  {
  Name = "IPAddress",
  ControlType = "Text",
  Count = 1,
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "Username",
  ControlType = "Text",
  Count = 1,
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "Password",
  ControlType = "Text",
  Count = 1,
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "Status",
  ControlType = "Indicator",
  IndicatorType = "Status",
  Count = 1,
  UserPin = true,
  PinStyle = 'Output',
  })

table.insert (ctrls,
  {
  Name = "Refresh",
  ControlType = "Button",
  ButtonType = "Trigger",
  Count = 1,
  Icon = 'Refresh',
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "Channel",
  ControlType = "Text",
  Count = 10,
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "Receiver",
  ControlType = "Text",
  Count = 10,
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "Mode",
  ControlType = "Text",
  Count = 10,
  UserPin = false,
  })

table.insert (ctrls,
  {
  Name = "ConnectChannel",
  ControlType = "Button",
  ButtonType = "Trigger",
  Count = 10,
  UserPin = true,
  PinStyle = 'both',
  })

-- debug mode
-- table.insert(ctrls,{Name = "code",ControlType = "Text",UserPin = false,PinStyle = "Input",Count = 1})