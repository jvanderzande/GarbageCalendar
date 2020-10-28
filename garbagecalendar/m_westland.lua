-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_westland.lua
----------------------------------------------------------------------------------------------------------------
ver="20200606-1300"
websitemodule="m_westland"
-- Link to WebSite: https://huisvuilkalender.gemeentewestland.nl
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
-- only include when run in separate process
if scriptpath == nil then
   dofile (script_path() .. "generalfuncs.lua") --
end
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery(' "https://huisvuilkalender.gemeentewestland.nl/huisvuilkalender/Huisvuilkalender/get-huisvuilkalender-ajax" -H "Origin: https://huisvuilkalender.gemeentewestland.nl" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Accept: application/json, text/javascript, */*; q=0.01" -H "Referer: https://huisvuilkalender.gemeentewestland.nl/huisvuilkalender?dummy=0.9778403611955824" -H "X-Requested-With: XMLHttpRequest" -H "Connection: keep-alive" --data "postcode=' .. Zipcode .. '&query="')
   if Web_Data == "" then
      dprint("### Error: Web_Data is empty.")
      return
   elseif string.find(Web_Data,'{"error":true}') ~= nil then
      dprint("### Error: check Zipcode   Web_Data:" .. Web_Data)
      return
   end
   -- Process received webdata.
   local web_garbagetype=""
   local web_garbagetype_date=""
   local web_garbagetype_changed=""
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   dprint('- start looping through received data ----------------------------------------------------')
   for web_garbagetype,web_garbagedate in string.gmatch(Web_Data, '.-soort.(.-)%sclearfix.-text dag.-\\">(.-)<\\/span') do
      i = i + 1
      if (web_garbagetype == nil) then
         dprint ('### Error: "web_garbagetype" not found in Web_Data ... Stopping process' )
         break
      end
      if (web_garbagedate == nil) then
         dprint ('### Error: "text dag" not found in Web_Data for ' .. web_garbagetype)
         break
      end
      -- first match for each Type we save the date to capture the first next dates
      -- get the long description from the JSON data
      dprint(i.." web_garbagetype:"..tostring(web_garbagetype).."   web_garbagedate:"..tostring (web_garbagedate))
      local dateformat = "????????"
      -- Get days diff
      dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"[^%s]+%s+(%d+)%s+([^%s]+)%s-(%d-)$",{"dd","mmm","yyyy"})

      if daysdiffdev == nil then
         daysdiffdev = -99
         dprint ('### Error: Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
      end
      if ( daysdiffdev >= 0 ) then
         pickuptimes[#pickuptimes+1] = {}
         pickuptimes[#pickuptimes].garbagetype = web_garbagetype
         pickuptimes[#pickuptimes].garbagedate = dateformat
         pickuptimes[#pickuptimes].diff = daysdiffdev
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
            -- field to be used when Web_Data contains a description
            -- garbagedata[#garbagedata].wdesc = ....
         end
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date("*t")
-- get paramters from the commandline
domoticzjsonpath = domoticzjsonpath or arg[1]
Zipcode = Zipcode or arg[2]
Housenr = Housenr or arg[3] or ""
Housenrsuf = Housenrsuf or arg[4]
afwdatafile = datafile or arg[5]
afwlogfile = weblogfile or arg[6]
Hostname = (Hostname or arg[7]) or ""   -- Not needed
Street = (Street or arg[8]) or ""       -- Not needed
-- other variables
garbagedata = {}            -- array to save information to which will be written to the data file
-- required when you use format mmm in the call to GetDateFromInput()
InputMonth={jan=1,feb=2,maa=3,apr=4,mei=5,jun=6,jul=7,aug=8,sep=9,okt=10,nov=11,dec=12}

dprint('#### '..os.date("%c")..' ### Start garbagecalendar module '.. websitemodule..' (v'..ver..')')
if domoticzjsonpath == nil then
   dprint("!!! domoticzjsonpath not specified!")
elseif Zipcode == nil then
   dprint("!!! Zipcode not specified!")
elseif afwdatafile == nil then
   dprint("!!! afwdatafile not specified!")
elseif afwlogfile == nil then
   dprint("!!! afwlogfile not specified!")
else
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
