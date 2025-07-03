--[[
REVISION HISTORY
=======================================================================================
ver   date      Auth  Description
---------------------------------------------------------------------------------------
1.1   ???????   EB    v1.1.1.0 of plugin written by Elliott Balsley.

1.2   11MAR25   REH   Slight modification to remove need to press refresh button
                      when changing IP address etc.

1.3   11MAR25   REH   Minor update to prevent 'compromised' state after 24hrs
                      * Added timer to request new token every 12 hrs
                        This will not help if AIM is restarted!

                      * Added code to call login() if connect_channel fails
                        This will help if AIM is restarted.

                      * Enabled input pin for refresh button
=======================================================================================
]]
PluginInfo = {
  Name = "Adder Infinity Plugin",
  Version = "1.3",
  BuildVersion = "1.3.0.2",
  Id = "67cb0d58-1be8-4641-8e64-d1705a74d07e",
  Author = "Elliott Balsley",
  Description = "A plugin for Adder Infinity KVM",
  Manufacturer = "Adder"
}