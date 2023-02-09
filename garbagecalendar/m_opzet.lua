-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230209-2000'
websitemodule = 'm_opzet'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   local txt = ''
   local txtcnt = 0
   --
   Print_weblogfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/adres/' .. Zipcode .. ':' .. Housenr .. ':' .. Housenrsuf .. '"')
   if Web_Data == '' then
      Print_weblogfile( 'Error Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      Print_weblogfile( 'Error check postcode   Web_Data:' .. Web_Data)
      return
   end
   -- retrieve bagid from address data web data
   --[[
   <script>
      let adres = '{"bagid":"0743200000013039","postcode":"5721GW","huisnummer":74,"huisletter":"a","toevoeging":"","description":"Kerkstraat 74a, 5721GW Asten","straat":"Kerkstraat","woonplaats":"Asten","woonplaatsId":2928,"gemeenteId":743,"latitude":51.39906,"longitude":5.750401}'
      if (adres==='') {
         window.location.href = "/"
      } else {
         window.localStorage.setItem('zcalendarAdresWidget-data', adres)
         window.location.href = "/overzicht"
      }
   </script>
   ]]
   Web_Data = Web_Data:match('let adres = \'(.-)\'')
   if Web_Data == nil or Web_Data == '' then
      print('### Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
      return
   end
   Print_weblogfile( '---- web data stripped -------------------------------------------------------------------')
   Print_weblogfile( Web_Data)
   Print_weblogfile( '---- end web data ------------------------------------------------------------------------')
   -- Decode JSON table and get bagid
   local record = JSON:decode(Web_Data)
   local bagid = record['bagid'] or ''
   if bagid == nil or bagid == '' then
      Print_weblogfile( '### Error: No bagid retrieved...  stopping execution.')
      return
   end
   Print_weblogfile( 'found bagid:' .. bagid)

   -- Get Garbage Calendar info
   Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/ical/' .. bagid .. '"')
   if Web_Data == '' then
      Print_weblogfile( 'Error Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      Print_weblogfile( 'Error check postcode   Web_Data:' .. Web_Data)
      return
   end

   -- Process received iCal data.
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   Print_weblogfile( '- start looping through received data ----------------------------------------------------')
   for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, 'DTSTART;VALUE=DATE:(.-)\n.-SUMMARY:(.-)\n') do
      i = i + 1
      Print_weblogfile( i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
      if web_garbagetype ~= nil and web_garbagedate ~= nil then
         -- first match for each Type we save the date to capture the first next dates
         --Print_weblogfile( web_garbagetype,web_garbagedate)
         local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d%d%d%d)(%d%d)(%d%d)', {'yyyy', 'mm', 'dd'})
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if (daysdiffdev >= 0) then
            pickuptimes[#pickuptimes + 1] = {}
            pickuptimes[#pickuptimes].garbagetype = web_garbagetype
            pickuptimes[#pickuptimes].garbagedate = dateformat
            pickuptimes[#pickuptimes].diff = daysdiffdev
         end
      end
   end
   Print_weblogfile( '- Sorting records.')
   for x = 0, 60, 1 do
      for mom in pairs(pickuptimes) do
         if pickuptimes[mom].diff == x then
            garbagedata[#garbagedata + 1] = {}
            garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
            garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
         end
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
	"weblogfile",
	"Hostname",
--	"Street",
--	"companyCode"
}
local param_err=0
-- Check whether the required parameters are specified.
for key, value in pairs(chkfields) do
	if (_G[value] or '') == '' then
		param_err = param_err + 1
		Print_weblogfile('!!! '..value .. ' not specified!', 1)
	end
end
-- Get the web info when all required parameters are defined
if param_err == 0 then
	Print_weblogfile('!!! perform web data update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. companyCode)
	Perform_Update()
	Print_weblogfile('=> Write data to ' .. afwdatafile)
	table.save(garbagedata, afwdatafile)
else
	Print_weblogfile('!!! Webupdate cancelled due to misseng parameters!', 1)
end
