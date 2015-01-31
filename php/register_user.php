<?php
/*
Neue User anzeigen:
https://backend.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA

Neue User nach all kopieren (und dadurch aktivieren):
https://backend.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&savenewtoall=WsI65yuGCkjcA

Einen User anlegen: (dazu vorher freischalten mit: cp -p data/userlistnew_empty.php data/userlistnew.php
https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=ii1&name=nn1


Ablauf Registrierung:
1. Admin schaltet Registrierung frei:
    cd ... && cp -p data/userlistnew_empty.php data/userlistnew.php
2. User registrieren sich mit App. D.h.
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=ii1&name=nn1
3. Admin zeigt User an:
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA
4. Admin speichert neue User nach all und aktiviert sie daurch:
    https://backendsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&savenewtoall=WsI65yuGCkjcA&showusers=WsI65yuGCkjcA
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
$savenewtoall = (array_key_exists("savenewtoall", $_REQUEST) && $_REQUEST["savenewtoall"] == $adminsecret);

$suffix = "new";
if ($showusers) {
        $suffix = "all";
}

loadUserlist($suffix);


$new_installationid = array_key_exists("installationid", $_REQUEST) ? $_REQUEST["installationid"] : "";
$new_name = array_key_exists("name", $_REQUEST) ? $_REQUEST["name"] : "";
$new_pin = array_key_exists("pin", $_REQUEST) ? $_REQUEST["pin"] : "";

if ($debug) print "installationid=$new_installationid<br>";
if ($debug) print "name=$new_name<br>";

if ($new_installationid && $new_name && $new_pin) {
        if ($suffix != "new") {
                reject("can't save to all");
        }
        $glob_userlist[$new_installationid] = array("name" => $new_name, "pin" => $new_pin);
        saveUserlist($suffix);
        print "saved_waiting";
}

if ($savenewtoall) {
        loadUserlist("new");
        $newuserlist = $glob_userlist;
        $glob_userlist = array();
        saveUserlist("new");

        loadUserlist();
        foreach($newuserlist as $installationid => $userarr) {
                $glob_userlist[$installationid] = $userarr;
        }
        saveUserlist();
        print "done_savenewtoall";
}

if ($showusers) {
        $userlist2display = $glob_userlist;
        loadUserlist("new");
        $userlistnew = $glob_userlist;

        // erstmal new und all für die Anzeige zusammenführen; markeren, was neu ist.
        foreach($userlistnew as $installationid => $usernewarr) {
                if (array_key_exists($installationid, $userlist2display)) {
                        // user, der "überschrieben" wurde
                        $useroldarr = $userlist2display[$installationid];
                        if ( ! array_key_exists("pin", $useroldarr)) {
                                $useroldarr["pin"] = "-";
                        }
                        if ($usernewarr["name"] != $useroldarr["name"]) {
                                $useroldarr["name_new"] = 1;
                                $useroldarr["name_orig"] = $useroldarr["name"];
                                $useroldarr["name"] = $usernewarr["name"];
                        }
                        if ($usernewarr["pin"] != $useroldarr["pin"]) {
                                $useroldarr["pin_new"] = 1;
                                $useroldarr["pin_orig"] = $useroldarr["pin"];
                                $useroldarr["pin"] = $usernewarr["pin"];
                        }
                        $userlist2display[$installationid] = $useroldarr;
                }
                else {
                        $usernewarr["user_new"] = 1;
                        $userlist2display[$installationid] = $usernewarr;
                }
        }

        // jetzt das Ergebnis anzeigen:
        print "<table>\n<tr><th>installationid</th><th>name</td><th>pin</td></tr>\n";
        foreach($userlist2display as $installationid => $userarr) {

                $bold_installationid = array_key_exists("user_new", $userarr);
                $bold_name = (array_key_exists("name_new", $userarr) || $bold_installationid);
                $bold_pin = (array_key_exists("pin_new", $userarr) || $bold_installationid);

                print "<tr><td>";

                if ($bold_installationid) { print "<b>"; }
                print $installationid;
                if ($bold_installationid) { print "</b>"; }

                print "</td><td>";

                if ($bold_name) { print "<b>"; }
                print $userarr["name"];
                if ($bold_name) { print "</b>"; }
                if (array_key_exists("name_orig", $userarr)) {
                        print " (was: ".$userarr["name_orig"].")";
                }

                print "</td><td>";

                if ($bold_pin) { print "<b>"; }
                print $userarr["pin"];
                if ($bold_pin) { print "</b>"; }
                if (array_key_exists("pin_orig", $userarr)) {
                        print " (was: ".$userarr["pin_orig"].")";
                }

                print "</td></tr>\n";
        }
        print "</table>\n";

        print "<pre>";
        print_r($userlist2display);
        print "</pre>";

}


?>