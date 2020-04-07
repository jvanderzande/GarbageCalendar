-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_montferland.lua
----------------------------------------------------------------------------------------------------------------
ver="20200407-1100"
websitemodule="m_montferland"
-- Link to WebSite:  http://www.montferland.afvalwijzer.net/introductie.aspx.
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
spath=script_path()
dofile (script_path() .. "generalfuncs.lua") --

--------------------------------------------------------------------------
-- get date, return a standard format and calculate the difference in days
function getdate(i_garbagetype_date, stextformat)
   local curTime = os.time{day=timenow.day,month=timenow.month,year=timenow.year}
   -- get day,month,year from the i_garbagetype_date   2020-04-06T00:00:00
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
-- Perform the actual update process for the given address
function Perform_Update()
   function processdata(ophaaldata)
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == "table" then
            web_garbagetype = record["Soort"]
            web_garbagedate = record["Datum"]
            wnameType = ""
            dprint ("  web_garbagetype:"..web_garbagetype..' web_garbagedate : ' .. web_garbagedate)
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
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   -- Get the information for the specified address: AdresID and AdministratieID  (required for the subsequent call)
   Web_Data=perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/Login.ashx?Username=GSD&Password='..url_encode('gsd$2014')..'&Postcode='..Zipcode..'&Huisnummer='..Housenr..'&Toevoeging='..Housenrsuf..'"')
   if Web_Data == "" then
      return
   end
   if Web_Data == "" then
      return
   end
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Check your Zipcode and Housenr as we get an [] response.")
      return
   end
   adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   AdresID = adressdata[1].AdresID
   AdministratieID = adressdata[1].AdministratieID
   if AdresID == nil or AdresID == "" then
      print("Error: No AdresID retrieved...  stopping execution.")
      return
   end
   if AdministratieID == nil or AdministratieID == "" then
      print("Error: No AdministratieID retrieved...  stopping execution.")
      return
   end
   dprint(" AdresID:"..AdresID.."  AdministratieID:"..AdministratieID)

   -- get the Afvalstromen information for all possible garbagetypeid's for this address(AdministratieID)
   Web_Data=perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID='..AdministratieID..'&Username=GSD&Password=gsd$2014&ADR_ID='..AdresID..'&Jaar='..os.date("%Y")..'&Date='..os.date("%m/%d/%Y%%20%I:%M:%S%p")..'&Type=Topdagen"')
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      return
   end
   jdata = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
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
Hostname = arg[7] or ""   -- Required!
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
