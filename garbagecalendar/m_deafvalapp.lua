-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_deafvalapp.lua
----------------------------------------------------------------------------------------------------------------
ver="20200317-1600"
websitemodule="m_deafvalapp"
-- Link to WebSite:  https://huisvuilkalender.gemeentewestland.nl
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
spath=script_path()
dofile (script_path() .. "table_funcs.lua") --

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
   local garbageyear =timenow.year
   local garbageday  =timenow.day
   local garbagemonth=timenow.month
   -- check if date in variable i_garbagetype_date contains "vandaag" in stead of a valid date -> use today's date
   if i_garbagetype_date == "vandaag" then
      -- use the set todays info
   else
      -- get day,month,year from the i_garbagetype_date
      garbageday, garbagemonth, garbageyear=i_garbagetype_date:match("(%d-)-(%d-)-(%d+)$")
      if garbagemonth == nil then
         dprint ('Error: No valid month found for abbreviation: ' .. s_garbagemonth..' adapt the line: "local MON={" to correct it.')
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
   local sQuery   = 'curl "'..url..'" 2>nul'
   dprint("sQuery="..sQuery)
   local handle=assert(io.popen(sQuery))
   local Web_Data = handle:read('*all')
   handle:close()
   if ( Web_Data == "" ) then
      dprint("Error: Empty result from curl command")
      return ""
   end
   return Web_Data
end
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data=perform_webquery('http://dataservice.deafvalapp.nl/dataservice/DataServiceServlet?service=OPHAALSCHEMA&land=NL&postcode='..Zipcode..'&straatId=0&huisnr='..Housenr..''..Housenrsuf)
   if Web_Data == "" then
      dprint("Error Web_Data is empty.")
      return
   elseif string.find(Web_Data,'{"error":true}') ~= nil then
      dprint("Error check postcode   Web_Data:" .. Web_Data)
      return
   end
   -- Read from the data table, and extract duration and distance in value. Divide distance by 1000 and duration_in_traffic by 60
   local web_garbagetype=""
   local web_garbagetype_date=""
   local web_garbagetype_changed=""
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   dprint('---- web data ----------------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   dprint('- start looping through received data ----------------------------------------------------')
   for web_garbagetype, web_garbagedates in string.gmatch(Web_Data, '(.-);(.-)[\r\n|$]') do
      dprint(web_garbagetype)
      for web_garbagedate in string.gmatch(web_garbagedates, '(.-);') do
         if web_garbagetype~= nil and web_garbagedate ~= nil then
            -- first match for each Type we save the date to capture the first next dates
            --dprint(web_garbagetype,web_garbagedate)
            dateformat, daysdiffdev = getdate(web_garbagedate, "yyyy-mm-dd")
            -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
            if ( daysdiffdev >= 0 ) then
               pickuptimes[#pickuptimes+1] = {}
               pickuptimes[#pickuptimes].garbagetype = web_garbagetype
               pickuptimes[#pickuptimes].garbagedate = dateformat
               pickuptimes[#pickuptimes].diff = daysdiffdev
            -- field to be used when Web_Data contains a description
            -- pickuptimes[#pickuptimes].wdesc = ....
            end
         end
      end
   end
   dprint("- Sorting records.")
   local eventcnt = 0
   for x = 0,60,1 do
      for mom in pairs(pickuptimes) do
         if pickuptimes[mom].diff == x then
            garbagedata[#garbagedata+1] = {}
            garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
            garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
            -- field to be used when Web_Data contains a description
            --garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
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
   dprint("!!! domoticzjsonpath not specified!")
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
