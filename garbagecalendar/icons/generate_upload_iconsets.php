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

   GarbageCalendar will check whether "garbagecalendar_grey" already available is in DOmoticz, and else, when zip file is found
   in the icons directory, will upload it as custom icon to domoticz for you.
}
*/
// php.ini requires "extension=zip" to be enabled for this script to work!
//
// ================================================================================================
// Define here the ico directories that contain the different ico sets.
// The standard set of custom icons, with thanks to the Dashticz project for a copy of their set!!
create_ico_collection("original_icons");
// more modern ico set supplied arjantenhoopen: https://github.com/jvanderzande/GarbageCalendar/issues/43
create_ico_collection("modern_icons");


function create_ico_collection($dirname) {
	// loop through directory, find *.png and generate zip file for each
	print(" ----- Directory " . $dirname . " ---------------------------\n");
	$dir = new DirectoryIterator($dirname);
	foreach ($dir as $fileinfo) {
		if ($fileinfo->isDot()) continue;
		if (!$fileinfo->isFile()) continue;
		print("- " . $fileinfo->getFilename() . " => ");
		if (substr($fileinfo->getFilename(), -4) != ".png") continue;
		$name = substr($fileinfo->getFilename(), 0, -4);
		create_ico_zipfile($dirname, $name, $name);
	}
}

function create_ico_zipfile($dirname, $name, $text)
{
    $zip = new ZipArchive();
    $filename = "${name}.zip";

    if ($zip->open("$filename", ZipArchive::CREATE)!==true) {
        exit("cannot open <$filename>\n");
    }
    if (!file_exists("$dirname/${name}.png")) {
        exit("File missing: <$dirname/${name}.png>\n");
    }
    $zip->addFromString("icons.txt", "$name;garbagecalendar $text;Used by Garbagecalendar");
    $zip->addFile("$dirname/${name}.png", "${name}.png");
    $zip->addFile("$dirname/${name}.png", "${name}48_Off.png");
    $zip->addFile("$dirname/${name}.png", "${name}48_On.png");
    $zip->close();
    print(" $filename generated. \n");
}