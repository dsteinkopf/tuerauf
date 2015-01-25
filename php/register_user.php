<?php
/*
Neue User anzeigen:
https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&type=new

Neue User nach all kopieren (und dadurch aktivieren):
https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&type=new&savenewtoall=WsI65yuGCkjcA

Einen User anlegen: (dazu vorher freischalten mit: cp -p data/userlistnew_empty.php data/userlistnew.php
https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=ii1&name=nn1


Ablauf Registrierung:
1. Admin schaltet Registrierung frei:
    cd ... && cp -p data/userlistnew_empty.php data/userlistnew.php
2. User registrieren sich mit App. D.h.
    https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&installationid=ii1&name=nn1
3. Admin zeigt neue User an:
    https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&type=new
4. Admin speichert neue User nach all und aktiviert sie daurch:
    https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&type=new&savenewtoall=WsI65yuGCkjcA&showusers=WsI65yuGCkjcA
5. Admin schaltet Registrierung ab:
    cd ... && rm data/userlistnew.php
6. Admin zeigt alle user an:
    https://owncloudsrv.steinkopf.net:39931/tuerauf/register_user.php?appsecret=plUwPcIE82vKwHUVnGiS4o5J6o&showusers=WsI65yuGCkjcA&type=all
   */

require 'incl/lib.php';
require 'incl/users.php';

check_appsecret();

$adminsecret = "WsI65yuGCkjcA";


$showusers = (array_key_exists("showusers", $_REQUEST) && $_REQUEST["showusers"] == $adminsecret);
$savenewtoall = (array_key_exists("savenewtoall", $_REQUEST) && $_REQUEST["savenewtoall"] == $adminsecret);

$suffix = "new";
if ($showusers) {
        $type = $_REQUEST["type"];
        if ($type) {
                $suffix = $type;
        }
}

loadUserlist($suffix);


$new_installationid = array_key_exists("installationid", $_REQUEST) ? $_REQUEST["installationid"] : "";
$new_name = array_key_exists("name", $_REQUEST) ? $_REQUEST["name"] : "";

if ($new_installationid && $new_name) {
        $glob_userlist[$new_installationid] = $new_name;
        saveUserlist($suffix);
        print "saved_waiting";
}

if ($savenewtoall) {
        loadUserlist("new");
        $newuserlist = $glob_userlist;
        $glob_userlist = array();
        saveUserlist("new");

        loadUserlist();
        foreach($newuserlist as $installationid => $name) {
                $glob_userlist[$installationid] = $name;
        }
        saveUserlist();
        print "done_savenewtoall";
}

if ($showusers) {
        print "<pre>";
        print_r($glob_userlist);
        print "</pre>";
}


?>