# Notifications

config notification script

1. ## Use Event system script
   Edit the following information in file **"garbagecalendarconfig.lua"**:

   1. #### Update garbagecalendarconfig.lua:

      ```lua
      -- Specify personal notification event script located in GarbageCalendar directory
      -- This example is provided and will work in DzVents and regular Lua Time Events
      EventNotificationscript = 'notification_event_script.lua'
      ```

   2. #### Available variables that can be used in the scriptcode:

      ```lua
      Notify_type     = GarbageType as defined as key in "garbagetype_cfg" and coming from the internet.
      Notify_text     = Formed text sentence using the settings from the "notificationtext" field
      Notify_date     = Formatted notification date using the config variable "notificationdate"
      Notify_mtitle   = Formatted Title sentence using the settings from the "notificationtitle" field
      Notify_mtext    = Description from "garbagetype_cfg" "text" field
      Notify_reminder = Formatted content for the config variable "notificationreminder"
      ```

   3. #### Edit the "notification_event_script.lua" scipt:

      This script currently contains an example to swithc an RGB lamp on for xx seconds and set the color depending on the garbagetype. The actions are by default disabled and the script return's always on line 15 without performing any action.
      To active the script just comment or remove line 15!
      It contains both the logic when ran in DzVents or as regular LUA Time Event.

      ```lua
      function notification_event(RunbyDzVents, commandArray, domoticz)
         -----------------------------------------------------------------------------------------------------------------
         -- garbagecalendar notification script
         -- Example script which will Switch a light on with specified color in case of a garbagecalendar notification
         --[[=== Available variables from the mainscript :
               Notify_type     = GarbageType as defined as key in "garbagetype_cfg" and coming from the internet.
               Notify_text     = Formed text sentence using the settings from the "notificationtext" field
               Notify_date     = Formatted notification date using the config variable "notificationdate"
               Notify_mtitle   = Formatted Title sentence using the settings from the "notificationtitle" field
               Notify_mtext    = Description from "garbagetype_cfg" "text" field
               Notify_reminder = Formatted content for the config variable "notificationreminder"
         ]]

         --##### To enable the script you have to remove/comment the next line ####
         if 1==1 then return end

         -- ensure they are all initialised to avoid errors.
         Notify_type = Notify_type or ""
         Notify_text = Notify_text or ""
         Notify_date = Notify_date or ""
         Notify_mtitle = Notify_mtitle or ""
         Notify_mtext = Notify_mtext or ""
         Notify_reminder = Notify_Reminder or ""
         -----------------------------------------------------------------------------------------------------------------
         -- Start you logic here in the appropriate section
         -----------------------------------------------------------------------------------------------------------------
         local lamp = 'TestLight'
         local ontime = 30

         if RunbyDzVents then
            -- ##############################################################
            -- DzVents logic part will only run when implemented in DzVents
            -- ##############################################################
            print('DzVents Type:' .. Notify_type ..
            ' text:' .. Notify_text ..
            ' Date:' .. Notify_date ..
            ' message title:' .. Notify_mtitle ..
            ' message text:' .. Notify_mtext ..
            ' Reminder:' .. Notify_reminder
            )

            print('Turn ' .. lamp .. ' on with a Color on for '..ontime..' seconds')
            --## Turn on lamp xx percent
            domoticz.devices(lamp).switchOn()
            --##  setColor(r, g, b, br, cw, ww, m, t)
            if Notify_type == 'gft' then	--green
               domoticz.devices(lamp).setColor(0, 255, 0, 50, 0, 0, 3, 0)
            elseif Notify_type == 'papier' then --blue
               domoticz.devices(lamp).setColor(0, 0, 255, 50, 0, 0, 3, 0)
            elseif Notify_type == 'pmd' then -- yellow
               domoticz.devices(lamp).setColor(255, 255, 0, 50, 0, 0, 3, 0)
            elseif Notify_type == 'restafval' then --
               domoticz.devices(lamp).setColor(128, 128, 128, 100, 0, 0, 3, 0)
            else -- purple
               domoticz.devices(lamp).setColor(128, 0, 128, 50, 0, 0, 3, 0)
            end

            --## Reset to WarmWhite after xx seconds
            domoticz.devices(lamp).setColor(0, 0, 0, 20, 0, 0, 2, 255) .afterSec(ontime-5)

            --## Turn off lamp after xx seconds when it is currently off
            if domoticz.devices(lamp).state == "Off" then
               domoticz.devices(lamp).switchOff().afterSec(ontime)
            end
         else
            -- ##############################################################
            -- LUA Time Event script, will only run when Lua Time Script
            -- ##############################################################
            print('LUA Time:' .. Notify_type ..
            ' text:' .. Notify_text ..
            ' Date:' .. Notify_date ..
            ' message title:' .. Notify_mtitle ..
            ' message text:' .. Notify_mtext ..
            ' Reminder:' .. Notify_reminder
            )
            print('Turn ' .. lamp .. ' on with a Color on for '..ontime..' seconds')
            --## get idx for lamp
            idx=otherdevices_idx[lamp]
            --## Turn on lamp
            commandArray[#commandArray + 1] = {[lamp] = 'On'}

            --##  setColor(r, g, b, br, cw, ww, m, t)
            url = 'http://127.0.0.1:8080/json.htm?type=command&param=setcolbrightnessvalue&idx='..idx
            if Notify_type == 'gft' then	--green
               url = url .. '&color={"m":3,"t":0,"r":0,"g":255,"b":0,"cw":0,"ww":0}&brightness=50'
            elseif Notify_type == 'papier' then --blue
               url = url .. '&color={"m":3,"t":0,"r":0,"g":0,"b":255,"cw":0,"ww":0}&brightness=50'
               domoticz.devices(lamp).setColor(0, 0, 255, 50, 0, 0, 3, 0)
            elseif Notify_type == 'pmd' then -- yellow
               url = url .. '&color={"m":3,"t":0,"r":255,"g":255,"b":0,"cw":0,"ww":0}&brightness=50'
               domoticz.devices(lamp).setColor(255, 255, 0, 50, 0, 0, 3, 0)
            elseif Notify_type == 'restafval' then --
               url = url .. '&color={"m":3,"t":0,"r":128,"g":128,"b":128,"cw":0,"ww":0}&brightness=50'
               domoticz.devices(lamp).setColor(128, 128, 128, 100, 0, 0, 3, 0)
            else -- purple
               url = url .. '&color={"m":3,"t":0,"r":128,"g":0,"b":128,"cw":0,"ww":0}&brightness=50'
               domoticz.devices(lamp).setColor(128, 0, 128, 50, 0, 0, 3, 0)
            end
            commandArray[#commandArray + 1] = {["OpenURL"] = url}

            --## Reset color after xx seconds via URL
            url = url .. '&color={"m":2,"t":255,"r":0,"g":0,"b":0,"cw":0,"ww":0}&brightness=20'
            url = url .. ' AFTER '..ontime
            commandArray[#commandArray + 1] = {["OpenURL"] = url}

            --## Turn off lamp after xx seconds when it is currently off
            if otherdevices['yourotherdevicename'] == "Off" then
               commandArray[#commandArray + 1] = {[lamp] = 'Off AFTER '..ontime}
            end
         end
      end
      ```

2. ## Use an async External process/script
   Edit the following information in file **"garbagecalendarconfig.lua"**:

   1. #### Available variables that can be used in the commandline:

      ```lua
      -- Supported variables for Title and Body
      -- @DAY@         ==> Will be replaced by notificationtoday; notificationtomorrow; notificationlonger depending on the days difference.
      -- @GARBAGETYPE@ ==> Will be replaced by the GarbageType definition from the WebSite
      -- @GARBAGEDATE@ ==> Will be replaced by the pickup date found on the schedule data
      -- @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
      -- @REMINDER@    ==> Will be set to "" for first notification and "notificationreminder" for the reminder run
      -- @TEXT@        ==> Will be replaced by the finalised notificationtext and can be used in the notification script
      -- @TITLE@       ==> Will be replaced by the finalised notificationtitle and can be used in the notification script
      ```

   2. #### Update garbagecalendarconfig.lua:

      ```lua
      -- Specify personal notification script/command eg:  lua sendmessage.lua "@TEXT@"  (where @TEXT@ will be replaced by the notification text.)
      ---Notificationscript = 'lua /home/pi/domoticz/scripts/lua/garbagecalendar/notification_external_script.lua "@GARBAGETYPE@" > /tmp/GC_Notify.log 2> /tmp/GC_Notify.log'
      ```

   3. #### Edit the scipt:

      ```lua
      -----------------------------------------------------------------------------------------------------------------
      -- garbagecalendar external notification script
      -- example for this setting which will switch on a CCT (RGB&CC/CW) lightbulb on a selected color at notification time:
      --   Notificationscript = 'lua notification_extenal_scrint.lua "@GARBAGETYPE@" > /tmp/GCexternal.log'
      -----------------------------------------------------------------------------------------------------------------
      --=============================================================
      -- get general functions script directory
      function script_path()
         return arg[0]:match('.*[/\\]') or './'
      end
      print(script_path() or '')
      -- include generalfunctions library
      dofile((script_path() or '') .. 'generalfuncs.lua') --

      -- Variables
      local domoticzurl = 'http://127.0.0.1:8080' -- define the url for domoticz
      local idx = 439 -- define the IDX of the Light
      afwlogfile = '/tmp/GC_ExEvent.data' -- datafile voor perform_webquery()
      local red = 0 -- Red color 0-255
      local green = 0 -- Green color 0-255
      local blue = 0 -- Blue color 0-255

      -- Get first commandline parameter => garbagetype
      local garbagetype = arg[1] or ''
      print('garbagetype:' .. (garbagetype or ''))

      -- Start logic
      if garbagetype == 'paper' then
         -- Turn on lamp and set color to blue
         blue = 255
      elseif garbagetype == 'gft' then
         -- Turn on lamp and set color to green
         green = 255
      end

      -- Proces when a color was defined
      if red ~= 0 or green ~= 0 or blue ~= 0 then
         print('Colors (r g b):', red, green, blue)

         -- Set lamp to the defined color and brightness
         -- See the Wiki for the proper definition you might require for your lightbulbs:
         -- https://www.domoticz.com/wiki/Domoticz_API/JSON_URL's#Set_a_light_to_a_certain_color_or_color_temperature
         brightness = 100 -- (0-100%)
         url = " --data-urlencode 'color={\"m\":3,\"t\":0,\"r\":" .. red .. ',"g":' .. green .. ',"b":' .. blue .. "}' "
         url = url .. ' "' .. domoticzurl .. '/json.htm?type=command&param=setcolbrightnessvalue&idx=' .. idx .. '&brightness=' .. brightness .. '"'
         print(url)

         perform_webquery(url, true)

         -- sleep xx seconds
         os.execute('sleep 30')

         -- Set lamp back to regular color and brightness
         brightness = 20 -- (0-100%)
         url = " --data-urlencode 'color={\"m\":2,\"t\":0,\"r\":0,\"g\":0,\"b\":0,\"cw\":0,\"ww\":255}' "
         url = url .. ' "' .. domoticzurl .. '/json.htm?type=command&param=setcolbrightnessvalue&idx=' .. idx .. '&brightness=' .. brightness .. '"'
         perform_webquery(url, true)

         -- Switch Off the light when required
         url = '"' .. domoticzurl .. '/json.htm?type=command&param=switchlight&idx=' .. idx .. '&switchcmd=Off"'
         print(url)
         perform_webquery(url, true)
      end
      ```

3. ## force Notification for testing your changes

   Open your **"garbagecalendarconfig.lua"** and set these debugging variables to **true**:  
   **mydebug = true  -- (true/false)**  
   **testnotification = true -- (true/false)**  
   This will force the first found event notification each run.

## We're done

   You should be ready to go now. Ensure you reset the mydebug to:   
   **"mydebug = false  -- (true/false)"**  
   **testnotification = false -- (true/false)**  
   to avoid a lot of messages in the Domoticz log.  
   check the [testing](testing) page in case you need to test/debug your installation.
