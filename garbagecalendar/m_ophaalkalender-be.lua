-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_ophaalkalender-be
----------------------------------------------------------------------------------------------------------------
ver="20200406-0945"
websitemodule="m_ophaalkalender-be"
-- Link to WebSite: https://huisvuilkalender.gemeentewestland.nl
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
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
   -- get say/month year from the i_garbagetype_date
   garbageyear,garbagemonth,garbageday=i_garbagetype_date:match("(%d-)-(%d-)-(%d-)T.*$")
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
   dprint("Web_Data="..Web_Data)
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
            web_garbagetype = record["title"]
            web_garbagedate = record["start"]
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
               -- field to be used when Web_Data contains a description
               -- garbagedata[#garbagedata].wdesc =
            end
         end
      end
   end
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
--~    https://www.ophaalkalender.be/Calendar/findstreets/?query=gaverlanddam&zipcode=9120
--~ [{"Value":"Gaverlanddam","Id":6644,"Brussels":false}]
   Web_Data=perform_webquery(' "https://www.ophaalkalender.be/Calendar/findstreets/?query='..Street..'&zipcode='..Zipcode..'"')
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("@OphaalKalender findstreets Error: Check your Zipcode and Street as we get an [] response.")
      return
   end
   dprint("adressid:"..Web_Data)
   adressdata = JSON:decode(Web_Data)
   adressid = adressdata[1].Id or ""
   if adressid == nil or adressid == "" then
      print("Error: No adressid retrieved...  stopping execution.")
      return
   end
   dprint("adressid:"..adressid)
   --
   -- get the Kalender information for this address(bagId) for the current year
   Web_Data=perform_webquery(' "https://www.ophaalkalender.be/api/rides?id='..adressid..'&housenumber='..Housenr..Housenrsuf..'&zipcode='..Zipcode..'"')
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      print(Web_Data)
      return
   end
   Web_Data = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(Web_Data) ~= "table" then
      print("Error: Empty Kalender for "..cYear..".  stopping execution.")
      return
   end
   processdata(Web_Data)

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
Street   = arg[8] or ""   -- Required!
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

