-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer_API.lua
----------------------------------------------------------------------------------------------------------------
ver = '20210826-1600'
websitemodule = 'm_mijnafvalwijzer_API'
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or './'
end
-- only include when run in separate process
if scriptpath == nil then
   dofile(script_path() .. 'generalfuncs.lua') --
end

-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   local function longGarbageName(str) -- Use descriptive strings
      str = tostring(str)
      str = str:gsub("plastic"," Plastic verpakkingen, blik en drinkpakken ")
      str = str:gsub("papier"," Papier en kartonnen verpakkingen ")
      str = str:gsub("gft"," Groente-, fruit- en tuin afval ")
      return str
   end
   -- function to process ThisYear and Lastyear JSON data
   function processdata(ophaaldata)
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == 'table' then
            wnameType = record['nameType']
            web_garbagetype = record['type']
            web_garbagedate = record['date']
            -- first match for each Type we save the date to capture the first next dates
            -- get the long description from the JSON data
            dprint(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
            local dateformat = '????????'
            -- Get days diff
            dateformat, daysdiffdev = GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
            if daysdiffdev == nil then
               dprint('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
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
   --
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = perform_webquery('"https://api.mijnafvalwijzer.nl/webservices/appsinput/?apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&postcode=' .. Zipcode .. '&street=&huisnummer=' .. Housenr .. '&toevoeging=&app_name=afvalwijzer&platform=phone&mobiletype=android&afvaldata=' .. tostring(os.date('*t').year) .. '-01-01&version=58&langs=nl"')
   if (Web_Data == '') then
      dprint('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
      return
   end
   if (Web_Data:sub(1, 3) == 'NOK') then
      dprint('### Error: Check your Postcode and Huisnummer as we get an NOK response.')
      return
   end
   if (Web_Data:find('ophaaldagen') == nil) then
      dprint('### Error: returned information does not contain the ophaaldagen section. stopping process.')
      return
   end
   --
   -- Decode JSON table
   decoded_response = JSON:decode(Web_Data)

   -- get the ophaaldagen tabel for the coming scheduled pickups for this year
   rdata = decoded_response['ophaaldagen']
   if type(rdata) ~= 'table' then
      dprint('### Error: Empty data.ophaaldagen table in JSON data...  stopping execution.')
      return
   end

   rdata = rdata['data']
   if type(rdata) ~= 'table' then
      dprint('### Error: Empty ophaaldagen.data table in JSON data...  stopping execution.')
      return
   end
   dprint('- start looping through this year received data -----------------------------------------------------------')
   processdata(rdata)
   -- only process nextyear data in case we do not have the requested number of next events
   if #garbagedata < 10 then
      -- get the ophaaldagen tabel for next year when needed
      rdataly = decoded_response['ophaaldagenNext']
      if type(rdataly) ~= 'table' then
         print('@AFW: Empty data.ophaaldagen table in JSON data...  stopping execution.')
      else
         rdataly = rdataly['data']
         if type(rdataly) ~= 'table' then
            dprint('### Error: Empty data.ophaaldagen.data table in JSON data...  stopping execution.')
         else
            -- get the next number of ShowNextEvents
            dprint('- start looping through next year received data -----------------------------------------------------------')
            processdata(rdataly)
         end
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date('*t')
-- get paramters from the commandline
domoticzjsonpath = domoticzjsonpath or arg[1]
Zipcode = Zipcode or arg[2]
Housenr = Housenr or arg[3] or ''
Housenrsuf = Housenrsuf or arg[4]
afwdatafile = datafile or arg[5]
afwlogfile = weblogfile or arg[6]
Hostname = (Hostname or arg[7]) or '' -- Not needed
Street = (Street or arg[8]) or '' -- Not needed
-- other variables
garbagedata = {} -- array to save information to which will be written to the data file

dprint('#### ' .. os.date('%c') .. ' ### Start garbagecalendar module ' .. websitemodule .. ' (v' .. ver .. ')')
if domoticzjsonpath == nil then
   dprint('!!! domoticzjsonpath not specified!')
elseif Zipcode == nil then
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
      dprint('### Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. domoticzjsonpath .. '.')
      dprint('### Error: Please check your setup and try again.')
      os.exit() -- stop execution
   end
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. Hostname)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
end
