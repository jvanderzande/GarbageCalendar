function gc_main(commandArray, domoticz, batchrun)
	----------------------------------------------------------------------------------------------------------------
	-- Regular LUA GarbageCalendar huisvuil script: script_time_garbagewijzer.lua
	----------------------------------------------------------------------------------------------------------------
	MainScriptVersion = '20250614-1700'
	-- curl in os required!!
	-- create dummy text device from dummy hardware with the name defined for: myGarbageDevice
	-- Update all your personal settings in garbagecalendarconfig.lua
	--
	-- Wiki for details: https://github.com/jvanderzande/GarbageCalendar/wiki
	-- source updates:   https://github.com/jvanderzande/garbagecalendar
	-- forumtopic:       https://www.domoticz.com/forum/viewtopic.php?f=61&t=31295
	--
	-- ##################################################################################################################################################################
	-- ##  update the settings in /garbagecalendar/garbagecalendarconfig.lua !!!!
	-- ##################################################################################################################################################################
	-- check if ran by DzVents or regular time script

	-- make domoticz a global
	if batchrun then
		RunText = 'Background run for WebData update:'
	elseif domoticz ~= nil then
		RunbyDzVents = true
		RunText = 'DzVents:'
	else
		RunbyDzVents = false
		RunText = 'TimeEvent:'
	end

	--===================================================================================================================
	-- start logic - no changes below this line
	--===================================================================================================================
	-- Define gobal variable
	_G.websitemodule = 'unknown'
	_G.datafilepath = nil
	_G.GC_scriptpath = ''
	_G.RunLogfile = ''
	-- set temp log to capture the initial log messages in until the final logfile is known
	_G.HRunLogfile = io.tmpfile()
	_G.Datafile = ''
	_G.icalfile = ''
	_G.UpdateDevRun = false
	_G.UpdateDataRun = false
	_G.timenow = os.date('*t')
	_G.genfuncs = {}
	_G.param = {}

	genfuncs.DomoticzBuildDate = nil
	genfuncs.DomoticzVersion = nil
	genfuncs.DomoticzRevision = nil
	DomoticzURL = DomoticzURL or 'http://127.0.0.1:8080'

	---====================================================================================================
	-- mydebug print
	function Print_logfile(text, toconsole, prefix)
		-- get callstack info for logging
		function traceback()
			local level = 3
			while true do
				local info = debug.getinfo(level, 'Slfn')
				if not info then
					break
				end
				-- if info.what ~= 'C' and not info.short_src:match('gc_generalfuncs.lua') then
				if info.what ~= 'C' then
					calledfrom = info.short_src:match('.*[/\\](.*)%.lua')
					calledline = ('   ' .. (info.currentline or '?')):sub(-4, -1)
					--print(string.format('[%s]:%d %s ->%s', calledfrom, info.currentline, info.name, info.short_src))
					break
				end
				level = level + 1
			end
		end

		-- retrieve callstack info for logging
		calledfrom = '??'
		traceback()
		-- translate filename to abbreviation or simply trim
		ShortFileNames = {gc_generalfuncs = 'gc_func'}
		calledfrom = ShortFileNames[calledfrom] or calledfrom
		calledfrom = (calledfrom .. '    '):sub(1, 7)
		-- intent text
		local ptext = text or 'nil?'
		if ptext:sub(1, 3) ~= '-> ' and ptext:sub(1, 3) ~= '-< ' and ptext:sub(1, 3) ~= '#> ' and ptext:sub(1, 3) ~= '<< ' then
			ptext = '   ' .. ptext
		end
		--
		local ctext = ptext or 'nil?'
		if (prefix or 1) == 1 then
			ptext = os.date('%X ') .. calledfrom .. ':' .. calledline .. ': ' .. ptext
		end
		-- Console print in case .....
		toconsole = toconsole or 0
		if (mydebug or false) or (toconsole > 0) then
			if toconsole > 10 then
				genfuncs.addlogmessage(ctext, toconsole-10)
			else
				print(ctext)
		end
		end
		-- LOG Print when file is specified
		if ((RunLogfile or '') ~= '') then
			local file = io.open(RunLogfile, 'a')
			if file ~= nil then
				file:write(ptext .. '\n')
				file:close()
			end
		elseif HRunLogfile then
			-- Write to tempfile until the RunLogfile is known
			HRunLogfile:write(ptext .. '\n')
		end
	end

	---====================================================================================================
	-- Add scriptdir to lua package.path to be able to first load garbagecalendarconfig.lua and other modules
	local function script_path()
		local str = debug.getinfo(2, 'S').source:sub(2)
		return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
	end
	GC_scriptpath = script_path() or './'
	if not (package.path):match(GC_scriptpath .. '%?.lua;') then
		package.path = GC_scriptpath .. '?.lua;' .. package.path
	end
	Print_logfile('-> ### ' .. RunText .. ' Start garbagecalendar script v' .. MainScriptVersion .. '   ' .. os.date('%c'))

	-- ########################################################
	-- First Load garbagecalendarconfig.lua
	-- ########################################################
	local status, err = pcall(require, 'garbagecalendarconfig')
	--print(testdataload)
	--print(status)
	--print(err)
	if not status then
		print('!!! failed loading "garbagecalendarconfig.lua" from package.path:"' .. package.path .. '"')
		if (err:find("module 'garbagecalendarconfig' not found:")) then
			Print_logfile(' ->Ensure you have copied "garbagecalendarconfig_model.lua" to "garbagecalendarconfig.lua" and modified it to your requirements.')
		else
			Print_logfile(' ->Check your garbagecalendarconfig.lua for below error(s):')
		end
		Print_logfile('!!! LUA Error: ' .. err)
		return
	else
		Print_logfile('Loaded ' .. GC_scriptpath .. 'garbagecalendarconfig.lua.')
	end

	-- ########################################################
	-- Load General functions module
	-- ########################################################
	status, genfuncs = pcall(require, 'gc_generalfuncs')
	if not status then
		Print_logfile('### Error: failed loading gc_generalfuncs.lua from : ' .. GC_scriptpath .. '', 1)
		Print_logfile('!!! LUA Error: ' .. genfuncs)
		return
	else
		--Print_logfile('Loaded ' .. GC_scriptpath .. 'gc_generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ')')
		if MainScriptVersion ~= MainGenUtilsVersion then
			Print_logfile('### Warning: Version of gc_generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ') is different from the main script! (v' .. (MainScriptVersion or '??') .. ')')
		end
		Print_logfile('Loaded ' .. GC_scriptpath .. 'gc_generalfuncs.lua.')
	end

	-- ########################################################
	-- Load JSON module
	-- ########################################################
	JSON = genfuncs.loadlualib('JSON')
	if not JSON then
		return
	end

	-- ########################################################
	-- process information in garbagecalendarconfig.lua
	-- ########################################################
	local status, err =
		pcall(
		function()
			Print_logfile('-> Start processing garbagecalendarconfig.lua information.')
			-- check if debugging is required
			testdataload = testdataload or false
			testdataloadbatch = testdataloadbatch or false
			mydebug = mydebug or false
			testrun = testrun or false
			--
			-- Default to the data subdirectory when not provided
			datafilepath = datafilepath or (GC_scriptpath .. 'data')
			-- check whether provide datafilepath is valid
			if (not genfuncs.isdir(datafilepath)) then
				if (datafilepath ~= GC_scriptpath .. 'data') then
					print('### Warning: Invalid datafilepath in garbagecalendar_config.lua: datafilepath=' .. datafilepath .. '.')
				end
				-- using data in the garbagecalendar subdirectory.
				datafilepath = GC_scriptpath .. 'data'
				if (not genfuncs.isdir(datafilepath)) then
					-- Try creating subdir data in the garbagecalendar subdirectory.
					os.execute('mkdir "' .. datafilepath .. '"')
					print('### Info: Try creating Subdir for Data and Logs:"' .. datafilepath .. '"')
				end
				if (genfuncs.isdir(datafilepath)) then
					print('### Info: Directory used for Data and Logs is changed to:"' .. datafilepath .. '"')
				else
					print('### Error: Check path in variable "datafilepath= " in your "garbagecalenderconfig.lua" setup and try again.')
					return
				end
			end

			-- copy temp runlog content and put that in the final runlog
			local loginfo = ''
			if HRunLogfile then
				HRunLogfile:seek('set', 0)
				loginfo = HRunLogfile:read('*all') or ''
			end

			-- initialise the variables
			datafilepath = (datafilepath .. '/'):gsub('//', '/')
			RunLogfile = datafilepath .. 'garbagecalendar_' .. websitemodule .. '_run.log'
			if (batchrun) then
				RunLogfile = datafilepath .. 'garbagecalendar_' .. websitemodule .. '_run_webupdate_backgound.log'
			end
			Datafile = datafilepath .. 'garbagecalendar_' .. websitemodule .. '.data'
			icalfile = datafilepath .. 'garbagecalendar_' .. websitemodule .. '.ics'

			-- empty previous run RunLogfile and add the temp log
			local file = io.open(RunLogfile, 'w')
			if file == nil then
				print('!!! Error opening RunLogfile ' .. RunLogfile)
			else
				file:write(loginfo)
				file:close()
			end
			if testdataload then
				Print_logfile('!> Debuging dataload each cycle in the foreground because "testdataload=true" in garbagecalendarconfig.lua')
				Print_logfile('!>    please change it back to "testdataload=false" when done testing to avoid growing a big domoticz log and slowing down the event system.')
			end
			if testdataloadbatch then
				Print_logfile('!> Debuging dataload each cycle in batch because "testdataloadbatch=true" in garbagecalendarconfig.lua')
				Print_logfile('!>    please change it back to "testdataloadbatch=false" when done testing.')
			end

			if mydebug then
				Print_logfile('!> Debuging with extra messages because "mydebug=true" in garbagecalendarconfig.lua')
				Print_logfile('!>    please change it back to "mydebug=false" when done testing to avoid growing a big domoticz log.')
			end
			--ensure the all path variables ends with /
			--Print_logfile('datafilepath: ' .. datafilepath)
			-- check some config settings
			ShowSinglePerType = ShowSinglePerType or false
			Combine_Garbage_perDay = Combine_Garbage_perDay or false
			-- Force ShowSinglePerType to false when Combine_Garbage_perDay = true
			if Combine_Garbage_perDay and ShowSinglePerType then
				ShowSinglePerType = false
				Print_logfile("! changed ShowSinglePerType=false because Combine_Garbage_perDay=true and they can't be both set.")
			end
		end
	)
	-- Check success of process information in garbagecalendarconfig.lua
	if not status then
		print('!!! failed processing information of "garbagecalendarconfig.lua"')
		print('       check errors and correct "garbagecalendarconfig.lua".')
		print('!!! LUA Error: ' .. err)
		return
	else
		Print_logfile('-< End processing garbagecalendarconfig.lua information.')
	end

	---====================================================================================================
	-- check whether provide paths are valid
	if (not genfuncs.exists(GC_scriptpath .. '' .. websitemodule .. '.lua')) then
		Print_logfile('### Error: module not found: ' .. GC_scriptpath .. '' .. websitemodule .. '.lua', 1)
		Print_logfile('### Error: Please check the path&name in variables "GC_scriptpath=" "websitemodule= "  in your "garbagecalenderconfig.lua" setup and try again.', 1)
		return
	end

	---====================================================================================================
	-- perform  Web data update
	function GetWebData(whenrun)
		-- Modules variables
		UpdateDataRun = true
		Companycode = (Companycode or Hostname) -- Left Hostname alternative in there for backwards compatibility as that was initially used.
		Hostname = genfuncs.Hostname_strip(Hostname)
		-- Update Now or in the BackGround to avoid slowdown of the Domoticz event process
		if ((whenrun or '') ~= 'now') then
			-- Test if lua is installed, if so submit backgrond task to update the Datafile to relieve the event system
			os.execute('lua -v >' .. datafilepath .. 'luatest.log 2>&1')
			local ifile, ierr = io.open(datafilepath .. 'luatest.log', 'r')
			local Chk_Error = ierr or ''
			local luaversion = ''
			if not ierr then
				Chk_Error = ifile:read('*all'):gsub('[\r\n]', '')
				ifile:close()
				os.remove(datafilepath .. 'luatest.log')
				luaversion = Chk_Error:match('[lL][uU][aA]%s*([%d*%.]*)[^\r\n]*') or ''
				Print_logfile('  LUA check version:' .. luaversion .. '   > Lua check output:' .. (Chk_Error or '?'))
			else
				Print_logfile('  LUA check error:' .. (Chk_Error or '?'))
			end
			-- if the testfile contain this error, it means lua is installed.
			if luaversion ~= '' then
				--
				-- test resubmit gc_main.lua in batch
				if (batchrun) then
					Print_logfile("=> Batchrun trying to do another Batchrun...This shouldn't happen, so stopping to avoid enless loop.", 1)
					return
				end
				local command = 'lua "' .. GC_scriptpath .. 'gc_main.lua" "GetDataInBatch"'
				Print_logfile('-> garbagecalendar: Start background webupdate for module ' .. websitemodule, 1)
				Print_logfile('   datafile:' .. Datafile)
				Print_logfile('   ' .. command .. ' &')
				rc = os.execute(command .. ' &')
			else
				Print_logfile('=> check LUA not found -> Run foreground to use internal LUA.', 1)
				whenrun = 'now' -- perform the update in the foreground with the domoticz LUA implementation
			end
		end

		-- ==================================================
		-- Run the Webupdate in the foreground when required.
		-- This happens in case the Datafile doesn't exists or LUA can't be found.
		if ((whenrun or '') == 'now') then
			-------------------------------------------------------
			-- Error handling function
			function errhandler(x)
				return x .. '\n' .. debug.traceback()
			end

			-------------------------------------------------------
			-- RunWebModule Function
			function RunWebModule()
				-------------------------------------------------------
				-- Check module provided
				if (websitemodule or '') == '' then
					return '', '!!!! Module name not provided. Ending run.'
				end
				local websitemodulescript = GC_scriptpath .. websitemodule .. '.lua'
				-- other variables
				garbagedata = {} -- array to save information to which will be written to the data file

				-- Load required Module
				Print_logfile('-> Load module ' .. (websitemodule or '??'))
				dofile(websitemodulescript)
				-- Check whether the required parameters are specified.
				Print_logfile('-> ========== Start module ' .. (websitemodule or '??') .. '.lua (v' .. (M_ver or '??') .. ')')
				chkfields = chkfields or {}
				local param_err = 0
				for key, value in pairs(chkfields) do
					if (_G[value] or '') == '' then
						param_err = param_err + 1
						Print_logfile('### Error: ' .. value .. ' not specified! Please update your configuration with the correct information for this module', 1)
					else
						Print_logfile('--> ' .. value .. '=' .. _G[value])
					end
				end
				-- =======================================================================================
				-- Get the Module web info when all required parameters are defined
				-- =======================================================================================
				if param_err == 0 then
					Print_logfile('!!! perform web data update to ' .. Datafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf)
					Perform_Update()
					genfuncs.SortGarbagedata()
					Print_logfile('> Write data to ' .. Datafile)
					table.save(garbagedata, Datafile)
					return '', '-< Module ' .. (websitemodule or '') .. ' done. Saved ' .. (#garbagedata or 0) .. ' records to data file ' .. Datafile
				else
					Print_logfile('!!! ==============================================', 1)
					Print_logfile('!!! Webupdate cancelled due to missing parameters!', 1)
					Print_logfile('!!! ==============================================', 1)
					return '', '-< Module ' .. (websitemodule or '') .. ' stopped! Look at ' .. RunLogfile .. ' for more information.'
				end
			end

			-- run module
			local estatus, err, result = xpcall(RunWebModule, errhandler)
			--print(estatus, '|', err, '|', result)
			if estatus then
				Print_logfile((err or '') .. (result or ''))
			else
				Print_logfile('!! Module ' .. (websitemodule or '???') .. ' had hard error. check log:' .. (RunLogfile or '') .. '\n' .. (err or ''))
				Print_logfile(RunLogfile or 'no logfile')
				Print_logfile('\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
				Print_logfile(estatus)
				Print_logfile(err)
				Print_logfile(debug.traceback())
			end
			Print_logfile('-< ========== End module ' .. (websitemodule or '??') .. '.lua (v' .. (M_ver or '??') .. ')')
		end
	end

	---====================================================================================================
	-- get days between today and provided date
	function getdaysdiff(i_garbagetype_date, stextformat)
		local curTime = os.time {day = timenow.day, month = timenow.month, year = timenow.year}
		-- check if date in variable i_garbagetype_date contains "vandaag" in stead of a valid date -> use today's date
		garbageyear, garbagemonth, garbageday = i_garbagetype_date:match('(%d-)-(%d-)-(%d-)$')
		if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
			Print_logfile('### Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date, 1)
			return
		end
		local garbageTime = os.time {day = garbageday, month = garbagemonth, year = garbageyear}
		local wday = daysoftheweek[os.date('*t', garbageTime).wday]
		local lwday = Longdaysoftheweek[os.date('*t', garbageTime).wday]
		stextformat = stextformat:gsub('wdd', lwday)
		stextformat = stextformat:gsub('wd', wday)
		stextformat = stextformat:gsub('dd', garbageday)
		stextformat = stextformat:gsub('mmmm', LongMonth[tonumber(garbagemonth)])
		stextformat = stextformat:gsub('mmm', ShortMonth[tonumber(garbagemonth)])
		stextformat = stextformat:gsub('mm', garbagemonth)
		stextformat = stextformat:gsub('yyyy', garbageyear)
		stextformat = stextformat:gsub('yy', garbageyear:sub(3, 4))
		-- return number of days diff
		return stextformat, genfuncs.Round(os.difftime(garbageTime, curTime) / 86400, 0) -- 1 day = 86400 seconds
	end

	----------------------------------------------------------------------------------------------------------------
	--
	function GarbageNotification(s_garbagetype, s_garbagetype_date, i_daysdifference)
		if (timenow.min == garbagetype_cfg[s_garbagetype].min and garbagetype_cfg[s_garbagetype].active == 'on') or (testnotification or false) then
			if
				((timenow.hour == garbagetype_cfg[s_garbagetype].hour or --First notification
					timenow.hour == garbagetype_cfg[s_garbagetype].hour + garbagetype_cfg[s_garbagetype].reminder) and --same day reminder
					i_daysdifference == garbagetype_cfg[s_garbagetype].daysbefore) or
					(timenow.hour == garbagetype_cfg[s_garbagetype].hour + garbagetype_cfg[s_garbagetype].reminder - 24 and --next day reminder
						i_daysdifference + 1 == garbagetype_cfg[s_garbagetype].daysbefore) or
					(testnotification or false)
			 then
				if (testnotification) then
					Print_logfile('---> test notification active', 1, 0)
					testnotification = false -- this will trigger a test notification for the first record
				end
				-- Set ireminder field text
				local ireminder = ''
				if garbagetype_cfg[s_garbagetype].reminder ~= 0 and timenow.hour ~= garbagetype_cfg[s_garbagetype].hour then
					ireminder = notificationreminder or 'reminder'
				end
				local dag = ''
				if i_daysdifference == 0 then
					dag = notificationtoday or 'vandaag'
				elseif i_daysdifference == 1 then
					dag = notificationtomorrow or 'morgen'
				else
					dag = notificationlonger or 'over @DAYS@ dagen'
					dag = dag:gsub('@DAYS@', tostring(i_daysdifference))
				end
				inotificationdate = notificationdate or 'yyyy-mm-dd'
				garbageyear, garbagemonth, garbageday = s_garbagetype_date:match('(%d-)-(%d-)-(%d-)$')
				local garbageTime = os.time {day = garbageday, month = garbagemonth, year = garbageyear}
				local wday = daysoftheweek[os.date('*t', garbageTime).wday]
				local lwday = Longdaysoftheweek[os.date('*t', garbageTime).wday]
				inotificationdate = inotificationdate:gsub('wdd', lwday)
				inotificationdate = inotificationdate:gsub('wd', wday)
				inotificationdate = inotificationdate:gsub('dd', garbageday)
				inotificationdate = inotificationdate:gsub('mmmm', LongMonth[tonumber(garbagemonth)])
				inotificationdate = inotificationdate:gsub('mmm', ShortMonth[tonumber(garbagemonth)])
				inotificationdate = inotificationdate:gsub('mm', garbagemonth)
				inotificationdate = inotificationdate:gsub('yyyy', garbageyear)
				inotificationdate = inotificationdate:gsub('yy', garbageyear:sub(3, 4))
				inotificationtitle = notificationtitle or 'GarbageCalendar: @DAY@ de @GARBAGETEXT@ aan de weg zetten!'
				inotificationtitle = inotificationtitle:gsub('@DAY@', dag)
				inotificationtitle = inotificationtitle:gsub('@GARBAGETYPE@', s_garbagetype)
				inotificationtitle = inotificationtitle:gsub('@GARBAGETEXT@', tostring(garbagetype_cfg[s_garbagetype].text))
				inotificationtitle = inotificationtitle:gsub('@GARBAGEDATE@', inotificationdate)
				inotificationtitle = inotificationtitle:gsub('@REMINDER@', ireminder)
				inotificationtext = notificationtext or '@GARBAGETEXT@ wordt @DAY@ opgehaald!'
				inotificationtext = inotificationtext:gsub('@DAY@', dag)
				inotificationtext = inotificationtext:gsub('@GARBAGETYPE@', s_garbagetype)
				inotificationtext = inotificationtext:gsub('@GARBAGETEXT@', tostring(garbagetype_cfg[s_garbagetype].text))
				inotificationtext = inotificationtext:gsub('@GARBAGEDATE@', inotificationdate)
				inotificationtext = inotificationtext:gsub('@REMINDER@', ireminder)
				if type(NotificationEmailAdress) == 'table' then
					for x, emailaddress in pairs(NotificationEmailAdress) do
						if emailaddress ~= '' then
							if RunbyDzVents then
								domoticz.email(inotificationtitle, inotificationtext, emailaddress)
							else
								commandArray[#commandArray + 1] = {
									['SendEmail'] = inotificationtitle .. '#' .. inotificationtext .. '#' .. emailaddress
								}
							end
							Print_logfile('---> Notification Email send for ' .. s_garbagetype .. ' |' .. inotificationtitle .. '#' .. inotificationtext .. '#' .. emailaddress .. '|', 1, 0)
						end
					end
				else
					if (NotificationEmailAdress or '') ~= '' then
						if RunbyDzVents then
							domoticz.email(inotificationtitle, inotificationtext, NotificationEmailAdress)
						else
							commandArray[#commandArray + 1] = {['SendEmail'] = inotificationtitle .. '#' .. inotificationtext .. '#' .. NotificationEmailAdress}
						end
						Print_logfile('---> Notification Email send for ' .. s_garbagetype .. ' |' .. inotificationtitle .. '#' .. inotificationtext .. '#' .. NotificationEmailAdress .. '|', 1, 0)
					end
				end

				if (Notificationsystem or '') ~= '' then
					if RunbyDzVents then
						domoticz.notify(inotificationtitle, inotificationtext, domoticz.PRIORITY_NORMAL, domoticz.SOUND_DEFAULT, '', Notificationsystem)
					else
						commandArray[#commandArray + 1] = {['SendNotification'] = inotificationtitle .. '#' .. inotificationtext .. '####' .. Notificationsystem}
					end
					Print_logfile('---> ' .. Notificationsystem .. ' Notification send for ' .. s_garbagetype .. ' |' .. inotificationtitle .. '#' .. inotificationtext, 1, 0)
				end

				if (Notificationscript or '') ~= '' then
					Notificationscript = Notificationscript:gsub('@TEXT@', inotificationtext)
					Notificationscript = Notificationscript:gsub('@TITLE@', inotificationtitle)
					Notificationscript = Notificationscript:gsub('@GARBAGETYPE@', s_garbagetype)
					Notificationscript = Notificationscript:gsub('@GARBAGETEXT@', tostring(garbagetype_cfg[s_garbagetype].text))
					Notificationscript = Notificationscript:gsub('@GARBAGEDATE@', inotificationdate)
					Notificationscript = Notificationscript:gsub('@REMINDER@', ireminder)
					Print_logfile('--->External Notification script started: ' .. Notificationscript)
					os.execute(Notificationscript .. ' &')
				end
				if (EventNotificationscript or '') ~= '' then
					Print_logfile('--->Check Internal Notification script : ' .. GC_scriptpath .. '' .. EventNotificationscript)
					if (not genfuncs.exists(GC_scriptpath .. '' .. EventNotificationscript)) then
						Print_logfile('### Error: EventNotificationscript not found: ' .. GC_scriptpath .. '' .. EventNotificationscript)
						return
					end
					Notify_mtext = inotificationtext
					Notify_mtitle = inotificationtitle
					Notify_date = inotificationdate
					Notify_type = s_garbagetype
					Notify_text = tostring(garbagetype_cfg[s_garbagetype].text)
					Notify_reminder = ireminder

					--
					-- User event script function to capture any errors seperately
					function run_notification_event(RunbyDzVents, commandArray, domoticz)
						dofile(GC_scriptpath .. '' .. EventNotificationscript)
					end

					-- run the extra function
					local n_rc, n_errmsg
					Print_logfile('--->Start Internal Notification script: ' .. EventNotificationscript)
					if RunbyDzVents then
						n_rc, n_errmsg = pcall(run_notification_event, RunbyDzVents, nil, domoticz)
					else
						n_rc, n_errmsg = pcall(run_notification_event, RunbyDzVents, commandArray, nil)
					end
					-- check for errors
					if n_rc then
						Print_logfile('--->Internal Notification script ended: ' .. EventNotificationscript)
					else
						Print_logfile('!!!!> ' .. EventNotificationscript .. '  ended with errors: ' .. n_errmsg, 1)
						genfuncs.addlogmessage('!!!!> ' .. EventNotificationscript .. '  ended with errors: ' .. n_errmsg, 4)
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------------------------------------------
	-- Do the actual update retrieving data from the website and processing it
	function Perform_Data_check()
		-- ensure the access is set correctly for data
		Print_logfile('-> Action starting, First check access to required files:')
		function ListAccess(name)
			local sCMD = 'ls -l ' .. name
			Print_logfile('   Run command:\n' .. sCMD .. ':')
			local handle = assert(io.popen(sCMD))
			local cmd_output = handle:read('*all')
			-- remove ending CR LF chars
			cmd_output = cmd_output:gsub('[\r\n]+$', '')
			handle:close()
			Print_logfile(cmd_output, 0, '')
		end

		-- show access info when debugging
		if mydebug or false then
			ListAccess(datafilepath .. 'garbagecal*' .. websitemodule .. '*')
		end
		-- Check for access to data & logfiles
		if not Perform_Rights_check(Datafile) then
			return
		end
		if not Perform_Rights_check(RunLogfile) then
			return
		end

		local missingrecords = ''
		local devtxt = ''
		local txtcnt = 0
		local icalcnt = 0
		-- fields used for Combine_Garbage_perDay option
		local txtdev_sdesc = ''
		local txtdev_ldesc = ''
		local txtdev_tdesc = ''
		local txtdev_prevdesc = ''
		local txtdev_prevdate = ''

		-- Read previous saved calendar information
		Print_logfile('-> Start update for GarbageCalendar text device "' .. (myGarbageDevice or '') .. '"', 1)
		local garbagedata, perr = table.load(Datafile)
		-- try reload data when Datafile is missing
		if perr ~= 0 then
			--- when file doesn't exist
			Print_logfile('### Warning: Datafile not found:' .. Datafile .. ' . Start webupdate now.')
			GetWebData('now')
			garbagedata, perr = table.load(Datafile)
		else
			-- try reload data when the number of records are 0 in the Datafile
			if (#garbagedata or 0) == 0 then
				--- when file doesn't exist
				Print_logfile('### Warning: Datafile contains ' .. (#garbagedata or '?') .. ' datarecords. Start webupdate now.')
				GetWebData('now')
				garbagedata, perr = table.load(Datafile)
			end
		end
		-- Check validity of the garbagecalendar data
		if perr ~= 0 then
			--- when file doesn't exist
			Print_logfile('#### Error: Unable to load the data. please check your setup and RunLogfile :' .. RunLogfile)
			return
		elseif (#garbagedata or 0) == 0 then
			Print_logfile('#### Error: There are ' .. (#garbagedata or '?') .. ' data records in Datafile:' .. Datafile)
			return
		end
		-- process the garbagecalendar data
		Print_logfile((#garbagedata or '?') .. ' data records loaded, updated at ' .. (garbagedata['Garbage_LastUpdate'] or '?') .. ' from Datafile:' .. Datafile)
		-- create ICS file when requested
		if (IcalEnable) then
			hIcal = io.open(icalfile, 'w')
			if (hIcal ~= nil) then
				hIcal:write('BEGIN:VCALENDAR\n')
				hIcal:write('VERSION:2.0\n')
				hIcal:write('PRODID:GarbageCalendar\n')
				hIcal:write('X-WR-CALNAME:' .. IcalTitle .. '\n')
				hIcal:write('X-PUBLISHED-TTL:P1H\n')
			else
				IcalEnable = false
				Print_logfile(' Unable to create iCAL file:' .. icalfile .. '  Check for the appropriate rights.')
			end
		end

		Print_logfile('-> Start looping through data to find the first ' .. ShowNextEvents .. ' events to show: ')
		FirstGType = nil
		FirstGTypeIcon = nil
		for i = 1, #garbagedata do
			if garbagedata[i].garbagetype ~= nil then
				-- change all table entries to lower to make the script case insensitive
				web_garbagetype = garbagedata[i].garbagetype:lower():gsub('\\', '')
				web_garbagedate = garbagedata[i].garbagedate
				web_garbagedesc = (garbagedata[i].wdesc or '')
				if (web_garbagedesc == '') then
					if garbagetype_cfg[web_garbagetype] ~= nil then
						web_garbagedesc = garbagetype_cfg[web_garbagetype].text
					else
						web_garbagedesc = '???'
					end
				end
				-- first match for each Type we save the date to capture the first next dates
				if garbagetype_cfg[web_garbagetype] == nil then
					if web_garbagedesc == '???' then
						web_garbagedesc = web_garbagetype
					end
					-- if missingrecords == '' then
					--  	missingrecords = 'garbagetype_cfg = {\n'
					-- end
					missingrecords = missingrecords .. '  ["' .. web_garbagetype:lower() .. '"]' .. string.rep(' ', 10 - string.len(web_garbagetype)) .. ' ={hour=19,min=02,daysbefore=1,reminder=0,text="' .. web_garbagedesc .. '", icon=nil},\n'
					garbagetype_cfg[web_garbagetype] = {hour = 0, min = 0, daysbefore = 0, reminder = 0, text = 'dummy'}
					garbagetype_cfg[web_garbagetype].text = web_garbagetype
					garbagetype_cfg[web_garbagetype].missing = true
				end
				-- Add event to Devtxt when the number of events to shown isn't reached
				if garbagetype_cfg[web_garbagetype].active ~= 'skip' and txtcnt < ShowNextEvents then
					-- get daysdiff
					local stextformat = textformat
					stextformat, daysdiffdev = getdaysdiff(web_garbagedate, stextformat)
					-- check whether the first nextdate for this garbagetype is already found to get only one next date per GarbageType
					if ((not ShowSinglePerType) or (garbagetype_cfg[web_garbagetype].nextdate == nil)) then
						-- When days is 0 or greater the date is today or in the future. Ignore any date in the past
						if daysdiffdev == nil then
							Print_logfile('    !!! Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
						elseif daysdiffdev >= 0 then
							-- Set the nextdate for this garbagetype
							garbagetype_cfg[web_garbagetype].nextdate = web_garbagedate
							--print(">>>>"..web_garbagetype)
							if not FirstGType then
								-- get the defined icon for the first collected garbagetype
								FirstGType = web_garbagetype
								FirstGTypeIcon = garbagetype_cfg[web_garbagetype].icon
								Print_logfile('> first type:' .. FirstGType .. ' Icon:"' .. (FirstGTypeIcon or 'nil') .. '"')
							end
							-- get the long description from the JSON data
							if garbagetype_cfg[web_garbagetype].missing then
								Print_logfile('>> GarbageDate:' .. tostring(web_garbagedate) .. ' GarbageType:' .. tostring(web_garbagetype) .. '; Calc Days Diff=' .. tostring(daysdiffdev) .. '; *** Notify skipped because garbagetype:' .. (garbagetype_cfg[web_garbagetype].active or '??') .. ' insn\'t defined in garbagetype_cfg[]!', 0, 0)
							elseif garbagetype_cfg[web_garbagetype].active ~= 'on' then
								Print_logfile('>> GarbageDate:' .. tostring(web_garbagedate) .. ' GarbageType:' .. tostring(web_garbagetype) .. '; Calc Days Diff=' .. tostring(daysdiffdev) .. '; *** Notify skipped because active <> on ( ' .. (garbagetype_cfg[web_garbagetype].active or '??') .. ') in garbagetype_cfg[]!', 0, 0)
							else
								Print_logfile(
									'>> GarbageDate:' ..
										tostring(web_garbagedate) ..
											' GarbageType:' ..
												tostring(web_garbagetype) ..
													';  Notify: Active=' ..
														tostring(garbagetype_cfg[web_garbagetype].active) ..
															'  Time=' ..
																tostring(garbagetype_cfg[web_garbagetype].hour) ..
																	':' .. tostring(garbagetype_cfg[web_garbagetype].min) .. '   DaysBefore=' .. tostring(garbagetype_cfg[web_garbagetype].daysbefore) .. '   reminder=' .. tostring(garbagetype_cfg[web_garbagetype].reminder) .. '   Calc Days Diff=' .. tostring(daysdiffdev),
									0,
									0
								)
								-- fill the text with the next defined number of events
								GarbageNotification(web_garbagetype, web_garbagedate, daysdiffdev) -- check notification for new found info
							end

							-- fill de domoticz text with the found info
							-- =========================================
							-- Check if we want to combine garbagetypes for one day
							if Combine_Garbage_perDay and txtdev_prevdate == web_garbagedate then
								txtdev_sdesc = txtdev_sdesc .. ', ' .. web_garbagetype
								txtdev_ldesc = txtdev_ldesc .. ', ' .. web_garbagedesc
								txtdev_tdesc = txtdev_tdesc .. ', ' .. garbagetype_cfg[web_garbagetype].text
								devtxt = txtdev_prevdesc
								Print_logfile('  -- merging record:' .. i - 1 .. ' Date:' .. garbagedata[i - 1].garbagedate .. ' Type:' .. garbagedata[i - 1].garbagetype .. '  wdesc:' .. (garbagedata[i - 1].wdesc or ''))
								Print_logfile('             record:' .. i .. ' Date:' .. garbagedata[i].garbagedate .. ' Type:' .. garbagedata[i].garbagetype .. '  wdesc:' .. (garbagedata[i].wdesc or ''))
							else
								txtdev_sdesc = web_garbagetype
								txtdev_ldesc = web_garbagedesc
								txtdev_tdesc = garbagetype_cfg[web_garbagetype].text
							end
							txtdev_prevdate = web_garbagedate
							stextformat = stextformat:gsub('sdesc', txtdev_sdesc)
							stextformat = stextformat:gsub('ldesc', txtdev_ldesc)
							stextformat = stextformat:gsub('tdesc', txtdev_tdesc)
							txtdev_prevdesc = devtxt
							devtxt = devtxt .. stextformat .. '\n'
							-- only add 1 when the next display record is a different date or seperate line wanted
							if (i < #garbagedata) then
								if ((not Combine_Garbage_perDay) or web_garbagedate ~= garbagedata[i + 1].garbagedate) then
									txtcnt = txtcnt + 1
									txtdev_prevdesc = devtxt
								end
							end
						end
					end
				else
					-- only warn once for a skip this type setting
					if (garbagetype_cfg[web_garbagetype].missing == nil and garbagetype_cfg[web_garbagetype].active == 'skip') then
						garbagetype_cfg[web_garbagetype].skipwarning = true
						Print_logfile('>>> skipping because active="skip" for GarbageType:' .. tostring(web_garbagetype) .. '  GarbageDate:' .. tostring(web_garbagedate), 0, 0)
					end
				end
				-- create ICAL file when requested
				if (IcalEnable and garbagetype_cfg[web_garbagetype].active ~= 'skip' and icalcnt < IcalEvents) then
					-- prepare required info
					garbageyear, garbagemonth, garbageday = web_garbagedate:match('(%d-)-(%d-)-(%d-)$')
					icalsdate = string.format('%04d%02d%02d', garbageyear, garbagemonth, garbageday)
					-- add one day to start day to calculate the enddate
					icaledate = os.date('%Y%m%d', os.time {year = garbageyear, month = garbagemonth, day = garbageday, hour = 0, min = 0, sec = 0} + 24 * 60 * 60)
					icurdate = os.date('%Y%m%dT%H%M%SZ')
					scalDesc = IcalDesc:gsub('@GARBAGETYPE@', web_garbagetype)
					scalDesc = scalDesc:gsub('@GARBAGETEXT@', tostring(garbagetype_cfg[web_garbagetype].text))
					-- write record
					--~                hIcal:write("---\n")
					hIcal:write('BEGIN:VEVENT\n')
					hIcal:write('UID:' .. web_garbagetype .. '-' .. icalsdate .. '\n')
					hIcal:write('DTSTART;VALUE=DATE:' .. icalsdate .. '\n')
					hIcal:write('SEQUENCE:' .. icalcnt .. '\n')
					hIcal:write('TRANSP:OPAQUE\n')
					hIcal:write('DTEND;VALUE=DATE:' .. icaledate .. '\n')
					hIcal:write('SUMMARY:' .. scalDesc .. '\n')
					hIcal:write('CLASS:PUBLIC\n')
					hIcal:write('DESCRIPTION:' .. scalDesc .. '\n')
					hIcal:write('X-MICROSOFT-CDO-ALLDAYEVENT:TRUE\n')
					hIcal:write('DTSTAMP:' .. icurdate .. '\n')
					--
					if IcalNotify > 0 then
						hIcal:write('BEGIN:VALARM\n')
						hIcal:write('TRIGGER:-PT' .. IcalNotify .. 'H\n')
						hIcal:write('ACTION:DISPLAY\n')
						hIcal:write('DESCRIPTION:' .. scalDesc .. '\n')
						hIcal:write('END:VALARM\n')
					end
					hIcal:write('END:VEVENT\n')
					icalcnt = icalcnt + 1
				end
			end
		end
		if txtcnt < 1 then
			Print_logfile('### Warning: No valid records found in the Datafile: ' .. Datafile, 1)
			Print_logfile('###          Please check the garbagecalendar log files for issues : ' .. RunLogfile, 1)
		end
		Print_logfile('-< End data loop')
		if missingrecords ~= '' then
			Print_logfile('#!# Warning: These garbage types are missing in your garbagetype_cfg table in file garbagecalendarconfig.lua, so no notifications will be send!', 11)
			Print_logfile('--> Add the below and adapt the schedule, text and icon info to your needs:', 11)
			missingrecords = 'garbagetype_cfg = {\n...\n' .. missingrecords .. '...\n}'
			Print_logfile(missingrecords, 11, 0)
			Print_logfile('#!# -- end ----------------------------', 11 ,0)
		end
		if (cnt == 0) then
			Print_logfile('### Error: No valid data found in returned webdata.  skipping the rest of the logic.', 1)
			return
		end
		-- always update the domoticz device so one can see it is updating and when it was ran last.
		Print_logfile('-> found schedule:' .. devtxt:gsub('\n', ' ; '), 1)

		-- add global formatting when defined
		tdevformat = tdevformat or ''
		if tdevformat:match('#') then
			devtxt = tdevformat:gsub('#', devtxt, 1)
			Print_logfile('-> added textdev formatting:' .. devtxt:gsub('\n', ' ; '), 1)
		end

		-- close ICAL file when requested
		if IcalEnable then
			hIcal:write('END:VCALENDAR')
			hIcal:close()
			Print_logfile('=> Created an ICS file with ' .. icalcnt .. ' Garbage collection events entries in file: ' .. icalfile)
		end

		-- Check the for the customicon idx for our defined icon in config (if defined)
		do_iconupdate = false
		-- only do icon update when icon= is defined in the config.
		-- when icon='' or not found then reset to default icon
		if FirstGTypeIcon then
			do_iconupdate = true
			Print_logfile('-> FirstGTypeIcon:' .. (FirstGTypeIcon or '?'))
			if (FirstGTypeIcon or '') ~= '' then
				FirstGTypeIconIdx, ierr = genfuncs.getcustomiconidx(FirstGTypeIcon)
				if ierr then
					Print_logfile('##  Icon update stopped with rc:' .. (ierr or '?'))
					do_iconupdate = false
				else
					Print_logfile('>> FirstGTypeIconIdx:' .. (FirstGTypeIconIdx or '?'))
				end
			else
				FirstGTypeIconIdx = 0
			end
		end

		if RunbyDzVents then
			if domoticz.devices(myGarbageDevice).idx == nil then
				Print_logfile("### Error: Couldn't get the current data of Domoticz text device: '" .. myGarbageDevice .. "'. Does it exist and is the name correct ", 1)
			else
				-- update the domoticz device text & icon
				domoticz.devices(myGarbageDevice).updateText(devtxt)
				if (domoticz.devices(myGarbageDevice).text ~= devtxt) then
					Print_logfile('> Update device from: \n' .. domoticz.devices(myGarbageDevice).text .. '\n replace with:\n' .. devtxt)
				else
					Print_logfile('> No updated text for TxtDevice.')
				end
				if do_iconupdate then
					FirstGTypeIconIdx = FirstGTypeIconIdx or 0
					if FirstGTypeIconIdx == 0 then
						Print_logfile('>> FirstGTypeIcon "' .. (FirstGTypeIcon or '?') .. '" not found so settting textdevice to DefaultTextIcon:0')
					else
						Print_logfile('>> Set textdevice to FirstGTypeIcon:' .. (FirstGTypeIcon or '?') .. '=>' .. FirstGTypeIconIdx)
					end
					-- update the domoticz device icon
					genfuncs.setdeviceicon(domoticz.devices(myGarbageDevice).idx, myGarbageDevice, FirstGTypeIconIdx, domoticz.devices(myGarbageDevice).idx)
				end
			end
		else
			if otherdevices_idx == nil or otherdevices_idx[myGarbageDevice] == nil then
				Print_logfile("### Error: Couldn't get the current data from Domoticz text device '" .. myGarbageDevice .. "'. Does it exist and is the name correct ", 1)
			else
				-- update the domoticz device text
				commandArray['UpdateDevice'] = otherdevices_idx[myGarbageDevice] .. '|0|' .. devtxt
				if (otherdevices[myGarbageDevice] ~= devtxt) then
					Print_logfile('> Update device from: \n' .. otherdevices[myGarbageDevice] .. '\n replace with:\n' .. devtxt)
				else
					Print_logfile('> No updated text for TxtDevice.')
				end
				if do_iconupdate then
					FirstGTypeIconIdx = FirstGTypeIconIdx or 0
					if FirstGTypeIconIdx == 0 then
						Print_logfile('>> FirstGTypeIcon "' .. (FirstGTypeIcon or '?') .. '" not found so settting textdevice to DefaultTextIcon:0')
					else
						Print_logfile('>> Set textdevice to FirstGTypeIcon:' .. (FirstGTypeIcon or '?') .. '=>' .. FirstGTypeIconIdx)
					end
					-- update the domoticz device icon
					genfuncs.setdeviceicon(otherdevices_idx[myGarbageDevice], myGarbageDevice, FirstGTypeIconIdx)
				end
			end
		end
	end

	----------------------------------------------------------------------------------------------------------------
	-- check access rights to file and try fixing for linux OSes
	function Perform_Rights_check(filename)
		if (genfuncs.exists(filename)) then
			if (not genfuncs.haveaccess(filename)) then
				Print_logfile('   No access to the file. Running->sudo chmod 777 ' .. filename, 1)
				os.execute('sudo chmod 777 ' .. filename .. ' 2>/dev/null')
				if (genfuncs.haveaccess(filename)) then
					Print_logfile('   Access Fixed: ' .. filename)
				else
					Print_logfile('### Error: Still no access. Please check the settings for ' .. filename .. ' and then try again.', 1)
					return false
				end
			else
				Print_logfile('   Access OK: ' .. filename)
			end
		else
			--Print_logfile("File doesn't exists: " .. filename, 1)
		end
		return true
	end

	-- End Functions ===============================================================================================
	-- check defaults set
	daysoftheweek = daysoftheweek or {'Zon', 'Maa', 'Din', 'Woe', 'Don', 'Vri', 'Zat'}
	Longdaysoftheweek = Longdaysoftheweek or {'zondag', 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag'}
	ShortMonth = ShortMonth or {'jan', 'feb', 'maa', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'}
	LongMonth = LongMonth or {'januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'}
	if (IcalEnable == nil) then
		IcalEnable = false
	end
	IcalTitle = IcalTitle or 'GarbageCalendar'
	IcalDesc = IcalDesc or '@GARBAGETEXT@ wordt opgehaald.'
	IcalEvents = IcalEvents or 10
	IcalNotify = IcalNotify or 12
	----------------------------------------------------------------------------------------------------------------
	-- checkif testload is requested
	if (batchrun) then
		Print_logfile('-> Batch load WebData')
		GetWebData('now')
		Print_logfile('-< ### ' .. RunText .. ' End garbagecalendar script v' .. MainScriptVersion)
		return
	elseif (testdataload or false) then
		GetWebData('now')
	elseif testdataloadbatch or false then
		GetWebData()
		Print_logfile('-< ### End run because testdataloadbatch=true and job submitted.')
		return
	end

	-- Start of logic ==============================================================================================

	-- check for notification times and run update only when we are at one of these defined times
	Print_logfile('-> Start checking garbagetype_cfg table whether an action is needed:')
	if garbagetype_cfg == nil then
		Print_logfile('### Error: failed loading the "garbagetype_cfg" table from your garbagecalendarconfig.lua file. Please check your setup file.', 1)
		return
	end
	if garbagetype_cfg['reloaddata'] == nil or garbagetype_cfg['reloaddata'].hour == nil or garbagetype_cfg['reloaddata'].min == nil then
		Print_logfile('### Warning: Web update will be performed on a default time at 02:30AM, because the "reloaddata" entry missing in the "garbagetype_cfg" table in your garbagecalendarconfig.lua file! ')
		Print_logfile('           Check the original provided garbagecalendarconfig_model.lua for the correct format: ')
		Print_logfile('             -- Add any missing records above this line')
		Print_logfile('             ["reloaddata"] ={hour=02,min=30,daysbefore=0,reminder=0,text="trigger for reloading data from website into garbagecalendar.data"},')
		garbagetype_cfg['reloaddata'] = {hour = 2, min = 30, daysbefore = 0, reminder = 0, text = 'default added'}
	end
	-- check and change all table entries for lowercase Garbagetype to make the script case insensitive and filled in fields
	for tbl_garbagetype, gtdata in pairs(garbagetype_cfg) do
		garbagetype_cfg[tbl_garbagetype].active = (gtdata.active or 'on'):lower()
		if garbagetype_cfg[tbl_garbagetype].active ~= 'on' and garbagetype_cfg[tbl_garbagetype].active ~= 'off' and garbagetype_cfg[tbl_garbagetype].active ~= 'skip' then
			Print_logfile('!!!! Check "active" field value for GarbageType ' .. tbl_garbagetype .. '  current value:"' .. garbagetype_cfg[tbl_garbagetype].active .. '". Using "on" as default.')
			garbagetype_cfg[tbl_garbagetype].active = 'on'
		end

		if gtdata.hour == nil or gtdata.hour > 24 or gtdata.hour < 1 then
			Print_logfile('!!!! Check "hour" field value for GarbageType "' .. tbl_garbagetype .. '"  current value:"' .. gtdata.hour .. '"')
			garbagetype_cfg[tbl_garbagetype].hour = 0
		end
		if gtdata.min == nil or gtdata.min > 59 or gtdata.min < 0 then
			Print_logfile('!!!! Check min field value for GarbageType "' .. tbl_garbagetype .. '"  current value:"' .. gtdata.min .. '"')
			garbagetype_cfg[tbl_garbagetype].min = 0
		end
		if gtdata.reminder == nil or gtdata.reminder > 23 or gtdata.reminder < 0 then
			Print_logfile('!!!! Check reminder field value for GarbageType "' .. tbl_garbagetype .. '"  current value:"' .. gtdata.reminder .. '"')
			garbagetype_cfg[tbl_garbagetype].reminder = 0
		end
		if (tbl_garbagetype ~= tbl_garbagetype:lower()) then
			Print_logfile(tbl_garbagetype .. ' change to ' .. tbl_garbagetype:lower())
			garbagetype_cfg[tbl_garbagetype:lower()] = {
				hour = gtdata.hour,
				min = gtdata.min,
				daysbefore = gtdata.daysbefore,
				reminder = gtdata.reminder,
				text = gtdata.text
			}
			garbagetype_cfg[tbl_garbagetype] = nil
		end
		-- create dummy entry to update the domoticz device 1 minute after the webupdate background task was scheduled
		if tbl_garbagetype == 'reloaddata' then
			local smin = gtdata.min + 1
			local shour = gtdata.hour
			if smin > 59 then
				smin = 0
				shour = shour + 1
				if shour > 24 then
					shour = 1
				end
			end
			garbagetype_cfg['updatedomoticzdevice'] = {
				hour = shour,
				min = smin,
				daysbefore = gtdata.daysbefore,
				reminder = gtdata.reminder,
				text = 'Dummy to trigger device update 1 minute after WebDataUpdate ran'
			}
		end
	end
	-- loop through the table to check event schedule
	local gcnt = 0
	for tbl_garbagetype, gtdata in pairs(garbagetype_cfg) do
		gcnt = gcnt + 1
		if
			(timenow.hour == gtdata.hour or timenow.hour == gtdata.hour + gtdata.reminder or --reminder same day
				timenow.hour == gtdata.hour + gtdata.reminder - 24) and --reminder next day
				timenow.min == gtdata.min
		 then
			Print_logfile(gcnt .. ' ==> NotificationTime=' .. string.format('%02d:%02d', gtdata.hour, gtdata.min) .. '  Garbagetype=' .. tostring(tbl_garbagetype) .. '  active=' .. (gtdata.active or '??') .. '  reminder=' .. (gtdata.reminder or '??'))
			if tbl_garbagetype == 'reloaddata' then
				-- perform background data updates
				GetWebData()
			else
				UpdateDevRun = true
			end
		else
			Print_logfile(gcnt .. ' --- NotificationTime=' .. string.format('%02d:%02d', gtdata.hour, gtdata.min) .. '  Garbagetype=' .. tostring(tbl_garbagetype) .. '  active=' .. (gtdata.active or '??') .. '  reminder=' .. (gtdata.reminder or '??'))
		end
	end
	-- Always update when mydebug is enabled
	if testrun then
		UpdateDevRun = true
		Print_logfile('#> Perform update because testrun=true.')
	end
	if mydebug then
		UpdateDevRun = true
		Print_logfile('#> Perform update because mydebug=true.')
	end
	-- Perform GarbageCalendar Date check and Send Notification/update Domoticz TXT device when required
	if UpdateDevRun then
		Perform_Data_check()
	else
		-- Only write this logfilerec when there's nothing to do
		if not UpdateDataRun then
			Print_logfile('Scheduled time(s) not reached yet, so nothing to do!')
		end
	end
	-- End of process run
	Print_logfile('-< ### ' .. RunText .. ' End garbagecalendar script v' .. MainScriptVersion)

	-- Save logfile when Webupdate or Device update run is done.
	if not batchrun and (UpdateDataRun or UpdateDevRun) then
		-- Determine which file needs to be created
		local nrunlogfile = string.gsub(RunLogfile, '_run', '_run_update')
		if UpdateDataRun then
			nrunlogfile = string.gsub(RunLogfile, '_run', '_run_webupdate')
		end
		-- Open current logfile and write to save log
		local ifile = io.open(RunLogfile, 'r')
		if ifile ~= nil then
			local ofile = io.open(nrunlogfile, 'w')
			if ofile ~= nil then
				ofile:write(ifile:read('*all'))
				ofile:close()
			else
				Print_logfile(' Unable to create _run_ log file:' .. nrunlogfile .. '. Check for the appropriate rights.')
			end
			ifile:close()
		else
			Print_logfile(' Unable to read current log file:' .. RunLogfile .. '. Check for the appropriate rights.')
		end
	end
end

-- Used to run the GetWebData as batch job in the background
if arg then
	if arg[1] == 'GetDataInBatch' then
		print('-----> Start Background process:')
		local rc, errmsg = pcall(gc_main, {}, {}, true)
		if not rc then
			print('-----< Background process done with error', errmsg)
			Print_logfile('-----< Background process done with error:' .. errmsg)
			Print_logfile(errmsg)
		else
			--Print_logfile('-----< Background process done  -----')
			print('-----< Background process done  -----')
		end
	end
end
