// mac-adresse, die das Ethernet-Shield erhält:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFD, 0xEC };

// lokale, feste IP-Adresse. Nur relevant, wenn do_dhcp = 0
IPAddress ip(192,168,99,99);

// Arduino erlaubt nur requests aus dem selben Netz wie Arduino selbst und von allowedip:
IPAddress allowedip(192,168,99,99);

// Soll Ardunio DHCP machen? wenn nein, wird die IP-Adresse ip (s.o.) fest eingestellt.
const int do_dhcp = 1;

// Auf welchem Port soll Ardunio lauschen:
const int ip_port = 9999;

// An welchem Arduino-Pin ist das Tür-Relais angeschlossen (level 0 = aktiv)
int pinTuer = 8;

// Feste Default-PIN
const int fixed_pin = 9999;

// Diese PIN macht immer auf. Nur für Debugging gedacht.
const String master_pin = "99999999999";

// SMTP-Server
char *smtp_server = "mail.meinedomain.top";
char *smtp_helo = "arduino.meinedomain.top";
char *smtp_mail_from = "tueroeffner_arduino@meinedomain.top";
char *smtp_mail_to = "admin@meinedomain.top";
