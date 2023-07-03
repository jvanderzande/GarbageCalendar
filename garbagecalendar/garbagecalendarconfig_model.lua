------------------------------------------------------------------------------------------------------------------------------------
-- garbagecalendarconfig.lua
------------------------------------------------------------------------------------------------------------------------------------
-- Specify your information here as needed for your needs

-- Domoticz URL to communicate with Domoticz for version & Icon updates Default http://127.0.0.1:8080
-- Ensure that you are allowing access to Domoticz from 127.0.0.1 without an userid/password!
DomoticzURL     = 'http://127.0.0.1:8080'
myGarbageDevice = '' -- The Text devicename in Domoticz. eg 'Container'
Zipcode = '' 			-- Your zipcode  eg '1234AB'
Housenr = '' 			-- Your housnr. eg '99'
Housenrsuf = '' 		-- Your housnr suffix  ('a', 'b'  etc)
Hostname = '' 			-- m_opzet & m_opzet_api: Specify the hostname of your website. eg 'inzamelkalender.hvcgroep.nl'
Street = '' 			-- Street name Only needed for: m_recycleapp
Companycode = ''		-- m_ximmio Companycode. (See m_ximmio.lua file for how to find this code).

-- ==============================
-- choose one of these modules ==
-- ==============================
--websitemodule = "m_deafvalapp"
--websitemodule = 'm_mijnafvalwijzer_API'
websitemodule = 'm_mijnafvalwijzer'
--websitemodule = "m_montferland"
--websitemodule = "m_ophaalkalender-be"
--websitemodule = "m_omrin"
--websitemodule = "m_opzet_api"
--websitemodule = "m_opzet"
--websitemodule = "m_recycleapp-be"
--websitemodule = "m_rmn_api"
--websitemodule = "m_rova_api"
--websitemodule = "m_ximmio"
--websitemodule = "m_zuidlimburg"
------------------------------------------------------------------------------------------------------------------------------------
-- When using a CSV input file uncomment the next 2 lines and specify the location and name of the file.
-- check the m_csv_file.lua file for the appropriate format.
--websitemodule = "m_csv_file"
--input_csv_file = "c:/data/garbage_input.csv"
--input_csv_file = "/home/pi/garbage_input.csv"
-- =================================================================================================================================

-- Switch on mydebug in case of issues and initially and check the domoticz log for any issues or missing
-- set to true or false
mydebug = false            -- run the script as it normally does when any of the scheduled times is the current time
testdataload = false       -- run the web update module in the foreground with each run for debugging.
testdataloadbatch = false  -- run the web update module in the background with each run for debugging. (testdataload takes presedence)
testnotification = false   -- trigger a test notification each run for the first record for testing the notification system

-- Specify the directoy used for the Data and Log files.
-- It will default to the gabagecalendar/data directory when invalid or missing.
--datafilepath = '/tmp'    -- Linux/RPI example
--datafilepath = 'D:/temp' -- windows example

------------------------------------------------------------------------------------------------------------------------------------
-- ### define format for text device in Domoticz
-- date options:
--    wd   = weekday in 3 characters as defined in the daysoftheweek table below. eg zon;maa;din
--    wdd  = weekday as defined in the Longdaysoftheweek table below. eg zondag;maandag;dinsdag
--    dd   = day in 2 digits   eg 31
--    mm   = month in 2 digits eg 01
--    mmm  = month abbreviation in 3 characters as defined in the ShortMonth table below. eg : jan
--    mmmm = month  as defined in the LongMonth table below. eg: januari
--    yy   = year in 2 digits eg 19
--    yyyy = year in 4 digits eg 2019
-- Garbage type description options
--    sdesc = short garbage type description from Website  eg pmd
--    ldesc = long garbage type description from Website when available, will be replaced by table description when not
--    tdesc = Use the description available in the table text field
--textformat = 'tdesc: wd dd mmm'
textformat = 'wd dd mmm: tdesc'
-- One can also add some html formatting formating to the output when the used interface supports that:eg:
--    textformat = '<font color="red" size=1>tdesc: wd dd mmm</font>'

-- ### define  what to show in the domoticz text device
-- !!! ShowSinglePerType will be forced to false when Combine_Garbage_perDay = true
ShowSinglePerType = false        -- (default) false => show multiple occurrences of a garbagetype (default)
--                               --	          true  => show one the next occurrence for a unique garbagetype
ShowNextEvents = 3               -- indicate the next x eventlines to show in the TEXT Sensor in Domoticz
Combine_Garbage_perDay = false   -- (default) false will show each garbagetype on its own line
--                               --            true will show multiple garbagetype on a single line when collected the same day

------------------------------------------------------------------------------------------------------------------------------------
-- Configuration for the Notificaton system:
-- IcalDesc:
--   @GARBAGETYPE@ ==> Will be replaced by the GarbageType definion from the WebSite
--   @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
IcalEnable = true -- false/true: When true, a garbagecalendar_Modulename.ics will be created in the datafilepath which can be used in a calendar application.
IcalTitle = 'GarbageCalendar' -- title of the calendar
IcalDesc = '@GARBAGETEXT@ wordt opgehaald.' -- text for the events in the calendar
IcalEvents = 10 -- max number of upcomming events to save to icalfile, but could be less when less events are provided by the website.
IcalNotify = 12 -- Notification Time in hours before event. 0=no notification
------------------------------------------------------------------------------------------------------------------------------------
-- Configuration for the Notificaton system:
NotificationEmailAdress = {'', ''} -- Specify multiple Email Addresses for the notifications. Leave empty to skip email notification
Notificationsystem = '' -- Specify notification system eg "telegram/pushover/gcm/http/kodi/lms/nma/prowl/pushalot/pushbullet/pushsafer" leave empty to skip

-- Specify external personal notification script/command (Shelled async)
--Notificationscript = 'lua /home/pi/domoticz/scripts/lua/garbagecalendar/notification_external_script.lua "@GARBAGETYPE@" > /tmp/GC_Notify.log 2> /tmp/GC_Notify.log'

-- Specify personal notification event script
-- This example is provided and will work in DzVents and regular Lua Time Events
-- EventNotificationscript = 'notification_event_script.lua' -- Specify personal notification script event eg: my_event_script.lua  (This needs to be placed in the GarbageCalendar directory together with the modules)

-- Supported variables for Title and Body
-- @DAY@         ==> Will be replaced by notificationtoday; notificationtomorrow; notificationlonger depending on the days difference.
-- @GARBAGETYPE@ ==> Will be replaced by the GarbageType definition from the WebSite
-- @GARBAGEDATE@ ==> Will be replaced by the pickup date found on the schedule data
-- @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
-- @REMINDER@    ==> Will be set to "" for first notification and "notificationreminder" for the reminder run
-- @TEXT@        ==> Will be replaced by the finalised notificationtext and can be used in the notification script
-- @TITLE@       ==> Will be replaced by the finalised notificationtitle and can be used in the notification script
--### Dutch example
-- Define how the title and bodytext should look
notificationreminder = ' (herinnering)'
notificationtitle = 'GarbageCalendar: @DAY@ de @GARBAGETEXT@ aan de weg zetten!'
notificationtext = '@GARBAGETEXT@ wordt @DAY@ opgehaald!@REMINDER@'
notificationtoday = 'vandaag'
notificationtomorrow = 'morgen'
notificationlonger = 'over @DAYS@ dagen'
notificationdate = 'wd dd mmmm yyyy' -- @GARBAGEDATE@ format -> Options are the same as available for textformat date options

--### English example
-- notificationreminder = ' (reminder)'
-- notificationtitle    = 'GarbageCalendar: @GARBAGETEXT@ will be picked up in @DAY@!'
-- notificationtext     = 'Put the @GARBAGETEXT@ out as it will be picked up @DAY@.!@REMINDER@'
-- notificationtoday    = 'today'
-- notificationtomorrow = 'tomorrow'
-- notificationlonger   = 'in @DAYS@ days'
-- notificationdate     = 'wd dd mmmm yyyy'      -- Options are the same as available for textformat date options
------------------------------------------------------------------------------------------------------------------------------------
-- Configuration for the generation of an ics file:
-- IcalDesc:
--   @GARBAGETYPE@ ==> Will be replaced by the GarbageType definion from the WebSite
--   @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
IcalEnable = false -- false/true: When true, a garbagecalendar_Modulename.ics will be created in the datafilepath which can be used in a calendar application.
IcalTitle = 'GarbageCalendar' -- title of the calendar
IcalDesc = '@GARBAGETEXT@ wordt opgehaald.' -- text for the events in the calendar
IcalEvents = 10 -- max number of upcomming events to save to icalfile, but could be less when less events are provided by the website.
IcalNotify = 12 -- Notification Time in hours before event. 0=no notification
------------------------------------------------------------------------------------------------------------------------------------
-- ### define a line for each garbage type returned by the webrequest.
-- Look at the Domoticz log for any missing records as they will be displayed there and can be just copy/pasted in.
-- Fields description:
-- hour & min ==> the time the check needs to be performed and notification send when daysbefore is true
-- daysbefore ==> 0 means that the notification is send on the day of the planned garbage collection
-- daysbefore ==> X means that the notification is send X day(s) before the day of the planned garbage collection
-- reminder   ==> Will send a second reminder after x hours. 0=no reminder (can be between 0 - 24 hours)
-- text       ==> define the text for the notification and Text Device.
-- active     ==> (optional)  default="on"
--           active="on"   Both will show in Domoticz Text Device and Send notifications
--           active="off"  Will show in Domoticz Text Device but not send notifications
--           active="skip" Will not show in Domoticz Text Device and not send notifications
-- The "reloaddata" entry is required to run the background process to update the data one time per day.
-- The "dummy" entry can be used to force reading the data, update the Domoticz text device and see if there are any errors or missing garbadge types.

-- Without updating the Text device ICON:
garbagetype_cfg = {
	-- Add any missing records below this line -----------------------------------------------------
	['pmd'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'plastic bak', icon = nil},
	['gft'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'groene bak', icon = nil},
	['papier'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'blauwe bak', icon = nil},
	['restafval'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'grijze bak', icon = nil},
	-- Add any missing records above this line -----------------------------------------------------
	--  "reloaddata" is used to start the background update process at this given time.
	['reloaddata'] = {hour = 02, min = 30, daysbefore = 0, reminder = 0, text = 'trigger for reloading data from website into garbagecalendar.data'},
	['dummy'] = {hour = 04, min = 01, daysbefore = 0, reminder = 0, text = 'dummy to trigger update of textdevice early morning'}
}

--[[
-- Also update the Text device ICON to your preference:
garbagetype_cfg = {
	-- Add any missing records below this line -----------------------------------------------------
	['pmd'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'plastic bak', icon = 'garbagecalendar_yellow'},
	['gft'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'groene bak', icon = 'garbagecalendar_green'},
	['papier'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'blauwe bak', icon = 'garbagecalendar_blue'},
	['restafval'] = {hour = 19, min = 22, daysbefore = 1, reminder = 3, text = 'grijze bak', icon = 'garbagecalendar_grey'},
	-- Add any missing records above this line -----------------------------------------------------
	--  "reloaddata" is used to start the background update process at this given time.
	['reloaddata'] = {hour = 02, min = 30, daysbefore = 0, reminder = 0, text = 'trigger for reloading data from website into garbagecalendar.data'},
	['dummy'] = {hour = 04, min = 01, daysbefore = 0, reminder = 0, text = 'dummy to trigger update of textdevice early morning'}
}
]]
------------------------------------------------------------------------------------------------------------------------------------
-- Taal opties Nederlands
-- Datum / dag informatie:
-- Gebruikt door functie getdate voor formats "mmmm" & "mmm"
daysoftheweek = {'zon', 'maa', 'din', 'woe', 'don', 'vri', 'zat'}
Longdaysoftheweek = {'zondag', 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag'}
ShortMonth = {'jan', 'feb', 'maa', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'}
LongMonth = {'januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'}
-- Wordt gebruikt om de maand afkorting van de ontvangen kalender data te vertalen naar het maandnummer. Meerder opties mogelijk.
-- Pas deze tabellen aan indien de afvalverwerker andere afkortingen gebruikt.
InputMonth = {jan = 1, feb = 2, mrt = 3, maa = 3, apr = 4, mei = 5, jun = 6, jul = 7, aug = 8, sep = 9, okt = 10, nov = 11, dec = 12}
------------------------------------------------------------------------------------------------------------------------------------
-- Language options English
-- Date/day info:
--daysoftheweek={"Sun","Mon","Tue","Wed","Thu","Fri","Sat"}
--Longdaysoftheweek={"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}
--ShortMonth={"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
--LongMonth={"January","February","March","April","May","June","July","August","September","October","November","December"}
-- Used to translate the month abbreviation back to the month number. Can contain multiple options for abbreviations.
-- Adapt when your GarbageCollector is using different abbreviations.
--InputMonth={jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12}
