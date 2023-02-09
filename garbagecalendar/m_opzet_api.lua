-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230209-2000'
websitemodule = 'm_opzet_api'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
--

-- Start Functions =========================================================================
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
               Print_weblogfile( ' Not collected web_garbagetype : ' .. (web_garbagetype or "?????"))
            else
               Print_weblogfile( ' web_garbagetype : ' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
               local dateformat = '????????'
               -- Get days diff
               dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', { 'yyyy', 'mm', 'dd' })
               if daysdiffdev == nil then
                  Print_weblogfile( 'Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
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

   Print_weblogfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   -- Get the information for the specified address specifically the bagId for the subsequent calls
   Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/rest/adressen/' .. Zipcode .. '-' .. Housenr .. '"')
   if Web_Data == '' then
      return
   end
   if (Web_Data:sub(1, 2) == '[]') then
      Print_weblogfile( '### Error: Check your Zipcode and Housenr as we get an [] response.')
      return
   end
   local adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   local bagId = ""
   for i = 1, #adressdata do
      local record = adressdata[i]
      Print_weblogfile( 'Address options: ' .. record['huisletter'] .. '=' .. Housenrsuf .. '->' .. record['bagId'])
      if type(record) == 'table' then
         bagId = record['bagId']
         if Housenrsuf == record['huisletter'] then
            break
         end
      end
   end
   if bagId == nil or bagId == '' then
      Print_weblogfile( '### Error: No bagId retrieved...  stopping execution.')
      return
   end
   Print_weblogfile( 'bagId:' .. bagId)

   -- get the Afvalstromen information for all possible garbagetypeid's with their ophaaldatum info for this address(bagId)
   Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/rest/adressen/' .. bagId .. '/afvalstromen"')
   if (Web_Data:sub(1, 2) == '[]') then
      Print_weblogfile( '### Error: Unable to retrieve Afvalstromen information...  stopping execution.')
      return
   end
   --
   -- Strip Icon info as that contains much data which is giving JSON lexing problems.
   Web_Data = Web_Data:gsub('(,"icon_data":".-",)', ',')
   Print_weblogfile( "==== Stripped 1 ========================================================")
   Print_weblogfile( Web_Data)
   --
   -- Strip \ infront of " to ensure the next stripping will work
   Web_Data = Web_Data:gsub('(\\")', '"')
   Print_weblogfile( "==== Stripped 2 ========================================================")
   Print_weblogfile( Web_Data)
   --
   -- Strip content field as that contains much data which is giving JSON lexing problems.
   Web_Data = Web_Data:gsub('(,"content":".-",)', ',')
   Print_weblogfile( "==== Stripped 3 ========================================================")
   Print_weblogfile( Web_Data)
   Print_weblogfile( "============================================================")

   -- process the data
   Print_weblogfile( '- start looping through received data -----------------------------------------------------------')
   local igarbagedata = processdata(JSON:decode(Web_Data))
   Print_weblogfile( '- Sorting records.')
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
