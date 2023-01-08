# Testing / Debugging

In case you have issues with your setup you can do the following steps described below. When you still can't figure out the issue you have, you can also zip up the below defined **log & data** files and your **garbagecalendarconfig.lua** file and Email them to my GitHub Email address so I can check what is happening. :) 

1. ### Check first your logfiles.
   * Check these files exist in the directory your defined in garbagecalendarconfig.lua in variable **datafilepath** whether they exist and/or contain errors:  
     * **garbage.data** => the file containing the result of the webupdate process by the module.
     * **garbage_run_modulename.log** => log of the last time the script was ran
     * **garbage_run_update_modulename.log** => log of the last time the script ran the update process
     * **garbage_web_modulename.log** => log of the backgroung webupdate process.

   * In case any of these is missing:
     * Check the **domoticz log**, **garbage_run_modulename.log** and **garbage_run_update_modulename.log**  for any errors.
     * Check your directory name and the security/access for this directory, in case the files do not exist.
     * Set any/all of these debugging options to true to test the specified part of the logic:
      ```
      -- Switch on mydebug in case of issues and initially and check the domoticz log for any issues or missing
      mydebug      = false      -- (true/false) -- run the script as it normally does when any of the scheduled times is the current time
      testdataload = false      -- (true/false) -- run the web update module with each run for testing/debugging purposes
      testnotification = false  -- (true/false) -- this will trigger a test notification for the first record for testing the notification system
      ```
     * Also check  **garbage.data** for valid table information looking like this format:
     ```
     return {
     -- Table: {1}
     {
        {2},
        {3},
     },
     -- Table: {2}
     {
        ["garbagetype"]="pmd",
        ["wdesc"]="Plastic, Metalen en Drankkartons",
        ["garbagedate"]="2020-02-11",
     },
     -- Table: {3}
     {
        ["garbagetype"]="gft",
        ["wdesc"]="Groente, Fruit en Tuinafval",
        ["garbagedate"]="2020-02-13",
     },
     }
     ```
     
1. ### Raspberry PI with Debian Buster+
   The default for tls is changed to TLSv1.2 which could give some issue on some sites not supporting this version yet. In case there is an issue retrieving the data for your GarbageCalender you could try updating file **/etc/ssl/openssl.cnf** to:
   ```
   [system_default_sect]
   #MinProtocol = TLSv1.2
   MinProtocol = TLSv1.0
   ```
   .. and reboot the system to activate this setting.

1. ### When the datafile is available and looking good, then check the **garbage_run_modulename.log** ,  **garbage_run_update_modulename.log** and **Domoticz log** for any messages in case the text devices isn't updated. Normally it should say something like this in case the new text is the same as the current text (Domoticz text device will still be updated so you can see that the script has ran):
    ```
    @GarbageCalendar(m_mijnafvalwijzer): ==> found schedule:Plastic, Metalen en Drankkartons: Din 11 feb ; Groente, Fruit en Tuinafval: Don 13 feb ; Plastic, Metalen en Drankkartons: Din 18 feb ;
    @GarbageCalendar(m_mijnafvalwijzer): No updated text for TxtDevice.
    ```
    ... and this when there is a update to be made for the text device:
    ```
    @GarbageCalendar(m_mijnafvalwijzer): ==> found schedule:Plastic, Metalen en Drankkartons: Din 11 feb ; Groente, Fruit en Tuinafval: Don 13 feb ; Plastic, Metalen en Drankkartons: Din 18 feb ;
    @GarbageCalendar(m_mijnafvalwijzer): Update device from:
    Groente, Fruit en Tuinafval: Don 6 feb
    Plastic, Metalen en Drankkartons: Din 11 feb
    Groente, Fruit en Tuinafval: Don 13 feb
    replace with:
    Plastic, Metalen en Drankkartons: Din 11 feb
    Groente, Fruit en Tuinafval: Don 13 feb
    Plastic, Metalen en Drankkartons: Din 18 feb
    ```
    When the Domoticz device name is invalid you see something like this:
    ```
    @GarbageCalendar(m_mijnafvalwijzer): Error: Couldn't get the current data from Domoticz text device Container
    ```
1. ### Notification issues:
   1. Ensure a record for each garbagetype is added to the garbagetype_cfg table. The log will contain a Warning section when you are missing any record in this table. (see Setup page section 4.iv)
   1. Ensure you defined an appropriate notification service configured and tested in Domoticz, as defined in Setup paragraph 5.
   1. Switch on testnotification to force the testing of the notifications:
      ```
         testnotification = false  -- (true/false) -- this will trigger a test notification for the first record for testing the notification system
      ```


1. additional checking steps will be added as people start using it and issues are encountered. :-)
