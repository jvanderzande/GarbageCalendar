-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_goeree_overflakkee.lua
----------------------------------------------------------------------------------------------------------------
ver="20200606-1300"
websitemodule="m_goeree_overflakkee"
-- Link to WebSite: https://webadapter.watsoftware.nl/
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
               dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"%w (%w-) (%w-)$",{"dd","mmmm"})
               if daysdiffdev == nil then
                  daysdiffdev = -99
                  dprint ('### Error:Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
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
   Web_Data=perform_webquery('"https://webadapter.watsoftware.nl/widget.aspx?version=3.7&action=3000001&xml=%3Cpostcode%3E'..Zipcode..'%3C/postcode%3E%3Chuisnummer%3E'..Housenr..Housenrsuf..'%3C/huisnummer%3E%3Cguid%3EBCE23C06-E248-4300-B97F-E308A451C6B4%3C/guid%3E"')
   Web_Data=Web_Data:sub(1, -2)  -- strip ending ")"
   Web_Data=Web_Data:sub(2)      -- strip start  "("
   if ( Web_Data:sub(1,2) == "[]" ) then
      dprint("### Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      return
   end
   jdata = JSON:decode(Web_Data)
   if type(jdata) ~= "table" then
      dprint("### Error: Empty Kalender stopping execution.")
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
      dprint('### Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. domoticzjsonpath..'.')
      dprint('### Error: Please check your setup and try again.' )
      os.exit() -- stop execution
   end
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
