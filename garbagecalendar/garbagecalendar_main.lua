function garbagecalendar_main(commandArray, domoticz)

	----------------------------------------------------------------------------------------------------------------
	-- Regular LUA GarbageCalendar huisvuil script: script_time_garbagewijzer.lua
	----------------------------------------------------------------------------------------------------------------
	MainScriptVersion = '20230104-1705'
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
	if domoticz ~= nil then
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
	websitemodule = '???'
	datafilepath = ''
	GC_scriptpath = ''
	weblogfile = ''
	runlogfile = ''
	datafile = ''
	icalfile = ''
	needupdate = false
	timenow = os.date('*t')

	---====================================================================================================
	-- mydebug print
	function dprintlog(text, always, prefix)
		text = text or 'nil'
		local ptext = ''
		if (prefix or 1) == 1 then
			ptext = '' .. os.date('%X ') .. 'GC Main: '
		end
		if testdataload or mydebug or (always or 0) >= 1 then
			print(ptext .. text)
		end
		if (runlogfile ~= nil) then
			file = io.open(runlogfile, 'a')
			if file ~= nil then
				file:write(ptext .. text .. '\n')
				file:close()
			end
		end
	end

	---====================================================================================================
	-- try getting current GC_scriptpath requied to get the garbagecalendarconfig.lua loaded
	-- this will be overridden by the garbagecalendarconfig.lua settings, but initially needed.
	function script_path()
		local str = debug.getinfo(2, 'S').source:sub(2)
		return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
	end
	GC_scriptpath = script_path() or './'
	dprintlog('GC_scriptpath:' .. GC_scriptpath)
	---====================================================================================================
	-- Load garbagecalendarconfig.lua
	function garbagecalendarconfig()
		if unexpected_condition then
			error()
		end
		-- add defined Domoticz path to the search path
		package.path = GC_scriptpath .. '?.lua;' .. package.path
		require 'garbagecalendarconfig'
		-- check if debugging is required
		testdataload = testdataload or false
		mydebug = mydebug or false

		-- initialise the variables
		datafilepath = (datafilepath .. '/'):gsub('//', '/')
		runlogfile = datafilepath .. 'garbagecalendar_run_' .. websitemodule .. '.log'
		weblogfile = datafilepath .. 'garbagecalendar_web_' .. websitemodule .. '.log'
		datafile = datafilepath .. 'garbagecalendar_' .. websitemodule .. '.data'
		icalfile = datafilepath .. 'garbagecalendar_' .. websitemodule .. '.ics'
		-- empty previous run runlogfile
		file = io.open(runlogfile, 'w')
		if file == nil then
			print('!!! Error opening runlogfile ' .. runlogfile)
		else
			file:close()
		end
		dprintlog('### ' .. RunText .. ' Start garbagecalendar script v' .. MainScriptVersion .. '   ' .. os.date('%c'))
		if testdataload then
			dprintlog('---> Debuging dataload each cycle in the foreground because "testdataload=true" in garbagecalendarconfig.lua')
			dprintlog('--->    please change it back to "testdataload=false" when done testing to avoid growing a big domoticz log and slowing down the event system.')
		end
		if mydebug or false then
			dprintlog('---> Debuging with extra messages because "mydebug=true" in garbagecalendarconfig.lua')
			dprintlog('--->    please change it back to "mydebug=false" when done testing to avoid growing a big domoticz log.')
		end
		--ensure the all path variables ends with /
		dprintlog('datafilepath: ' .. datafilepath)

		-- check some config settings
		ShowSinglePerType = ShowSinglePerType or false
		Combine_Garbage_perDay = Combine_Garbage_perDay or false
		-- Force ShowSinglePerType to false when Combine_Garbage_perDay = true
		if Combine_Garbage_perDay and ShowSinglePerType then
			ShowSinglePerType = false
			dprintlog("! changed ShowSinglePerType=false because Combine_Garbage_perDay=true and they can't be both set.")
		end
	end

	-- check if that worked correctly
	local status, err = pcall(garbagecalendarconfig)
	if err then
		print('#### ' .. os.date('%X') .. ' start garbagecalendar script v' .. MainScriptVersion .. '####')
		print('!!! failed loading "garbagecalendarconfig.lua" from : "' .. GC_scriptpath .. '"')
		print('       Ensure you have copied "garbagecalendarconfig_model.lua" to "garbagecalendarconfig.lua" and modified it to your requirements.')
		print('       Also check the path in variable "GC_scriptpath= "  is correctly set.')
		print('!!! LUA Error: ' .. err)
		return
	else
		dprintlog('Loaded ' .. GC_scriptpath .. 'garbagecalendarconfig.lua.')
	end

	---====================================================================================================
	-- Load generalfuncs.lua
	function generalfuncs()
		if unexpected_condition then
			error()
		end
		-- add defined Domoticz path to the search path
		package.path = GC_scriptpath .. '?.lua;' .. package.path
		require 'generalfuncs'
	end
	-- check if that worked correctly
	local status, err = pcall(generalfuncs)
	if err then
		dprintlog('### Error: failed loading generalfuncs.lua from : ' .. GC_scriptpath .. '', 1)
		dprintlog('### Error: Please check the path in variable "GC_scriptpath= "  in your setup and try again.', 1)
		print('!!! LUA Error: ' .. err)
		return
	else
		dprintlog('Loaded ' .. GC_scriptpath .. 'generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ')')
		if MainScriptVersion ~= MainGenUtilsVersion then
			dprintlog('### Warning: Version of generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ') is different from the main script! (v' .. (MainScriptVersion or '??') .. ')')
		end
	end
	---====================================================================================================
	-- check whether provide paths are valid
	if (not isdir(datafilepath)) then
		dprintlog('### Error: invalid path for datafilepath : ' .. datafilepath .. '.', 1)
		dprintlog('### Error: Please check the path in variable "datafilepath= " in your "garbagecalenderconfig.lua" setup and try again.', 1)
		return
	end

	if (not exists(GC_scriptpath .. '' .. websitemodule .. '.lua')) then
		dprintlog('### Error: module not found: ' .. GC_scriptpath .. '' .. websitemodule .. '.lua', 1)
		dprintlog('### Error: Please check the path&name in variables "GC_scriptpath=" "websitemodule= "  in your "garbagecalenderconfig.lua" setup and try again.', 1)
		return
	end

	---====================================================================================================
	-- perform  Web data update
	function GetWebData(whenrun)
		-- empty previous run weblogfile
		file = io.open(weblogfile, 'w')
		if file == nil then
			print('!!! Error opening weblogfile ' .. weblogfile)
		else
			file:close()
		end
		-- Update Now or in the BackGround to avoid slowdown of the Domoticz event process
		if ((whenrun or '') ~= 'now') then
			-- Shell _runmodule.lua as separate process in the background to perform update of the data
			local command = 'lua ' .. GC_scriptpath .. '_runmodule.lua ' .. websitemodule
			command = command .. ' "' .. Zipcode .. '"'
			command = command .. ' "' .. Housenr .. '"'
			command = command .. ' "' .. Housenrsuf .. '"'
			command = command .. ' "' .. datafile .. '"'
			command = command .. ' "' .. weblogfile .. '"'
			command = command .. ' "' .. (Hostname or '') .. '"' -- optional param
			command = command .. ' "' .. (Street or '') .. '"' -- optional param
			-- Test if lua is installed, if so submit backgrond task to update the datafile to relieve the event system
			os.execute('lua -v >' .. datafilepath .. 'luatest.log 2>&1')
			local ifile, ierr = io.open(datafilepath .. 'luatest.log', 'r')
			local Chk_Error = ierr or ''
			local luaversion = ''
			if not ierr then
				Chk_Error = ifile:read('*all'):gsub('[\r\n]', '')
				ifile:close()
				os.remove(datafilepath .. 'luatest.log')
				luaversion = Chk_Error:match('[lL][uU][aA]%s*([%d*%.]*)[^\r\n]*') or ''
				dprintlog('=>Found LUA version:' .. luaversion .. '   > Lua check output:' .. Chk_Error or '?')
			else
				dprintlog('Lua check error:' .. Chk_Error or '?')
			end
			-- if the testfile contain this error, it means lua is installed.
			if luaversion ~= '' then
				dprintlog('=> start background webupdate for module ' .. websitemodule .. ' of file ' .. datafile, 1)
				dprintlog(command .. ' &')
				print(command .. ' &')
				rc = os.execute(command .. ' &')
				-- Check the version to make sure it is the same as the main script.
				OnlyCheckVersion = true
				dofile(GC_scriptpath .. '_runmodule.lua')
			else
				dprintlog('=> check LUA not found --> Run foreground to use internal LUA.', 1)
				whenrun = 'now' -- perform the update in the foreground with the domoticz LUA implementation
			end
		end
		-- Run the Webupdate in the foreground when required. This happens in case the datafile doesn't exists or LUA can't be found.
		if ((whenrun or '') == 'now') then
			-- Fill the arg[] table with the required parameters and run the script with dofile().
			dprintlog('=> Start new foreground WebUpdate for module ' .. websitemodule, 1)
			dofile(GC_scriptpath .. '_runmodule.lua')
			dprintlog('=< End WebUpdate.')
		end
		-- Save run log during webupdate
		local ifile = io.open(runlogfile, 'r')
		if ifile ~= nil then
			local ofile = io.open(string.gsub(runlogfile, '_run_', '_run_webupdate_'), 'w')
			if ofile ~= nil then
				ofile:write(ifile:read('*all'))
				ofile:close()
			else
				dprintlog(' Unable to create _run_ log file:' .. string.gsub(runlogfile, '_run_', '_run_webupdate_') .. '. Check for the appropriate rights.')
			end
			ifile:close()
		else
			dprintlog(' Unable to create _run_webupdate log file:' .. runlogfile .. '. Check for the appropriate rights.')
		end
	end

	---====================================================================================================
	-- get days between today and provided date
	function getdaysdiff(i_garbagetype_date, stextformat)
		local curTime = os.time {day = timenow.day, month = timenow.month, year = timenow.year}
		-- check if date in variable i_garbagetype_date contains "vandaag" in stead of a valid date -> use today's date
		garbageyear, garbagemonth, garbageday = i_garbagetype_date:match('(%d-)-(%d-)-(%d-)$')
		if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
			dprintlog('### Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date, 1)
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
		return stextformat, Round(os.difftime(garbageTime, curTime) / 86400, 0) -- 1 day = 86400 seconds
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
					dprintlog('----> testnotification ?!?!', 1, 0)
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
				local inotificationdate = notificationdate or 'yyyy-mm-dd'
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
							dprintlog('----> Notification Email send for ' .. s_garbagetype .. ' |' .. inotificationtitle .. '#' .. inotificationtext .. '#' .. emailaddress .. '|', 1, 0)
						end
					end
				else
					if (NotificationEmailAdress or '') ~= '' then
						if RunbyDzVents then
							domoticz.email(inotificationtitle, inotificationtext, NotificationEmailAdress)
						else
							commandArray[#commandArray + 1] = {['SendEmail'] = inotificationtitle .. '#' .. inotificationtext .. '#' .. NotificationEmailAdress}
						end
						dprintlog('----> Notification Email send for ' .. s_garbagetype .. ' |' .. inotificationtitle .. '#' .. inotificationtext .. '#' .. NotificationEmailAdress .. '|', 1, 0)
					end
				end

				if (Notificationsystem or '') ~= '' then
					if RunbyDzVents then
						domoticz.notify(inotificationtitle, inotificationtext, domoticz.PRIORITY_NORMAL,domoticz.SOUND_DEFAULT, "" , Notificationsystem)
					else
						commandArray[#commandArray + 1] = {['SendNotification'] = inotificationtitle .. '#' .. inotificationtext .. '####' .. Notificationsystem}
					end
					dprintlog('----> '..Notificationsystem..' Notification send for ' .. s_garbagetype .. ' |' .. inotificationtitle .. '#' .. inotificationtext, 1, 0)
				end

				if (Notificationscript or '') ~= '' then
					Notificationscript = Notificationscript:gsub('@TEXT@', inotificationtext)
					Notificationscript = Notificationscript:gsub('@TITLE@', inotificationtitle)
					Notificationscript = Notificationscript:gsub('@GARBAGETYPE@', s_garbagetype)
					Notificationscript = Notificationscript:gsub('@GARBAGETEXT@', tostring(garbagetype_cfg[s_garbagetype].text))
					Notificationscript = Notificationscript:gsub('@GARBAGEDATE@', inotificationdate)
					Notificationscript = Notificationscript:gsub('@REMINDER@', ireminder)
					os.execute(Notificationscript .. ' &')
					dprintlog('---->Notification script started: ' .. Notificationscript)
				end
				if (EventNotificationscript or '') ~= '' then
					dprintlog('---->check : ' .. GC_scriptpath .. '' .. EventNotificationscript)
					if (not exists(GC_scriptpath .. '' .. EventNotificationscript)) then
						dprintlog('### Error: EventNotificationscript not found: ' .. GC_scriptpath .. '' .. EventNotificationscript)
						return
					end
					dprintlog('---->Notification script started: ' .. EventNotificationscript)
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
						notification_event(RunbyDzVents, commandArray, domoticz)
					end
					-- run the extra function
					local n_rc, n_errmsg
					if RunbyDzVents then
						n_rc, n_errmsg  = pcall(run_notification_event, RunbyDzVents, nil, domoticz)
					else
						n_rc, n_errmsg  = pcall(run_notification_event, RunbyDzVents, commandArray, nil)
					end
					-- check for errors
					if n_rc then
						dprintlog('---->Notification script ended: ' .. EventNotificationscript)
					else
						dprintlog('!!!!> '..EventNotificationscript..'  ended with errors: ' .. n_errmsg, 1)
						addlogmessage('!!!!> '..EventNotificationscript..'  ended with errors: ' .. n_errmsg,4)
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------------------------------------------
	-- Do the actual update retrieving data from the website and processing it
	function Perform_Data_check()
		-- ensure the access is set correctly for data
		dprintlog('=> Action starting, First check access to required files:')
		function ListAccess(name)
			local sCMD = 'ls -l ' .. name
			dprintlog('   Run command:\n' .. sCMD .. ':')
			local handle = assert(io.popen(sCMD))
			local cmd_output = handle:read('*all')
			-- remove ending CR LF chars
			cmd_output = cmd_output:gsub('[\r\n]+$', '')
			handle:close()
			dprintlog(cmd_output, 0, '')
		end
		-- show access info when debugging
		if mydebug or false then
			ListAccess(datafilepath .. 'garbagecal*' .. websitemodule .. '*')
		end

		if not Perform_Rights_check(datafilepath .. 'garbagecalendar_' .. websitemodule .. '.data') then
			return
		end
		if not Perform_Rights_check(datafilepath .. 'garbagecalendar_run_' .. websitemodule .. '.log') then
			return
		end
		if not Perform_Rights_check(datafilepath .. 'garbagecalendar_web_' .. websitemodule .. '.log') then
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

		-- function to process ThisYear and Lastyear JSON data
		--
		dprintlog('=> Start update for text device:', 1)
		local garbagedata, perr = table.load(datafile)
		-- try reload data when datafile is missing
		if perr ~= 0 then
			--- when file doesn't exist
			dprintlog('### Warning: Datafile not found:' .. datafile .. ' . Start webupdate now.')
			GetWebData('now')
			garbagedata, perr = table.load(datafile)
		else
			-- try reload data when the number of records are 0 in the datafile
			if (#garbagedata or 0) == 0 then
				--- when file doesn't exist
				dprintlog('### Warning: Datafile contains ' .. (#garbagedata or '?') .. ' datarecords. Start webupdate now.')
				GetWebData('now')
				garbagedata, perr = table.load(datafile)
			end
		end

		if perr ~= 0 then
			--- when file doesn't exist
			dprintlog('#### Error: Unable to load the data. please check your setup and runlogfile :' .. runlogfile)
			return
		elseif (#garbagedata or 0) == 0 then
			dprintlog('#### Error: ' .. (#garbagedata or '?') .. ' data records, updated at ' .. (garbagedata['Garbage_LastUpdate'] or '') .. ' from datafile:' .. datafile)
			return
		else
			dprintlog('   ' .. (#garbagedata or '?') .. ' data records loaded, updated at ' .. (garbagedata['Garbage_LastUpdate'] or '') .. ' from datafile:' .. datafile)
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
					dprintlog(' Unable to create iCAL file:' .. icalfile .. '  Check for the appropriate rights.')
				end
			end

			dprintlog('-> Start looping through data to find the first ' .. ShowNextEvents .. ' events to show: ')
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
						missingrecords = missingrecords .. '   ["' .. web_garbagetype:lower() .. '"]' .. string.rep(' ', 32 - string.len(web_garbagetype)) .. ' ={hour=19,min=02,daysbefore=1,reminder=0,text="' .. web_garbagedesc .. '"},\n'
						garbagetype_cfg[web_garbagetype] = {hour = 0, min = 0, daysbefore = 0, reminder = 0, text = 'dummy'}
						garbagetype_cfg[web_garbagetype].text = web_garbagetype
						garbagetype_cfg[web_garbagetype].missing = true
					end
					-- Add event to Devtxt
					if garbagetype_cfg[web_garbagetype].active ~= 'skip' and txtcnt < ShowNextEvents then
						-- get daysdiff
						local stextformat = textformat
						stextformat, daysdiffdev = getdaysdiff(web_garbagedate, stextformat)
						-- check whether the first nextdate for this garbagetype is already found to get only one next date per GarbageType
						if ((not ShowSinglePerType) or (garbagetype_cfg[web_garbagetype].nextdate == nil) and txtcnt < ShowNextEvents) then
							-- When days is 0 or greater the date is today or in the future. Ignore any date in the past
							if daysdiffdev == nil then
								dprintlog('    !!! Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
							elseif daysdiffdev >= 0 then
								-- Set the nextdate for this garbagetype
								garbagetype_cfg[web_garbagetype].nextdate = web_garbagedate
								-- get the long description from the JSON data
								if garbagetype_cfg[web_garbagetype].active ~= 'on' then
									dprintlog(
										'==> GarbageDate:' .. tostring(web_garbagedate) .. ' GarbageType:' .. tostring(web_garbagetype) .. '; Calc Days Diff=' .. tostring(daysdiffdev) .. '; *** Notify skipped because there is no record in garbagetype_cfg[]!',
										0,
										0
									)
								else
									dprintlog(
										'==> GarbageDate:' ..
											tostring(web_garbagedate) ..
												' GarbageType:' ..
													tostring(web_garbagetype) ..
														';  Notify: Active=' ..
															tostring(garbagetype_cfg[web_garbagetype].active) ..
																'  Time=' ..
																	tostring(garbagetype_cfg[web_garbagetype].hour) ..
																		':' ..
																			tostring(garbagetype_cfg[web_garbagetype].min) ..
																				'   DaysBefore=' .. tostring(garbagetype_cfg[web_garbagetype].daysbefore) .. '   reminder=' .. tostring(garbagetype_cfg[web_garbagetype].reminder) .. '   Calc Days Diff=' .. tostring(daysdiffdev),
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
									dprintlog('  -- merging record:' .. i - 1 .. ' Date:' .. garbagedata[i - 1].garbagedate .. ' Type:' .. garbagedata[i - 1].garbagetype .. '  wdesc:' .. (garbagedata[i - 1].wdesc or ''))
									dprintlog('             record:' .. i .. ' Date:' .. garbagedata[i].garbagedate .. ' Type:' .. garbagedata[i].garbagetype .. '  wdesc:' .. (garbagedata[i].wdesc or ''))
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
								devtxt = devtxt .. stextformat .. '\r\n'
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
							dprintlog('==> skipping because active="skip" for GarbageType:' .. tostring(web_garbagetype) .. '  GarbageDate:' .. tostring(web_garbagedate), 0, 0)
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
		end
		if txtcnt < 1 then
			dprintlog('### Warning: No valid records found in the datafile: ' .. datafile, 1)
			dprintlog('###          Please check the garbagecalendar log files for issues : ' .. weblogfile .. ' and ' .. runlogfile, 1)
		end
		dprintlog('-< End data loop')
		if missingrecords ~= '' then
			dprintlog('#!# Warning: These records are missing in your garbagecalendarconfig.lua file, so no notifications will be send!', 1)
			dprintlog('#!# -- start -- Add these records into the garbagetype_cfg table and adapt the schedule and text info to your needs :', 1)
			dprintlog(missingrecords, 1, 0)
			dprintlog('#!# -- end ----------------------------')
		end
		if (cnt == 0) then
			dprintlog('### Error: No valid data found in returned webdata.  skipping the rest of the logic.', 1)
			return
		end
		-- always update the domoticz device so one can see it is updating and when it was ran last.
		dprintlog('==> found schedule:' .. devtxt:gsub('\r\n', ' ; '), 1)
		if RunbyDzVents then
			if domoticz.devices(myGarbageDevice).idx == nil then
				dprintlog("### Error: Couldn't get the current data from Domoticz text device " .. myGarbageDevice)
			else
				if (domoticz.devices(myGarbageDevice).text ~= devtxt) then
					dprintlog('Update device from: \n' .. domoticz.devices(myGarbageDevice).text .. '\n replace with:\n' .. devtxt)
					domoticz.devices(myGarbageDevice).updateText(devtxt)
				else
					dprintlog('No updated text for TxtDevice.')
				end
			end
		else
			if otherdevices_idx == nil or otherdevices_idx[myGarbageDevice] == nil then
				dprintlog("### Error: Couldn't get the current data from Domoticz text device " .. myGarbageDevice)
			else
				commandArray['UpdateDevice'] = otherdevices_idx[myGarbageDevice] .. '|0|' .. devtxt
				if (otherdevices[myGarbageDevice] ~= devtxt) then
					dprintlog('Update device from: \n' .. otherdevices[myGarbageDevice] .. '\n replace with:\n' .. devtxt)
				else
					dprintlog('No updated text for TxtDevice.')
				end
			end
		end
		-- close ICAL file when requested
		if IcalEnable then
			hIcal:write('END:VCALENDAR')
			hIcal:close()
			dprintlog('==> Created an ICS file with ' .. icalcnt .. ' Garbage collection events entries in file: ' .. icalfile)
		end
	end

	----------------------------------------------------------------------------------------------------------------
	-- check access rights to file and try fixing for linux OSes
	function Perform_Rights_check(filename)
		if (exists(filename)) then
			if (not haveaccess(filename)) then
				dprintlog('No access to the file. Running->sudo chmod 777 ' .. filename, 1)
				os.execute('sudo chmod 777 ' .. filename .. ' 2>/dev/null')
				if (haveaccess(filename)) then
					dprintlog('Access Fixed: ' .. filename)
				else
					dprintlog('### Error: Still no access. Please check the settings for ' .. filename .. ' and then try again.', 1)
					return false
				end
			else
				dprintlog('Access OK: ' .. filename)
			end
		else
			dprintlog("File doesn't exists: " .. filename, 1)
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
	if testdataload or false then
		GetWebData('now')
	end

	-- Start of logic ==============================================================================================

	-- check for notification times and run update only when we are at one of these defined times
	if RunbyDzVents then
		dprintlog('=> DzVents: Start checking garbagetype_cfg table whether an action is needed:')
	else
		dprintlog('=> Time: Start checking garbagetype_cfg table whether an action is needed:')
	end
	if garbagetype_cfg == nil then
		dprintlog('### Error: failed loading the "garbagetype_cfg" table from your garbagecalendarconfig.lua file. Please check your setup file.', 1)
		return
	end
	if garbagetype_cfg['reloaddata'] == nil or garbagetype_cfg['reloaddata'].hour == nil or garbagetype_cfg['reloaddata'].min == nil then
		dprintlog('### Warning: Web update will be performed on a default time at 02:30AM, because the "reloaddata" entry missing in the "garbagetype_cfg" table in your garbagecalendarconfig.lua file! ')
		dprintlog('           Check the original provided garbagecalendarconfig_model.lua for the correct format: ')
		dprintlog('             -- Add any missing records above this line')
		dprintlog('             ["reloaddata"] ={hour=02,min=30,daysbefore=0,reminder=0,text="trigger for reloading data from website into garbagecalendar.data"},')
		garbagetype_cfg['reloaddata'] = {hour = 2, min = 30, daysbefore = 0, reminder = 0, text = 'default added'}
	end
	-- check and change all table entries for lowercase Garbagetype to make the script case insensitive and filled in fields
	for tbl_garbagetype, gtdata in pairs(garbagetype_cfg) do
		garbagetype_cfg[tbl_garbagetype].active = (gtdata.active or 'on'):lower()
		if garbagetype_cfg[tbl_garbagetype].active ~= 'on' and garbagetype_cfg[tbl_garbagetype].active ~= 'off' and garbagetype_cfg[tbl_garbagetype].active ~= 'skip' then
			dprintlog('!!!! Check "active" field value for GarbageType ' .. tbl_garbagetype .. '  current value:"' .. garbagetype_cfg[tbl_garbagetype].active .. '". Using "on" as default.')
			garbagetype_cfg[tbl_garbagetype].active = 'on'
		end

		if gtdata.hour == nil or gtdata.hour > 24 or gtdata.hour < 1 then
			dprintlog('!!!! Check "hour" field value for GarbageType "' .. tbl_garbagetype .. '"  current value:"' .. gtdata.hour .. '"')
			garbagetype_cfg[tbl_garbagetype].hour = 0
		end
		if gtdata.min == nil or gtdata.min > 59 or gtdata.min < 0 then
			dprintlog('!!!! Check min field value for GarbageType "' .. tbl_garbagetype .. '"  current value:"' .. gtdata.min .. '"')
			garbagetype_cfg[tbl_garbagetype].min = 0
		end
		if gtdata.reminder == nil or gtdata.reminder > 23 or gtdata.reminder < 0 then
			dprintlog('!!!! Check reminder field value for GarbageType "' .. tbl_garbagetype .. '"  current value:"' .. gtdata.reminder .. '"')
			garbagetype_cfg[tbl_garbagetype].reminder = 0
		end
		if (tbl_garbagetype ~= tbl_garbagetype:lower()) then
			dprintlog(tbl_garbagetype .. ' change to ' .. tbl_garbagetype:lower())
			garbagetype_cfg[tbl_garbagetype:lower()] = {
				hour = gtdata.hour,
				min = gtdata.min,
				daysbefore = gtdata.daysbefore,
				reminder = gtdata.reminder,
				text = gtdata.text
			}
			garbagetype_cfg[tbl_garbagetype] = nil
		end
	end
	-- loop through the table to check whether
	for tbl_garbagetype, gtdata in pairs(garbagetype_cfg) do
		if
			(timenow.hour == gtdata.hour or timenow.hour == gtdata.hour + gtdata.reminder or --reminder same day
				timenow.hour == gtdata.hour + gtdata.reminder - 24) and --reminder next day
				timenow.min == gtdata.min
		 then
			dprintlog('=> NotificationTime=' .. string.format('%02d:%02d', gtdata.hour, gtdata.min) .. '  Garbagetype=' .. tostring(tbl_garbagetype))
			if tbl_garbagetype == 'reloaddata' then
				-- perform background data updates
				GetWebData()
			else
				needupdate = true
			end
		else
			dprintlog('>   NotificationTime=' .. string.format('%02d:%02d', gtdata.hour, gtdata.min) .. '  Garbagetype=' .. tostring(tbl_garbagetype))
		end
	end
	-- Always update when mydebugging
	if mydebug then
		needupdate = true
		dprintlog('#> Perform update because mydebug=true.')
	end
	-- get information from website, update device and send notification when required
	if needupdate then
		-- empty previous run_update logfile
		Perform_Data_check()
		-- Save run log during update
		local ifile = io.open(runlogfile, 'r')
		if ifile ~= nil then
			local ofile = io.open(string.gsub(runlogfile, '_run_', '_run_update_'), 'w')
			if ofile ~= nil then
				ofile:write(ifile:read('*all'))
				ofile:close()
			else
				dprintlog(' Unable to create _run_ log file:' .. string.gsub(runlogfile, '_run_', '_run_update_') .. '. Check for the appropriate rights.')
			end
			ifile:close()
		else
			dprintlog(' Unable to create _run_update log file:' .. runlogfile .. '. Check for the appropriate rights.')
		end
	else
		dprintlog('Scheduled time(s) not reached yet, so nothing to do!')
	end
	dprintlog('### ' .. RunText .. ' End garbagecalendar script v' .. MainScriptVersion)

	-- save changes to Global variable
	--GC_domoticz=domoticz
end
