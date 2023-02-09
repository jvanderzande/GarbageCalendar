-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_montferland.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230209-1315'
websitemodule = 'm_montferland'
-- Link to WebSite:  http://www.montferland.afvalwijzer.net/introductie.aspx.
--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   function processdata(ophaaldata)
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == 'table' then
            web_garbagetype = record['Soort']
            web_garbagedate = record['Datum']
            wnameType = ''
            genfuncs.Print_afwlogfile( '  web_garbagetype:' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
            local dateformat = '????????'
            -- Get days diff
            dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
            if daysdiffdev == nil then
               genfuncs.Print_afwlogfile( 'Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
               return
            end
            if (daysdiffdev >= 0) then
               garbagedata[#garbagedata + 1] = {}
               garbagedata[#garbagedata].garbagetype = web_garbagetype
               garbagedata[#garbagedata].garbagedate = dateformat
            -- field to be used when WebData contains a description
            -- garbagedata[#garbagedata].wdesc = ....
            end
         end
      end
   end
   genfuncs.Print_afwlogfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   -- Get the information for the specified address: AdresID and AdministratieID  (required for the subsequent call)
   Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/Login.ashx?Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&Postcode=' .. Zipcode .. '&Huisnummer=' .. Housenr .. '&Toevoeging=' .. Housenrsuf .. '"')
   if Web_Data == '' then
      return
   end
   if (Web_Data:sub(1, 2) == '[]') then
      genfuncs.Print_afwlogfile( '### Error: Check your Zipcode and Housenr as we get an [] response.')
      return
   end
   adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   AdresID = adressdata[1].AdresID
   AdministratieID = adressdata[1].AdministratieID
   if AdresID == nil or AdresID == '' then
      genfuncs.Print_afwlogfile( '### Error: No AdresID retrieved...  stopping execution.')
      return
   end
   if AdministratieID == nil or AdministratieID == '' then
      genfuncs.Print_afwlogfile( '### Error: No AdministratieID retrieved...  stopping execution.')
      return
   end
   genfuncs.Print_afwlogfile( ' AdresID:' .. AdresID .. '  AdministratieID:' .. AdministratieID)

   -- get the Afvalstromen information for all possible garbagetypeid's for this address(AdministratieID)
   Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' .. AdministratieID .. '&Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. os.date('%Y') .. '&Date=' .. os.date('%d/%m/%Y%%2001:00:00%p') .. '"')
   if (Web_Data:sub(1, 2) == '[]') then
      genfuncs.Print_afwlogfile( '### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
      return
   end
   jdata = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(jdata) ~= 'table' then
      genfuncs.Print_afwlogfile( '### Error: Empty Kalender found stopping execution.')
      return
   end
   -- process the data
   genfuncs.Print_afwlogfile( '- start looping through received data -----------------------------------------------------------')
   processdata(jdata)

   -- also get nextyears data in november/december
   if tonumber(os.date('%m')) >= 11 then
      local nextyear = tostring(tonumber(os.date('%Y')) + 1)
      nextyear = nextyear:sub(0, 4)
      Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' .. AdministratieID .. '&Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. nextyear .. '&Date=' .. os.date('%m/%d/%Y%%20%I:%M:%S%p') .. '"')
      if (Web_Data:sub(1, 2) == '[]') then
         genfuncs.Print_afwlogfile( '### Warning: no calendar data for next year.')
      else
         jdata = JSON:decode(Web_Data)
         genfuncs.Print_afwlogfile( '- start looping through next received data -----------------------------------------------------------')
         processdata(jdata)
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
-- ================================================================================================
-- These activated fields will be checked for being defined and the script will end when one isn't
-- ================================================================================================
local chkfields = {"websitemodule",
	"Zipcode",
	"Housenr",
--	"Housenrsuf",
	"afwdatafile",
	"afwlogfile",
--	"Hostname",
--	"Street",
--	"companyCode"
}
local param_err=0
-- Check whether the required parameters are specified.
for key, value in pairs(chkfields) do
	if (_G[value] or '') == '' then
		param_err = param_err + 1
		genfuncs.Print_afwlogfile('!!! '..value .. ' not specified!', 1)
	end
end
-- Get the web info when all required parameters are defined
if param_err == 0 then
	genfuncs.Print_afwlogfile('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. companyCode)
	Perform_Update()
	genfuncs.Print_afwlogfile('=> Write data to ' .. afwdatafile)
	table.save(garbagedata, afwdatafile)
else
	genfuncs.Print_afwlogfile('!!! Webupdate cancelled due to misseng parameters!', 1)
end
