-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_ximmio.lua
----------------------------------------------------------------------------------------------------------------
ver = '20211010-1900'
websitemodule = 'm_ximmio'
-- API WebSite:  https://wasteapi.2go-mobile.com/api  &  https://wasteprod2api.ximmio.com
--
--- Find your companycode by:
--   1. goto your webpage calendar and display the garbage calendar
--   2. go into Developer mode for your browser
--   3. find source file controller.js
--   4. find this section and copy the value for companyCode:
--     $api('GetConfigOption', {
--       companyCode: '53d8db94-7945-42fd-9742-9bbc71dbe4c1',
--       configName: 'ALL'
--       })
-- Copy the found value and paste it into the hostname field in your garbagecalendarconfig.lua to make this module work!
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or './'
end
-- only include when run in separate process
if scriptpath == nil then
   dofile(script_path() .. 'generalfuncs.lua') --
end
--------------------------------------------------------------------------
-- Perform the actual update process for the given address
function Perform_Update()
   function processdata(ophaaldata)
      local pickuptimes = {}
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == 'table' then
            web_garbagetype = record['_pickupTypeText']
            --dprint(web_garbagetype)
            if (record['description'] ~= nil and record['description'] ~= "Null") then
               web_garbagedesc = record['description']
               --dprint(web_garbagedesc)
            else
               web_garbagedesc = ""
            end
            garbagedate = record['pickupDates']
            local dateformat = '????????'
            for i = 1, #garbagedate do
               record = garbagedate[i]
               -- Get days diff
               dprint(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(garbagedate[i]))
               dateformat, daysdiffdev = GetDateFromInput(garbagedate[i], '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
               if daysdiffdev == nil then
                  dprint('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. garbagedate[i])
               else
                  if (daysdiffdev >= 0) then
                     pickuptimes[#pickuptimes + 1] = {}
                     pickuptimes[#pickuptimes].garbagetype = web_garbagetype
                     pickuptimes[#pickuptimes].garbagedate = dateformat
                     pickuptimes[#pickuptimes].diff = daysdiffdev
                     pickuptimes[#pickuptimes].wdesc = web_garbagedesc
                  end
               end
            end
         end
      end
      dprint('- Sorting records.')
      local eventcnt = 0
      for x = 0, 60, 1 do
         for mom in pairs(pickuptimes) do
            if pickuptimes[mom].diff == x then
               garbagedata[#garbagedata + 1] = {}
               garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
               garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
               garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
            end
         end
      end
   end
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   local webhost = 'https://wasteprod2api.ximmio.com'
   ---
   -- Get the information for the specified address specifically the UniqueId for the subsequent calls
   Web_Data = perform_webquery('--data "companyCode=' .. companyCode .. '&postCode=' .. Zipcode .. '&houseNumber=' .. Housenr .. '&houseNumberAddition=' .. Housenrsuf .. '" "' .. webhost .. '/api/FetchAdress"')
   if Web_Data == '' then
      return
   end
   if (Web_Data:sub(1, 2) == '[]') then
      dprint('### Error: Check your Zipcode and Housenr as we get an [] response.')
      return
   end
   adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   if adressdata['dataList'] == nil or adressdata['dataList'][1] == nil then
      webhost = 'https://wasteapi.2go-mobile.com'
      Web_Data = perform_webquery('--data "companyCode=' .. companyCode .. '&postCode=' .. Zipcode .. '&houseNumber=' .. Housenr .. '&houseNumberAddition=' .. Housenrsuf .. '" "' .. webhost .. '/api/FetchAdress"')
      adressdata = JSON:decode(Web_Data)
   end
   if adressdata['dataList'] == nil or adressdata['dataList'][1] == nil then
      dprint('### Error: No UniqueId retrieved, datalist missing...  stopping execution.')
      return
   end
   UniqueId = adressdata['dataList'][1]['UniqueId']
   if UniqueId == nil or UniqueId == '' then
      dprint('### Error: No UniqueId retrieved...  stopping execution.')
      return
   end

   dprint('UniqueId:' .. UniqueId)
   -- set startdate to today en end date to today + 28 days
   startDate = os.date('%Y-%m-%d')
   endDate = os.date('%Y-%m-%d', os.time() + 28 * 24 * 60 * 60)
   Web_Data = perform_webquery('--data "companyCode=' .. companyCode .. '&uniqueAddressID=' .. UniqueId .. '&startDate=' .. startDate .. '&endDate=' .. endDate .. '" "' .. webhost .. '/api/GetCalendar"')
   if (Web_Data:sub(1, 2) == '[]') then
      dprint('### Error: Unable to retrieve Afvalstromen information...  stopping execution.')
      return
   end
   jdata = JSON:decode(Web_Data)
   -- get the Datalist tabel for the coming scheduled pickups
   if type(jdata) ~= 'table' then
      dprint('### Error: Empty Kalender found stopping execution.')
      return
   end
   jdata = jdata['dataList'] -- get the Datalist tabel for the coming scheduled pickups
   if type(jdata) ~= 'table' then
      print('### Error: Empty Kalender found stopping execution.')
      return
   end
   -- process the data
   dprint('- start looping through received data -----------------------------------------------------------')
   processdata(jdata)
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
companyCode = (Hostname or arg[7]) or '' -- Required !
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
elseif companyCode == '' then
   dprint('!!! companyCode not specified. Please check in file m_ximmio.lua how to obtain this companyCode!')
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
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. ' companyCode:' .. companyCode)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
end
