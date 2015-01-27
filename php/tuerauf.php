<?php
/*
Installieren mit:
rsync -av php/ root@backendsrv:/var/www/backend/tuerauf/
ssh root@backendsrv chown -R www-data:www-data /var/www/backend/tuerauf/data

Änderungen holen mit:
rsync -av root@backendsrv:/var/www/backend/tuerauf/ php/

Aufruf:
https://backendsrv.steinkopf.net:39931/tuerauf/tuerauf.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=C2EE441B-294F-4AFC-80A8-37122BFAD03B&geoy=48.109536&geox=11.622306&arduinoparam=1111
 */

require 'incl/lib.php';
check_appsecret();

require 'incl/users.php';

loadUserlist();

$installationid = $_REQUEST["installationid"];
$username = getUsername($installationid);
if (!$username) {
        reject("user unknown");
}


$geoy = $_REQUEST["geoy"]; // lat
$geox = $_REQUEST["geox"]; // lon
$arduinoparam = $_REQUEST["arduinoparam"];

$arduino_baseurl = "http://arduino.steinkopf.net:1080/";

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
    reject("not here");
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
$remote = $_SERVER['REMOTE_ADDR'].(array_key_exists('HTTP_X_FORWARDED_FOR', $_SERVER) ? "/".$_SERVER['HTTP_X_FORWARDED_FOR'] : "");
$logstr = $_SERVER['SCRIPT_NAME'].": user $username from $remote got response $response (installationid=$installationid)";
error_log($logstr, 0);
//if (strpos($logstr, 'OFFEN') !== FALSE) {
        error_log($logstr, 1, "dirk@wor.net");
//}

print $response;
exit(0);




?>
