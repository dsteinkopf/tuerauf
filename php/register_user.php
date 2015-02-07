<?php
/*
Neue User anzeigen:
https://backend.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA

Neue User nach all kopieren (und dadurch aktivieren):
https://backend.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&activateallnew=WsI65yuGCkjcA

Einen User anlegen: (dazu vorher freischalten mit: cp -p data/userlistnew_empty.php data/userlistnew.php
https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=ii1&name=nn1


Ablauf Registrierung:
1. Admin schaltet Registrierung frei:
    cd ... && cp -p data/userlistnew_empty.php data/userlistnew.php
2. User registrieren sich mit App. D.h.
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=ii1&name=nn1&pin=1111
3. Admin zeigt User an:
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA
4. Admin aktiviert neue User:
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&activateallnew=WsI65yuGCkjcA
5. Admin schaltet Registrierung ab:
    cd ... && rm data/userlistnew.php
6. Admin zeigt User an:
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA
   */

require 'incl/lib.php';
check_appsecret();

require 'incl/users.php';

if ($debug) print "debug is on<br>";

$adminsecret = "WsI65yuGCkjcA";


$showusers = (array_key_exists("showusers", $_REQUEST) && $_REQUEST["showusers"] == $adminsecret);
$activateallnew = (array_key_exists("activateallnew", $_REQUEST) && $_REQUEST["activateallnew"] == $adminsecret);

$installationid = array_key_exists("installationid", $_REQUEST) ? $_REQUEST["installationid"] : "";
$name = array_key_exists("name", $_REQUEST) ? $_REQUEST["name"] : "";
$pin = array_key_exists("pin", $_REQUEST) ? $_REQUEST["pin"] : "";

if ($debug) print "installationid=$installationid<br>";
if ($debug) print "name=$name<br>";
if ($debug) print "pin=$pin<br>";

if ($installationid && $name && $pin) {
        User::createUser($name, $pin, $installationid);
        User::saveUserlist();
        print "saved: new, inactive";
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
                print "</td><td>";
                print $emph.$user->pin.$emph_end;
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