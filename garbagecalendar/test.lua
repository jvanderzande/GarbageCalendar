-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer.lua
----------------------------------------------------------------------------------------------------------------
ver="20200916-1600"
websitemodule="m_mijnafvalwijzer"
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
-- Link to WebSite:  https://mijnafvalwijzer.nl/nl/postcode/huisnr--
-------------------------------------------------------
-- get script directory
function script_path()
   return arg[0]:match('.*[/\\]') or "./"
end
-- only include when run in separate process
if scriptpath == nil then
   dofile (script_path() .. "generalfuncs.lua") --
end
--~ GetDateFromInput("vrijdag 26 november","[^%s]+%s+([^%s]+)%s+([^%s]+)%s-(%d-)$",{"dd","mmm","yyyy"})
--~ GetDateFromInput("vrijdag 26 november 2021","[^%s]+%s+([^%s]+)%s+([^%s]+)%s-(%d-)$",{"dd","mmm","yyyy"})
--~ GetDateFromInput("13-01-2020"         ,"([^-]+)-([^-]+)-([^-]+)"   ,{"dd","mm","yyyy"})
--~ GetDateFromInput("2020-01-02"         ,"([^-]+)-([^-]+)-([^-T]+)"   ,{"yyyy","mm","dd"})
--~ GetDateFromInput("2020-04-08T00:00:00","([^-]+)-([^-]+)-([^-T]+)"   ,{"yyyy","mm","dd"})
--~ GetDateFromInput("7 januari"          ,"([^%s]+)%s+([^%s]+)%s-(%d-)$"    ,{"dd","mmm","yyyy"})
--~ GetDateFromInput("7 januari 2021"     ,"([^%s]+)%s+([^%s]+)%s-(%d-)$"    ,{"dd","mmm","yyyy"})
