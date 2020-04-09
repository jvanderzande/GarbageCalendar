-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_deafvalapp.lua
----------------------------------------------------------------------------------------------------------------
ver="20200407-1100"
websitemodule="m_deafvalapp"
-- Link to WebSite:  http://dataservice.deafvalapp.nl
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
spath=script_path()
dofile (script_path() .. "generalfuncs.lua") --

-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery('"http://dataservice.deafvalapp.nl/dataservice/DataServiceServlet?service=OPHAALSCHEMA&land=NL&postcode='..Zipcode..'&straatId=0&huisnr='..Housenr..''..Housenrsuf..'"')
   if Web_Data == "" then
      dprint("Error Web_Data is empty.")
      return
   elseif string.find(Web_Data,'{"error":true}') ~= nil then
      dprint("Error check postcode   Web_Data:" .. Web_Data)
      return
   end
   -- Read from the data table, and extract duration and distance in value. Divide distance by 1000 and duration_in_traffic by 60
   local web_garbagetype=""
   local web_garbagetype_date=""
   local web_garbagetype_changed=""
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   dprint('- start looping through received data ----------------------------------------------------')
   for web_garbagetype, web_garbagedates in string.gmatch(Web_Data, '(.-);(.-)[\r\n|$]') do
      dprint(web_garbagetype)
      for web_garbagedate in string.gmatch(web_garbagedates, '(.-);') do
         if web_garbagetype~= nil and web_garbagedate ~= nil then
            -- first match for each Type we save the date to capture the first next dates
            dprint ("  web_garbagetype:"..web_garbagetype..'   web_garbagedate:' .. web_garbagedate)
            dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"(%w-)-(%w-)-(%w-)$",{"dd","mm","yyyy"})
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
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
