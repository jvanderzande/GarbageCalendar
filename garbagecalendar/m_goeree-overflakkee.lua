-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_goeree_overflakkee.lua
----------------------------------------------------------------------------------------------------------------
ver="20200209-1800"
websitemodule="m_goeree_overflakkee"
-- Link to WebSite: https://webadapter.watsoftware.nl/
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
   local MON={jan=1,feb=2,maa=3,apr=4,mei=5,jun=6,jul=7,aug=8,sep=9,okt=10,nov=11,dec=12}
   local garbageyear =timenow.year
   -- get day,month,year from the i_garbagetype_date
   garbageday,s_garbagemonth=i_garbagetype_date:match("%a (%d-) (%a+)$")
   if (garbageday == nil or s_garbagemonth == nil or garbageyear == nil) then
      print ('Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
      return
   end
   local garbagemonth = MON[s_garbagemonth:sub(1,3)]
   if (garbagemonth == nil) then
      print ('Error: No valid month found in i_garbagetype_date: ' .. i_garbagetype_date)
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
--------------------------------------------------------------------------
-- Perform the actual update process for the given address
function Perform_Update()
   function processdata(ophaaldata)
      for k = 1, #ophaaldata.containers do
         ophaaldata2 = ophaaldata.containers[k]
         for i = 1, #ophaaldata2.container do
            record = ophaaldata2.container[i]
            stextformat=otextformat
            if type(record) == "table" then
               web_garbagetype = record["soortnaam"]
               web_garbagedate = record["datum"]
               -- first match for each Type we save the date to capture the first next dates
               dprint(i.." web_garbagetype:"..tostring(web_garbagetype).."   web_garbagedate:"..tostring (web_garbagedate))
               local dateformat = "????????"
               -- Get days diff
               dateformat, daysdiffdev = getdate(web_garbagedate, "yyyy-mm-dd")
               if daysdiffdev == nil then
                  dprint ('Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
                  return
               end
               if ( daysdiffdev >= 0 ) then
                  garbagedata[#garbagedata+1] = {}
                  garbagedata[#garbagedata].garbagetype = web_garbagetype
                  garbagedata[#garbagedata].garbagedate = dateformat
                  -- field to be used when WebData contains a description
                  -- garbagedata[#garbagedata].wdesc = ....
               end
            end
         end
      end
   end
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery('https://webadapter.watsoftware.nl/widget.aspx?version=3.7&action=3000001&xml=%3Cpostcode%3E'..Zipcode..'%3C/postcode%3E%3Chuisnummer%3E'..Housenr..Housenrsuf..'%3C/huisnummer%3E%3Cguid%3EBCE23C06-E248-4300-B97F-E308A451C6B4%3C/guid%3E')
   Web_Data=Web_Data:sub(1, -2)  -- strip ending ")"
   Web_Data=Web_Data:sub(2)      -- strip start  "("
   if ( Web_Data:sub(1,2) == "[]" ) then
      dprint("Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      return
   end
   jdata = JSON:decode(Web_Data)
   if type(jdata) ~= "table" then
      dprint("Error: Empty Kalender stopping execution.")
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