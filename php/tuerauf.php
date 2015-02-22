<?php
/*
Installieren mit:
rsync -av --exclude=config.php --exclude=data php/ root@backendsrv:/var/www/backend/tuerauf/
ssh root@backendsrv chown -R www-data:www-data /var/www/backend/tuerauf/data

Änderungen holen mit:
rsync -av --exclude=config.php --exclude=data root@backendsrv:/var/www/backend/tuerauf-test/ php/

Aufruf:
BASEURL/tuerauf.php?appsecret=APPSECRET&installationid=INST_ID&geoy=12.34567&geox=23.45678&pin=1111
 */

require 'config.php';
require 'incl/lib.php';
check_appsecret();

require 'incl/users.php';

$installationid = $_REQUEST["installationid"];
$user = User::getActiveUser($installationid);
if (!$user) {
        reject("user unknown");
}
$username = $user->username;
$userlfdid = $user->lfdid;


$geoy = $_REQUEST["geoy"]; // lat
$geox = $_REQUEST["geox"]; // lon
$pin = $_REQUEST["pin"];

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


$arduino_url = $arduino_baseurl . $pin . "/" . $userlfdid;

if (isNear($geoy, $geox)) {
        $arduino_url .= "/near";
}

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

logAndMail("user $username from $remote got response $response (installationid=$installationid)");

print $response;
exit(0);




?>
