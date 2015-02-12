<?php
/*
Aufruf:
https://backendsrv.steinkopf.net:39931/tuerauf/checkloc.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=03C085B2-D6C2-4172-A051-6BDB6ED93C12&geoy=48.109536&geox=11.622306
 */

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