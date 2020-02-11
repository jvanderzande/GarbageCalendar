# Welcome to the GarbageCalendar site for Domoticz
<b>**** currently in Beta ****** </b><br>
![Domotics text device](/domotextdevice.png)

This is a project to retrieve the Garbage calendar information for your home address by means of  a Domoticz time script which will update a Domoticz TEXT device and optionally send you a notification at the specified time(s) 0-x days before the event.<br>
This repository is a replacement for the initial repository I started: https://github.com/jvanderzande/mijnafvalwijzer. <br>
The main changes are:
  * the old repository had separate scripts for each supported website where this repository is modular, making it easier to maintain and add new website modules for other municipalities.
  * It has a single main script called **"script_time_garbagecalendar.lua"**
  * Subdirectory **"garbagecalendar"** contains all available modules for the supported municipality websites and your personal configuration file **"garbagecalendarconfig.lua"**.
  * The selected module scripts is ran one time per day in the background to get the website data and save that to a datafile which is used by the mainscript at the requested times. This will ensure that the Domoticz event system isn't hold up be the retrieval process!

Detailed [<i>Setup instructions</i>](../../wiki/Setup) can be found in the [<i>WiKi</i>](../../wiki).

garbagecalendar is a free and open source application written in lua and distributed under the [GNU General Public License](LICENSE).
