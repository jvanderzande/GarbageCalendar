----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar huisvuil script: script_time_garbagewijzer.lua
----------------------------------------------------------------------------------------------------------------
ver="20200404-1400"
-- curl in os required!!
-- create dummy text device from dummy hardware with the name defined for: myGarbageDevice
-- Update all your personal settings in garbagecalendar/garbagecalendarconfig.lua
--
-- Wiki for details: https://github.com/jvanderzande/GarbageCalendar/wiki
-- source updates:   https://github.com/jvanderzande/garbagecalendar
-- forumtopic:       https://www.domoticz.com/forum/viewtopic.php?f=61&t=31295
--
-- ##################################################################################################################################################################
-- ##  update the settings in /garbagecalendar/garbagecalendarconfig.lua !!!!
-- ##################################################################################################################################################################

--===================================================================================================================
-- start logic - no changes below this line
--===================================================================================================================
-- Define gobal variable
websitemodule = "???"
domoticzjsonpath=""
datafilepath=""
scriptpath=""
weblogfile = ""
runlogfile = ""
datafile = ""
needupdate = false
timenow = os.date("*t")

-- mydebug print
function dprint(text, always, prefix)
   local ptext = ""
   if (prefix or 1)==1 then
      ptext = "@GarbageCal("..websitemodule.."): "
   end
   if testdataload or mydebug or (always or 0)>=1 then
      print(ptext..text)
   end
   file = io.open(runlogfile, "a")
   file:write(ptext..text.."\n")
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
   ShowSinglePerType = ShowSinglePerType or false
   -- initialise the variables
   domoticzjsonpath=(domoticzjsonpath.."/"):gsub('//','/')
   datafilepath=(datafilepath.."/"):gsub('//','/')
   scriptpath=(scriptpath.."/"):gsub('//','/')
   runlogfile = datafilepath.."garbagecalendar_run_"..websitemodule..".log"
   weblogfile = datafilepath.."garbagecalendar_web_"..websitemodule..".log"
   datafile = datafilepath.."garbagecalendar_"..websitemodule..".data"
   -- empty previous run runlogfile
   file = io.open(runlogfile, "w")
   file:close()
   dprint('#### '..os.date("%c")..' ### Start garbagecalendar script v'.. ver)
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
   print('#### '..("%02d:%02d:%02d"):format(timenow.hour, timenow.min, timenow.sec)..' start garbagecalendar script v'.. ver)
   print('!!! Error: failed loading "garbagecalendarconfig.lua" from : "' .. scriptpath..'garbagecalendar/"')
   print('       Ensure you have copied "garbagecalendarconfig_model.lua" to "garbagecalendarconfig.lua" and modified it to your requirements.')
   print('       Also check the path in variable "scriptpath= "  is correctly set.',1 )
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
   dprint('!!! Error: failed loading tablefuncs.lua from : ' .. scriptpath..'garbagecalendar/.',1)
   dprint('!!! Error: Please check the path in variable "scriptpath= "  in your setup and try again.',1 )
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
   dprint('!!! Error: invalid path for datafilepath : ' .. datafilepath..'.',1)
   dprint('!!! Error: Please check the path in variable "datafilepath= " in your "garbagecalenderconfig.lua" setup and try again.',1 )
   return
end

if (not exists(scriptpath .. "garbagecalendar/"..websitemodule..".lua")) then
   dprint('!!! Error: module not found: ' .. scriptpath .. "garbagecalendar/"..websitemodule..'.lua',1)
   dprint('!!! Error: Please check the path&name in variables "scriptpath=" "websitemodule= "  in your "garbagecalenderconfig.lua" setup and try again.',1 )
   return
end

-- round function
function Round(num, idp)
   return tonumber(string.format("%." ..(idp or 0).. "f", num))
end

----------------------------------------------------------------------------------------------------------------
-- run dataupdate
function GetWebDataInBackground(whenrun)
   --# reshell this file in the background to perform update of the data
   local command = 'lua '..scriptpath .. "garbagecalendar/" .. websitemodule .. '.lua'
   command = command .. ' "' .. domoticzjsonpath ..'"'
   command = command .. ' "' .. Zipcode .. '"'
   command = command .. ' "' .. Housenr .. '"'
   command = command .. ' "' .. Housenrsuf .. '"'
   command = command .. ' "' .. datafile .. '"'
   command = command .. ' "' .. weblogfile .. '"'
   command = command .. ' "' .. (Hostname or "") .. '"' -- optional param
   command = command .. ' "' .. (Street or "") .. '"'   -- optional param
   if ((whenrun or "") == "now") then
      dprint('start foreground webupdate for module '..websitemodule..' of file '..datafile)
      os.execute(command .. ' > '.. weblogfile..' 2>&1 ')
   else
      dprint('start background webupdate for module '..websitemodule..' of file '..datafile)
      os.execute(command .. ' > '.. weblogfile..' 2>&1 &')
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
   local lwday=Longdaysoftheweek[os.date("*t", garbageTime).wday]
   stextformat = stextformat:gsub('wd',wday)
   stextformat = stextformat:gsub('wdd',lwday)
   stextformat = stextformat:gsub('dd',garbageday)
   stextformat = stextformat:gsub('mmmm',LongMonth[tonumber(garbagemonth)])
   stextformat = stextformat:gsub('mmm',ShortMonth[tonumber(garbagemonth)])
   stextformat = stextformat:gsub('mm',garbagemonth)
   stextformat = stextformat:gsub('yyyy',garbageyear)
   stextformat = stextformat:gsub('yy',garbageyear:sub(3,4))
   -- return number of days diff
   return stextformat, Round(os.difftime(garbageTime, curTime)/86400,0)   -- 1 day = 86400 seconds
end

----------------------------------------------------------------------------------------------------------------
--
function notification(s_garbagetype,s_garbagetype_date,i_daysdifference)
   if ( garbagetype_cfg[s_garbagetype] ~= nil and timenow.min==garbagetype_cfg[s_garbagetype].min and garbagetype_cfg[s_garbagetype].active == "on" )
   or ( testnotification or false ) then
      if (
            (  timenow.hour == garbagetype_cfg[s_garbagetype].hour                                               --First notification
            or timenow.hour == garbagetype_cfg[s_garbagetype].hour+garbagetype_cfg[s_garbagetype].reminder       --same day reminder
            )
            and i_daysdifference == garbagetype_cfg[s_garbagetype].daysbefore
         )
      or (
            timenow.hour == garbagetype_cfg[s_garbagetype].hour+garbagetype_cfg[s_garbagetype].reminder-24       --next day reminder
            and i_daysdifference+1 == garbagetype_cfg[s_garbagetype].daysbefore
         )
      or ( testnotification or false ) then
         testnotification = false  -- this will trigger a test notification for the first record
         local dag = ""
         if i_daysdifference == 0 then
            dag = notificationtoday or "vandaag"
         elseif i_daysdifference == 1 then
            dag = notificationtomorrow or "morgen"
         else
            dag = notificationlonger or 'over @DAYS@ dagen'
            dag = dag:gsub('@DAYS@',tostring(i_daysdifference))
         end
         local inotificationdate  = notificationdate or 'yyyy-mm-dd'
         garbageyear,garbagemonth,garbageday=s_garbagetype_date:match("(%d-)-(%d-)-(%d-)$")
         local garbageTime = os.time{day=garbageday,month=garbagemonth,year=garbageyear}
         local wday=daysoftheweek[os.date("*t", garbageTime).wday]
         local lwday=Longdaysoftheweek[os.date("*t", garbageTime).wday]
         inotificationdate = inotificationdate:gsub('wdd',lwday)
         inotificationdate = inotificationdate:gsub('wd',wday)
         inotificationdate = inotificationdate:gsub('dd',garbageday)
         inotificationdate = inotificationdate:gsub('mmmm',LongMonth[tonumber(garbagemonth)])
         inotificationdate = inotificationdate:gsub('mmm',ShortMonth[tonumber(garbagemonth)])
         inotificationdate = inotificationdate:gsub('mm',garbagemonth)
         inotificationdate = inotificationdate:gsub('yyyy',garbageyear)
         inotificationdate = inotificationdate:gsub('yy',garbageyear:sub(3,4))
         inotificationtitle = notificationtitle or 'GarbageCalendar: @DAY@ de @GARBAGETEXT@ aan de weg zetten!'
         inotificationtitle = inotificationtitle:gsub('@DAY@',dag)
         inotificationtitle = inotificationtitle:gsub('@GARBAGETYPE@',s_garbagetype)
         inotificationtitle = inotificationtitle:gsub('@GARBAGETEXT@',tostring(garbagetype_cfg[s_garbagetype].text))
         inotificationtitle = inotificationtitle:gsub('@GARBAGEDATE@',inotificationdate)
         inotificationtext = notificationtext or '@GARBAGETEXT@ wordt @DAY@ opgehaald!'
         inotificationtext = inotificationtext:gsub('@DAY@',dag)
         inotificationtext = inotificationtext:gsub('@GARBAGETYPE@',s_garbagetype)
         inotificationtext = inotificationtext:gsub('@GARBAGETEXT@',tostring(garbagetype_cfg[s_garbagetype].text))
         inotificationtext = inotificationtext:gsub('@GARBAGEDATE@',inotificationdate)
         if type(NotificationEmailAdress) == 'table' then
            for x,emailaddress in pairs(NotificationEmailAdress) do
               if emailaddress ~= "" then
                  commandArray[x] = {['SendEmail'] = inotificationtitle .. '#' .. inotificationtext .. '#' .. emailaddress}
                  dprint ('---->Notification Email send for ' .. s_garbagetype.. " |"..inotificationtitle .. '#' .. inotificationtext .. '#' .. emailaddress.."|", 1)
               end
            end
         else
            if (NotificationEmailAdress or "") ~= "" then
               commandArray['SendEmail'] = inotificationtitle .. '#' .. inotificationtext .. '#' .. NotificationEmailAdress
               dprint ('---->Notification Email send for ' .. s_garbagetype.. " |"..inotificationtitle .. '#' .. inotificationtext .. '#' .. NotificationEmailAdress.."|", 1)
            end
         end

         if (Notificationsystem or "") ~= "" then
            commandArray['SendNotification']=inotificationtitle .. '#' .. inotificationtext .. '####'..Notificationsystem
            dprint ('---->Notification send for '.. s_garbagetype.. " |"..inotificationtitle .. '#' .. inotificationtext .. '####'..Notificationsystem, 1)
         end

         if (Notificationscript or "") ~= "" then
            Notificationscript = Notificationscript:gsub('@TEXT@',inotificationtext)
            Notificationscript = Notificationscript:gsub('@GARBAGETYPE@',s_garbagetype)
            Notificationscript = Notificationscript:gsub('@GARBAGETEXT@',tostring(garbagetype_cfg[s_garbagetype].text))
            Notificationscript = Notificationscript:gsub('@GARBAGEDATE@',inotificationdate)
            os.execute( Notificationscript..' &')
            dprint ('---->Notification script started: '.. Notificationscript, 1)
         end
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
   garbagedata,perr = table.load( datafile )
   if perr ~= 0 then
      --- when file doesn't exist
      dprint("Warning: Datafile not found:"..datafile.." . Start webupdate now.")
      GetWebDataInBackground("now")
   end
   garbagedata,perr = table.load( datafile )
   if perr ~= 0 then
      --- when file doesn't exist
      dprint(" Unable to load the data. please check your setup and runlogfile :"..runlogfile)
   else
      dprint("- Start looping through data from the website: "..datafile)
      for i = 1, #garbagedata do
         if garbagedata[i].garbagetype ~= nil then
            -- change all table entries to lower to make the script case insensitive
            web_garbagetype = garbagedata[i].garbagetype:lower()
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
--~                dprint (' Warning: Garbagetype not defined in the "garbagetype_cfg" table: ' .. web_garbagetype.."  desc:"..web_garbagedesc,1)
               if web_garbagedesc == "???" then web_garbagedesc = web_garbagetype end
               missingrecords = missingrecords .. '   ["' .. web_garbagetype:lower()..'"]'..string.rep(" ", 32-string.len(web_garbagetype))..' ={hour=19,min=02,daysbefore=1,reminder=0,text="'..web_garbagetype..'"},\n'
               garbagetype_cfg[web_garbagetype] = {hour=0,min=0,daysbefore=0,reminder=0,text="dummy"}
               garbagetype_cfg[web_garbagetype].text = web_garbagetype
            end
            if txtcnt < ShowNextEvents then
               -- get daysdiff
               local stextformat = textformat
               stextformat, daysdiffdev = getdaysdiff(web_garbagedate, stextformat)
               -- check whether the first nextdate for this garbagetype is already found to get only one next date per GarbageType
               if ((not ShowSinglePerType) or (garbagetype_cfg[web_garbagetype].nextdate == nil) and txtcnt < ShowNextEvents) then
                  -- get the long description from the JSON data
                  dprint("==> GarbageDate:" .. tostring (web_garbagedate) .. " GarbageType:" .. tostring(web_garbagetype) .. '  Notify: Active=' .. tostring(garbagetype_cfg[web_garbagetype].active) .. '  Time=' .. tostring(garbagetype_cfg[web_garbagetype].hour) .. ':' .. tostring(garbagetype_cfg[web_garbagetype].min) .. '   DaysBefore=' .. tostring(garbagetype_cfg[web_garbagetype].daysbefore) .. '   reminder=' .. tostring(garbagetype_cfg[web_garbagetype].reminder) .. '   Calc Days Diff=' .. tostring(daysdiffdev),0,0)
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
	if txtcnt < 1 then
		dprint("### Warning: No valid records found in the datafile: " .. datafile,1)
		dprint("###          Please check the garbagecalendar log files for issues : " .. weblogfile .. " and " .. runlogfile,1)
	end
   dprint("- End  ----------------- ")
   if missingrecords ~= "" then
      dprint('#### Warning: These records are missing in your garbagecalendarconfig.lua file, so no notifications will be send!',1)
      dprint('#### -- start -- Add these records into the garbagetype_cfg table and adapt the schedule and text info to your needs :',1)
      dprint(missingrecords,1,0)
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
            return false
         end
      end
   end
   return true
end

-- End Functions ===============================================================================================
-- check defaults set
daysoftheweek = daysoftheweek or {"Zon","Maa","Din","Woe","Don","Vri","Zat"}
Longdaysoftheweek = Longdaysoftheweek or {"zondag","maandag","dinsdag","woensdag","donderdag","vrijdag","zaterdag"}
ShortMonth = ShortMonth or {"jan","feb","maa","apr","mei","jun","jul","aug","sep","okt","nov","dec"}
LongMonth = LongMonth or {"januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december"}
----------------------------------------------------------------------------------------------------------------
-- checkif testload is requested
if testdataload or false then
   GetWebDataInBackground("now")
end

-- Start of logic ==============================================================================================
commandArray = {}
-- ensure the access is set correctly for data
if not Perform_Rights_check(datafilepath.."garbagecalendar.data") then return end
if not Perform_Rights_check(datafilepath.."garbagecalendar_run_"..websitemodule..".log") then return end
if not Perform_Rights_check(datafilepath.."garbagecalendar_web_"..websitemodule..".log") then return end

-- check for notification times and run update only when we are at one of these defined times
dprint('Start checking garbagetype_cfg table:')
if garbagetype_cfg == nil then
   dprint('!!! Error: failed loading the "garbagetype_cfg" table from your garbagecalendarconfig.lua file. Please check your setup file.',1)
   return
end
if garbagetype_cfg["reloaddata"] == nil or garbagetype_cfg["reloaddata"].hour == nil or garbagetype_cfg["reloaddata"].min == nil then
   dprint('!!! Warning: Web update will be performed on a default time at 02:30AM, because the "reloaddata" entry missing in the "garbagetype_cfg" table in your garbagecalendarconfig.lua file! ')
   dprint('           Check the original provided garbagecalendarconfig_model.lua for the correct format: ')
   dprint('             -- Add any missing records above this line')
   dprint('             ["reloaddata"] ={hour=02,min=30,daysbefore=0,reminder=0,text="trigger for reloading data from website into garbagecalendar.data"},')
   garbagetype_cfg["reloaddata"] = {hour=2,min=30,daysbefore=0,reminder=0,text="default added"}
end
-- check change all table entries for lowercase Garbagetype to make the script case insensitive and filled in fields
for tbl_garbagetype, gtdata in pairs(garbagetype_cfg) do
   if gtdata.active == nil or gtdata.active:lower() ~= "on" or gtdata.active:lower() ~= "off"then
      -- default active=on to perform each a notification for each GarbageType by default
      gtdata.active = "on"
   else
      gtdata.active = gtdata.active:lower()
   end
   if gtdata.hour == nil or gtdata.hour > 24 or gtdata.hour < 1  then
      dprint("!!!! Check hour field value for GarbageType "..tbl_garbagetype.."  current value:"..gtdata.hour)
      garbagetype_cfg[tbl_garbagetype].hour = 0
   end
   if gtdata.min == nil or gtdata.min > 59 or gtdata.min < 0  then
      dprint("!!!! Check min field value for GarbageType "..tbl_garbagetype.."  current value:"..gtdata.min)
      garbagetype_cfg[tbl_garbagetype].min = 0
   end
   if gtdata.reminder == nil or gtdata.reminder > 23  or gtdata.reminder < 0  then
      dprint("!!!! Check reminder field value for GarbageType "..tbl_garbagetype.."  current value:"..gtdata.reminder)
      garbagetype_cfg[tbl_garbagetype].reminder = 0
   end
   if (tbl_garbagetype ~= tbl_garbagetype:lower()) then
      dprint(tbl_garbagetype .. " change to "..tbl_garbagetype:lower())
      garbagetype_cfg[tbl_garbagetype:lower()] = {hour=gtdata.hour,min=gtdata.min,daysbefore=gtdata.daysbefore,reminder=gtdata.reminder,text=gtdata.text}
      garbagetype_cfg[tbl_garbagetype] = nil
   end
end
-- loop through the table to check whether
for tbl_garbagetype, gtdata in pairs(garbagetype_cfg) do
   dprint("-> NotificationTime:"..tostring(gtdata.hour)..":"..tostring(gtdata.min)..'  Garbagetype:'..tostring(tbl_garbagetype))
   if (   timenow.hour == gtdata.hour
      or  timenow.hour == gtdata.hour+gtdata.reminder    --reminder same day
      or  timenow.hour == gtdata.hour+gtdata.reminder-24 --reminder next day
      )
   and timenow.min  == gtdata.min then
      dprint("   NotificationTime is true ")
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
   -- empty previous run_update logfile
   Perform_Data_check()
   -- Save run log during update
   ifile = io.open(runlogfile, "r")
   ofile = io.open(string.gsub(runlogfile, "_run_", "_run_update_"), "w")
   ofile:write(ifile:read("*all"))
   ifile:close()
   ofile:close()
else
   dprint("Scheduled time(s) not reached yet, so nothing to do!")
end
timenow = os.date("*t")
dprint('#### '..("%02d:%02d:%02d"):format(timenow.hour, timenow.min, timenow.sec)..' End garbagecalendar script v'.. ver)

return commandArray