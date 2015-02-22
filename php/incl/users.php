<?php

class User {

        const userlistfilename_base = "data/userlist";
        const max_lfdid = 16;

        private static $userlist = null;

        public $username;
        public $pin;
        public $lfdid;
        public $new;
        public $active;


        private function __construct($username, $pin, $installationid) {
                $this->username = $username;
                $this->pin = $pin;
                $this->installationid = $installationid;
                $this->new = 1;
                $this->active = 0;
                $this->lfdid = null;
        }

        public function updateData($username, $pin) {
                if ($username != $this->username) {
                        if ( ! $this->usernameOld) {
                                $this->usernameOld = $this->username;
                        }
                        $this->username = $username;
                }
                if ($pin != $this->pin) {
                        if ( ! $this->pinOld) {
                                $this->pinOld = $this->pin;
                        }
                        $this->pin = $pin;
                }
        }

        /**
         Liefert den User anhand der installationid
        */
        public static function getUser($installationid) {
                self::checkToLoadUserlist();
                if (array_key_exists($installationid, self::$userlist)) {
                        $user = self::$userlist[$installationid];
                        return $user;
                }
                return null;
        }

        /**
         Liefert den User anhand der installationid - aber nur, wenn er aktiv ist
        */
        public static function getActiveUser($installationid) {
                self::checkToLoadUserlist();
                $user = self::getUser($installationid);
                if ($user && $user->active) {
                        return $user;
                }
                return null;
        }

        /**
         * Stellt alle neuen User auf aktiv
         */
        public static function activateAllNew() {
                self::checkToLoadUserlist();
                foreach(self::$userlist as $installationid => $user) {
                        if ($user->new && ! $user->active) {
                                $user->active = 1;
                                $user->new = 0;
                        }
                        $user->usernameOld = null;
                        $user->pinOld = null;
                }
        }

        /**
         * Liefer die ganze Userliste
         */
        public static function getUserlist()  {
                self::checkToLoadUserlist();
                return self::$userlist;
        }


        /**
         * Legt einen neuen User an.
         */
        public static function createUser($username, $pin, $installationid) {
                global $debug;
                if ($debug) print "createUser $username<br>\n";
                self::checkToLoadUserlist();
                if (array_key_exists($installationid, self::$userlist)) {
                        $user = self::$userlist[$installationid];
                        $user->updateData($username, $pin);
                }
                else {
                        $user = new User($username, $pin, $installationid);
                        $lfdid = self::getFreeLfdid();
                        $user->lfdid = $lfdid;
                }
                self::$userlist[$installationid] = $user;

                return $user;
        }

        /**
         * freie lfdid suchen:
         */
        private static function getFreeLfdid() {
                global $debug;
                self::checkToLoadUserlist();
                $used_lfdids = array();
                foreach(self::$userlist as $installationid => $user) {
                        $lfdid = $user->lfdid;
                        is_numeric($lfdid) || die();
                        $used_lfdids[$lfdid] = 1;
                }
                for ($lfdid = 0; $lfdid < self::max_lfdid; $lfdid++) {
                        $isused = array_key_exists($lfdid, $used_lfdids) && $used_lfdids[$lfdid];
                        if ( ! $isused) {
                                if ($debug) print "getFreeLfdid returns $lfdid<br>\n";
                                return $lfdid;
                        }
                }
                $logstr = "too many users - max_lfdid reached";
                error_log($logstr, 1, "dirk@wor.net");
                die($logstr);
        }

        /**
         * Liefert Array der aktiven pins in der form array(lfdid => pin):
         */
        public static function getPinList() {
                global $debug;
                if ($debug) print "getPinList<br>";
                self::checkToLoadUserlist();
                $pins = array();
                foreach(self::$userlist as $installationid => $user) {
                        if ($user->active) {
                                $lfdid = $user->lfdid;
                                is_numeric($lfdid) || die();
                                $pins[$lfdid] = $user->pin;
                        }
                }
                for ($lfdid = 0; $lfdid < self::max_lfdid; $lfdid++) {
                        $isused = array_key_exists($lfdid, $pins) && $pins[$lfdid];
                        if ( ! $isused) {
                                $pins[$lfdid] = 0;
                        }
                }
                return $pins;
        }

        /**
         * speichert die Userlist als PHP-Include-File, damit sie nicht von extern direkt aufgerufen werden kann.
         * Return true, wenn ok
         */
        public static function saveUserlist() {
                $filename = self::userlistfilename_base.".php";
                $userlist_string = serialize(self::$userlist);
                $quoted_userlist_string = str_replace("\"", "\\\"", $userlist_string);
                $bytecountOrFalse = file_put_contents($filename,
                                                      "<?php\n"
                                                      ."\$users=\"".$quoted_userlist_string."\";\n"
                                                      ."?>\n");
                if ($bytecountOrFalse === false || $bytecountOrFalse < 2) {
                        return false; // false
                }
                else {
                        return true; // ok
                }
        }

        /**
         * lädt die Userliste
         */
        private static function loadUserlist() {
                global $debug;
                $filename = self::userlistfilename_base.".php";
                if (file_exists($filename)) {
                        include $filename;
                        // var $users geladen
                        // if ($debug) print "users=$users<br>\n";
                        self::$userlist = unserialize($users);
                }
                else {
                        self::$userlist = array();
                }
        }

        /**
         * stellt sicher, dass die userlist geladen ist
         */
        private static function checkToLoadUserlist() {
                if ( ! self::$userlist) {
                        self::loadUserlist();
                }
        }

  } // end class User
?>
