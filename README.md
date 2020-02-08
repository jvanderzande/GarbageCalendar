# Welcome to the GarbageCalendar site for Domoticz
<b>/##### DRAFT ###################################</b>

This Domoticz time script will retrieve the garbage collection calendar information for your home address, update a TEXT device in Domoticz and optionally send you a notification at the specified time(s) 0-x days before the event.<br>
This repository is a replacement for the initial repository I started: https://github.com/jvanderzande/mijnafvalwijzer. The main changes are:
  * the old repository had separate scripts for each supported website where this repository is modular, making it easier to maintain and add new website modules for other municipalities.
  * It has a single main script called **"script_time_garbagecalendar.lua"**
  * Subdirectory **"garbagecalendar"** contains all available modules for the supported municipality websites and your personal configuration file **"garbagecalendarconfig.lua"**.
  * The selected module scripts is ran one time per day in the background to get the website data and save that to a datafile which is used by the mainscript at the requested times. This will ensure that the Domoticz event system isn't hold up be the retrieval process!

Detailed [<i>Setup instructions</i>](Setup) can be found in the Wiki.
