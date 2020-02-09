----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar huisvuil script: script_time_garbagewijzer.lua
----------------------------------------------------------------------------------------------------------------
ver="20200209-1800"
-- curl in os required!!
-- create dummy text device from dummy hardware with the name defined for: myGarbageDevice
-- Check the timing when to get a notification for each Garbagetype in the garbagetype_cfg table
-- Check forumtopic:       https://www.domoticz.com/forum/viewtopic.php?f=61&t=17963
-- Check source updates:   https://github.com/jvanderzande/mijngarbagewijzer
--
-- ##################################################################################################################################################################
---##  update the settings in /garbagecalendar/garbagecalendarconfig.lua !!!!
-- ##################################################################################################################################################################

--===================================================================================================================
-- start logic - no changes below this line
--===================================================================================================================
websitemodule = "???"

-- mydebug print
function dprint(text, always)
   if testdataload or mydebug or (always or 0)==1 then
      print("@GarbageCalendar("..websitemodule.."): "..text)
   end
   file = io.open(datafilepath.."garbagecalendar_run_"..websitemodule..".log", "a")
   file:write("@GarbageCalendar("..websitemodule.."): "..text.."\n")
   file:close()
end
-- try getting current scriptpath to be able to get the /garbagecalendar/garbagecalendarconfig.lua loaded
function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*[/\\])")
end
scriptpath=script_path() or "./"
--ensure the all path variables ends with /
scriptpath=(scriptpath.."/"):gsub('//','/')
-------------------------------------------------------
-- Load garbagecalendarconfig.lua
function garbagecalendarconfig()
   if unexpected_condition then error() end
   -- add defined Domoticz path to the search path
   package.path = scriptpath..'garbagecalendar/?.lua;./garbagecalendar/?.lua;' .. package.path
   require "garbagecalendarconfig"
   -- check if debugging is required
   testdataload = testdataload or false
   mydebug = mydebug or false
   ShowSinglePerType = mydebug or true
   -- emptyprevious run logfile
   domoticzjsonpath=(domoticzjsonpath.."/"):gsub('//','/')
   datafilepath=(datafilepath.."/"):gsub('//','/')
   scriptpath=(scriptpath.."/"):gsub('//','/')
   file = io.open(datafilepath.."garbagecalendar_run_"..websitemodule..".log", "w")
   file:close()
   dprint('#### start garbagecalendar script v'.. ver)
   if testdataload then
      dprint('#### Debuging dataload each cycle in the foreground because "testdataload=true" in garbagecalendarconfig.lua')
      dprint('####    please change it back to "testdataload=false" when done testing to avoid growing a big domoticz log and slowing down the event system.')
   end
   if mydebug or false then
      dprint('#### Debuging with extra messages because "mydebug=true" in garbagecalendarconfig.lua')
      dprint('####    please change it back to "mydebug=false" when done testing to avoid growing a big domoticz log.')
   end
   --ensure the all path variables ends with /
   dprint('domoticzjsonpath: ' .. domoticzjsonpath)
   dprint('datafilepath: ' .. datafilepath)
   dprint('scriptpath: ' .. scriptpath)
end
if pcall(garbagecalendarconfig) then
   dprint('Loaded ' .. scriptpath..'garbagecalendar/garbagecalendarconfig.lua.' )
else
   dprint('#### start garbagecalendar script v'.. ver)
   dprint('Error: failed loading "garbagecalendarconfig.lua" from : "' .. scriptpath..'garbagecalendar/"',1)
   dprint('       Ensure you have copied "garbagecalendarconfig_model.lua" to "garbagecalendarconfig.lua" and modified it to your requirements.',1 )
   dprint('       Also check the path in variable "scriptpath= "  is correctly set.',1 )
   os.exit() -- stop execution
   return
end

-------------------------------------------------------
-- Load tablefuncs.lua
function tablefuncs()
   if unexpected_condition then error() end
   -- add defined Domoticz path to the search path
   package.path = scriptpath..'garbagecalendar/?.lua;' .. package.path
   require "table_funcs"
end
if pcall(tablefuncs) then
   dprint('Loaded ' .. scriptpath..'garbagecalendar/tablefuncs.lua.' )
else
   dprint('Error: failed loading tablefuncs.lua from : ' .. scriptpath..'garbagecalendar/.',1)
   dprint('Error: Please check the path in variable "scriptpath= "  in your setup and try again.',1 )
   os.exit() -- stop execution
   return
end
----------------------------------------------------------------------------------------------------------------
-- Function to check if we can access a file
function haveaccess(file)
--~    print ("---------------------")
--~    print (file)
   local ok, err, code = io.open(file, "r")
--~    print (ok)
--~    print (err)
--~    print (code)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return false
      end
   end
--~    print ("---------------------")
   if ok ~= nil then
      ok:close()
      return true
   else
      return false
   end
end
----------------------------------------------------------------------------------------------------------------
-- Function to check if directory exists
function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end
--- Check if a directory exists in this path
function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end
if (not isdir(datafilepath)) then
   dprint('Error: invalid path for datafilepath : ' .. datafilepath..'.',1)
   dprint('Error: Please check the path in variable "datafilepath= " in your "garbagecalenderconfig.lua" setup and try again.',1 )
   os.exit() -- stop execution
end

if (not exists(scriptpath .. "garbagecalendar/"..websitemodule..".lua")) then
   dprint('Error: module not found: ' .. scriptpath .. "garbagecalendar/"..websitemodule..'.lua',1)
   dprint('Error: Please check the path&name in variables "scriptpath=" "websitemodule= "  in your "garbagecalenderconfig.lua" setup and try again.',1 )
   os.exit() -- stop execution
end
----------------------------------------------------------------------------------------------------------------
-- General conversion tables
local nMON={"jan","feb","maa","apr","mei","jun","jul","aug","sep","okt","nov","dec"}
----------------------------------------------------------------------------------------------------------------
-- round function
function Round(num, idp)
   return tonumber(string.format("%." ..(idp or 0).. "f", num))
end

----------------------------------------------------------------------------------------------------------------
-- run dataupdate
function GetWebDataInBackground(whenrun)
   logfile = datafilepath.."garbagecalendar_web_"..websitemodule..".log"
   datafile = datafilepath.."garbagecalendar.data"
   --# reshell this file in the background to perform update of the data
   local command = 'lua '..scriptpath .. "garbagecalendar/" .. websitemodule .. '.lua'
   command = command .. ' "' .. domoticzjsonpath ..'"'
   command = command .. ' "' .. Zipcode .. '"'
   command = command .. ' "' .. Housenr .. '"'
   command = command .. ' "' .. Housenrsuf .. '"'
   command = command .. ' "' .. datafile .. '"'
   command = command .. ' "' .. logfile .. '"'
   command = command .. ' "' .. (Hostname or "") .. '"' -- optional param
   command = command .. ' "' .. (Street or "") .. '"'   -- optional param
   if ((whenrun or "") == "now") then
      dprint('start foreground webupdate for module '..websitemodule..' of file '..datafile)
      os.execute(command .. ' > '.. logfile..' 2>&1 ')
   else
      dprint('start background webupdate for module '..websitemodule..' of file '..datafile)
      os.execute(command .. ' > '.. logfile..' 2>&1 &')
   end
   dprint(command,1)
end


----------------------------------------------------------------------------------------------------------------
-- get days between today and provided date
function getdaysdiff(i_garbagetype_date, stextformat)
   local curTime = os.time{day=timenow.day,month=timenow.month,year=timenow.year}
   -- check if date in variable i_garbagetype_date contains "vandaag" in stead of a valid date -> use today's date
   garbageyear,garbagemonth,garbageday=i_garbagetype_date:match("(%d-)-(%d-)-(%d-)$")
   if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
      dprint (' Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date,1)
      return
   end
   local garbageTime = os.time{day=garbageday,month=garbagemonth,year=garbageyear}
   local wday=daysoftheweek[os.date("*t", garbageTime).wday]
   stextformat = stextformat:gsub('wd',wday)
   stextformat = stextformat:gsub('dd',garbageday)
   stextformat = stextformat:gsub('mmm',nMON[tonumber(garbagemonth)])
   stextformat = stextformat:gsub('mm',garbagemonth)
   stextformat = stextformat:gsub('yyyy',garbageyear)
   stextformat = stextformat:gsub('yy',garbageyear:sub(3,4))
   -- return number of days diff
   return stextformat, Round(os.difftime(garbageTime, curTime)/86400,0)   -- 1 day = 86400 seconds
end

----------------------------------------------------------------------------------------------------------------
--
function notification(s_garbagetype,s_garbagetype_date,i_daysdifference)
   if garbagetype_cfg[s_garbagetype] ~= nil
   and (timenow.hour==garbagetype_cfg[s_garbagetype].hour or timenow.hour==garbagetype_cfg[s_garbagetype].hour+garbagetype_cfg[s_garbagetype].reminder)
   and timenow.min==garbagetype_cfg[s_garbagetype].min
   and i_daysdifference == garbagetype_cfg[s_garbagetype].daysbefore then
      local dag = ""
      if garbagetype_cfg[s_garbagetype].daysbefore == 0 then
         dag = notificationtoday or "vandaag"
      elseif garbagetype_cfg[s_garbagetype].daysbefore == 1 then
         dag = notificationtomorrow or "morgen"
      else
         dag = notificationlonger or 'over @DAYS@ dagen'
         dag = dag:gsub('@DAYS@',tostring(garbagetype_cfg[s_garbagetype].daysbefore))
      end
      notificationtitle = notificationtitle:gsub('@DAY@',dag)
      notificationtitle = notificationtitle:gsub('@GARBAGETYPE@',s_garbagetype)
      notificationtitle = notificationtitle:gsub('@GARBAGETEXT@',tostring(garbagetype_cfg[s_garbagetype].text))
      notificationtitle = notificationtitle:gsub('@GARBAGEDATE@',s_garbagetype_date)
      notificationtext = notificationtext:gsub('@DAY@',dag)
      notificationtext = notificationtext:gsub('@GARBAGETYPE@',s_garbagetype)
      notificationtext = notificationtext:gsub('@GARBAGETEXT@',tostring(garbagetype_cfg[s_garbagetype].text))
      notificationtext = notificationtext:gsub('@GARBAGEDATE@',s_garbagetype_date)
      if type(NotificationEmailAdress) == 'table' then
         for x,emailaddress in pairs(NotificationEmailAdress) do
            if emailaddress ~= "" then
               commandArray[x] = {['SendEmail'] = notificationtitle .. '#' .. notificationtext .. '#' .. emailaddress}
               dprint ('---->Notification Email send for ' .. s_garbagetype.. " |"..notificationtitle .. '#' .. notificationtext .. '#' .. emailaddress.."|", 1)
            end
         end
      else
         if NotificationEmailAdress ~= "" then
            commandArray['SendEmail'] = notificationtitle .. '#' .. notificationtext .. '#' .. NotificationEmailAdress
            dprint ('---->Notification Email send for ' .. s_garbagetype.. " |"..notificationtitle .. '#' .. notificationtext .. '#' .. NotificationEmailAdress.."|", 1)
         end
      end

      if Notificationsystem ~= "" then
         commandArray['SendNotification']=notificationtitle .. '#' .. notificationtext .. '####'..Notificationsystem
         dprint ('---->Notification send for '.. s_garbagetype.. " |"..notificationtitle .. '#' .. notificationtext .. '####'..Notificationsystem, 1)
      end

      if Notificationscript ~= "" then
         Notificationscript = Notificationscript:gsub('@TEXT@',notificationtext)
         os.execute( Notificationscript..' &')
         dprint ('---->Notification script started: '.. Notificationscript, 1)
      end
   end
end

----------------------------------------------------------------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Data_check()
   local missingrecords=""
   local devtxt=""
   local txtcnt = 0
   -- function to process ThisYear and Lastyear JSON data
   --
   dprint('Start update for text device:',1)
   local datafile = datafilepath.."garbagecalendar.data"
   logfile = datafilepath.."garbagecalendar.log"
   garbagedata,perr = table.load( datafile )
   if perr ~= 0 then
      --- when file doesn't exist
      dprint("Warning: Datafile not found:"..datafile.." . Start webupdate now.")
      GetWebDataInBackground("now")
   end
   garbagedata,perr = table.load( datafile )
   if perr ~= 0 then
      --- when file doesn't exist
      dprint(" Unable to load the data. please check your setup and logfile :"..logfile)
   else
      dprint("- start looping through the received data from the websaite stored in "..datafilepath.."garbagecalendar.data  -------------------------")
      for i = 1, #garbagedata do
         if garbagedata[i].garbagetype ~= nil then
            web_garbagetype = garbagedata[i].garbagetype
            web_garbagedate = garbagedata[i].garbagedate
            web_garbagedesc = (garbagedata[i].wdesc or "")
            if (web_garbagedesc == "") then
               if garbagetype_cfg[web_garbagetype] ~= nil then
                  web_garbagedesc = garbagetype_cfg[web_garbagetype].text
               else
                  web_garbagedesc = "???"
               end
            end
            -- first match for each Type we save the date to capture the first next dates
            if garbagetype_cfg[web_garbagetype] == nil then
               dprint (' Error: Garbagetype not defined in the "garbagetype_cfg" table for found GarbageType : ' .. web_garbagetype.."  desc:"..web_garbagedesc,1)
               if web_garbagedesc == "???" then web_garbagedesc = web_garbagetype end
               missingrecords = missingrecords .. '   ["' .. web_garbagetype..'"]'..string.rep(" ", 32-string.len(web_garbagetype))..' ={hour=19,min=02,daysbefore=1,reminder=0,text="'..web_garbagetype..'"},\n'
               garbagetype_cfg[web_garbagetype] = {hour=0,min=0,daysbefore=0,reminder=0,text="dummy"}
               garbagetype_cfg[web_garbagetype].text = web_garbagetype
            end
            if txtcnt < ShowNextEvents then
               -- get daysdiff
               local stextformat = textformat
               stextformat, daysdiffdev = getdaysdiff(web_garbagedate, stextformat)
               -- check whether the first nextdate for this garbagetype is already found to get only one next date per GarbageType
               if ShowSinglePerType or (garbagetype_cfg[web_garbagetype].nextdate == nil and txtcnt < ShowNextEvents) then
                  -- get the long description from the JSON data
                  dprint("==> GarbageDate:"..tostring (web_garbagedate) .. "  GarbageType:"..tostring(web_garbagetype).. '  Notification Config_Time='..tostring(garbagetype_cfg[web_garbagetype].hour)..':'..tostring(garbagetype_cfg[web_garbagetype].min)..'   Config_Notify_DaysBefore='..tostring(garbagetype_cfg[web_garbagetype].daysbefore)..'   Calculated_Days_Differerence='..tostring(daysdiffdev))
                 -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
                  if daysdiffdev == nil then
                     dprint ('    !!! Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
                  elseif daysdiffdev >= 0 then
                     -- Set the nextdate for this garbagetype
                     garbagetype_cfg[web_garbagetype].nextdate = web_garbagedate
                     -- fill the text with the next defined number of events
                     notification(web_garbagetype,web_garbagedate,daysdiffdev)  -- check notification for new found info
                  end
                  stextformat = stextformat:gsub('sdesc',web_garbagetype)
                  stextformat = stextformat:gsub('ldesc',web_garbagedesc)
                  stextformat = stextformat:gsub('tdesc',garbagetype_cfg[web_garbagetype].text)
                  devtxt = devtxt..stextformat.."\r\n"
                  txtcnt = txtcnt + 1
               end
            end
         end
      end
   end
   dprint("-End   ---------------------------------------------------------------------------------------------------------")
   if missingrecords ~= "" then
      dprint('#### -- start -- Add these records to you garbagecalendarconfig.lua file to variable garbagetype_cfg and adapt the scgedule and text :',1)
      print(missingrecords)
      dprint('#### -- end ----------------------------')
   end
   if (cnt==0) then
      dprint (' Error: No valid data found in returned webdata.  skipping the rest of the logic.',1)
      return
   end
   -- always update the domoticz device so one can see it is updating and when it was ran last.
   dprint ('==> found schedule:'..devtxt:gsub('\r\n', ' ; '),1)
   if otherdevices_idx == nil or otherdevices_idx[myGarbageDevice] == nil then
      dprint ("Error: Couldn't get the current data from Domoticz text device "..myGarbageDevice )
   else
      commandArray['UpdateDevice'] = otherdevices_idx[myGarbageDevice] .. '|0|' .. devtxt
      if (otherdevices[myGarbageDevice] ~= devtxt) then
         dprint ('Update device from: \n'.. otherdevices[myGarbageDevice] .. '\n replace with:\n' .. devtxt)
      else
         dprint ('No updated text for TxtDevice.')
      end
   end
end

----------------------------------------------------------------------------------------------------------------
-- check access rights to file and try fixing for linux OSes
function Perform_Rights_check(filename)
   if (exists(filename)) then
      if (not haveaccess(filename)) then
         dprint('No access to the file. Running->sudo chmod 777 '..filename,1)
         os.execute("sudo chmod 777 "..filename.." 2>nul")
         if (haveaccess(filename)) then
            dprint('Access fixed to the data file.',1)
         else
            dprint('Still no access. Please check the settings for '..filename.. ' and then try again.',1)
            os.exit()
         end
      end
   end
end

-- End Functions ===============================================================================================
-- check defaults set
if daysoftheweek == nil then
   daysoftheweek={"Zon","Maa","Din","Woe","Don","Vri","Zat"}
end
-- checkif testload is requested
if testdataload or false then
   GetWebDataInBackground("now")
end
-- Start of logic ==============================================================================================
commandArray = {}
timenow = os.date("*t")
-- ensure the access is set correctly for data
Perform_Rights_check(datafilepath.."garbagecalendar.data")
Perform_Rights_check(datafilepath.."garbagecalendar_run_"..websitemodule..".log")
Perform_Rights_check(datafilepath.."garbagecalendar_web_"..websitemodule..".log")

-- check for notification times and run update only when we are at one of these defined times
dprint('Start checking garbagetype_cfg table:')
local needupdate = false
if garbagetype_cfg == nil then
   dprint('Error: failed loading the "garbagetype_cfg" table from your garbagecalendarconfig.lua file. Please check your setup file.',1)
   os.exit()
end
for tbl_garbagetype,get in pairs(garbagetype_cfg) do
   if garbagetype_cfg[tbl_garbagetype].reminder == nil then
      garbagetype_cfg[tbl_garbagetype].reminder = 0
   end
   dprint("-> NotificationTime:"..tostring(garbagetype_cfg[tbl_garbagetype].hour)..":"..tostring(garbagetype_cfg[tbl_garbagetype].min)..'  Garbagetype:'..tostring(tbl_garbagetype))
   if (timenow.hour==garbagetype_cfg[tbl_garbagetype].hour
   or  timenow.hour==garbagetype_cfg[tbl_garbagetype].hour+garbagetype_cfg[tbl_garbagetype].reminder)
   and timenow.min==garbagetype_cfg[tbl_garbagetype].min then
      if tbl_garbagetype == "reloaddata" then
         -- perform background data updates
         GetWebDataInBackground()
      else
         needupdate = true
      end
   end
end
-- Always update when mydebugging
if mydebug then needupdate = true end
-- get information from website, update device and send notification when required
if needupdate then
   Perform_Data_check()
else
   dprint("Scheduled time(s) not reached yet, so nothing to do!")
end

return commandArray