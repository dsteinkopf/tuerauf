#include <Dhcp.h>
#include <Dns.h>
#include <Ethernet.h>
#include <EthernetClient.h>
#include <EthernetServer.h>
#include <EthernetUdp.h>

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

#include "config.h"

#ifdef DEBUG
#ifdef DEBUG_TO_SYSLOG
#define LOG_PRINT(msg) (Serial.print(msg))
#define LOG_PRINTLN(msg) (Serial.println(msg))
#else
#define LOG_PRINT(msg) (sendSyslogMessage(6, String(msg)))
#define LOG_PRINTLN(msg) (sendSyslogMessage(6, String(msg)))
#endif
#else
#define LOG_PRINT(msg) (0)
#define LOG_PRINTLN(msg) (0)
#endif


//  Ethernet shield attached to pins 10, 11, 12, 13
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

const unsigned long timeout_awaiting_dyn_code = 60ul*1000ul; // Vorsicht Konstanten wie 60 sind offenbar nur 16 bit

int email_pending = 0;
int checkOK = -1; // -1 ok not checked, 0 = bad, 1 = ok


const int dht22Pin = 7; // Sensor an Pin D7

float temperaturDHT22 = -999;
float feuchtigkeit = -999;
String dht22_state;

DHT22 DHT22_1(dht22Pin); // bilde DHT22-Instanz


IPAddress doorRequestCameFromIP;


EthernetServer server(ip_port);
IPAddress myNet;

Timer timer;
int relaisOffEventId = -1;
int resetStateEventId = -1;
int testrelaisCheckEventId = -1;
int testrelaisOffEventId = -1;

EthernetUDP udp;                           // An EthernetUDP instance to let us send and receive packets over UDP
int syslogInited = 0;


void setup() {

  pinMode(pinTuer, OUTPUT);
  pinMode(pinTest, OUTPUT);
  pinMode(pinTestInput, INPUT);
  closeRalais();
  closeTestRalais();
  
  // randomSeed(millis());
  randomSeed(analogRead(0));

  // Open serial communications and wait for port to open:
#ifdef DEBUG
  Serial.begin(9600);
#endif
#ifdef WAIT_FOR_SERIAL
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
#endif

  // start the Ethernet connection and the server:
  if (do_dhcp) {
    while (1) {
      LOG_PRINTLN(F("doing DHCP..."));
      int dhcpok = Ethernet.begin(mac);
      if (dhcpok) {
        LOG_PRINTLN(F("DHCP ok"));
        break;
      }
      else {
        LOG_PRINTLN(F("DHCP failed"));
        delay(5*1000);
      }
    }
  }
  else {
    Ethernet.begin(mac, ip);
  }

  udp.begin(8888);
  syslogInited = 1;
  LOG_PRINTLN(F("Arduino syslog logging started"));

  loadConfig();

  server.begin();
  LOG_PRINT(F("server is at "));
  IPAddress myIp = Ethernet.localIP();
  LOG_PRINTLN(String(myIp));
  myNet = IPAddress(myIp[0], myIp[1], myIp[2], 0);

  // start dht22 every 100 sec.
  dht22_state = F("dht22 not yet checked");
  timer.every(100ul*1000ul, dht22);
  
  // start self check every 50 sec
  timer.every(3600ul*1000ul, doTestNow);
  doTestNow(); // Do a first check now.
}


void loop() {
  timer.update();

  EthernetClient client = server.available();
  if (client) {
    int charcount = 0;
    LOG_PRINTLN(F("new client"));
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
    LOG_PRINTLN(F("client disconnected"));
  }
  delay(100); // damit kein busy wait entsteht
}

String processRequest(EthernetClient client, char *input)
{
  LOG_PRINTLN(F("processRequest"));
  
  // check remote ip first - only local net and allowedip are allowed:
  String errString = checkAllowedIP(client, false); // true = onlyLocalNet, false = allowedip is allowed
  if (errString != NULL) return errString;

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
  LOG_PRINT(F("command=")); LOG_PRINTLN(command);
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
    return dumpPins(client);
  }
  if (strcmp(command, "/storepinlist") == 0) {
    return storePinList(client);
  }
  if (strcmp(command, "/status") == 0) {
    return getStatus();
  }

  switch (mystate) {
    case awaiting_fixed_pin: return checkFixedPin(command); break;
    case awaiting_dyn_code:  return checkDynCode(command); break;
    default:
      switchToState(awaiting_fixed_pin);
      return F("bad internal state");
  }
}

// Parameters: 1000&1001&1002&...
// PINs that are not passed (not between 1000 and 9999) are not changed
// Parameters are passed to this function via strtok
String storePinList(EthernetClient client) {
        String errString = checkAllowedIP(client, false); // true = onlyLocalNet, false = allowedip is allowed
        if (errString != NULL) return errString;
        
        char *pinPassword = strtok(0, ":");
        if (pinPassword == 0 || strcmp(pinPassword, REQUIRED_PIN_PASSWORD) != 0) {
                return F("pinPassword missing or wrong");
        }

        int pinNum = 0;
        for (char *param = strtok(0, "&");
             param != 0 && pinNum < max_pins;
             param = strtok(0, "&"), pinNum++) {
                int pin = atoi(param);
                if (pin >= 1000 && pin <= 9999) {
                        settings.pin[pinNum] = pin;
                        LOG_PRINT("Stored pin "); LOG_PRINTLN(param);
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
  LOG_PRINT(F("checkFixedPin ")); LOG_PRINTLN(command);

  // korrekte PIN bestimmen:
  int got_pin = atoi(strtok(command, "/"));
  char *pinIndex = strtok(0, "/");

  int correct_pin = fixed_pin;
  if (pinIndex) {
    correct_pin = settings.pin[atoi(pinIndex)];
    LOG_PRINT(F("pinIndex=")); LOG_PRINTLN(pinIndex);
  }
  LOG_PRINT(F("correct_pin=")); LOG_PRINTLN(correct_pin);

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
  LOG_PRINTLN(F("sendNewDynCode"));
  int randNumber4digits = random(1000,9999);

  dyn_code = String(randNumber4digits);
  return "dyn_code "+dyn_code;
}

String checkDynCode(String input) // input ist z.B. "/1234"
{
  LOG_PRINT(F("checkDynCode ")); LOG_PRINTLN(input);
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
  LOG_PRINTLN(F("openDoorNow"));
  digitalWrite(pinTuer, LOW);   // Relais AN
  // delay(1000);              // wait for a second
  relaisOffEventId = timer.after(3000ul, closeRalais); // call closeRalais with delay

  email_pending = 1;
}

void doTestNow()
{
  int value = digitalRead(pinTestInput);
  LOG_PRINT(F("doTestNow value=")); LOG_PRINTLN(value == LOW ? F("Low") : F("High")); // current state (before check)
  if (value != LOW) {
    // current state ist NOT ok
    LOG_PRINTLN(F("check current state NOT ok"));
    checkOK = 0;
  }
  else {
    // current state is OK
    LOG_PRINTLN(F("check current state ok"));
    digitalWrite(pinTest, LOW);   // Relais AN
    delay(500);              // wait for a second
    testrelaisCheckEventId = timer.after(5000ul, checkTestRalais); // call checkTestRalais with delay
  }
  LOG_PRINTLN(F("doTestNow done"));
}

void closeRalais()
{
  LOG_PRINTLN(F("closeRalais"));
  digitalWrite(pinTuer, HIGH);   // Tür-Relais aus
  relaisOffEventId = -1;

  if (email_pending) {
    email_pending = 0;
    sendEMail(F("Tuer wurde geoeffnet"));
  }
}

void checkTestRalais()
{
  testrelaisCheckEventId = -1;
  int value = digitalRead(pinTestInput);
  LOG_PRINT(F("checkTestRalais value=")); LOG_PRINTLN(value == HIGH ? F("High") : F("Low"));
  
  if (value != HIGH) {
    // current state ist NOT ok
    LOG_PRINTLN(F("check NOT ok"));
    checkOK = 0;
  }
  else {
    // current state is OK
    checkOK = 1;
    LOG_PRINTLN(F("check OK"));
  }
  testrelaisOffEventId = timer.after(500ul, closeTestRalais); // call closeTestRalais with delay
}

void closeTestRalais()
{
  LOG_PRINTLN(F("closeTestRalais"));
  digitalWrite(pinTest, HIGH);   // Test-Relais aus
  testrelaisOffEventId = -1;
}

void switchToState(int newState)
{
  LOG_PRINT(F("switchToState ")); LOG_PRINTLN(newState);
  mystate = (serverstate) newState;

  if (resetStateEventId >= 0) {
    timer.stop(resetStateEventId);
    resetStateEventId = -1;
  }

  // awaiting_dyn_code bleibt nur so lange:
  if (mystate == awaiting_dyn_code) {
    LOG_PRINT("start timer to reset state after ms "); LOG_PRINTLN(timeout_awaiting_dyn_code);
    resetStateEventId = timer.after(timeout_awaiting_dyn_code, resetState);
  }
}

void resetState()
{
  LOG_PRINTLN(F("resetState"));
  switchToState(awaiting_fixed_pin);
  resetStateEventId = -1;
}

String checkAllowedIP(EthernetClient client, boolean onlyLocalNet)
{
    // check remote ip first - only local net and allowedip are allowed:
  byte rip[] = {0,0,0,0 };
  client.getRemoteIP(rip);
  doorRequestCameFromIP = IPAddress(rip[0], rip[1], rip[2], rip[3]);
  IPAddress doorRequestCameFromNet(rip[0], rip[1], rip[2], 0);
  if (myNet == doorRequestCameFromNet) { // myNet is allowed in any case
    return (char *)NULL; // = ok
  }
  // we only get here if request did NOT come from local net
  if (onlyLocalNet) {
    return F("bad client ip");
  }
  else {
    return (char *)NULL; // = ok
  }
}

void sendEMail(String content)
{
  LOG_PRINTLN(F("sendEMail"));
  EthernetClient client = EthernetClient();
  client.connect(smtp_server,25);
  LOG_PRINTLN(F("connected"));
  int count = 0;
  while (count < 20) {
    if (client.available()) {
      char c = client.read();
      if (c == '\n')
        break;
    }
    else {
      LOG_PRINTLN(F("delay"));
      delay(1000);
    }
  }
  LOG_PRINTLN(F("got response from mail server"));
  client.print(F("HELO ")); client.print(smtp_helo); client.print("\n");
  delay(100);
  // client.print(F("AUTH PLAIN\n"));
  // client.print(F("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\r\n"));  // x: base64 encoded login: \0foo@yahoo.com\0password
  client.print(F("MAIL FROM:<")); client.print(smtp_mail_from); client.print(">\n");
  client.print(F("RCPT TO:<")); client.print(smtp_mail_to); client.print(">\n");
  client.print(F("DATA\n"));
  delay(100);
  client.print(F("From: \"tueroeffner_arduino\" <")); client.print(smtp_mail_from); client.print(">\r\n");
  client.print(F("To: ")); client.print(smtp_mail_to); client.print("\r\n");

  client.print(F("Subject: "));
  client.print(content);
  client.print(F("\r\n"));

  client.print(content);  // Lines of text
  client.print(F("\r\n"));  // Lines of text
  if (doorRequestCameFromIP != NULL) {
    LOG_PRINT(F("doorRequestCameFromIP=")); LOG_PRINTLN(doorRequestCameFromIP);
    client.print(F("von "));
    client.print(doorRequestCameFromIP);
    client.print(F("\r\n"));
  }
  // ......................................
  client.print(F("\r\n"));
  client.print(F(".\r\n"));
  client.print(F("quit\n"));
  client.stop();
  LOG_PRINTLN(F("mail sent"));
}

int freeRam () {
  extern int __heap_start, *__brkval;
  int v;
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval);
}

void dht22()
{
  DHT22_ERROR_t fehlerCodeDHT22;
  LOG_PRINT(F("Hole Daten DHT22 ...: "));
  fehlerCodeDHT22 = DHT22_1.readData(); // hole Status
  switch(fehlerCodeDHT22) // werte Status aus
  {
    case DHT_ERROR_NONE:; // wenn kein Fehler
      temperaturDHT22 = DHT22_1.getTemperatureC();
      LOG_PRINT(temperaturDHT22);
      LOG_PRINT(F(" C "));
      feuchtigkeit = DHT22_1.getHumidity();
      LOG_PRINT(feuchtigkeit);
      LOG_PRINTLN(F(" %"));
      dht22_state = F("dht22 ok");
      break;
    case DHT_ERROR_CHECKSUM:
      dht22_state = F("Fehler Pruefziffer ");
      break;
    case DHT_BUS_HUNG:
      dht22_state = F("BUS haengt ");
      break;
    case DHT_ERROR_NOT_PRESENT:
      dht22_state = F("nicht vorhanden ");
      break;
    case DHT_ERROR_ACK_TOO_LONG:
      dht22_state = F("Fehler ACK Timeout ");
      break;
    case DHT_ERROR_SYNC_TIMEOUT:
      dht22_state = F("Fehler Sync Timeout ");
      break;
    case DHT_ERROR_DATA_TIMEOUT:
      dht22_state = F("Fehler Daten Timeout ");
      break;
    case DHT_ERROR_TOOQUICK:
      dht22_state = F("Abfrage zu schnell ");
      break;
  }
  LOG_PRINTLN(dht22_state);
  LOG_PRINTLN(freeRam());
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
    LOG_PRINTLN(F("no settings in eeprom"));
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
       LOG_PRINTLN(F("error writing to EEPROM"));
    }
  }
}

// to be used for PIN backup
String dumpPins(EthernetClient client) {
  String errString = checkAllowedIP(client, true); // true = onlyLocalNet, false = allowedip is allowed
  if (errString != NULL) return errString;
  
  String result = "PINs:\n";

  loadConfig();
  for (int i = 0; i < max_pins; i++) {
    LOG_PRINTLN(settings.pin[i]);
    result += String(F("PIN ")) + i + F(": ") + settings.pin[i] + F("\n");
  }
  LOG_PRINTLN(settings.version_of_program);
  result += String(F("settings version: ")) + settings.version_of_program;
        
  return result;
}

String getStatus()
{
  loadConfig();
  
  String statusString = dht22_state;
  statusString += String(F(", freeRam=")) + freeRam();
  statusString += String(F(", checkOK=")) + checkOK;
  // statusString += F(", version=") + settings.version_of_program;
  
  return statusString;
}

// see http://www.msxfaq.de/sonst/bastelbude/arduinoethernet.htm#meldung_per_syslog
// http://www.dl8rds.de/index.php/Arduino_Syslog_Client_Library
void sendSyslogMessage(int severity, String message)
{
  /*
   0 Emergency: system is unusable 
   1 Alert: action must be taken immediately 
   2 Critical: critical conditions 
   3 Error: error conditions 
   4 Warning: warning conditions 
   5 Notice: normal but significant condition 
   6 Informational: informational messages 
   */

  if (!syslogInited)
     return;

  int facility = 17; // local1
  int pri = (8*facility + severity);
  String priString = String(pri, DEC);
  String buffer = "<" + priString + ">" + "arduino " + message;
  int bufferLength = buffer.length();
  char char1[bufferLength+1];
  for(int i=0; i < bufferLength; i++)  {
    char1[i]=buffer.charAt(i);
  }
  char1[bufferLength] = '\0'; 
  
  udp.beginPacket(syslogServer, syslogPort); 
  udp.write(char1); 
  udp.endPacket();  

  Serial.println(char1);
}

