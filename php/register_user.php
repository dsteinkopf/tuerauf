<?php
/*
Ablauf Registrierung:
1. User registrieren sich mit App. D.h.
    BASEURL/register_user.php?appsecret=APPSECRET&installationid=ii1&name=nn1&pin=1111
2. Admin zeigt User an:
    BASEURL/register_user.php?appsecret=APPSECRET&showusers=ADMINSECRET
3. Admin aktiviert neue User:
    BASEURL/register_user.php?appsecret=APPSECRET&showusers=ADMINSECRET&activateallnew=ADMINSECRET
4. Admin zeigt User an:
    BASEURL/register_user.php?appsecret=APPSECRET&showusers=ADMINSECRET
*/

require 'config.php';
require 'incl/lib.php';
check_appsecret();

require 'incl/users.php';

if ($debug) print "debug is on<br>";


$showusers = (array_key_exists("showusers", $_REQUEST) && $_REQUEST["showusers"] == $adminsecret);
$activateallnew = (array_key_exists("activateallnew", $_REQUEST) && $_REQUEST["activateallnew"] == $adminsecret);

$installationid = array_key_exists("installationid", $_REQUEST) ? $_REQUEST["installationid"] : "";
$name = array_key_exists("name", $_REQUEST) ? $_REQUEST["name"] : "";
$pin = array_key_exists("pin", $_REQUEST) ? $_REQUEST["pin"] : "";

if ($debug) print "installationid=$installationid<br>";
if ($debug) print "name=$name<br>";
if ($debug) print "pin=$pin<br>";

if ($installationid && $name && $pin) {
        $user = User::createUser($name, $pin, $installationid);
        User::saveUserlist();
        print "saved:";
        print ($user->new ? " new" : " changed");
        print ($user->active ? " active" : " inactive");
        if ($user->usernameOld) {
                logAndMail("user $user->usernameOld changed name to $user->username (installationid=$user->installationid)");
        }
        if ($user->pinOld) {
                logAndMail("user $user->username changed pin to $user->pin (installationid=$user->installationid)");
        }
}

if ($activateallnew) {
        User::activateAllNew();
        User::saveUserlist();
        print "done: activateallnew";
}

if ($showusers) {
        // jetzt das Ergebnis anzeigen:
        print "<table>\n<tr><th>installationid</th><th>name</td><th>pin</td><th>lfdid</td></tr>\n";
        foreach (User::getUserlist() as $installationid => $user) {

                $emph = $user->new ? "<b>" : "";
                $emph_end = $user->new ? "</b>" : "";
                $emph = $emph . (! $user->active ? "<i>" : "");
                $emph_end = (! $user->active ? "</i>" : "") . $emph_end;

                print "<tr><td>";
                print $emph.$user->installationid.$emph_end;
                print "</td><td>";
                print $emph.$user->username.$emph_end;
                print $user->usernameOld ? " (was: $user->usernameOld)" : "";
                print "</td><td>";
                print $emph.$user->pin.$emph_end;
                print $user->pinOld ? " (was: $user->pinOld)" : "";
                print "</td><td>";
                print $emph.$user->lfdid.$emph_end;
                print "</td></tr>\n";
        }
        print "</table>\n";

        print "<br>Aktive Pins an Arduino schicken:<br>";
        $pinlist = User::getPinList();
        // print_r($pinlist);
        $pins4arduino = implode('&',
                                array_map(function ($v, $k) { return $v; },
                                          $pinlist,
                                          array_keys($pinlist))
                                );
        $arduinourl = $arduino_baseurl."storepinlist?".$pins4arduino;
        print "<a href='$arduinourl'>$arduinourl</a><br>";
}


?>