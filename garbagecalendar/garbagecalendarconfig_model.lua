-----------------------------------------------------------------------------
-- garbagecalendarconfig.lua
-----------------------------------------------------------------------------
-- Specify your information here as needed for your needs
myGarbageDevice = 'Container'      -- The Text devicename in Domoticz
ShowNextEvents = 3                 -- indicate the next x events to show in the TEXT Sensor in Domoticz
Zipcode = ''                       -- Your zipcode
Housenr = ''                       -- Your housnr
Housenrsuf = ''                    -- Your housnr suffix                    (Optional: a/b/c  etc)
Street=''                          -- Street name                           Only needed for: m_ophaalkalender-be
Hostname = ''                      -- Specify the hostname of your website. Only needed for: m_opzet ; m_opzet_api ;
                                   -- OR Specify the companycode for the m_ximmio.lua module. See m_ximmio.lua on how to find this code.

-- choose one of these modules
--websitemodule = "m_deafvalapp"
--websitemodule = "m_goeree-overflakkee"
websitemodule = "m_mijnafvalwijzer"
--websitemodule = "m_ophaalkalender-be"
--websitemodule = "m_opzet"
--websitemodule = "m_opzet_api"
--websitemodule = "m_westland"
--websitemodule = "m_ximmio"           --
--websitemodule = "m_zuidlimburg"

-- Switch on mydebug in case of issues and initially and check the domoticz log for any issues or missing
mydebug      = false  -- (true/false)
testdataload = false  -- (true/false)

-- Specify the appropriate directories (Raspberry Pi example)
datafilepath     = '/var/tmp'                           -- specify the directory where the garbagecalendar.data & garbagecalendar.log will be stored
scriptpath       = '/home/pi/domoticz/scripts/lua'      -- specify the directory for the main "script_time_garbagecalendar.lua" script
domoticzjsonpath = '/home/pi/domoticz/scripts/lua'      -- specify the path to domoticz where the JSON.lua file can be found
-- Specify the appropriate directories (Windows example)
--datafilepath     = 'D:/temp'                            -- specify the directory where the garbagecalendar.data & garbagecalendar.log will be stored
--scriptpath       = 'D:/_domoticz/scripts/lua'   -- specify the directory for this script
--domoticzjsonpath = 'D:/_domoticz/scripts/lua'   -- specify the path to domoticz where the JSON.lua file can be found

------------------------------------------------------------------------------------------------------------------------------------
-- ### define format for text device
   -- date options:
   --    wd   = weekday in 3 characters as defined in the daysoftheweek table below. eg Zon;Maa;Din
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
textformat = "tdesc: wd dd mmm"
-- ### define  what to show in the domoticz text device
   -- false => show multiple occurrences of a garbagetype (default)
   -- true  => show one the next occurrence for a unique garbagetype
ShowSinglePerType = false

------------------------------------------------------------------------------------------------------------------------------------
-- Configuration for the Notificaton system:
NotificationEmailAdress = {'',''}  -- Specify multiple Email Addresses for the notifications. Leave empty to skip email notification
Notificationsystem = ''            -- Specify notification system eg "telegram/pushover/gcm/http/kodi/lms/nma/prowl/pushalot/pushbullet/pushsafer" leave empty to skip
Notificationscript = ''            -- Specify personal notification script/command eg:  lua sendmessage.lua "@TEXT@"  (where @TEXT@ will be replaced by the notification text.)
-- Define how the title and bodytext should look
-- @DAY@         ==> Will be replaced by notificationtoday; notificationtomorrow; notificationlonger depending on the days difference.
-- @GARBAGEDATE@ ==> Will be replaced by the pickup date found on the schedule data
-- @GARBAGETEXT@ ==> Will be replaced by the text from garbagetype_cfg[].text field
--### Dutch example
notificationtitle    = 'GarbageCalendar: @DAY@ de @GARBAGETEXT@ aan de weg zetten!'
notificationtext     = '@GARBAGETEXT@ wordt @DAY@ opgehaald!'
notificationtoday    = 'vandaag'
notificationtomorrow = 'morgen'
notificationlonger   = 'over @DAYS@ dagen'
--### English example
--~ notificationtitle    = 'GarbageCalendar: @GARBAGETEXT@ will be picked up in @DAY@!'
--~ notificationtext     = 'Put the @GARBAGETEXT@ out as it will be picked up @DAY@.!'
--~ notificationtoday    = 'today'
--~ notificationtomorrow = 'tomorrow'
--~ notificationlonger   = 'in @DAYS@ days'

------------------------------------------------------------------------------------------------------------------------------------
-- ### define a line for each garbage type returned by the webrequest.
-- Look at the Domoticz log for any missing records as they will be displayed there and can be just copy/pasted in.
-- Fields description:
   -- hour & min ==> the time the check needs to be performed and notification send when daysbefore is true
   -- daysbefore ==> 0 means that the notification is send on the day of the planned garbage collection
   -- daysbefore ==> X means that the notification is send X day(s) before the day of the planned garbage collection
   -- reminder   ==> Will send a second reminder after x hours. 0=no reminder (needs to be in the same day!)
   -- text       ==> define the text for the notification and Text Device.
-- The "reloaddata" entry is required to run the background process to update the data one time per day.
-- The "dummy" entry can be used to force reading the data, update the Domoticz text device and see if there are any errors or missing garbadge types.

garbagetype_cfg = {
-- Add any missing records below this line
   ["pmd"]                              ={hour=19,min=22,daysbefore=1,reminder=0,text="pmd"},
   ["gft"]                              ={hour=19,min=22,daysbefore=1,reminder=0,text="gft"},
   ["papier"]                           ={hour=19,min=22,daysbefore=1,reminder=0,text="papier"},
-- Add any missing records above this line
   ["reloaddata"]                       ={hour=02,min=30,daysbefore=0,reminder=0,text="trigger for reloading data from website into garbagecalendar.data"},
   ["dummy1"]                           ={hour=02,min=30,daysbefore=0,reminder=0,text="dummy to trigger testing"}}


-------------------------------------------------------------------------
-- Language options Dutch
-- Date/day info:
daysoftheweek={"zon","maa","din","woe","don","vri","zat"}
ShortMonth={"jan","feb","maa","apr","mei","jun","jul","aug","sep","okt","nov","dec"}
LongMonth={"januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december"}
-------------------------------------------------------------------------
-- Language options English
-- Date/day info:
--~ daysoftheweek={"Sun","Mon","Tue","Wed","Thu","Fri","Sat"}
--~ ShortMonth={"Jan","Feb","Mar","Apr","Mei","Jun","Jul","Aug","Sep","Okt","Nov","Dec"}
--~ LongMonth={"January","February","March","April","May","June","July","August","September","October","November","December"}
