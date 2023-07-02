<?php
/*
   Script that will generate the required zip file for uploading custom icons to domoticz
   All it needs is a proper standard png file eg: garbagecalendar_grey.png
   The process will then generate the proper garbagecalendar_grey.zip file in  the icons sub directory, which will be uploaded
   automaticcally to Domoticz by Garbagecalendar when used in configuration eg:
      garbagetype_cfg = {
   	-- Add any missing records below this line
   	['paper'] = {hour = 19, min = 02, daysbefore = 1, reminder = 0, text = 'paper', icon = 'garbagecalendar_blue'},
   	['grey'] = {hour = 19, min = 02, daysbefore = 1, reminder = 0, text = 'grey', icon = 'garbagecalendar_grey'},
   	['green'] = {hour = 19, min = 02, daysbefore = 1, reminder = 0, text = 'green', icon = 'garbagecalendar_green'},
   	-- Add any missing records above this line
   	['reloaddata'] = {hour = 08, min = 23, daysbefore = 0, reminder = 0, text = 'trigger for reloading data from website into a file'},
   	['dummy1'] = {hour = 02, min = 31, daysbefore = 0, reminder = 0, text = 'dummy to trigger update of textdevice'}

   GarbageClerder will check whether "garbagecalendar_grey" already available is and else, when zip file is found
   in the icons directory, will be tried to upload it as custom icon to domoticz for you.
}
*/
// php.ini requires "extension=zip" to be enabled for this script to work!
//
// ================================================================================================
// Define here the iconname.png you have added and run the script to generate the required zipfile
create_ico_collection("garbagecalendar_Type-here-your-icon-name", "zwarte");
// ================================================================================================
/* standard set of custom icons, with thanks to the Dashticz project for a copy of their set!!
create_ico_collection("garbagecalendar_black", "zwarte bak");
create_ico_collection("garbagecalendar_blue", "blauwe bak");
create_ico_collection("garbagecalendar_brown", "bruine bak");
create_ico_collection("garbagecalendar_green", "groene bak");
create_ico_collection("garbagecalendar_grey", "grijze bak");
create_ico_collection("garbagecalendar_orange", "oranje bak");
create_ico_collection("garbagecalendar_red", "rode bak");
create_ico_collection("garbagecalendar_white", "witte bak");
create_ico_collection("garbagecalendar_yellow", "gele bak");
create_ico_collection("garbagecalendar_tree", "kerstbomen");
*/
//
function create_ico_collection($name, $text)
{
    $zip = new ZipArchive();
    $filename = "${name}.zip";

    if ($zip->open("".$filename, ZipArchive::CREATE)!==true) {
        exit("cannot open <$filename>\n");
    }
    if (!file_exists("${name}.png")) {
        exit("File missing: <${name}.png>\n");
    }
    $zip->addFromString("icons.txt", "$name;garbagecalendar $text;Used by Garbagecalendar");
    $zip->addFromString("${name}.png", "");
    $zip->addFile("${name}.png", "${name}48_Off.png");
    $zip->addFile("${name}.png", "${name}48_On.png");
    $zip->close();
    print("-1> $filename generated. \n");
}