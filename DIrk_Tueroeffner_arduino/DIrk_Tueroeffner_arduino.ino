/*

  Dirk Steinkopf

  Türöffner

  Zur Sicherheit wird die Client-IP geprüft.
  Hierzu muss EthernetClient.cpp/h gepatcht werden :-(
  siehe http://forum.arduino.cc/index.php?topic=82416.0
  ->
  I added the following lines to the end of the EthernetClient.cpp file:
uint8_t *EthernetClient::getRemoteIP(uint8_t remoteIP[])
{
  W5100.readSnDIPR(_sock, remoteIP);
  return remoteIP;
}
I then added the following line (under the virtual void stop(); line)to the EthernetClient.h file:
uint8_t *getRemoteIP(uint8_t RemoteIP[]);//adds remote ip address


***

F("abc") spart Speicher. siehe http://electronics.stackexchange.com/questions/66983/how-to-discover-memory-overflow-errors-in-the-arduino-c-code
 */

#include <stdlib.h>

#include <SPI.h>
#include <Ethernet.h>
#include <Timer.h>
#include <DHT22.h>
#include <EEPROM.h>


//  Ethernet shield attached to pins 10, 11, 12, 13
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFD, 0xEC };
IPAddress ip(192,168,40,14);
IPAddress allowedip(192,168,41,18);
const int do_dhcp = 1;
const int ip_port = 1080;
int pinTuer = 8;

const int fixed_pin = 4242;
const String master_pin = "uasdaccbai36dxas";
String dyn_code;

const int bufsize = 100;
char line[bufsize];

// ID of the settings block
#define CONFIG_VERSION "ta1"
// Tell it where to store your config data in EEPROM
#define CONFIG_START 32
const int max_pins = 16;
struct StoreStruct {
  int pin[max_pins];
  // This is for mere detection if they are your settings
  char version_of_program[4]; // it is the last variable of the struct
  // so when settings are saved, they will only be validated if
  // they are stored completely.
} settings = {
  // default values
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  CONFIG_VERSION
};

enum serverstate {
  awaiting_fixed_pin,
  awaiting_dyn_code
};
serverstate mystate = awaiting_fixed_pin;

const unsigned long timeout_awaiting_dyn_code = 60u*1000u; // Vorsicht long ist offenbar nur 16 bit

int email_pending = 0;


const int dht22Pin = 7; // Sensor an Pin D7

float temperaturDHT22 = -999;
float feuchtigkeit = -999;

DHT22 DHT22_1(dht22Pin); // bilde DHT22-Instanz


IPAddress doorRequestCameFromIP;


EthernetServer server(ip_port);
IPAddress myNet;

Timer timer;
int relaisOffEventId = -1;
int resetStateEventId = -1;


void setup() {

  pinMode(pinTuer, OUTPUT);
  closeRalais();

  // randomSeed(millis());
  randomSeed(analogRead(0));

  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }

  // start the Ethernet connection and the server:
  if (do_dhcp) {
    while (1) {
      Serial.println(F("doing DHCP..."));
      int dhcpok = Ethernet.begin(mac);
      if (dhcpok) {
        Serial.println(F("DHCP ok"));
        break;
      }
      else {
        Serial.println(F("DHCP failed"));
        delay(5*1000);
      }
    }
  }
  else {
    Ethernet.begin(mac, ip);
  }

  loadConfig();

  server.begin();
  Serial.print(F("server is at "));
  IPAddress myIp = Ethernet.localIP();
  Serial.println(myIp);
  myNet = IPAddress(myIp[0], myIp[1], myIp[2], 0);

  timer.every(10*1000, dht22);
}


void loop() {
  timer.update();

  EthernetClient client = server.available();
  if (client) {
    int charcount = 0;
    Serial.println(F("new client"));
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.write(c);

        if (charcount < bufsize-1) {
          line[charcount++] = c;
        }

        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          line[charcount-1] = '\0';

          String result = processRequest(client, line);

          // send a standard http response header
          client.println(F("HTTP/1.1 200 OK"));
          client.println(F("Content-Type: text/html"));
          client.println(F("Connection: close"));  // the connection will be closed after completion of the response
	  // client.println("Refresh: 5");  // refresh the page automatically every 5 sec
          client.println();

          client.println(result);

          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        }
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(10);
    // close the connection:
    client.stop();
    Serial.println(F("client disconnected"));
  }
  delay(100); // damit kein busy wait entsteht
}

String processRequest(EthernetClient client, char *input)
{
  Serial.println(F("processRequest"));

  // check remote ip first - only local net and allowedip are allowed:
  byte rip[] = {0,0,0,0 };
  client.getRemoteIP(rip);
  doorRequestCameFromIP = IPAddress(rip[0], rip[1], rip[2], rip[3]);
  IPAddress doorRequestCameFromNet(rip[0], rip[1], rip[2], 0);
  if (myNet != doorRequestCameFromNet && allowedip != doorRequestCameFromIP) {
      return F("bad client ip");
  }

  // strtok: siehe http://arduino.stackexchange.com/questions/1013/how-do-i-split-an-incoming-string
  char *part1 = strtok(input, " ");
  if (part1 == 0) {
          return F("bad request 1");
  }
  char *querystring = strtok(0, " ");
  if (querystring == 0) {
          return F("bad request 2");
  }
  char* command = strtok(querystring, "?");
  Serial.print(F("command=")); Serial.println(command);
  if (command == 0) {
    return "no_command";
  }
  if (strcmp(command, "/gettemp") == 0) {
    return getTemperature();
  }
  if (strcmp(command, "/gethumid") == 0) {
    return getHumidity();
  }
  if (strcmp(command, "/dumppins") == 0) {
    dumpPins();
    return F("done");
  }
  if (strcmp(command, "/storepinlist") == 0) {
          // check remote ip first - only local net  ist allowed - not allowedip here:
          if (myNet != doorRequestCameFromNet) {
                  return F("bad client ip for storepinlist");
          }
          return storePinList();
  }

  switch (mystate) {
    case awaiting_fixed_pin: return checkFixedPin(command); break;
    case awaiting_dyn_code:  return checkDynCode(command); break;
    default:
      switchToState(awaiting_fixed_pin);
      return F("bad internal state");
  }
}

// Übergabe der Parameter via strtok
String storePinList() {
        int pinNum = 0;
        for (char *param = strtok(0, "&");
             param != 0 && pinNum < max_pins;
             param = strtok(0, "&"), pinNum++) {
                int pin = atoi(param);
                if (pin >= 1000 && pin <= 9999) {
                        settings.pin[pinNum] = pin;
                        Serial.print("Stored pin "); Serial.println(param);
                }
        }
        for (; pinNum < max_pins; pinNum++) {
           settings.pin[pinNum] = 0;
        }
        saveConfig();
        return F("done");
}

// input ist z.B. "/1234" oder "/1234/22" oder "/1234/22/near"
// 22 ist dann der pin-Index
// near zeigt an, dass die dyn_code-Schritt ausgelassen werden kann, weil der Nutzer "nah" ist.
String checkFixedPin(char *command)
{
  Serial.print(F("checkFixedPin ")); Serial.println(command);

  // korrekte PIN bestimmen:
  int got_pin = atoi(strtok(command, "/"));
  char *pinIndex = strtok(0, "/");

  int correct_pin = fixed_pin;
  if (pinIndex) {
    correct_pin = settings.pin[atoi(pinIndex)];
    Serial.print(F("pinIndex=")); Serial.println(pinIndex);
  }
  Serial.print(F("correct_pin=")); Serial.println(correct_pin);

  // PIN überprüfen:
  if (got_pin == correct_pin) {
          // fixed_pin stimmt

          // nach "near" suchen und ggf. Tür direkt öffnen
          if (pinIndex) {
                  char *nearString = strtok(0, "/");
                  if (nearString && 0 == strcmp("near", nearString)) {
                          openDoorNow();
                          switchToState(awaiting_fixed_pin);
                          return "OFFEN";
                  }
          }

          switchToState(awaiting_dyn_code);
          return sendNewDynCode();
  }

  // fixed_pin falsch, vielleicht ist es ja die masterpin
  int pos_masterpin = String(command).indexOf(master_pin);
  if (pos_masterpin > 0) {
    // masterpin stimmt
    openDoorNow();
    switchToState(awaiting_fixed_pin);
    return "OFFEN";
  }

  // MasterPin war es auch nicht - also Mail schicken und von vorne
  switchToState(awaiting_fixed_pin);
  sendEMail(F("bad fixed_pin")); // Mail-Verschicken erzeugt außerdem ein Delay von ein paar Sekunden
  return F("bad fixed_pin");
}

String sendNewDynCode()
{
  Serial.println(F("sendNewDynCode"));
  int randNumber4digits = random(1000,9999);

  dyn_code = String(randNumber4digits);
  return "dyn_code "+dyn_code;
}

String checkDynCode(String input) // input ist z.B. "/1234"
{
  Serial.print(F("checkDynCode ")); Serial.println(input);
  int pos = input.indexOf(dyn_code);

  if (pos > 0) {
    // dyn_code stimmt
    openDoorNow();
    switchToState(awaiting_fixed_pin);
    return "OFFEN";
  }
  else {
    // dyn_code falsch - einfach von vorne
    switchToState(awaiting_fixed_pin);
    return "bad dyn_code";
  }
}

void openDoorNow()
{
  Serial.println(F("openDoorNow"));
  digitalWrite(pinTuer, LOW);   // Relais AN
  // delay(1000);              // wait for a second
  relaisOffEventId = timer.after(3000, closeRalais); // call closeRalais with delay

  email_pending = 1;
}

void closeRalais()
{
  Serial.println(F("closeRalais"));
  digitalWrite(pinTuer, HIGH);   // Tür-Relaus aus
  relaisOffEventId = -1;

  if (email_pending) {
    email_pending = 0;
    sendEMail(F("Tuer wurde geoeffnet"));
  }
}

void switchToState(int newState)
{
  Serial.print(F("switchToState ")); Serial.println(newState);
  mystate = (serverstate) newState;

  if (resetStateEventId >= 0) {
    timer.stop(resetStateEventId);
    resetStateEventId = -1;
  }

  // awaiting_dyn_code bleibt nur so lange:
  if (mystate == awaiting_dyn_code) {
    Serial.print("start timer to reset state after ms "); Serial.println(timeout_awaiting_dyn_code);
    resetStateEventId = timer.after(timeout_awaiting_dyn_code, resetState);
  }
}

void resetState()
{
  Serial.println(F("resetState"));
  switchToState(awaiting_fixed_pin);
  resetStateEventId = -1;
}


void sendEMail(String content)
{
  Serial.println(F("sendEMail"));
  EthernetClient client = EthernetClient();
  client.connect("mail.wor.net",25);
  Serial.println(F("connected"));
  int count = 0;
  while (count < 20) {
    if (client.available()) {
      char c = client.read();
      if (c == '\n')
        break;
    }
    else {
      Serial.println(F("delay"));
      delay(1000);
    }
  }
  Serial.println(F("got response from mail server"));
  client.print(F("HELO arduino.steinkopf.net\n"));
  delay(100);
  // client.print(F("AUTH PLAIN\n"));
  // client.print(F("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\r\n"));  // x: base64 encoded login: \0foo@yahoo.com\0password
  client.print(F("MAIL FROM:<tueroeffner_arduino@steinkopf.net>\n"));
  client.print(F("RCPT TO:<dirk@wor.net>\n"));
  client.print(F("DATA\n"));
  delay(100);
  client.print(F("From: \"tueroeffner_arduino\" <tueroeffner_arduino@steinkopf.net>\r\n"));
  client.print(F("To: dirk@wor.net\r\n"));

  client.print(F("Subject: "));
  client.print(content);
  client.print(F("\r\n"));

  client.print(content);  // Lines of text
  client.print(F("\r\n"));  // Lines of text
  if (doorRequestCameFromIP != NULL) {
    Serial.print(F("doorRequestCameFromIP=")); Serial.println(doorRequestCameFromIP);
    client.print(F("von "));
    client.print(doorRequestCameFromIP);
    client.print(F("\r\n"));
  }
  // ......................................
  client.print(F("\r\n"));
  client.print(F(".\r\n"));
  client.print(F("quit\n"));
  client.stop();
  Serial.println(F("mail sent"));
}

int freeRam () {
  extern int __heap_start, *__brkval;
  int v;
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval);
}

void dht22()
{
  DHT22_ERROR_t fehlerCodeDHT22;
  Serial.print(F("Hole Daten DHT22 ...: "));
  fehlerCodeDHT22 = DHT22_1.readData(); // hole Status
  switch(fehlerCodeDHT22) // werte Status aus
  {
    case DHT_ERROR_NONE:; // wenn kein Fehler
      temperaturDHT22 = DHT22_1.getTemperatureC();
      Serial.print(temperaturDHT22);
      Serial.print(F(" C "));
      feuchtigkeit = DHT22_1.getHumidity();
      Serial.print(feuchtigkeit);
      Serial.println(F(" %"));
      break;
    case DHT_ERROR_CHECKSUM:
      Serial.print(F("Fehler Pruefziffer "));
      break;
    case DHT_BUS_HUNG:
      Serial.println(F("BUS haengt "));
      break;
    case DHT_ERROR_NOT_PRESENT:
      Serial.println(F("nicht vorhanden "));
      break;
    case DHT_ERROR_ACK_TOO_LONG:
      Serial.println(F("Fehler ACK Timeout "));
      break;
    case DHT_ERROR_SYNC_TIMEOUT:
      Serial.println(F("Fehler Sync Timeout "));
      break;
    case DHT_ERROR_DATA_TIMEOUT:
      Serial.println(F("Fehler Daten Timeout "));
      break;
    case DHT_ERROR_TOOQUICK:
      Serial.println(F("Abfrage zu schnell "));
      break;
  }
  Serial.println(freeRam());
}

String getTemperature()
{
  static char tempStr[10];
  dtostrf(temperaturDHT22,1,1,tempStr);

  return tempStr;
}

String getHumidity()
{
  static char tempStr[10];
  dtostrf(feuchtigkeit,1,0,tempStr);

  return tempStr;
}

void loadConfig() {
  // To make sure there are settings, and they are YOURS!
  // If nothing is found it will use the default settings.
  if (//EEPROM.read(CONFIG_START + sizeof(settings) - 1) == settings.version_of_program[3] // this is '\0'
      EEPROM.read(CONFIG_START + sizeof(settings) - 2) == settings.version_of_program[2] &&
      EEPROM.read(CONFIG_START + sizeof(settings) - 3) == settings.version_of_program[1] &&
      EEPROM.read(CONFIG_START + sizeof(settings) - 4) == settings.version_of_program[0])
  { // reads settings from EEPROM
    for (unsigned int t=0; t<sizeof(settings); t++)
      *((char*)&settings + t) = EEPROM.read(CONFIG_START + t);
  } else {
    // settings aren't valid! will overwrite with default settings
    Serial.println(F("no settings in eeprom"));
    saveConfig();
  }
}

void saveConfig() {
  for (unsigned int t=0; t<sizeof(settings); t++)
  { // writes to EEPROM
    EEPROM.write(CONFIG_START + t, *((unsigned char*)&settings + t));
    // and verifies the data
    if (EEPROM.read(CONFIG_START + t) != *((unsigned char*)&settings + t))
    {
       Serial.println(F("error writing to EEPROM"));
    }
  }
}

void dumpPins() {
  loadConfig();
  for (int i = 0; i < max_pins; i++) {
    Serial.println(settings.pin[i]);
  }
    Serial.println(settings.version_of_program);
}
