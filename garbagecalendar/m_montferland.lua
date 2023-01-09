-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_montferland.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230109-1437'
websitemodule = 'm_montferland'
-- Link to WebSite:  http://www.montferland.afvalwijzer.net/introductie.aspx.
--
-------------------------------------------------------
-- get script directory
function script_path()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
end
-- only include when run in separate process
if GC_scriptpath == nil then
   dofile(script_path() .. 'generalfuncs.lua') --
end
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
            dprint('  web_garbagetype:' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
            local dateformat = '????????'
            -- Get days diff
            dateformat, daysdiffdev = GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
            if daysdiffdev == nil then
               dprint('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
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
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   -- Get the information for the specified address: AdresID and AdministratieID  (required for the subsequent call)
   Web_Data = perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/Login.ashx?Username=GSD&Password=' .. url_encode('gsd$2014') .. '&Postcode=' .. Zipcode .. '&Huisnummer=' .. Housenr .. '&Toevoeging=' .. Housenrsuf .. '"')
   if Web_Data == '' then
      return
   end
   if (Web_Data:sub(1, 2) == '[]') then
      dprint('### Error: Check your Zipcode and Housenr as we get an [] response.')
      return
   end
   adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   AdresID = adressdata[1].AdresID
   AdministratieID = adressdata[1].AdministratieID
   if AdresID == nil or AdresID == '' then
      dprint('### Error: No AdresID retrieved...  stopping execution.')
      return
   end
   if AdministratieID == nil or AdministratieID == '' then
      dprint('### Error: No AdministratieID retrieved...  stopping execution.')
      return
   end
   dprint(' AdresID:' .. AdresID .. '  AdministratieID:' .. AdministratieID)

   -- get the Afvalstromen information for all possible garbagetypeid's for this address(AdministratieID)
   Web_Data = perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' .. AdministratieID .. '&Username=GSD&Password=' .. url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. os.date('%Y') .. '&Date=' .. os.date('%d/%m/%Y%%2001:00:00%p') .. '"')
   if (Web_Data:sub(1, 2) == '[]') then
      dprint('### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
      return
   end
   jdata = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(jdata) ~= 'table' then
      dprint('### Error: Empty Kalender found stopping execution.')
      return
   end
   -- process the data
   dprint('- start looping through received data -----------------------------------------------------------')
   processdata(jdata)

   -- also get nextyears data in november/december
   if tonumber(os.date('%m')) >= 11 then
      local nextyear = tostring(tonumber(os.date('%Y')) + 1)
      nextyear = nextyear:sub(0, 4)
      Web_Data = perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' .. AdministratieID .. '&Username=GSD&Password=' .. url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. nextyear .. '&Date=' .. os.date('%m/%d/%Y%%20%I:%M:%S%p') .. '"')
      if (Web_Data:sub(1, 2) == '[]') then
         dprint('### Warning: no calendar data for next year.')
      else
         jdata = JSON:decode(Web_Data)
         dprint('- start looping through next received data -----------------------------------------------------------')
         processdata(jdata)
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date('*t')
-- get paramters from the commandline
Zipcode = Zipcode or arg[1]
Housenr = Housenr or arg[2] or ''
Housenrsuf = Housenrsuf or arg[3]
afwdatafile = datafile or arg[4]
afwlogfile = weblogfile or arg[5]
Hostname = (Hostname or arg[6]) or '' -- Not needed
Street = (Street or arg[7]) or '' -- Not needed
-- other variables
garbagedata = {} -- array to save information to which will be written to the data file

dprint('#### ' .. os.date('%c') .. ' ### Start garbagecalendar module ' .. websitemodule .. ' (v' .. ver .. ')')
if Zipcode == nil then
   dprint('!!! Zipcode not specified!')
elseif Housenr == nil then
   dprint('!!! Housenr not specified!')
elseif Housenrsuf == nil then
   dprint('!!! Housenrsuf not specified!')
elseif afwdatafile == nil then
   dprint('!!! afwdatafile not specified!')
elseif afwlogfile == nil then
   dprint('!!! afwlogfile not specified!')
else
   -- Load JSON.lua
   if pcall(loaddefaultjson) then
      dprint('Loaded JSON.lua.')
   else
      dprint('### Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. GC_scriptpath .. '.')
      dprint('### Error: Please check your setup and try again.')
      os.exit() -- stop execution
   end
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. Hostname)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
end
