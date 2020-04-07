-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_zuidlimburg.lua
----------------------------------------------------------------------------------------------------------------
ver="20200407-1100"
websitemodule="m_zuidlimburg"
-- Link to WebSite:  https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=AAAA99&nr=999&t
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
dofile (script_path() .. "generalfuncs.lua") --

-------------------------------------------------------
-- dprint function to format log records
function dprint(text)
   print("@"..(websitemodule or "?")..":"..(text or "?"))
end

-------------------------------------------------------
-- round function
function Round(num, idp)
   return tonumber(string.format("%." ..(idp or 0).. "f", num))
end

--------------------------------------------------------------------------
-- get date, return a standard format and calculate the difference in days
function getdate(i_garbagetype_date, stextformat)
   local curTime = os.time{day=timenow.day,month=timenow.month,year=timenow.year}
   local MON={januari=1,februari=2,maart=3,april=4,mei=5,juni=6,juli=7,augustus=8,september=9,oktober=10,november=11,december=12}
   local garbageyear =timenow.year
   local garbageday  =timenow.day
   local garbagemonth=timenow.month
   -- check if date in variable i_garbagetype_date contains "vandaag" in stead of a valid date -> use today's date
   if i_garbagetype_date == "vandaag" then
      -- use the set todays info
   else
      -- get day,month,year from the i_garbagetype_date
      garbageday, s_garbagemonth=i_garbagetype_date:match("(%d+) (%a-) %d+")
      if (garbageday == nil or s_garbagemonth == nil) then
         print ('Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
         return
      end
      garbagemonth = MON[s_garbagemonth]
      if garbagemonth == nil then
         print ('Error: No valid month found for abbreviation: ' .. s_garbagemonth..' adapt the line: "local MON={" to correct it.')
         return 0
      end
   end
   if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
      dprint ('Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
      return
   end
   local garbageTime = os.time{day=garbageday,month=garbagemonth,year=garbageyear}
   local diffdays  = Round(os.difftime(garbageTime, curTime)/86400,0) -- 1 day = 86400 seconds
   stextformat = stextformat:gsub('dd',garbageday)
   stextformat = stextformat:gsub('mm',garbagemonth)
   stextformat = stextformat:gsub('yyyy',garbageyear)
   stextformat = stextformat:gsub('yy',tostring(garbageyear):sub(3,4))
   dprint("...-> diff:".. diffdays.. "  garbageyear:"..tostring(garbageyear).."  garbagemonth:"..tostring(garbagemonth).."  garbageday:"..tostring(garbageday))   --
   -- return standard date (yyyy-mm-dd) and diffdays
   return stextformat, diffdays
end
--------------------------------------------------------------------------
-- Do the actual webquery, retrieving data from the website
function perform_webquery(url)
   local sQuery   = 'curl '..url..' 2>'..afwlogfile:gsub('_web_','_web_err_')
   dprint("sQuery="..sQuery)
   local handle=assert(io.popen(sQuery))
   local Web_Data = handle:read('*all')
   handle:close()
   dprint('---- web data ----------------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- web err ------------------------------------------------------------------------')
   ifile = io.open(afwlogfile:gsub('_web_','_web_err_'), "r")
   dprint("Web_Err="..ifile:read("*all"))
   ifile:close()
   os.remove(afwlogfile:gsub('_web_','_web_err_'))
   if ( Web_Data == "" ) then
      dprint("Error: Empty result from curl command")
      return ""
   end
   return Web_Data
end
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery(' "https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc='..Zipcode..'&nr='..Housenr..Housenrsuf..'&t"')
   if Web_Data == "" then
      dprint("Error: Web_Data is empty.")
      return
   elseif string.find(Web_Data,'{"error":true}') ~= nil then
      dprint("Error: check Zipcode   Web_Data:" .. Web_Data)
      return
   end
   -- Read from the data table, and extract duration and distance in value. Divide distance by 1000 and duration_in_traffic by 60
   local web_garbagetype=""
   local web_garbagetype_date=""
   local web_garbagetype_changed=""
   local i = 0
   -- loop through returned result
   i = 0
   -- Retrieve part with the dates for pickup
   Web_Data=Web_Data:match('.-<div id="Afvalkalender1_pnlAfvalKalender">(.-)</div>')
   dprint('---- web data Afvalkalender section ----------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ----------------------------------------------------------------------------')
   dprint('- start looping through received data --------------------------------------------------------')
   local web_garbagetype=""
   local web_garbagedate=""
   local txt = ""
   local cnt = 0
--   Loop through all dates
   for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, '<td>.-%s(.-)</td><td>(.-)</td>') do
      i = i + 1
      if web_garbagetype~= nil and web_garbagedate ~= nil then
         -- first match for each Type we save the date to capture the first next dates
         dprint(i.." web_garbagetype:"..tostring(web_garbagetype).."   web_garbagedate:"..tostring (web_garbagedate))
         -- check whether the first nextdate for this garbagetype is already found
         dateformat, daysdiffdev = getdate(web_garbagedate, "yyyy-mm-dd")
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if ( daysdiffdev >= 0 ) then
            garbagedata[#garbagedata+1] = {}
            garbagedata[#garbagedata].garbagetype = web_garbagetype
            garbagedata[#garbagedata].garbagedate = dateformat
            garbagedata[#garbagedata].diff = daysdiffdev
         end
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date("*t")
-- get paramters from the commandline
domoticzjsonpath=arg[1]
Zipcode = arg[2]
Housenr = arg[3]
Housenrsuf = arg[4]
afwdatafile = arg[5]
afwlogfile = arg[6]
Hostname = arg[7] or ""   -- Not needed
Street   = arg[8] or ""   -- Not needed
-- other variables
garbagedata = {}            -- array to save information to which will be written to the data file

dprint('#### '..os.date("%c")..' ### Start garbagekalerder module '.. websitemodule..' (v'..ver..')')
if domoticzjsonpath == nil then
   dprint("!!! domoticzjsonpath not specified! ...  script without paramaters?")
elseif Zipcode == nil then
   dprint("!!! Zipcode not specified!")
elseif Housenr == nil then
   dprint("!!! Housenr not specified!")
elseif Housenrsuf == nil then
   dprint("!!! Housenrsuf not specified!")
elseif afwdatafile == nil then
   dprint("!!! afwdatafile not specified!")
elseif afwlogfile == nil then
   dprint("!!! afwlogfile not specified!")
else
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
