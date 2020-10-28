-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_csv_file.lua
----------------------------------------------------------------------------------------------------------------
ver="20200916-1600"
websitemodule="m_csv_file"
--[[
This module requires an inputfile defined by this variable in the configfile:
input_csv_file = "garbagecalendar/garbage_input.csv"

--With the following format:--
garbagedate;garbagetype
20-8-2020;papier
23-8-2020;GFT
1-9-2020;Rest
10-9-2020;papier
21-9-2020;GFT
30-9-2020;Rest
3-10-2020;papier
4-10-2020;GFT
5-10-2020;Rest
--]]
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
-- only include when run in separate process
if scriptpath == nil then
   dofile (script_path() .. "generalfuncs.lua") --
end

-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   local txt=""
   local txtcnt = 0
   --
   dprint('---- check garbage_input.csv ----------------------------------------------------------------------------')
   if (exists(input_csv_file)) then
      dprint('input File '..input_csv_file.. ' found, check access.')
      if (not haveaccess(input_csv_file)) then
         dprint('No access to the file. Running->sudo chmod 777 '..input_csv_file)
         os.execute("sudo chmod 777 "..input_csv_file.." 2>nul")
         if (haveaccess(input_csv_file)) then
            dprint('Access fixed to the data file.')
         else
            dprint('Still no access. Please check the settings for '..input_csv_file.. ' and then try again.')
            return false
         end
      end
   else
      dprint('input File '..input_csv_file.. ' not found. exit process.')
      return false
   end

   dprint('---- Open garbage_input.csv ----------------------------------------------------------------------------')
   ifile = io.open(input_csv_file, "r")
   local Web_Data = ifile:read("*all")
   ifile:close()

   if Web_Data == "" then
      dprint("Error Web_Data is empty.")
      return
   end
   dprint('---- web data ----------------------------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ------------------------------------------------------------------------')
   -- Process received webdata.
   local web_garbagetype=""
   local web_garbagetype_date=""
   local web_garbagetype_changed=""
   local i = 0
   local pickuptimes = {}
   -- loop through returned result
   i = 0
   dprint('- start looping through received data ----------------------------------------------------')
   for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, '([^;\r\n]+);([^\r\n]+)') do
      i = i + 1
      dprint(i.." web_garbagetype:"..tostring(web_garbagetype or "?").."   web_garbagedate:"..tostring (web_garbagedate or "?"))
      if web_garbagetype~= nil and web_garbagedate ~= nil and web_garbagedate ~= "garbagedate" then
         web_garbagedesc = web_garbagedesc or ""
         -- first match for each Type we save the date to capture the first next dates
         --dprint(web_garbagetype,web_garbagedate)
         dateformat, daysdiffdev = GetDateFromInput(web_garbagedate,"(%d+)[-%s]+(%d+)[-%s]+(%d+)",{"dd","mm","yyyy"})
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if ( daysdiffdev >= 0 ) then
            pickuptimes[#pickuptimes+1] = {}
            pickuptimes[#pickuptimes].garbagetype = web_garbagetype
            pickuptimes[#pickuptimes].garbagedate = dateformat
            pickuptimes[#pickuptimes].diff = daysdiffdev
            -- field to be used when Web_Data contains a description
            pickuptimes[#pickuptimes].wdesc = web_garbagedesc
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
            garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
         end
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date("*t")
-- get paramters from the commandline
domoticzjsonpath = domoticzjsonpath or arg[1]
Zipcode = Zipcode or arg[2]
Housenr = Housenr or arg[3] or ""
Housenrsuf = Housenrsuf or arg[4]
afwdatafile = datafile or arg[5]
afwlogfile = weblogfile or arg[6]
Hostname = (Hostname or arg[7]) or ""   -- Not needed
Street = (Street or arg[8]) or ""       -- Not needed
-- other variables
garbagedata = {}            -- array to save information to which will be written to the data file

dprint('#### '..os.date("%c")..' ### Start garbagecalendar module '.. websitemodule..' (v'..ver..')')
dprint("!!! perform update to ".. afwdatafile)
Perform_Update()
dprint("=> Write data to ".. afwdatafile)
table.save( garbagedata, afwdatafile )
