-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_rova_web.lua
----------------------------------------------------------------------------------------------------------------
ver="20200611-1900"
websitemodule="m_rova_web"
-- Link to WebSite: https://inzamelkalender.rova.nl/nl/9999ZZ/123/A/
--
-- This script parses the website of the Rova inzamelkalender
-- Originally copied from m_opzet.lua
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
   local txt=""
   local txtcnt = 0
   --
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery('"https://inzamelkalender.rova.nl/nl/'..Zipcode..'/'..Housenr..'/'..Housenrsuf..'"')
   if Web_Data == "" then
      dprint("Error Web_Data is empty.")
      return
   elseif string.find(Web_Data,'<h2>Undefined index: postcodeContainers</h2>') ~= nil then
      dprint("Error check postcode   Web_Data:" .. Web_Data)
      return
   end
   -- Retrieve part with the dates for pickup
   Web_Data=Web_Data:match('.class="ophaaldagen"(.-)id="calendarMessage"')
   if Web_Data == nil or Web_Data == '' then
      print ('Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
      return
   end
   dprint('---- web data stripped -------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   local web_garbagetype=""
   local web_garbagetype_date=""
   local web_garbagetype_changed=""
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   dprint('- start looping through received data ----------------------------------------------------')
   for web_garbagetype in string.gmatch('pmd gft papier ', '(.-)%s') do
      -- dprint("Searching for "..web_garbagetype)
      for web_garbagedate in string.gmatch(Web_Data, '<p class="'..web_garbagetype..'.-class="span%-line%-break">(.-)</span>') do
         i = i + 1
         dprint(i.." web_garbagetype:"..tostring(web_garbagetype).."   web_garbagedate:"..tostring (web_garbagedate))
         if web_garbagetype~= nil and web_garbagedate ~= nil then
            -- first match for each Type we save the date to capture the first next dates
            --dprint(web_garbagetype,web_garbagedate)
            dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"%w- (%w-) (%w-)$",{"dd","mmm"})
            -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
            if ( daysdiffdev >= 0 ) then
               pickuptimes[#pickuptimes+1] = {}
               pickuptimes[#pickuptimes].garbagetype = web_garbagetype
               pickuptimes[#pickuptimes].garbagedate = dateformat
               pickuptimes[#pickuptimes].diff = daysdiffdev
            -- field to be used when Web_Data contains a description
            -- pickuptimes[#pickuptimes].wdesc = ....
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
            -- field to be used when Web_Data contains a description
            --garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
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
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
