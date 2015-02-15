<?php
/*
Aufruf:
BASEURL/checkloc.php?appsecret=APPSECRET&installationid=INST_ID&geoy=12.34567&geox=23.45678
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

$geoy = $_REQUEST["geoy"]; // lat
$geox = $_REQUEST["geox"]; // lon

if (isNear($geoy, $geox)) {
        print "near";
}
else {
        print "far";
}

exit(0);

?>