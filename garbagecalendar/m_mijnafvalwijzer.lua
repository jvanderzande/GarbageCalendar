-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230223-1500'
websitemodule = 'm_mijnafvalwijzer'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
-- Link to WebSite:  https://mijnafvalwijzer.nl/nl/postcode/huisnr--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   local txt = ''
   local txtcnt = 0
   --
   Print_logfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = genfuncs.perform_webquery('"https://www.mijnafvalwijzer.nl/nl/' .. Zipcode .. '/' .. Housenr .. '' .. Housenrsuf .. '"', false)
   if Web_Data == '' then
      Print_logfile( 'Error Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      Print_logfile( 'Error check postcode   Web_Data:' .. Web_Data)
      return
   end
   -- Retrieve part with the dates for pickup
   Web_Data = Web_Data:match('.-class="ophaaldagen">(.-)<div id="calendarMessage"')
   if Web_Data == nil or Web_Data == '' then
      print('### Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
      return
   end
   Web_Data = Web_Data:gsub('%s+',' ')
   Print_logfile( '---- web data stripped -------------------------------------------------------------------')
   Print_logfile( Web_Data)
   Print_logfile( '---- end web data stripped ------------------------------------------------------------------------')
   -- Process received webdata.
   local web_garbagetype = ''
   local web_garbagetype_date = ''
   local web_garbagetype_changed = ''
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   Print_logfile( '- start looping through received data ----------------------------------------------------')
   for web_garbagetype, web_garbagedesc, web_garbagedate in string.gmatch(Web_Data, '#waste.(.-)".-title="(.-)".-span.line.break">(.-)<') do
      i = i + 1
      Print_logfile( i .. ' web_garbagetype:' .. tostring(web_garbagetype or '?') .. ' web_garbagedesc:' .. tostring(web_garbagedesc or '?') .. '   web_garbagedate:' .. tostring(web_garbagedate or '?'))
      if web_garbagetype ~= nil and web_garbagedate ~= nil then
         web_garbagedesc = web_garbagedesc or ''
         -- first match for each Type we save the date to capture the first next dates
         --Print_logfile( web_garbagetype,web_garbagedate)
         dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '[^%s]+%s+(%d+)%s+([^%s]+)%s-(%d-)$', {'dd', 'mmm', 'yyyy'})
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if (daysdiffdev >= 0) then
            pickuptimes[#pickuptimes + 1] = {}
            pickuptimes[#pickuptimes].garbagetype = web_garbagetype
            pickuptimes[#pickuptimes].garbagedate = dateformat
            pickuptimes[#pickuptimes].diff = daysdiffdev
            -- field to be used when Web_Data contains a description
            pickuptimes[#pickuptimes].wdesc = web_garbagedesc
         end
      end
   end
   Print_logfile( '- Sorting records.')
   local eventcnt = 0
   for x = 0, 60, 1 do
      for mom in pairs(pickuptimes) do
         if pickuptimes[mom].diff == x then
            garbagedata[#garbagedata + 1] = {}
            garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
            garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
            -- field to be used when Web_Data contains a description
            garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
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
