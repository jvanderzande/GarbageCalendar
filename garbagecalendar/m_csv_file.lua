-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_csv_file.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230629-1930'
websitemodule = 'm_csv_file'

--[[
This module requires an inputfile defined by this variable in the configfile:
input_csv_file = "garbagecalendar/garbage_input.csv"

--With the following format:--
garbagedate;garbagetype
20-8-2020;papier
23-8-2020;GFT
1-9-2020;Rest
10-9-2020;papier
21-9-2020;GFT
30-9-2020;Rest
3-10-2020;papier
4-10-2020;GFT
5-10-2020;Rest
--]]
-- =======================================================================================
-- Check required fields for this module. The script will end when one is missing.
-- =======================================================================================
chkfields = {
	'websitemodule',
	--	"Zipcode",
	--	"Housenr",
	--	"Housenrsuf",
	'Datafile'
	--	"Hostname",
	--	"Street",
	--	"Companycode"
}
-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	local txt = ''
	local txtcnt = 0
	--
	Print_logfile('---- check garbage_input.csv ----------------------------------------------------------------------------')
	if (genfuncs.exists(input_csv_file)) then
		Print_logfile('input File ' .. input_csv_file .. ' found, check access.')
		if (not genfuncs.haveaccess(input_csv_file)) then
			Print_logfile('No access to the file. Running->sudo chmod 777 ' .. input_csv_file)
			os.execute('sudo chmod 777 ' .. input_csv_file .. ' 2>/dev/null')
			if (genfuncs.haveaccess(input_csv_file)) then
				Print_logfile('Access fixed to the data file.')
			else
				Print_logfile('Still no access. Please check the settings for ' .. input_csv_file .. ' and then try again.')
				return false
			end
		end
	else
		Print_logfile('input File ' .. input_csv_file .. ' not found. exit process.')
		return false
	end

	Print_logfile('---- Open garbage_input.csv ----------------------------------------------------------------------------')
	ifile, err = io.open(input_csv_file, 'r')
	local Web_Data = ''
	if not err then
		Web_Data = ifile:read('*all')
		ifile:close()
	end

	if Web_Data == '' then
		Print_logfile('Error Web_Data is empty.')
		return
	end
	Print_logfile('---- web data ----------------------------------------------------------------------------')
	Print_logfile(Web_Data)
	Print_logfile('---- end web data ------------------------------------------------------------------------')
	-- Process received webdata.
	local i = 0
	-- loop through returned result
	Print_logfile('- start looping through received data ----------------------------------------------------')
	for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, '([^;\r\n]+);([^\r\n;]+)') do
		i = i + 1
		Print_logfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype or '?') .. '   web_garbagedate:' .. tostring(web_garbagedate or '?'))
		if web_garbagetype ~= nil and web_garbagedate ~= nil and web_garbagedate ~= 'garbagedate' then
			web_garbagedesc = web_garbagedesc or ''
			-- first match for each Type we save the date to capture the first next dates
			--Print_logfile( web_garbagetype,web_garbagedate)
			dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'dd', 'mm', 'yyyy'})
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
