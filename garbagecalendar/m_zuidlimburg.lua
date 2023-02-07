-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_zuidlimburg.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230207-1242'
websitemodule = 'm_zuidlimburg'
-- Link to WebSite:  https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=AAAA99&nr=999&t
--
-------------------------------------------------------
-- get script directory
function script_path()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
end
-- only include when run in separate process
if GC_scriptpath == nil then
   dofile(script_path() .. 'generalfuncs.lua') --
end
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
   dprint('---- web update ----------------------------------------------------------------------------')
   local Web_Data
   Web_Data = perform_webquery(' "https://www.rd4info.nl/NSI/Burger/Aspx/afvalkalender_public_text.aspx?pc=' .. Zipcode .. '&nr=' .. Housenr .. Housenrsuf .. '&t"')
   if Web_Data == '' then
      dprint('### Error: Web_Data is empty.')
      return
   elseif string.find(Web_Data, '{"error":true}') ~= nil then
      dprint('### Error: check Zipcode   Web_Data:' .. Web_Data)
      return
   end
   -- Process received webdata.
   local web_garbagetype = ''
   local web_garbagetype_date = ''
   local web_garbagetype_changed = ''
   local i = 0
   -- loop through returned result
   i = 0
   -- Retrieve part with the dates for pickup
   Web_Data = Web_Data:match('.-<div id="Afvalkalender1_pnlAfvalKalender">(.-)</div>')
   dprint('---- web data Afvalkalender section ----------------------------------------------------------')
   dprint(Web_Data)
   dprint('---- end web data ----------------------------------------------------------------------------')
   dprint('- start looping through received data --------------------------------------------------------')
   local web_garbagetype = ''
   local web_garbagedate = ''
   local txt = ''
   local cnt = 0
   --   Loop through all dates
   for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, '<td>.-%s(.-)</td><td>(.-)</td>') do
      i = i + 1
      if web_garbagetype ~= nil and web_garbagedate ~= nil then
         -- first match for each Type we save the date to capture the first next dates
         dprint(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
         -- check whether the first nextdate for this garbagetype is already found
         dateformat, daysdiffdev = GetDateFromInput(web_garbagedate, '([%d]+)%s+([^%s]+)%s-(%d-)$', {'dd', 'mmm', 'yyyy'})
         -- When days is 0 or greater the date is today or in the future. Ignore any date in the past
         if (daysdiffdev >= 0) then
            garbagedata[#garbagedata + 1] = {}
            garbagedata[#garbagedata].garbagetype = web_garbagetype
            garbagedata[#garbagedata].garbagedate = dateformat
            garbagedata[#garbagedata].diff = daysdiffdev
         end
      end
   end
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date('*t')
-- get paramters from the commandline
Zipcode = Zipcode or arg[1]
Housenr = Housenr or arg[2] or ''
Housenrsuf = Housenrsuf or arg[3]
afwdatafile = datafile or arg[4]
afwlogfile = weblogfile or arg[5]
Hostname = (Hostname or arg[6]) or '' -- Not needed
Street = (Street or arg[7]) or '' -- Not needed
-- other variables
garbagedata = {} -- array to save information to which will be written to the data file

dprint('#### ' .. os.date('%c') .. ' ### Start garbagecalendar module ' .. websitemodule .. ' (v' .. ver .. ')')
if Zipcode == nil then
   dprint('!!! Zipcode not specified!')
elseif Housenr == nil then
   dprint('!!! Housenr not specified!')
elseif Housenrsuf == nil then
   dprint('!!! Housenrsuf not specified!')
elseif afwdatafile == nil then
   dprint('!!! afwdatafile not specified!')
elseif afwlogfile == nil then
   dprint('!!! afwlogfile not specified!')
else
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. Hostname)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
end
