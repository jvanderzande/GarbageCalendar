-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_ximmio.lua
----------------------------------------------------------------------------------------------------------------
ver="20200317-1600"
websitemodule="m_ximmio"
-- API WebSite:  https://wasteapi.2go-mobile.com/api
--
--- Find your companycode by:
--   1. goto your webpage calendar and display the garbage calendar
--   2. go into Developer mode for your browser
--   3. find source file controller.js
--   4. find this section and copy the value for companyCode:
--     $api('GetConfigOption', {
--       companyCode: '53d8db94-7945-42fd-9742-9bbc71dbe4c1',
--       configName: 'ALL'
--       })
-- Copy the found value and paste it into the hostname field in your garbagecalendarconfig.lua to make this module work!
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
spath=script_path()
dofile (script_path() .. "table_funcs.lua") --

-------------------------------------------------------
-- dprint function to format log records
function dprint(text)
   print("@"..(websitemodule or "?")..":"..(text or "?"))
end

-------------------------------------------------------
-- round function
function Round(num, idp)
   return tonumber(string.format("%." ..(idp or 0).. "f", num))
end

-------------------------------------------------------
-- try to load JSON library
function loaddefaultjson()
   if unexpected_condition then error() end
   -- add defined Domoticz path to the search path
   package.path = domoticzjsonpath..'?.lua;' .. package.path
   JSON = require "JSON"     -- use generic JSON.lua
end

--------------------------------------------------------------------------
-- get date, return a standard format and calculate the difference in days
function getdate(i_garbagetype_date, stextformat)
   local curTime = os.time{day=timenow.day,month=timenow.month,year=timenow.year}
   -- get day,month,year from the i_garbagetype_date
--~    2020-03-13T00:00:00
   garbageyear,garbagemonth,garbageday=i_garbagetype_date:match("(%d-)-(%d-)-(%d-)T")
   if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
      print ('Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
      return
   end
   local garbageTime = os.time{day=garbageday,month=garbagemonth,year=garbageyear}
   local diffdays  = Round(os.difftime(garbageTime, curTime)/86400,0) -- 1 day = 86400 seconds
   stextformat = stextformat:gsub('dd',garbageday)
   stextformat = stextformat:gsub('mm',garbagemonth)
   stextformat = stextformat:gsub('yyyy',garbageyear)
   stextformat = stextformat:gsub('yy',tostring(garbageyear):sub(3,4))
   dprint("...-> diff:".. diffdays.. "  garbageyear:"..tostring(garbageyear).."  garbagemonth:"..tostring(garbagemonth).."  garbageday:"..tostring(garbageday))   --
   -- return standard date (yyyy-mm-dd) and diffdays
   return stextformat, diffdays
end
--------------------------------------------------------------------------
-- Do the actual webquery, retrieving data from the website
function perform_webquery(url)
   local sQuery   = 'curl '..url..' 2>nul'
   dprint("sQuery="..sQuery)
   local handle=assert(io.popen(sQuery))
   local Web_Data = handle:read('*all')
   handle:close()
   if ( Web_Data == "" ) then
      dprint("Error: Empty result from curl command")
      return ""
   end
   return Web_Data
end
--------------------------------------------------------------------------
-- Perform the actual update process for the given address
function Perform_Update()
   function processdata(ophaaldata)
      local pickuptimes = {}
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == "table" then
            web_garbagetype = record["_pickupTypeText"]
            print(web_garbagetype)
            web_garbagedesc = record["description"]
            print(web_garbagedesc)
            garbagedate = record["pickupDates"]
            local dateformat = "????????"
            for i = 1, #garbagedate do
               record = garbagedate[i]
               -- Get days diff
               dateformat, daysdiffdev = getdate(garbagedate[i], "yyyy-mm-dd")
               if daysdiffdev == nil then
                  dprint ('Invalid date from web for : ' .. web_garbagetype..'   date:'..garbagedate[i])
               else
                  if ( daysdiffdev >= 0 ) then
                     pickuptimes[#pickuptimes+1] = {}
                     pickuptimes[#pickuptimes].garbagetype = web_garbagetype
                     pickuptimes[#pickuptimes].garbagedate = dateformat
                     pickuptimes[#pickuptimes].diff = daysdiffdev
                     pickuptimes[#pickuptimes].wdesc = web_garbagedesc
                  end
               end
            end
         end
      end
      dprint("- Sorting records.")
      local eventcnt = 0
      for x = 0,60,1 do
         for mom in pairs(pickuptimes) do
            if pickuptimes[mom].diff == x then
               garbagedata[#garbagedata+1] = {}
               garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
               garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
               garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
            end
         end
      end
   end
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   ---
   -- Get the information for the specified address specifically the UniqueId for the subsequent calls
   Web_Data=perform_webquery('--data "companyCode='..companyCode..'&postCode='..Zipcode..'&houseNumber='..Housenr.."&houseNumberAddition="..Housenrsuf..'" "https://wasteapi.2go-mobile.com/api/FetchAdress"')
   if Web_Data == "" then
      return
   end
   dprint('---- web data UniqueId ----------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   if Web_Data == "" then
      return
   end
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Check your Zipcode and Housenr as we get an [] response.")
      return
   end
   adressdata = JSON:decode(Web_Data)
    -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   UniqueId = adressdata['dataList'][1]['UniqueId']
   if UniqueId == nil or UniqueId == "" then
      print("Error: No UniqueId retrieved...  stopping execution.")
      return
   end
   dprint("UniqueId:"..UniqueId)
   -- set startdate to today en end date to today + 28 days
   startDate=os.date("%Y-%m-%d")
   endDate=os.date("%Y-%m-%d",os.time()+28*24*60*60)
   Web_Data=perform_webquery('--data "companyCode='..companyCode..'&uniqueAddressID='..UniqueId..'&startDate='..startDate.."&endDate="..endDate..'" "https://wasteapi.2go-mobile.com/api/GetCalendar"')
   dprint('---- web data garbagestromen ---------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Unable to retrieve Afvalstromen information...  stopping execution.")
      return
   end
   jdata = JSON:decode(Web_Data)
   -- get the Datalist tabel for the coming scheduled pickups
   if type(jdata) ~= "table" then
      print("Error: Empty Kalender found stopping execution.")
      return
   end
   jdata = jdata["dataList"]   -- get the Datalist tabel for the coming scheduled pickups
   if type(jdata) ~= "table" then
      print("Error: Empty Kalender found stopping execution.")
      return
   end
   -- process the data
   dprint("- start looping through received data -----------------------------------------------------------")
   processdata(jdata)
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date("*t")
-- get paramters from the commandline
domoticzjsonpath=arg[1]
Zipcode = arg[2]
Housenr = arg[3]
Housenrsuf = arg[4]
afwdatafile = arg[5]
afwlogfile = arg[6]
companyCode = arg[7] or ""   -- Required !
Street   = arg[8] or ""      -- Not needed
-- other variables
garbagedata = {}            -- array to save information to which will be written to the data file

dprint('#### '..os.date("%c")..' ### Start garbagekalerder module '.. websitemodule..' (v'..ver..')')
if domoticzjsonpath == nil then
   dprint("!!! domoticzjsonpath not specified!")
elseif Zipcode == nil then
   dprint("!!! Zipcode not specified!")
elseif Housenr == nil then
   dprint("!!! Housenr not specified!")
elseif Housenrsuf == nil then
   dprint("!!! Housenrsuf not specified!")
elseif companyCode == "" then
   dprint("!!! companyCode not specified. Please check in file m_ximmio.lua how to obtain this companyCode!")
elseif afwdatafile == nil then
   dprint("!!! afwdatafile not specified!")
elseif afwlogfile == nil then
   dprint("!!! afwlogfile not specified!")
else
   -- Load JSON.lua
   if pcall(loaddefaultjson) then
      dprint('Loaded JSON.lua.' )
   else
      dprint('Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. domoticzjsonpath..'.')
      dprint('Error: Please check your setup and try again.' )
      os.exit() -- stop execution
   end
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. " companyCode:"..companyCode)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
