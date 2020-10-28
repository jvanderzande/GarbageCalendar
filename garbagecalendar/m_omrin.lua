-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_omrin_api.lua
----------------------------------------------------------------------------------------------------------------
ver="20200920-1600"
websitemodule="m_omrin"
-- Link to WebSite: "https://www.omrin.nl/bij-mij-thuis/afval-regelen/afvalkalender"
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
   -- function to process ThisYear and Lastyear JSON data
   function processdata(ophaaldata)
      local i = 0
      local pickuptimes = {}
      for web_garbageyear, web_yeardata in pairs(ophaaldata) do
         for web_garbagetype, web_typedata in pairs(web_yeardata) do
            for web_typemonth, web_typedays in pairs(web_typedata.dates) do
               for x, web_typeday in pairs(web_typedays) do
                  web_garbagedate = web_garbageyear.."-"..web_typemonth.."-"..web_typeday
                  i = i + 1
                  dprint(i.." web_garbagetype:"..tostring(web_garbagetype).."   web_garbagedate:"..tostring (web_garbagedate))
                  local dateformat = "????????"
                  -- Get days diff
                  dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"([^-]+)-([^-]+)-([^-T]+)",{"yyyy","mm","dd"})
                  if daysdiffdev == nil then
                     dprint ('Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
                  end
                  if ( daysdiffdev >= 0 ) then
                     pickuptimes[#pickuptimes+1] = {}
                     pickuptimes[#pickuptimes].garbagetype = web_garbagetype
                     pickuptimes[#pickuptimes].garbagedate = dateformat
                     pickuptimes[#pickuptimes].diff = daysdiffdev
                     -- field to be used when WebData contains a description
                     pickuptimes[#pickuptimes].wdesc = web_garbagetype.title
                  end
               end
            end
         end
      end
      dprint("- Sorting records."..#pickuptimes)
      local eventcnt = 0
      for x = 0,60,1 do
         for mom in pairs(pickuptimes) do
            if pickuptimes[mom].diff == x then
               garbagedata[#garbagedata+1] = {}
               garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
               garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
               -- field to be used when Web_Data contains a description
               garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
            end
         end
      end
   end
   --
--[[
  info from: https://github.com/Dashticz/dashticz/blob/9266ca820adea22b03f13e8939f662c9d74eb4ba/vendor/dashticz/garbage/index.php
--]]
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   local thnr = Housenr..Housenrsuf
   local cookie = 'address='..url_encode("a:3:{s:7:\"ziparea\";s:2:\""..Zipcode:sub(5,6).."\";s:9:\"zipnumber\";s:4:\""..Zipcode:sub(1,4).."\";s:7:\"housenr\";s:"..thnr:len()..":\""..thnr.."\";}")
   -- get the Afvalstromen information for all possible garbagetypeid's for this address(AdministratieID)
   Web_Data=perform_webquery('--cookie "'..cookie..'" https://www.omrin.nl/bij-mij-thuis/afval-regelen/afvalkalender')
   if ( Web_Data:sub(1,2) == "[]" ) then
      dprint("### Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      return
   end
   -- Retrieve part with the dates for pickup
   Web_Data=Web_Data:match('omrinDataGroups = (.-);')
   print(Web_Data)
   if Web_Data == nil or Web_Data == '' then
      print ('Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
      return
   end
   dprint('---- web data stripped -------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   jdata = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(jdata) ~= "table" then
      dprint("### Error: Empty Kalender found stopping execution.")
      return
   end
   -- process the data
   processdata(jdata)

end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date("*t")
-- get paramters from the commandline
domoticzjsonpath = domoticzjsonpath or arg[1]
Zipcode = Zipcode or arg[2]
Housenr = Housenr or arg[3]
Housenrsuf = Housenrsuf or arg[4] or "" -- optional
afwdatafile = datafile or arg[5]
afwlogfile = weblogfile or arg[6]
Hostname = (Hostname or arg[7]) or ""   -- Not needed
Street = (Street or arg[8]) or ""       -- Not needed
-- other variables
garbagedata = {}            -- array to save information to which will be written to the data file

dprint('#### '..os.date("%c")..' ### Start garbagecalender module '.. websitemodule..' (v'..ver..')')
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
