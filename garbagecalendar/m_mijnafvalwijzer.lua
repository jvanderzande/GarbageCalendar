-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer.lua
----------------------------------------------------------------------------------------------------------------
M_ver = '20250728-1130'
websitemodule = 'm_mijnafvalwijzer'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
-- Link to WebSite:  https://mijnafvalwijzer.nl/nl/postcode/huisnr--
-- Also used for rova with config: Hostname=afvalkalender.rova.nl
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
	--
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	if Hostname == '' then
		Hostname = 'www.mijnafvalwijzer.nl'  -- default
	end
	local Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/nl/' .. Zipcode .. '/' .. Housenr .. '' .. Housenrsuf .. '"', false)
	if Web_Data == '' then
		Print_logfile('Error Web_Data is empty.')
		return
	elseif string.find(Web_Data, '{"error":true}') ~= nil then
		Print_logfile('Error check postcode   Web_Data:' .. Web_Data)
		return
	end
	-- Retrieve part with the dates for pickup
	-- local s_data = Web_Data:find('class="ophaaldagen"') or 0
	local s_data = Web_Data:find('href="#waste', 0, true) or 0
	if s_data == 0 then
		Print_logfile('### Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
		return
	end
	-- Find end section or else use a length of 30000 characters to get the first 25ish occurences
	local e_data = Web_Data:find('id="waste-info-sections"', s_data, true) or (s_data + 30000)
	-- Maximise the Data to review to keep the speed of the module
	if e_data - s_data > 30000 then
		e_data = s_data + 30000
	end
	Web_Data = Web_Data:sub(s_data, e_data)
	if Web_Data == nil or Web_Data == '' then
		Print_logfile('### Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
		return
	end
	Web_Data = Web_Data:gsub('%s+', ' ')
	Print_logfile('### Calendar data section: s_data:'..s_data ..  ' -> e_data:'..e_data)
	Print_logfile('---- web data stripped -------------------------------------------------------------------')
	Print_logfile(Web_Data)
	Print_logfile('---- end web data stripped ------------------------------------------------------------------------')
	-- Process received webdata.
	local i = 0
	-- loop through returned result
	Print_logfile('- start looping through received data ----------------------------------------------------')
	for web_garbagetype, web_garbagedesc, web_garbagedate in string.gmatch(Web_Data, '#waste.(.-)".-title="(.-)".-span.line.break">(.-)<') do
		i = i + 1
		Print_logfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype or '?') .. ' web_garbagedesc:' .. tostring(web_garbagedesc or '?') .. '   web_garbagedate:' .. tostring(web_garbagedate or '?'))
		if web_garbagetype ~= nil and web_garbagedate ~= nil then
			web_garbagedesc = web_garbagedesc or ''
			-- first match for each Type we save the date to capture the first next dates
			--Print_logfile( web_garbagetype,web_garbagedate)
			local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '[^%s]+%s+(%d+)%s+([^%s]+)%s-(%d-)$', {'dd', 'mmm', 'yyyy'})
			-- When days is 0 or greater the date is today or in the future. Ignore any date in the past
			if (daysdiffdev >= 0) then
				garbagedata[#garbagedata + 1] = {}
				garbagedata[#garbagedata].garbagetype = web_garbagetype
				garbagedata[#garbagedata].garbagedate = dateformat
				garbagedata[#garbagedata].diff = daysdiffdev
				-- field to be used when Web_Data contains a description
				garbagedata[#garbagedata].wdesc = web_garbagedesc
			end
		end
	end
end
-- End Functions =========================================================================
