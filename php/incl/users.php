<?php

$glob_userlistfilename_base = "data/userlist";

$glob_userlist = array();


/**
 * speichert die Userlist als PHP-Include-File, damit sie nicht von extern direkt aufgerufen werden kann
 */
function saveUserlist($suffix = "all") {
        global $glob_userlist;
        global $glob_userlistfilename_base;
        $userlist_string = json_encode($glob_userlist);
        $quoted_userlist_string = str_replace("\"", "\\\"", $userlist_string);
        $filename = $glob_userlistfilename_base.$suffix.".php";
        file_put_contents($filename,
                          "<?php\n"
                          ."\$users=\"".$quoted_userlist_string."\";\n"
                          ."?>\n");
}

/**
 * lädt die Userliste
 */
function loadUserlist($suffix = "all") {
        global $glob_userlist;
        global $glob_userlistfilename_base;
        global $debug;

        $filename = $glob_userlistfilename_base.$suffix.".php";

        if (file_exists($filename)) {
                include $filename;
                // var $users geladen
                // if ($debug) print "users=$users<br>\n";
                $glob_userlist = json_decode($users, true);
        }
        else {
                reject("no ".$filename);
        }
}

?>
