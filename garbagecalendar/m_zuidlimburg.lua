-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_zuidlimburg.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230630-1300'
websitemodule = 'm_zuidlimburg'
-- Link to WebSite:  https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=AAAA99&nr=999&t
--
-- =======================================================================================
-- Check required fields for this module. The script will end when one is missing.
-- =======================================================================================
chkfields = {
	'websitemodule',
	'Zipcode',
	'Housenr',
	--	'Housenrsuf',
	'Datafile'
	--	'Hostname',
	--	'Street',
	--	'Companycode'
}
-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	local Web_Data = genfuncs.perform_webquery(' "https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=' .. Zipcode .. '&nr=' .. Housenr .. Housenrsuf .. '&t"')
	if Web_Data == '' then
		Print_logfile('### Error: Web_Data is empty.')
		return
	elseif string.find(Web_Data, '{"error":true}') ~= nil then
		Print_logfile('### Error: check Zipcode   Web_Data:' .. Web_Data)
		return
	end
	-- Process received webdata.
	local i = 0
	-- loop through returned result
	-- Retrieve part with the dates for pickup
	Web_Data = Web_Data:match('.-<div id="Afvalkalender1_pnlAfvalKalender">(.-)</div>')
	Print_logfile('---- web data Afvalkalender section ----------------------------------------------------------')
	Print_logfile(Web_Data)
	Print_logfile('---- end web data ----------------------------------------------------------------------------')
	Print_logfile('- start looping through received data --------------------------------------------------------')
	--   Loop through all dates
	for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, '<td>.-%s(.-)</td><td>(.-)</td>') do
		i = i + 1
		if web_garbagetype ~= nil and web_garbagedate ~= nil then
			-- first match for each Type we save the date to capture the first next dates
			Print_logfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
			-- check whether the first nextdate for this garbagetype is already found
			local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '([%d]+)%s+([^%s]+)%s-(%d-)$', {'dd', 'mmm', 'yyyy'})
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
