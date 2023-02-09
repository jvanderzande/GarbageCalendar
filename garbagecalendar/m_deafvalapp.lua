-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_deafvalapp.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230209-2000'
websitemodule = 'm_deafvalapp'
-- Link to WebSite:  http://dataservice.deafvalapp.nl
--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   Print_weblogfile( '---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = genfuncs.perform_webquery('"https://dataservice.deafvalapp.nl/dataservice/DataServiceServlet?service=OPHAALSCHEMA&land=NL&postcode=' .. Zipcode .. '&straatId=0&huisnr=' .. Housenr .. '' .. Housenrsuf .. '"')
   if Web_Data == '' then
      Print_weblogfile( 'Error Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      Print_weblogfile( 'Error check postcode   Web_Data:' .. Web_Data)
      return
   end
   -- Process received webdata.
   local web_garbagetype = ''
   local web_garbagetype_date = ''
   local web_garbagetype_changed = ''
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   Print_weblogfile( '- start looping through received data ----------------------------------------------------')
   for web_garbagetype, web_garbagedates in string.gmatch(Web_Data, '(.-);(.-)[\r\n|$]') do
      Print_weblogfile( web_garbagetype)
      for web_garbagedate in string.gmatch(web_garbagedates, '(.-);') do
         if web_garbagetype ~= nil and web_garbagedate ~= nil then
            -- first match for each Type we save the date to capture the first next dates
            Print_weblogfile( '  web_garbagetype:' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
            dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'dd', 'mm', 'yyyy'})
            -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
            if (daysdiffdev >= 0) then
               pickuptimes[#pickuptimes + 1] = {}
               pickuptimes[#pickuptimes].garbagetype = web_garbagetype
               pickuptimes[#pickuptimes].garbagedate = dateformat
               pickuptimes[#pickuptimes].diff = daysdiffdev
            -- field to be used when Web_Data contains a description
            -- pickuptimes[#pickuptimes].wdesc = ....
            end
         end
      end
   end
   Print_weblogfile( '- Sorting records.')
   local eventcnt = 0
   for x = 0, 60, 1 do
      for mom in pairs(pickuptimes) do
         if pickuptimes[mom].diff == x then
            garbagedata[#garbagedata + 1] = {}
            garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
            garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
         -- field to be used when Web_Data contains a description
         --garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
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
--	"Hostname",
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
