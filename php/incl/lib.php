<?php

$debug = 0;

if (strstr($_SERVER['HTTP_USER_AGENT'], "Mozilla") && startsWith($_SERVER['REMOTE_ADDR'], "192.168.40.")) {
    $debug=1;
}

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 'on');
}

$arduino_baseurl = "http://arduino.steinkopf.net:1080/";

$stkhomey = 48.109535;
$stkhomex = 11.622306;

$stkhomey_min = 48.109388; // 48.109420;
$stkhomey_max = 48.109584;
$stkhomex_min = 11.622288;
$stkhomex_max = 11.622506; // 11.622456;


function check_appsecret()
{
        $appsecret = $_REQUEST["appsecret"];
        if ($appsecret != "plUwPcIE82vKwHUVnGiS4o5J6o")  {
                reject();
        }
}

function reject($msg = "bad")
{
	print $msg;
	exit(1);
}

function startsWith($haystack, $needle) {
    // search backwards starting from haystack length characters from the end
    return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}

function isNear($geoy, $geox) {
        global $stkhomey_min, $stkhomey_max, $stkhomex_min, $stkhomex_max;

        return $stkhomey_min <= $geoy && $geoy <= $stkhomey_max &&
                $stkhomex_min <= $geox && $geox <= $stkhomex_max;
}


/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
/*::                                                                         :*/
/*::  This routine calculates the distance between two points (given the     :*/
/*::  latitude/longitude of those points). It is being used to calculate     :*/
/*::  the distance between two locations using GeoDataSource(TM) Products    :*/
/*::                     													 :*/
/*::  Definitions:                                                           :*/
/*::    South latitudes are negative, east longitudes are positive           :*/
/*::                                                                         :*/
/*::  Passed to function:                                                    :*/
/*::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :*/
/*::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :*/
/*::    unit = the unit you desire for results                               :*/
/*::           where: 'M' is statute miles                                   :*/
/*::                  'K' is kilometers (default)                            :*/
/*::                  'N' is nautical miles                                  :*/
/*::  Worldwide cities and other features databases with latitude longitude  :*/
/*::  are available at http://www.geodatasource.com                          :*/
/*::                                                                         :*/
/*::  For enquiries, please contact sales@geodatasource.com                  :*/
/*::                                                                         :*/
/*::  Official Web site: http://www.geodatasource.com                        :*/
/*::                                                                         :*/
/*::         GeoDataSource.com (C) All Rights Reserved 2015		     :*/
/*::                                                                         :*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
function distance($lat1, $lon1, $lat2, $lon2, $unit) {

  $theta = $lon1 - $lon2;
  $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
  $dist = acos($dist);
  $dist = rad2deg($dist);
  $miles = $dist * 60 * 1.1515;
  $unit = strtoupper($unit);

  if ($unit == "K") {
    return ($miles * 1.609344);
  } else if ($unit == "N") {
      return ($miles * 0.8684);
    } else {
        return $miles;
      }
}

//echo distance(32.9697, -96.80322, 29.46786, -98.53506, "M") . " Miles<br>";
//echo distance(32.9697, -96.80322, 29.46786, -98.53506, "K") . " Kilometers<br>";
//echo distance(32.9697, -96.80322, 29.46786, -98.53506, "N") . " Nautical Miles<br>";

?>