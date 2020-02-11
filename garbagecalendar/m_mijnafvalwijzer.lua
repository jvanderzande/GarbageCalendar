-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer.lua
----------------------------------------------------------------------------------------------------------------
ver="20200209-1800"
websitemodule="m_mijnafvalwijzer"
-- Link to WebSite:        http://json.mijnafvalwijzer.nl/?method=postcodecheck&postcode=1234ab&street=&huisnummer=1&toevoeging=
--
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
   garbageyear,garbagemonth,garbageday=i_garbagetype_date:match("(%d-)-(%d-)-(%d-)$")
   if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
      dprint ('Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
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
   local sQuery   = 'curl "'..url..'" 2>nul'
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
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   -- function to process ThisYear and Lastyear JSON data
   function processdata(ophaaldata)
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == "table" then
            wnameType = record["nameType"]
            web_garbagetype = record["type"]
            web_garbagedate = record["date"]
            -- first match for each Type we save the date to capture the first next dates
            -- get the long description from the JSON data
            dprint(i.." web_garbagetype:"..tostring(web_garbagetype).."   web_garbagedate:"..tostring (web_garbagedate))
            local dateformat = "????????"
            -- Get days diff
            dateformat, daysdiffdev = getdate(web_garbagedate, "yyyy-mm-dd")
            if daysdiffdev == nil then
               dprint ('Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
            end
            if ( daysdiffdev >= 0 ) then
               garbagedata[#garbagedata+1] = {}
               garbagedata[#garbagedata].garbagetype = web_garbagetype
               garbagedata[#garbagedata].garbagedate = dateformat
               -- field to be used when WebData contains a description
               garbagedata[#garbagedata].wdesc = rdesc[web_garbagetype:upper().."_L"]
            end
         end
      end
   end
   --
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery('https://json.mijnafvalwijzer.nl/?method=postcodecheck&postcode='..Zipcode..'&street=&huisnummer='..Housenr..'&toevoeging='..Housenrsuf)
   if ( Web_Data == "" ) then
      dprint("Error: Empty result from curl command. Please check whether curl.exe is installed.")
      return
   end
   if ( Web_Data:sub(1,3) == "NOK" ) then
      dprint("Error: Check your Postcode and Huisnummer as we get an NOK response.")
      return
   end
   -- strip bulk data from "ophaaldagenNext" till the end, because this is causing some errors for some gemeentes
   if ( Web_Data:find('ophaaldagenNext')  == nil ) then
      dprint("Error: returned information does not contain the ophaaldagenNext section. stopping process.")
      return
   end
   Web_Data=Web_Data:match('(.-),\"mededelingen\":')
   Web_Data=Web_Data.."}}"
   --
   -- Decode JSON table
   decoded_response = JSON:decode(Web_Data)
   rdata = decoded_response["data"]
   if type(rdata) ~= "table" then
      dprint("Error: Empty data table in JSON data...  stopping execution.")
      return
   end
   -- get the description records into rdesc to retrieve the long description
   rdesc = rdata["langs"]
   rdesc = rdesc["data"]
   -- get the ophaaldagen tabel for the coming scheduled pickups for this year
   rdataty = rdata["ophaaldagen"]
   if type(rdataty) ~= "table" then
      dprint("Error: Empty data.ophaaldagen table in JSON data...  stopping execution.")
      return
   end
   rdataty = rdataty["data"]
   if type(rdataty) ~= "table" then
      dprint("Error: Empty data.ophaaldagen.data table in JSON data...  stopping execution.")
      return
   end
   dprint("- start looping through this year received data -----------------------------------------------------------")
   processdata(rdataty)
   -- only process nextyear data in case we do not have the requested number of next events
   if #garbagedata < 10 then
      -- get the ophaaldagen tabel for next year when needed
      rdataly = rdata["ophaaldagenNext"]
      if type(rdataly) ~= "table" then
         print("@AFW: Empty data.ophaaldagen table in JSON data...  stopping execution.")
      else
         rdataly = rdataly["data"]
         if type(rdataly) ~= "table" then
            dprint("Error: Empty data.ophaaldagen.data table in JSON data...  stopping execution.")
         else
            -- get the next number of ShowNextEvents
            dprint("- start looping through next year received data -----------------------------------------------------------")
            processdata(rdataly)
         end
      end
   end
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
Hostname = arg[7] or ""   -- Not needed
Street   = arg[8] or ""   -- Not needed
-- other variables
garbagedata = {}            -- array to save information to which will be written to the data file

dprint("Start garbagekalerder module ".. websitemodule..' (v'..ver..')')
if domoticzjsonpath == nil then
   dprint("!!! domoticzjsonpath not specified!")
elseif Zipcode == nil then
   dprint("!!! Zipcode not specified!")
elseif Housenr == nil then
   dprint("!!! Housenr not specified!")
elseif Housenrsuf == nil then
   dprint("!!! Housenrsuf not specified!")
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
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end