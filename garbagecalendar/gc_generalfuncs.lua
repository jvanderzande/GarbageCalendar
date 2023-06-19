-- ######################################################
-- functions library used by the garbagecalendar modules
-- ######################################################
MainGenUtilsVersion = '20230610-2317'

local genfuncs = {}

-- Get Domoticz Version used
function genfuncs.getdomoticzversion()
	url = "http://127.0.0.1:8080/json.htm?type=command&param=getversion"
	local sQuery = 'curl  "' .. url .. '"'
	--print(sQuery)
	local handle = assert(io.popen(sQuery))
	local Web_Data = handle:read("*all")
	if Web_Data ~= nil then
		decoded_response = JSON:decode(Web_Data)
		-- Set the Global variables for Domoticz version and revision
		genfuncs.DomoticzRevision = (decoded_response["Revision"] or 0)
		genfuncs.DomoticzVersion = (decoded_response["version"] or 0)
	end
	Print_logfile('-> DomoticzVersion ' .. (genfuncs.DomoticzVersion or 'nil'))
	Print_logfile('-> DomoticzRevision ' .. (genfuncs.DomoticzRevision or 'nil'))
end

-- addlogmessage function sends messages to Domoticz log
function genfuncs.addlogmessage(text, level)
	text = text or 'nil'
	level = tostring(level) or '1'
	url = 'http://127.0.0.1:8080/json.htm?type=command&param=addlogmessage&message=' .. genfuncs.url_encode(text) .. '&level=' .. level
	local sQuery = 'curl -k "' .. url .. '" > /tmp/garbagecalendar_logerrors.log 2>&1 '
	local handle = assert(io.popen(sQuery))
	local Web_Data = handle:read('*all')
	handle:close()
end

function genfuncs.file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

-- ---------------------------------------------------------
-- Get available Domoticz device icons
function genfuncs.getdeviceiconidx(GTypeIcon)
	if not GTypeIcon then
		Print_logfile("No GTypeIcon specified.",1)
		return nil
	end

	Print_logfile('0-> DomoticzVersion ' .. (genfuncs.DomoticzVersion or 'nil'))
	Print_logfile('0-> DomoticzRevision ' .. (genfuncs.DomoticzRevision or 'nil'))

	-- Check if icon exists in Domoticz and get its idx
	iidx = genfuncs.getcustom_light_icons(GTypeIcon)
	if iidx then
		Print_logfile(GTypeIcon.." idx "..iidx.." found in Domoticz custom icons")
		return iidx
	end

	-- else try uploading it outself when it is a standard available.
	-- lua/garbagecalendar//garbagecalendar/icons
	iconfile = GC_scriptpath.."icons/"..GTypeIcon..".zip"
	if not genfuncs.file_exists(iconfile) then
		-- not a standard iconset
		Print_logfile(iconfile .. " not found so won't try upload.")
		return nil
	end

	Print_logfile(GTypeIcon.." not found in Domoticz custom icons")
	Print_logfile("Trying to upload the found default:"..iconfile)

	if (genfuncs.DomoticzRevision or 0) > 15325 then
		--curl -F file=@domoticz_custom_icon_garbagecalendar_green.zip http://192.168.0.190:8080/json.htm?type=command&param=uploadcustomicon
		url = "http://127.0.0.1:8080/json.htm?type=command&param=uploadcustomicon"
	else
		--OLD:
		--curl -F file=@domoticz_custom_icon_garbagecalendar_green.zip http://192.168.0.190:8080/json.htm?type=command&param=uploadcustomicon
		url = "http://127.0.0.1:8080/uploadcustomicon"
	end
	local sQuery = 'curl -F file="@' .. iconfile .. '" "' .. url .. '"';
	local handle = assert(io.popen(sQuery))
	local Web_Data = handle:read("*all")
	Print_logfile("sQuery:"..(sQuery or ""))
	-- Check if upload was successfull
	if Web_Data ~= nil then
		data = JSON:decode(Web_Data)
		if (data == nil or data["status"] ~= 'OK') then
			-- upload must have failed
			Print_logfile("Upload iconf file failed:")
			Print_logfile(Web_Data)
			return nil
		end
	end
	Print_logfile("Upload icons done.")
	-- Icons uploaded so try to get the IDX again
	-- Check if icon exists in Domoticz and get its idx
	iidx = genfuncs.getcustom_light_icons(GTypeIcon)
	if iidx then
		Print_logfile(GTypeIcon.." idx "..iidx.." found in Domoticz custom icons")
		return iidx
	end
	-- idx still not found. We shoul never get here
	Print_logfile(GTypeIcon.." idx still not found in Domoticz custom icons, even after upload?")
	return nil
end

-- Get available Domoticz device icons
function genfuncs.getcustom_light_icons(GTypeIcon)
	if not GTypeIcon then
		Print_logfile("getdeviceiconidx No GTypeIcon")
		return nil
	end

	if not genfuncs.DomoticzRevision then
		genfuncs.getdomoticzversion()
	end

	Print_logfile('1-> DomoticzVersion ' .. (genfuncs.DomoticzVersion or 'nil'))
	Print_logfile('1-> DomoticzRevision ' .. (genfuncs.DomoticzRevision or 'nil'))

	if (genfuncs.DomoticzRevision or 0) > 15325 then
		url = "http://127.0.0.1:8080/json.htm?type=command&param=custom_light_icons"
	else
		url = "http://127.0.0.1:8080/json.htm?type=custom_light_icons"
	end
	local sQuery = 'curl  "' .. url .. '"'
	local handle = assert(io.popen(sQuery))
	local Web_Data = handle:read("*all")
	Print_logfile("url:" .. (url or "?"), 0)
	Print_logfile("result:" .. (Web_Data or "?"), 0)

	if Web_Data ~= nil then
		decoded_response = JSON:decode(Web_Data)
		result = decoded_response["result"]
		for i = 1, #result do
			local record = result[i]
			if type(record) == "table" then
				--[[
				description: "Used by Garbagecalendar",
				idx: 104,
				imageSrc: "garbagecalendar_blue",
				text: "Garbagecalendar blauwe bak"
				]]
				gicontype=record["imageSrc"]:match("^garbagecalendar_(.*)")
				--print(gicontype)
				if record["imageSrc"]:lower() == GTypeIcon:lower() then
					--print("found:",GTypeIcon,record["idx"],record["imageSrc"])
					return record["idx"]
				end
			end
		end
	end
	return nil
end


-- Set Domoticz device icon
function genfuncs.setdeviceicon(idx, devname, iconidx)
	--print("setdeviceicon",idx, devname, iconidx)
	if not iconidx then
			Print_logfile("!! Icon not update, idx = nil")
		return
	end
	if not genfuncs.DomoticzRevision then
		genfuncs.getdomoticzversion()
	end

	Print_logfile('2-> DomoticzVersion ' .. (genfuncs.DomoticzVersion or 'nil'))
	Print_logfile('2-> DomoticzRevision ' .. (genfuncs.DomoticzRevision or 'nil'))

	if (genfuncs.DomoticzRevision or 0) > 15325 then
		url = 'http://127.0.0.1:8080/json.htm?type=command&param=setused&used=true&name='.. (devname:gsub(" ", "%%20")) ..'&idx='.. idx ..'&switchtype=0&customimage='..iconidx
	else
		url = 'http://127.0.0.1:8080/json.htm?type=setused&used=true&name='.. (devname:gsub(" ", "%%20")) ..'&idx='.. idx ..'&switchtype=0&customimage='..iconidx
	end
	Print_logfile(url)
	local sQuery = 'curl -k "' .. url .. '"'
	local handle = assert(io.popen(sQuery))
	local Web_Data = handle:read('*all')
	handle:close()
	if Web_Data ~= nil then
		--print(Web_Data)
		record = JSON:decode(Web_Data)
		if record and (record['status'] or '') == 'OK' then
			Print_logfile("> Icon updated to idx:"..iconidx)
		else
			Print_logfile("!! Icon update failed")
		end
	end
end

-------------------------------------------------------
-- try to load module/library
function genfuncs.loadlualib(libname)
	Print_logfile('-> Loading module ' .. (libname or 'nil'))
	local moduleobject
	local function loadlib()
		if unexpected_condition then
			error()
		end
		-- add defined Domoticz path to the search path
		if not package.path:match(GC_scriptpath .. '%?.lua;') then
			package.path = GC_scriptpath .. '?.lua;' .. package.path
			Print_logfile('updated package.path:'.. package.path)
		end
		moduleobject = require(libname)
	end

	if pcall(loadlib) then
		Print_logfile('-< Loaded ' .. libname .. '.lua.  ->moduleobject type:' .. type(moduleobject))
		return moduleobject
	else
		Print_logfile('### Error: failed loading default ' .. libname .. '.lua!')
		Print_logfile('    package.path=' .. package.path .. '.')
		Print_logfile('### Error: Please check your setup and try again.')
		return nil
	end
end

-------------------------------------------------------
-- round function
function genfuncs.Round(num, idp)
	return tonumber(string.format('%.' .. (idp or 0) .. 'f', num))
end

-------------------------------------------------------
-- url_encode function
function genfuncs.url_encode(str)
	if (str) then
		str =
				string.gsub(str, '([^%w %-%_%.%~])', function(c)
					return string.format('%%%02X', string.byte(c))
				end
				)
		str = string.gsub(str, ' ', '+')
	end
	return str
end

-------------------------------------------------------
-- url_unescape function
local hex_to_char = function(x)
	return string.char(tonumber(x, 16))
end

function genfuncs.url_unescape(url)
	return url:gsub('%%(%x%x)', hex_to_char)
end

--------------------------------------------------------------------------
-- Do the actual webquery, retrieving data from the website
function genfuncs.perform_webquery(url, logdata)
	-- Show retrieved webdat by default or else depening on mydebug
	if logdata == nil then
		logdata = true
	else
		logdata = mydebug
	end
	-- Define Web Query
	local sQuery = 'curl -k ' .. url
	errlogfile = (datafilepath or ((GC_scriptpath or '/') .. 'data/')) .. 'webquery_err.log'
	-- Pipe STDERR to file when defined
	sQuery = sQuery .. ' 2>' .. errlogfile
	-- Run Query
	Print_logfile('sQuery=' .. sQuery)
	local handle = assert(io.popen(sQuery))
	local Web_Data = handle:read('*all')
	handle:close()
	-- Show Webdata retrieved
	if logdata then
		Print_logfile('---- web data ----------------------------------------------------------------------------')
		Print_logfile(Web_Data)
	end
	-- Check for Web request errors when seperate file is defined, else all output is in Web_Data
	Print_logfile('---- web err ------------------------------------------------------------------------')
	local Web_Error = ''
	local ifile, ierr = io.open(errlogfile, 'r')
	Web_Error = ierr or ''
	if not ierr then
		Web_Error = ifile:read('*all')
		ifile:close()
	end
	Print_logfile('Web_Err=' .. Web_Error)
	--os.remove(errlogfile)
	Print_logfile('---- end web data ------------------------------------------------------------------------')
	if (Web_Error:find('unsupported protocol')) then
		Print_logfile('### Error: unsupported protocol.')
		Print_logfile('#### This website still uses tls 1.0 and Debian Buster (and up) has set the minssl to tls 1.2 so will fail.')
		Print_logfile('#### To fix: Set /etc/ssl/openssl.cnf; goto section [system_default_sect]; Change-> MinProtocol = TLSv1.0 ;  and reboot')
		return ''
	end
	if (Web_Data == '') then
		Print_logfile('### Error: Empty result from curl command')
		return ''
	end
	return Web_Data
end

----------------------------------------------------------------------------------------------------------------
-- Function to check if we can access a file
function genfuncs.haveaccess(file)
	--~    print ("---------------------")
	--~    print (file)
	local ok, err, code = io.open(file, 'r')
	--~    print (ok)
	--~    print (err)
	--~    print (code)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return false
		end
	end
	--~    print ("---------------------")
	if ok ~= nil then
		ok:close()
		return true
	else
		return false
	end
end

----------------------------------------------------------------------------------------------------------------
-- Function to check if directory exists
function genfuncs.exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

-------------------------------------------------------
--- Check if a directory exists in this path
function genfuncs.isdir(path)
	-- "/" works on both Unix and Windows
	return genfuncs.exists(path .. '/')
end

--------------------------------------------------------------------------
-- get date, return a standard format and calculate the difference in days
-- This are some of the used regex options for the different inputdates found:
--                    --inputdate--            , regex Date elements                   , Date elements sequence
--~ genfuncs.GetDateFromInput("vrijdag 26 november"     ,"[^%s]+%s+(%d+)%s+([^%s]+)%s-(%d-)$"   ,{"dd","mmm","yyyy"})
--~ genfuncs.GetDateFromInput("vrijdag 26 november 2021","[^%s]+%s+(%d+)%s+([^%s]+)%s-(%d-)$"   ,{"dd","mmm","yyyy"})
--~ genfuncs.GetDateFromInput("13-01-2020"              ,"(%d+)[-%s]+(%d+)[-%s]+(%d+)"          ,{"dd","mm","yyyy"})
--~ genfuncs.GetDateFromInput("2020-01-02"              ,"(%d+)[-%s]+(%d+)[-%s]+(%d+)"          ,{"yyyy","mm","dd"})
--~ genfuncs.GetDateFromInput("2020-04-08T00:00:00"     ,"(%d+)[-%s]+(%d+)[-%s]+(%d+)"          ,{"yyyy","mm","dd"})
--~ genfuncs.GetDateFromInput("7 januari"               ,"([%d]+)%s+([^%s]+)%s-(%d-)$"          ,{"dd","mmm","yyyy"})
--~ genfuncs.GetDateFromInput("7 januari 2021"          ,"([%d]+)%s+([^%s]+)%s-(%d-)$"          ,{"dd","mmm","yyyy"})
function genfuncs.GetDateFromInput(i_garbagetype_date, iregex, idatev)
	local timenow = os.date('*t')
	local curTime = os.time{day = timenow.day, month = timenow.month, year = timenow.year}
	local garbageday = '??'
	local garbagemonth = '??'
	local garbageyear = timenow.year
	-- Define InputMonth table in the Module itself, this is just in case it isn't defined yet as default
	local InputMonth = InputMonth or {jan = 1, feb = 2, mrt = 3, maa = 3, apr = 4, mei = 5, jun = 6, jul = 7, aug = 8, sep = 9, okt = 10, nov = 11, dec = 12}
	-- get information from the input garbagedate using the provided regex
	local d = {}
	if i_garbagetype_date == nil then
		print('   ### Error: inputdate i_garbagetype_date is nil')
		return 0, -99
	end
	if iregex == nil then
		print('   ### Error: iregex is nil')
		return 0, -99
	end
	if idatev == nil then
		print('   ### Error: idatev is nil')
		return 0, -99
	end
	d[1], d[2], d[3], d[4] = i_garbagetype_date:match(iregex)
	-- loop through the provided table to find the right date information and formats
	local podate = ''
	if d[1] ~= nil then
		for dindex, dfield in pairs(idatev) do
			podate = podate .. dfield .. '->' .. (d[dindex] or 'nil') .. ';'
			if dfield == 'dd' then
				garbageday = tonumber(d[dindex])
			elseif dfield == 'mm' then
				garbagemonth = tonumber(d[dindex])
			elseif dfield == 'mmm' then
				garbagemonth = InputMonth[d[dindex]:sub(1, 3)]
			elseif dfield == 'mmmm' then
				garbagemonth = InputMonth[d[dindex]:sub(1, 3)]
			elseif dfield == 'yy' then
				garbageyear = tonumber(tostring(timenow.year):sub(1, 2) .. d[dindex])
			elseif dfield == 'yyyy' then
				garbageyear = tonumber(d[dindex]) or garbageyear
			end
		end
	end
	-- found this output with the provide info
	Print_logfile('    input: date=' .. (i_garbagetype_date or 'nil') .. '   iregex=' .. (iregex or 'nil') .. '   podate=' .. (podate or 'nil'))
	if garbageday == nil or garbagemonth == nil or garbageyear == nil or garbageday == '??' or garbagemonth == '??' or garbageyear == '??' then
		Print_logfile('    #### Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
		Print_logfile('         garbageyear:' .. tostring(garbageyear) .. '  garbagemonth:' .. tostring(garbagemonth) .. '  garbageday:' .. tostring(garbageday)) --
		return 0, -99
	end
	local garbageTime = os.time{day = garbageday, month = garbagemonth, year = garbageyear}
	local diffdays = genfuncs.Round(os.difftime(garbageTime, curTime) / 86400, 0) -- 1 day = 86400 seconds
	local oDate = garbageyear .. '-' .. garbagemonth .. '-' .. garbageday
	Print_logfile('    output: date=' .. oDate .. '  -> diff:' .. diffdays .. '  (garbageyear:' .. tostring(garbageyear) .. '  garbagemonth:' .. tostring(garbagemonth) .. '  garbageday:' .. tostring(garbageday) .. ')') --
	-- return standard date (yyyy-mm-dd) and diffdays
	return oDate, diffdays
end

--
-- strip http(s):// from hostnames to avoid issues when specified.
function genfuncs.Hostname_strip(Hostname)
	Hostname = Hostname:gsub('[hH][tT][tT][pP][sS]-://', '')
	return Hostname
end

-------------------------------------------------------------------------------
--[[
	Save Table to File
	Load Table from File
	v 1.0

	Lua 5.2 compatible

	Only Saves Tables, Numbers and Strings
	Insides Table References are saved
	Does not save Userdata, Metatables, Functions and indices of these
	----------------------------------------------------
	table.save( table , filename )

	on failure: returns an error msg

	----------------------------------------------------
	table.load( filename or stringtable )

	Loads a table that has been saved via the table.save function

	on success: returns a previously saved table
	on failure: returns as second argument an error msg
	----------------------------------------------------

	Licensed under the same terms as Lua itself.
]]
do
	-- declare local variables
	--// exportstring( string )
	--// returns a "Lua" portable version of the string
	local function exportstring(s)
		return string.format('%q', s)
	end

	--// The Save Function
	function table.save(tbl, filename, skipprintresult)
		local printresult = (skipprintresult == true)
		local charS, charE = '   ', '\n'
		local file, err = io.open(filename, 'wb')
		if err then
			print('!!! Table.save error:' .. err .. '. Data not updated in ' .. filename)
			return err
		end
		if tbl == nil then
			tbl = {}
		end
		tbl['Garbage_LastUpdate'] = os.date('%c')
		-- initiate variables for save procedure
		local tables, lookup = {tbl}, {[tbl] = 1}
		file:write('return {' .. charE)

		for idx, t in ipairs(tables) do
			file:write('-- Table: {' .. idx .. '}' .. charE)
			file:write('{' .. charE)
			local thandled = {}

			for i, v in ipairs(t) do
				thandled[i] = true
				local stype = type(v)
				-- only handle value
				if stype == 'table' then
					if not lookup[v] then
						table.insert(tables, v)
						lookup[v] = #tables
					end
					file:write(charS .. '{' .. lookup[v] .. '},' .. charE)
				elseif stype == 'string' then
					file:write(charS .. exportstring(v) .. ',' .. charE)
				elseif stype == 'number' then
					file:write(charS .. tostring(v) .. ',' .. charE)
				end
			end

			for i, v in pairs(t) do
				-- escape handled values
				if (not thandled[i]) then
					local str = ''
					local stype = type(i)
					-- handle index
					if stype == 'table' then
						if not lookup[i] then
							table.insert(tables, i)
							lookup[i] = #tables
						end
						str = charS .. '[{' .. lookup[i] .. '}]='
					elseif stype == 'string' then
						str = charS .. '[' .. exportstring(i) .. ']='
					elseif stype == 'number' then
						str = charS .. '[' .. tostring(i) .. ']='
					end

					if str ~= '' then
						stype = type(v)
						-- handle value
						if stype == 'table' then
							if not lookup[v] then
								table.insert(tables, v)
								lookup[v] = #tables
							end
							file:write(str .. '{' .. lookup[v] .. '},' .. charE)
						elseif stype == 'string' then
							file:write(str .. exportstring(v) .. ',' .. charE)
						elseif stype == 'number' then
							file:write(str .. tostring(v) .. ',' .. charE)
						end
					end
				end
			end
			file:write('},' .. charE)
		end
		file:write('}')
		file:close()
		if printresult then
			Print_logfile('==> Data is saved, file ' .. filename .. ' contains ' .. #tbl .. ' records.')
		end
	end

	--// The Load Function
	function table.load(sfile)
		local ftables, err = loadfile(sfile)
		if err then
			print('!!! table.load error:' .. err)
			print('!!! unable to read Data from ' .. sfile)
			return _, err
		end
		local tables = ftables()
		if tables == nil then
			print('!!! table.load error:' .. (err or '??') .. ' -> error loading (empty?) file: ' .. sfile)
			return _, err
		end
		for idx = 1, #tables do
			local tolinki = {}
			for i, v in pairs(tables[idx]) do
				if type(v) == 'table' then
					tables[idx][i] = tables[v[1]]
				end
				if type(i) == 'table' and tables[i[1]] then
					table.insert(tolinki, {i, tables[i[1]]})
				end
			end
			-- link indices
			for _, v in ipairs(tolinki) do
				tables[idx][v[2]], tables[idx][v[1]] = tables[idx][v[1]], nil
			end
		end
		return tables[1], 0
	end

	-- close do
end

return genfuncs
