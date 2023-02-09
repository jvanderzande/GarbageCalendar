-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_ximmio.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230209-2000'
websitemodule = 'm_ximmio'
-- API WebSite:  https://wasteapi.2go-mobile.com/api  &  https://wasteprod2api.ximmio.com
--
--- Find your companycode by:
--   1. goto your webpage calendar and display the garbage calendar
--   2. go into Developer mode for your browser (F12)
--   3. find source file controller.js
--   4. find this section and copy the value for companyCode:
--     $api('GetConfigOption', {
--       companyCode: '53d8db94-7945-42fd-9742-9bbc71dbe4c1',
--       configName: 'ALL'
--       })
-- Copy the found companyCode value and paste it into the hostname field in your garbagecalendarconfig.lua
-- to make this module work!

-- Start Functions =========================================================================
--------------------------------------------------------------------------
-- Perform the actual update process for the given address
function Perform_Update()
	function processdata(ophaaldata)
		local pickuptimes = {}
		for i = 1, #ophaaldata do
			record = ophaaldata[i]
			if type(record) == 'table' then
				web_garbagetype = record['_pickupTypeText']
				--Print_weblogfile( web_garbagetype)
				if (record['description'] ~= nil and record['description'] ~= 'Null') then
					--Print_weblogfile( web_garbagedesc)
					web_garbagedesc = record['description']
				else
					web_garbagedesc = ''
				end
				garbagedate = record['pickupDates']
				local dateformat = '????????'
				for i = 1, #garbagedate do
					record = garbagedate[i]
					-- Get days diff
					Print_weblogfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(garbagedate[i]))
					dateformat, daysdiffdev = genfuncs.GetDateFromInput(garbagedate[i], '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
					if daysdiffdev == nil then
						Print_weblogfile('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. garbagedate[i])
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
		Print_weblogfile('- Sorting records.')
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
	Print_weblogfile('---- web update ----------------------------------------------------------------------------')
	local Web_Data
	local webhost = 'https://wasteprod2api.ximmio.com'
	---
	-- Get the information for the specified address specifically the UniqueId for the subsequent calls
	Web_Data = genfuncs.perform_webquery('--data "companyCode=' .. companyCode .. '&postCode=' .. Zipcode .. '&houseNumber=' .. Housenr .. '&houseNumberAddition=' .. Housenrsuf .. '" "' .. webhost .. '/api/FetchAdress"')
	if Web_Data == '' then
		return
	end
	if (Web_Data:sub(1, 2) == '[]') then
		Print_weblogfile('### Error: Check your Zipcode and Housenr as we get an [] response.')
		return
	end
	adressdata = JSON:decode(Web_Data)
	-- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
	if adressdata['dataList'] == nil or adressdata['dataList'][1] == nil then
		webhost = 'https://wasteapi.2go-mobile.com'
		Web_Data = genfuncs.perform_webquery('--data "companyCode=' .. companyCode .. '&postCode=' .. Zipcode .. '&houseNumber=' .. Housenr .. '&houseNumberAddition=' .. Housenrsuf .. '" "' .. webhost .. '/api/FetchAdress"')
		adressdata = JSON:decode(Web_Data)
	end
	if adressdata['dataList'] == nil or adressdata['dataList'][1] == nil then
		Print_weblogfile('### Error: No UniqueId retrieved, datalist missing...  stopping execution.')
		return
	end
	UniqueId = adressdata['dataList'][1]['UniqueId']
	if UniqueId == nil or UniqueId == '' then
		Print_weblogfile('### Error: No UniqueId retrieved...  stopping execution.')
		return
	end

	Print_weblogfile('UniqueId:' .. UniqueId)
	-- set startdate to today en end date to today + 28 days
	startDate = os.date('%Y-%m-%d')
	endDate = os.date('%Y-%m-%d', os.time() + 28 * 24 * 60 * 60)
	Web_Data = genfuncs.perform_webquery('--data "companyCode=' .. companyCode .. '&uniqueAddressID=' .. UniqueId .. '&startDate=' .. startDate .. '&endDate=' .. endDate .. '" "' .. webhost .. '/api/GetCalendar"')
	if (Web_Data:sub(1, 2) == '[]') then
		Print_weblogfile('### Error: Unable to retrieve Afvalstromen information...  stopping execution.')
		return
	end
	jdata = JSON:decode(Web_Data)
	-- get the Datalist tabel for the coming scheduled pickups
	if type(jdata) ~= 'table' then
		Print_weblogfile('### Error: Empty Kalender found stopping execution.')
		return
	end
	jdata = jdata['dataList'] -- get the Datalist tabel for the coming scheduled pickups
	if type(jdata) ~= 'table' then
		print('### Error: Empty Kalender found stopping execution.')
		return
	end
	-- process the data
	Print_weblogfile('- start looping through received data -----------------------------------------------------------')
	processdata(jdata)
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
Print_weblogfile('#### ' .. os.date('%c') .. ' ### Start garbagecalendar module ' .. websitemodule .. ' (v' .. ver .. ')')

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
	"companyCode"
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
