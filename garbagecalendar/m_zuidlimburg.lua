-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_zuidlimburg.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230209-1315'
websitemodule = 'm_zuidlimburg'
-- Link to WebSite:  https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=AAAA99&nr=999&t
--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   genfuncs.Print_afwlogfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = genfuncs.perform_webquery(' "https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=' .. Zipcode .. '&nr=' .. Housenr .. Housenrsuf .. '&t"')
   if Web_Data == '' then
      genfuncs.Print_afwlogfile( '### Error: Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      genfuncs.Print_afwlogfile( '### Error: check Zipcode   Web_Data:' .. Web_Data)
      return
   end
   -- Process received webdata.
   local web_garbagetype = ''
   local web_garbagetype_date = ''
   local web_garbagetype_changed = ''
   local i = 0
   -- loop through returned result
   i = 0
   -- Retrieve part with the dates for pickup
   Web_Data = Web_Data:match('.-<div id="Afvalkalender1_pnlAfvalKalender">(.-)</div>')
   genfuncs.Print_afwlogfile( '---- web data Afvalkalender section ----------------------------------------------------------')
   genfuncs.Print_afwlogfile( Web_Data)
   genfuncs.Print_afwlogfile( '---- end web data ----------------------------------------------------------------------------')
   genfuncs.Print_afwlogfile( '- start looping through received data --------------------------------------------------------')
   local web_garbagetype = ''
   local web_garbagedate = ''
   local txt = ''
   local cnt = 0
   --   Loop through all dates
   for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, '<td>.-%s(.-)</td><td>(.-)</td>') do
      i = i + 1
      if web_garbagetype ~= nil and web_garbagedate ~= nil then
         -- first match for each Type we save the date to capture the first next dates
         genfuncs.Print_afwlogfile( i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
         -- check whether the first nextdate for this garbagetype is already found
         dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '([%d]+)%s+([^%s]+)%s-(%d-)$', {'dd', 'mmm', 'yyyy'})
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if (daysdiffdev >= 0) then
            garbagedata[#garbagedata + 1] = {}
            garbagedata[#garbagedata].garbagetype = web_garbagetype
            garbagedata[#garbagedata].garbagedate = dateformat
            garbagedata[#garbagedata].diff = daysdiffdev
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
	"afwlogfile",
--	"Hostname",
--	"Street",
--	"companyCode"
}
local param_err=0
-- Check whether the required parameters are specified.
for key, value in pairs(chkfields) do
	if (_G[value] or '') == '' then
		param_err = param_err + 1
		genfuncs.Print_afwlogfile('!!! '..value .. ' not specified!', 1)
	end
end
-- Get the web info when all required parameters are defined
if param_err == 0 then
	genfuncs.Print_afwlogfile('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. companyCode)
	Perform_Update()
	genfuncs.Print_afwlogfile('=> Write data to ' .. afwdatafile)
	table.save(garbagedata, afwdatafile)
else
	genfuncs.Print_afwlogfile('!!! Webupdate cancelled due to misseng parameters!', 1)
end
