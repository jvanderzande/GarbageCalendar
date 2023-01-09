-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_recycleapp-be
-- Remarks:
----------------------------------------------------------------------------------------------------------------
ver = '20230109-1437'
websitemodule = 'm_recycleapp-be'
-- Link to https://www.recycleapp.be
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
   -- function to process ThisYear and Lastyear JSON data
   function processdata(ophaaldata)
      aantal = ophaaldata.total
      ophaaldata = ophaaldata['items'] -- get the Datalist tabel for the coming scheduled pickups
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == 'table' then
            web_garbagetype = record.fraction.name.nl
            web_garbagedate = record.timestamp
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
            -- field to be used when Web_Data contains a description
            -- garbagedata[#garbagedata].wdesc =
            end
         end
      end
   end
   dprint('---- web update ----------------------------------------------------------------------------')
   -- Get Access token
   -- step 1: Get main js name from home page: <script src="/static/js/main.0b66adb4.chunk.js">
   local Web_Data
   Web_Data = perform_webquery('https://recycleapp.be')
   MainScript = Web_Data:match('<script src="(/static/js/main.-)">')
   dprint(' MainScript:' .. (MainScript or '?')) -- MainScript:/static/js/main.0b66adb4.chunk.js
   -- step 2: retrieve main js and get code from source:
   --          var n="8a9pIQlfYpgmJZD15KdK70MCTR2xyD0EAvOmi9HCBfiBUY4n34ytxQmqo3AP2OET6tssYy6R4Be6N2M2GtiX3AcbiNxR8G7pOalN45dXPZ4emKE2c1nimx9B1YFciutJwFZHYHI2Qpzo0E0GCDHkg5",c="/api/v1/assets/<script src="/static/js/main.0b66adb4.chunk.js">
   Web_Data = perform_webquery('https://recycleapp.be' .. MainScript)
   secret = Web_Data:match('.+var n="(.-)",')
   dprint(' secret:' .. (secret or '?'))
   headerdata = ' -H "x-secret: ' .. secret .. '"' .. ' -H "x-consumer: recycleapp.be"'
   -- step 3: Get access token:
   Web_Data = perform_webquery(headerdata .. ' https://recycleapp.be/api/app/v1/access-token')
   webdata = JSON:decode(Web_Data)
   accessToken = webdata.accessToken or ''
   if accessToken == '' then
      dprint('### Error: No accessToken retrieved...  stopping execution.')
      return
   end
   dprint('accessToken:' .. accessToken)
   headerdata = headerdata .. ' -H "Authorization:' .. accessToken .. '"'

   -- Step 4: Get zipcodeid
   Web_Data = perform_webquery(headerdata .. ' "https://recycleapp.be/api/app/v1/zipcodes?q=' .. Zipcode .. '"')
   Web_Data = JSON:decode(Web_Data)
   postcode_id = Web_Data.items[1].id or ''
   if postcode_id == '' then
      dprint('### Error: No postcode_id retrieved...  stopping execution.')
      return
   end
   dprint('postcode_id:' .. postcode_id)

   -- Step 5: Get streetid
   Web_Data = perform_webquery(headerdata .. ' "https://recycleapp.be/api/app/v1/streets?q=' .. url_encode(Street) .. '&zipcodes=' .. postcode_id .. '"')
   Web_Data = JSON:decode(Web_Data)

   street_id = Web_Data.items[1].id or ''
   if street_id == '' then
      dprint('### Error: No street_id retrieved...  stopping execution.')
      return
   end
   dprint('street_id:' .. street_id)

   -- Step 6: Get calendar data
   startDate = os.date('%Y-%m-%d')
   endDate = os.date('%Y-%m-%d', os.time() + 28 * 24 * 60 * 60) -- 4 weken
   Web_Data = perform_webquery(headerdata .. ' "https://recycleapp.be/api/app/v1/collections?zipcodeId=' .. postcode_id .. '&streetId=' .. street_id .. '&houseNumber=' .. Housenr .. '&fromDate=' .. startDate .. '&untilDate=' .. endDate .. '&size=100"')
   Web_Data = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(Web_Data) ~= 'table' then
      dprint('### Error: Empty Kalender .  stopping execution.')
      return
   end
   processdata(Web_Data)
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
Street = (Street or arg[7]) or '' -- Required!!
-- other variables
garbagedata = {} -- array to save information to which will be written to the data file

dprint('#### ' .. os.date('%c') .. ' ### Start garbagecalendar module ' .. websitemodule .. ' (v' .. ver .. ')')
if Zipcode == nil then
   dprint('!!! Zipcode not specified!')
elseif Housenr == nil then
   dprint('!!! Housenr not specified!')
elseif Housenrsuf == nil then
   dprint('!!! Housenrsuf not specified!')
elseif Street == '' then
   dprint('!!! Street not specified!')
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
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  Street:' .. Street)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
end
