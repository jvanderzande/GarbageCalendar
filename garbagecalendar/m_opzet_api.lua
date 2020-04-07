-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet_api.lua
----------------------------------------------------------------------------------------------------------------
ver="20200407-1100"
websitemodule="m_opzet_api"
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
spath=script_path()
dofile (script_path() .. "generalfuncs.lua") --

--------------------------------------------------------------------------
-- get date, return a standard format and calculate the difference in days
function getdate(i_garbagetype_date, stextformat)
   local curTime = os.time{day=timenow.day,month=timenow.month,year=timenow.year}
   -- get day,month,year from the i_garbagetype_date
   garbageyear,garbagemonth,garbageday=i_garbagetype_date:match("(%d-)-(%d-)-(%d-)$")
   if (garbageday == nil or garbagemonth == nil or garbageyear == nil) then
      print ('Error: No valid date found in i_garbagetype_date: ' .. i_garbagetype_date)
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
   local sQuery   = 'curl "'..url..'" 2>'..afwlogfile:gsub('_web_','_web_err_')
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
   dprint('---- end web data ------------------------------------------------------------------------')
   os.remove(afwlogfile:gsub('_web_','_web_err_'))
   if ( Web_Data == "" ) then
      dprint("Error: Empty result from curl command")
      return ""
   end
   return Web_Data
end
--------------------------------------------------------------------------
-- Perform the actual update process for the given address
function Perform_Update()
   function processdata(ophaaldata)
      for i = 1, #ophaaldata do
         record = ophaaldata[i]
         if type(record) == "table" then
            web_garbageid = record["afvalstroom_id"]
            web_garbagetype = ""
            web_garbagedate = record["ophaaldatum"]
            wnameType = ""
            for i = 1, #garbagedata do
               record = garbagedata[i]
               if type(record) == "table" then
                  if web_garbageid == record["id"] then
                     web_garbagetype = record["title"]
                     break
                  end
               end
            end
            dprint ("  web_garbageid:"..web_garbageid..' Afvalsoort : ' .. web_garbagetype)
            local dateformat = "????????"
            -- Get days diff
            dateformat, daysdiffdev = getdate(web_garbagedate, "yyyy-mm-dd")
            if daysdiffdev == nil then
               dprint ('Invalid date from web for : ' .. web_garbagetype..'   date:'..web_garbagedate)
               return
            end
            if ( daysdiffdev >= 0 ) then
               garbagedata[#garbagedata+1] = {}
               garbagedata[#garbagedata].garbagetype = web_garbagetype
               garbagedata[#garbagedata].garbagedate = dateformat
               -- field to be used when WebData contains a description
               -- garbagedata[#garbagedata].wdesc = ....
            end
         end
      end
   end
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   -- Get the information for the specified address specifically the bagId for the subsequent calls
   Web_Data=perform_webquery('https://'..Hostname..'/rest/adressen/'..Zipcode..'-'..Housenr)
   if Web_Data == "" then
      return
   end
   if Web_Data == "" then
      return
   end
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Check your Zipcode and Housenr as we get an [] response.")
      return
   end
   adressdata = JSON:decode(Web_Data)
   -- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
   for i = 1, #adressdata do
      record = adressdata[i]
      dprint("Address options: "..record["huisletter"].."="..Housenrsuf.."->"..record["bagId"])
      if type(record) == "table" then
         if Housenrsuf == record["huisletter"] then
            bagId = record["bagId"]
            break
         end
      end
   end
   if bagId == nil or bagId == "" then
      print("Error: No bagId retrieved...  stopping execution.")
      return
   end
   dprint("bagId:"..bagId)
   -- get the Afvalstromen information for all possible garbagetypeid's for this address(bagId)
   Web_Data=perform_webquery('https://'..Hostname..'/rest/adressen/'..bagId..'/afvalstromen')
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Unable to retrieve Afvalstromen information...  stopping execution.")
      return
   end
   garbagedata = JSON:decode(Web_Data)
   -- get the Kalender information for this address(bagId) for the current year
   local Web_Data=perform_webquery('https://'..Hostname..'/rest/adressen/'..bagId..'/ophaaldata')
   dprint('---- web data ophaaldata -----------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   if ( Web_Data:sub(1,2) == "[]" ) then
      print("Error: Unable to retrieve the Kalender information for this address...  stopping execution.")
      return
   end
   jdata = JSON:decode(Web_Data)
   -- get the ophaaldagen tabel for the coming scheduled pickups
   if type(jdata) ~= "table" then
      print("Error: Empty Kalender found stopping execution.")
      return
   end
   -- process the data
   dprint("- start looping through received data -----------------------------------------------------------")
   processdata(jdata)
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
Hostname = arg[7] or ""   -- Required!
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
   -- Load JSON.lua
   if pcall(loaddefaultjson) then
      dprint('Loaded JSON.lua.' )
   else
      dprint('Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. domoticzjsonpath..'.')
      dprint('Error: Please check your setup and try again.' )
      os.exit() -- stop execution
   end
   dprint("!!! perform background update to ".. afwdatafile .. " for Zipcode " .. Zipcode .. " - "..Housenr..Housenrsuf .. "  (optional) Hostname:"..Hostname)
   Perform_Update()
   dprint("=> Write data to ".. afwdatafile)
   table.save( garbagedata, afwdatafile )
end
