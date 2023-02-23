-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer_API.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230223-1500'
websitemodule = 'm_mijnafvalwijzer_API'
-- Link to WebSite: https://api.mijnafvalwijzer.nl/webservices/appsinput/?apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&postcode=1234AB&street=&huisnummer=1&toevoeging=&app_name=afvalwijzer&platform=phone&mobiletype=android&afvaldata=2021-01-01&version=58&langs=nl
--

-- Start Functions =========================================================================
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
            Print_logfile( i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
            local dateformat = '????????'
            -- Get days diff
            dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
            if daysdiffdev == nil then
               Print_logfile( 'Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
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
   Print_logfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = genfuncs.perform_webquery('"https://api.mijnafvalwijzer.nl/webservices/appsinput/?apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&postcode=' .. Zipcode .. '&street=&huisnummer=' .. Housenr .. '&toevoeging=&app_name=afvalwijzer&platform=phone&mobiletype=android&afvaldata=' .. tostring(os.date('*t').year) .. '-01-01&version=58&langs=nl"')
   if (Web_Data == '') then
      Print_logfile( '### Error: Empty result from curl command. Please check whether curl.exe is installed.')
      return
   end
   if (Web_Data:sub(1, 3) == 'NOK') then
      Print_logfile( '### Error: Check your Postcode and Huisnummer as we get an NOK response.')
      return
   end
   if (Web_Data:find('ophaaldagen') == nil) then
      Print_logfile( '### Error: returned information does not contain the ophaaldagen section. stopping process.')
      return
   end
   --
   -- Decode JSON table
   decoded_response = JSON:decode(Web_Data)

   -- get the ophaaldagen tabel for the coming scheduled pickups for this year
   rdata = decoded_response['ophaaldagen']
   if type(rdata) ~= 'table' then
      Print_logfile( '### Error: Empty data.ophaaldagen table in JSON data...  stopping execution.')
      return
   end

   rdata = rdata['data']
   if type(rdata) ~= 'table' then
      Print_logfile( '### Error: Empty ophaaldagen.data table in JSON data...  stopping execution.')
      return
   end
   Print_logfile( '- start looping through this year received data -----------------------------------------------------------')
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
            Print_logfile( '### Error: Empty data.ophaaldagen.data table in JSON data...  stopping execution.')
         else
            -- get the next number of ShowNextEvents
            Print_logfile( '- start looping through next year received data -----------------------------------------------------------')
            processdata(rdataly)
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
	"datafile",
--	"Hostname",
--	"Street",
--	"companyCode"
}
local param_err=0
-- Check whether the required parameters are specified.
for key, value in pairs(chkfields) do
	if (_G[value] or '') == '' then
		param_err = param_err + 1
		Print_logfile('!!! '..value .. ' not specified!', 1)
	end
end
-- Get the web info when all required parameters are defined
if param_err == 0 then
	Print_logfile('!!! perform web data update to ' .. datafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf )
	Perform_Update()
	Print_logfile('=> Write data to ' .. datafile)
	table.save(garbagedata, datafile)
else
	Print_logfile('!!! Webupdate cancelled due to missing parameters!', 1)
end
