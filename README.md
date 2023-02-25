This is a project to retrieve the Garbage calendar information for your home address by means of  a Domoticz time script which will update a Domoticz TEXT device and optionally send you a notification at the specified time(s) 0-x days before the event.<br>
This repository is a replacement for the initial repository I started: https://github.com/jvanderzande/mijnafvalwijzer.<br>
The main changes are:
  * This repository is modular making it easier to maintain and add new website modules for other municipalities.
  * It has a single main script called **"script_time_garbagecalendar.lua"**
  * It will run both as Time Event LUA script as DzVents script.
  * Subdirectory **"garbagecalendar"** contains all available modules for the supported municipality websites and your personal configuration file **"garbagecalendarconfig.lua"**.
  * The selected module scripts is ran one time per day in the background to get the website data and save that to a Datafile.
  * This Data file is used by the mainscript at the requested times.
  * Add your own LUA/DzVents logic for Notifications to e.g. switch on a RGB bulb in a particular color.
  * No hanging Domoticz event system, generating a "longer than 10 seconds" error when the website is unresponsive, as the Webupdate is running in the background in its own process.
  * The script has much more error checking and standard logging to make problem solving much simpler.
  * The main script can optionally create an ics calendar file which can be used by a calendar application.

## Check the Wiki for:
  * [How does it all work](../../wiki/x_Process)
  * [Modules](../../wiki/x_Available_modules)
  * [**Setup instructions**](../../wiki/x_Setup)
  * [Add own notification code](../../wiki/x_Notifications)
  * [**Test and Debugging instructions**](../../wiki/x_Testing)


**More information can be found or questions can asked here**:  
 [Domoticz forum thread:](https://www.domoticz.com/forum/viewtopic.php?f=61&t=31295)  
 [Github discussions section:](https://github.com/jvanderzande/GarbageCalendar/discussions)

**PullRequest for Fixes/Changes/Additions must be made against the development branch so it can be tested first. Thanks :-)**

GarbageCalendar is a free and open source application written in lua and distributed under the [GNU General Public License](LICENSE).
