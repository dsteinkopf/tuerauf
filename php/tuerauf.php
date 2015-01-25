<?php

require 'incl/lib.php';

$geoy = $_REQUEST["geoy"]; // lat
$geox = $_REQUEST["geox"]; // lon
$arduinoparam = $_REQUEST["arduinoparam"];

$arduino_baseurl = "http://arduino.steinkopf.net:1080/";


check_appsecret();


$stkhomey = 48.109535;
$stkhomex = 11.622306;
$maxdist = 80; // meter
$dist = distance($stkhomey, $stkhomex, $geoy, $geox, "K") * 1000;

if ($debug) {
    print "geoy = $geoy ";
    print "geox = $geox<br>\n";
    print "dist = $dist meter<br>\n";
}

if ($dist > $maxdist) {
    reject();
}

$arduino_url = $arduino_baseurl . $arduinoparam;
if ($debug) print "arduino_url=$arduino_url<br>\n";
$opts = array('http' =>
    array(
        'timeout' => 15, // seconds
    )
);
$response = file_get_contents($arduino_url, false, stream_context_create($opts));
if ($response === false) {
    print "bad request";
    exit(2);
}

print $response;
exit(0);




?>
