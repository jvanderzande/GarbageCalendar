-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20220505-1900'
websitemodule = 'm_opzet_api'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
--
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
   function processdata(ophaaldata)
      local pickuptimes = {}
      for record, data in pairs(ophaaldata) do
         if type(data) == 'table' then
            local web_garbagetype = data.title
            local web_garbagedate = data.ophaaldatum
            if web_garbagedate == nil then
               -- this is a type that is not collected and has no ophaaldag defined
               dprint(' Not collected web_garbagetype : ' .. (web_garbagetype or "?????"))
            else
               dprint(' web_garbagetype : ' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
               local dateformat = '????????'
               -- Get days diff
               dateformat, daysdiffdev = GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', { 'yyyy', 'mm', 'dd' })
               if daysdiffdev == nil then
                  dprint('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
                  return
               end
               if (daysdiffdev >= 0) then
                  pickuptimes[#pickuptimes + 1] = {}
                  pickuptimes[#pickuptimes].garbagetype = web_garbagetype
                  pickuptimes[#pickuptimes].garbagedate = dateformat
                  pickuptimes[#pickuptimes].diff = daysdiffdev
               end
            end
         end
      end
      return pickuptimes
   end

   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   -- Get the information for the specified address specifically the bagId for the subsequent calls
   Web_Data = perform_webquery('"https://' .. Hostname .. '/rest/adressen/' .. Zipcode .. '-' .. Housenr .. '"')
   if Web_Data == '' then
      return
   end
   if (Web_Data:sub(1, 2) == '[]') then
      dprint('### Error: Check your Zipcode and Housenr as we get an [] response.')
      return
   end
   local adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   local bagId = ""
   for i = 1, #adressdata do
      local record = adressdata[i]
      dprint('Address options: ' .. record['huisletter'] .. '=' .. Housenrsuf .. '->' .. record['bagId'])
      if type(record) == 'table' then
         bagId = record['bagId']
         if Housenrsuf == record['huisletter'] then
            break
         end
      end
   end
   if bagId == nil or bagId == '' then
      dprint('### Error: No bagId retrieved...  stopping execution.')
      return
   end
   dprint('bagId:' .. bagId)

   -- get the Afvalstromen information for all possible garbagetypeid's with their ophaaldatum info for this address(bagId)
   Web_Data = perform_webquery('"https://' .. Hostname .. '/rest/adressen/' .. bagId .. '/afvalstromen"')
   if (Web_Data:sub(1, 2) == '[]') then
      dprint('### Error: Unable to retrieve Afvalstromen information...  stopping execution.')
      return
   end
   --
   -- Strip Icon info as that contains much data which is giving JSON lexing problems.
   Web_Data = Web_Data:gsub('(,"icon_data":".-",)', ',')
   dprint("==== Stripped 1 ========================================================")
   dprint(Web_Data)
   --
   -- Strip \ infront of " to ensure the next stripping will work
   Web_Data = Web_Data:gsub('(\\")', '"')
   dprint("==== Stripped 2 ========================================================")
   dprint(Web_Data)
   --
   -- Strip content field as that contains much data which is giving JSON lexing problems.
   Web_Data = Web_Data:gsub('(,"content":".-",)', ',')
   dprint("==== Stripped 3 ========================================================")
   dprint(Web_Data)
   dprint("============================================================")

   -- process the data
   dprint('- start looping through received data -----------------------------------------------------------')
   local igarbagedata = processdata(JSON:decode(Web_Data))
   dprint('- Sorting records.')
   for x = 0, 60, 1 do
      for mom in pairs(igarbagedata) do
         if igarbagedata[mom].diff == x then
            garbagedata[#garbagedata + 1] = {}
            garbagedata[#garbagedata].garbagetype = igarbagedata[mom].garbagetype
            garbagedata[#garbagedata].garbagedate = igarbagedata[mom].garbagedate
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
elseif Hostname == '' then
   dprint('!!! Hostname not specified!')
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
