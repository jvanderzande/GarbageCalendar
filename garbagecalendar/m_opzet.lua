-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230207-1242'
websitemodule = 'm_opzet'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
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
   local txt = ''
   local txtcnt = 0
   --
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = perform_webquery('"https://' .. Hostname .. '/adres/' .. Zipcode .. ':' .. Housenr .. ':' .. Housenrsuf .. '"')
   if Web_Data == '' then
      dprint('Error Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      dprint('Error check postcode   Web_Data:' .. Web_Data)
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
   dprint('---- web data stripped -------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   -- Decode JSON table and get bagid
   local record = JSON:decode(Web_Data)
   local bagid = record['bagid'] or ''
   if bagid == nil or bagid == '' then
      dprint('### Error: No bagid retrieved...  stopping execution.')
      return
   end
   dprint('found bagid:' .. bagid)

   -- Get Garbage Calendar info
   Web_Data = perform_webquery('"https://' .. Hostname .. '/ical/' .. bagid .. '"')
   if Web_Data == '' then
      dprint('Error Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      dprint('Error check postcode   Web_Data:' .. Web_Data)
      return
   end

   -- Process received iCal data.
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   dprint('- start looping through received data ----------------------------------------------------')
   for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, 'DTSTART;VALUE=DATE:(.-)\n.-SUMMARY:(.-)\n') do
      i = i + 1
      dprint(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
      if web_garbagetype ~= nil and web_garbagedate ~= nil then
         -- first match for each Type we save the date to capture the first next dates
         --dprint(web_garbagetype,web_garbagedate)
         local dateformat, daysdiffdev = GetDateFromInput(web_garbagedate, '(%d%d%d%d)(%d%d)(%d%d)', {'yyyy', 'mm', 'dd'})
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if (daysdiffdev >= 0) then
            pickuptimes[#pickuptimes + 1] = {}
            pickuptimes[#pickuptimes].garbagetype = web_garbagetype
            pickuptimes[#pickuptimes].garbagedate = dateformat
            pickuptimes[#pickuptimes].diff = daysdiffdev
         end
      end
   end
   dprint('- Sorting records.')
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
timenow = os.date('*t')
-- get paramters from the commandline
Zipcode = Zipcode or arg[1]
Housenr = Housenr or arg[2] or ''
Housenrsuf = Housenrsuf or arg[3]
afwdatafile = datafile or arg[4]
afwlogfile = weblogfile or arg[5]
Hostname = Hostname_strip((Hostname or arg[6]) or '')
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
elseif Hostname == '' then
   dprint('!!! Hostname not specified!')
elseif afwdatafile == nil then
   dprint('!!! afwdatafile not specified!')
elseif afwlogfile == nil then
   dprint('!!! afwlogfile not specified!')
else
	local Load_Success = true
   -- Load JSON.lua
   if pcall(loaddefaultjson) then
      dprint('Loaded JSON.lua.')
   else
      dprint('### Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. GC_scriptpath .. '.')
      dprint('### Error: Please check your setup and try again.')
		Load_Success = false
   end
	if Load_Success then
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. Hostname)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
	end
end
