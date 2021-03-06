-----------------------------------------------------------------------------
-- garbagecalendarconfig.lua
-----------------------------------------------------------------------------
-- Specify your information here as needed for your needs
myGarbageDevice = ''  -- The Text devicename in Domoticz. eg 'Container'
ShowNextEvents = 3    -- indicate the next x events to show in the TEXT Sensor in Domoticz
Zipcode = ''          -- Your zipcode  eg '1234AB'
Housenr = ''          -- Your housnr. eg '99'
Housenrsuf = ''       -- Your housnr suffix  ('a', 'b'  etc)
Hostname = ''         -- m_opzet & m_opzet_api: Specify the hostname of your website. eg 'inzamelkalender.hvcgroep.nl'
                      -- *m_ximmio: Specify the companycode. (See m_ximmio.lua on how to find this code).
Street=''             -- Street name Only needed for: m_recycleapp
-- ==============================
-- choose one of these modules ==
-- ==============================
--websitemodule = "m_deafvalapp"
--websitemodule = "m_goeree-overflakkee"
websitemodule = 'm_mijnafvalwijzer'
--websitemodule = "m_montferland"
--websitemodule = "m_recycleapp-be"
--websitemodule = "m_opzet"
--websitemodule = "m_opzet_api"
--websitemodule = "m_omrin"
--websitemodule = "m_rova_api"
--websitemodule = "m_westland"
--websitemodule = "m_ximmio"           --
--websitemodule = "m_zuidlimburg"
-------------------------------------------------------------------------------------------------------
-- When using a CSV input file uncomment the next 2 lines and specify the location and name of the file.
-- check the m_csv_file.lua file for the appropriate format.
--websitemodule = "m_csv_file"
--input_csv_file = "c:/data/garbage_input.csv"
--input_csv_file = "/home/pi/garbage_input.csv"
-- =====================================================================================================

-- Switch on mydebug in case of issues and initially and check the domoticz log for any issues or missing
mydebug = false -- (true/false) -- run the script as it normally does when any of the scheduled times is the current time
testdataload = false -- (true/false) -- run the web update module with each run for testing/debugging purposes
testnotification = false -- (true/false) -- this will trigger a test notification for the first record for testing the notification system

-- Specify the appropriate directories (Raspberry Pi example)
datafilepath = '/var/tmp' -- specify the directory where the garbagecalendar.data & garbagecalendar.log will be stored
scriptpath = '/home/pi/domoticz/scripts/lua' -- specify the directory for the main "script_time_garbagecalendar.lua" script
domoticzjsonpath = '/home/pi/domoticz/scripts/lua' -- specify the path to domoticz where the JSON.lua file can be found
-- Specify the appropriate directories (Windows example)
--datafilepath     = 'D:/temp'                            -- specify the directory where the garbagecalendar.data & garbagecalendar.log will be stored
--scriptpath       = 'D:/_domoticz/scripts/lua'   -- specify the directory for this script
--domoticzjsonpath = 'D:/_domoticz/scripts/lua'   -- specify the path to domoticz where the JSON.lua file can be found

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
textformat = 'tdesc: wd dd mmm'
-- ### define  what to show in the domoticz text device
-- false => show multiple occurrences of a garbagetype (default)
-- true  => show one the next occurrence for a unique garbagetype
ShowSinglePerType = false
------------------------------------------------------------------------------------------------------------------------------------
-- Configuration for the Notificaton system:
-- IcalDesc:
--   @GARBAGETYPE@ ==> Will be replaced by the GarbageType definion from the WebSite
--   @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
IcalEnable = false -- false/true: When true, a garbagecalendar_Modulename.ics will be created in the datafilepath which can be used in a calendar application.
IcalTitle = 'GarbageCalendar' -- title of the calendar
IcalDesc = '@GARBAGETEXT@ wordt opgehaald.' -- text for the events in the calendar
IcalEvents = 10 -- max number of upcomming events to save to icalfile, but could be less when less events are provided by the website.
IcalNotify = 12 -- Notification Time in hours before event. 0=no notification
------------------------------------------------------------------------------------------------------------------------------------
-- Configuration for the Notificaton system:
NotificationEmailAdress = {'', ''} -- Specify multiple Email Addresses for the notifications. Leave empty to skip email notification
Notificationsystem = '' -- Specify notification system eg "telegram/pushover/gcm/http/kodi/lms/nma/prowl/pushalot/pushbullet/pushsafer" leave empty to skip
Notificationscript = '' -- Specify personal notification script/command eg:  lua sendmessage.lua "@TEXT@"  (where @TEXT@ will be replaced by the notification text.)
--                                                                                                                     It also supports: @GARBAGETYPE@; @GARBAGEDATE@; @GARBAGETEXT@
-- Define how the title and bodytext should look
-- @DAY@         ==> Will be replaced by notificationtoday; notificationtomorrow; notificationlonger depending on the days difference.
-- @GARBAGETYPE@ ==> Will be replaced by the GarbageType definition from the WebSite
-- @GARBAGEDATE@ ==> Will be replaced by the pickup date found on the schedule data
-- @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
-- @REMINDER@    ==> Will be set to "" for first notification and "notificationreminder" for the reminder run
-- @TEXT@        ==> Will be replaced by the finalised notificationtext and can be used in the notification script
--### Dutch example
notificationreminder = 'herinnering'
notificationtitle    = 'GarbageCalendar: @DAY@ de @GARBAGETEXT@ aan de weg zetten!'
notificationtext     = '@GARBAGETEXT@ wordt @DAY@ opgehaald! (@REMINDER@)'
notificationtoday    = 'vandaag'
notificationtomorrow = 'morgen'
notificationlonger   = 'over @DAYS@ dagen'
notificationdate     = 'wd dd mmmm yyyy' -- @GARBAGEDATE@ format -> Options are the same as available for textformat date options

--### English example
--~ notificationtitle    = 'GarbageCalendar: @GARBAGETEXT@ will be picked up in @DAY@!'
--~ notificationtext     = 'Put the @GARBAGETEXT@ out as it will be picked up @DAY@.!'
--~ notificationtoday    = 'today'
--~ notificationtomorrow = 'tomorrow'
--~ notificationlonger   = 'in @DAYS@ days'
--~ notificationdate     = 'wd dd mmmm yyyy'      -- Options are the same as available for textformat date options
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

garbagetype_cfg = {
   -- Add any missing records below this line
   ['pmd']        = {hour = 19, min = 22, daysbefore = 1, reminder = 0, text = 'pmd'},
   ['gft']        = {hour = 19, min = 22, daysbefore = 1, reminder = 0, text = 'gft'},
   ['papier']     = {hour = 19, min = 22, daysbefore = 1, reminder = 0, text = 'papier'},
   -- Add any missing records above this line
   --  "reloaddata" is used to start the background update process at this given time.
   ['reloaddata'] = {hour = 02, min = 30, daysbefore = 0, reminder = 0, text = 'trigger for reloading data from website into garbagecalendar.data'},
   ['dummy1']     = {hour = 02, min = 31, daysbefore = 0, reminder = 0, text = 'dummy to trigger testing'}
}

-------------------------------------------------------------------------
-- Language options Dutch
-- Date/day info:
-- used by getdate for formats "mmm" & "mm"
--
-- Pas deze tabellen aan indien de afvalverwerker andere afkortingen gebruikt.
daysoftheweek = {'zon', 'maa', 'din', 'woe', 'don', 'vri', 'zat'}
Longdaysoftheweek = {'zondag', 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag'}
ShortMonth = {'jan', 'feb', 'maa', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'}
LongMonth = {'januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'}
-- Wordt gebruikt om de maand afkorting van de ontvangen kalender data te vertalen naar het maandnummer. Meerder opties mogelijk.
InputMonth = {jan = 1, feb = 2, mrt = 3, maa = 3, apr = 4, mei = 5, jun = 6, jul = 7, aug = 8, sep = 9, okt = 10, nov = 11, dec = 12}
-------------------------------------------------------------------------
-- Language options English
-- Date/day info:
--~ daysoftheweek={"Sun","Mon","Tue","Wed","Thu","Fri","Sat"}
--~ Longdaysoftheweek={"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}
--~ ShortMonth={"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
--~ LongMonth={"January","February","March","April","May","June","July","August","September","October","November","December"}
-- Used to translate the month abbreviation back to the month number. Can contain multiple options for abbreviations.
--~ InputMonth={jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12}
