<?php
$debug = 0;

if (strstr($_SERVER['HTTP_USER_AGENT'], "Mozilla") && startsWith($_SERVER['REMOTE_ADDR'], "192.168.40.")) {
    $debug=1;
}

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 'on');
}

$appsecret = $_REQUEST["appsecret"];
$geoy = $_REQUEST["geoy"]; // lat
$geox = $_REQUEST["geox"]; // lon
$arduinoparam = $_REQUEST["arduinoparam"];

$arduino_baseurl = "http://arduino.steinkopf.net:1080/";
//$arduino_baseurl = "http://www.heise.de/";

$stkhomey = 48.109535;
$stkhomex = 11.622306;
$maxy = 48.109870;
$maxx = 11.622764;
$maxdiffy = $maxy - $stkhomey;
$maxdiffx = $maxx - $stkhomex;
$diffy = abs($geoy - $stkhomey);
$diffx = abs($geox - $stkhomex);

if ($debug) {
    print "geoy = $geoy ";
    print "geox = $geox<br>\n";
    print "maxdiffy = $maxdiffy ";
    print "maxdiffx = $maxdiffx<br>\n";
    print "diffy = $diffy ";
    print "diffx = $diffx<br>\n";
}

if ($diffx > $maxdiffx || $diffy > $maxdiffy) {
    reject();
}

if ($appsecret != "plUwPcIE82vKwHUVnGiS4o5J6o")  {
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

/*
$response = http_get($arduino_url, array("timeout"=>1), $info);
print_r($info);
*/



function reject() {
	print "bad";
	exit(1);
}

function startsWith($haystack, $needle) {
    // search backwards starting from haystack length characters from the end
    return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}
?>
