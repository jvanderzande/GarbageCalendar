-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_ophaalkalender-be
-- Remarks:
--   This website still uses tls 1.0 and Demian Buster has set the minssl to tls 1.2 so will fail.
--   To fix:
--       Set /etc/ssl/openssl.cnf to MinProtocol = TLSv1.0
--       * reboot
--       And It should work
----------------------------------------------------------------------------------------------------------------
ver="20200410-1300"
websitemodule="m_ophaalkalender-be"
-- Link tohttps://www.ophaalkalender.be
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
dofile (script_path() .. "generalfuncs.lua") --

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
            dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"(%w-)-(%w-)-(%w-)T",{"yyyy","mm","dd"})
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
      dprint("### Error: findstreets Check for your Zipcode and Street as we get an [] response.")
      return
   end
   dprint("adressid:"..Web_Data)
   adressdata = JSON:decode(Web_Data)
   adressid = adressdata[1].Id or ""
   if adressid == nil or adressid == "" then
      dprint("### Error: No adressid retrieved...  stopping execution.")
      return
   end
   dprint("adressid:"..adressid)
   --
   -- get the Kalender information for this address(bagId) for the current year
   Web_Data=perform_webquery(' "https://www.ophaalkalender.be/api/rides?id='..adressid..'&housenumber='..Housenr..Housenrsuf..'&zipcode='..Zipcode..'"')
   if ( Web_Data:sub(1,2) == "[]" ) then
      dprint("### Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      return
   end
   Web_Data = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(Web_Data) ~= "table" then
      dprint("### Error: Empty Kalender for "..cYear..".  stopping execution.")
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
elseif Street == "" then
   dprint("!!! Street not specified!")
elseif afwdatafile == nil then
   dprint("!!! afwdatafile not specified!")
elseif afwlogfile == nil then
   dprint("!!! afwlogfile not specified!")
else
   -- Load JSON.lua
   if pcall(loaddefaultjson) then
      dprint('Loaded JSON.lua.' )
   else
      dprint('### Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. domoticzjsonpath..'.')
      dprint('### Error: Please check your setup and try again.' )
      os.exit() -- stop execution
   end
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
