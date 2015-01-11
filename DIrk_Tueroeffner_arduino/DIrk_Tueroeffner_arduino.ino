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


byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFD, 0xEC };
IPAddress ip(192,168,40,14);
const int do_dhcp = 0;
const int ip_port = 1080;
int pinTuer = 8;

const String fixed_pin = "4242";
const String master_pin = "uasdaccbai36dxas";
String dyn_code;

const int bufsize = 50;
char line[bufsize];

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
          client.println(F("<!DOCTYPE HTML>"));
          client.println(F("<html>"));
          // client.print(F("line:");
          // client.print(line);
          client.println(F("<br/>"));

          client.print(result);          
          client.println(F("<br/>"));       

          client.println(F("</html>"));

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
}

String processRequest(EthernetClient client, String input)
{
  Serial.println(F("processRequest"));
   
  // check remote ip first - only local net allowed:
  byte rip[] = {0,0,0,0 };
  client.getRemoteIP(rip);
  IPAddress remoteNet(rip[0], rip[1], rip[2], 0); 
  if (myNet != remoteNet) {
      return F("bad client ip");
  }
  
  int pos = input.indexOf(F("gettemp"));
  if (pos > 0) {
    return getTemperature();
  }

  pos = input.indexOf(F("gethum"));
  if (pos > 0) {
    return getHumidity();
  }
  
  doorRequestCameFromIP = IPAddress(rip[0], rip[1], rip[2], rip[3]);

  switch (mystate) {
    case awaiting_fixed_pin: return checkFixedPin(input); break;
    case awaiting_dyn_code:  return checkDynCode(input); break;
    default: 
      switchToState(awaiting_fixed_pin);
      return F("bad internal state");
  }
}

String checkFixedPin(String input)
{
  Serial.println(F("checkFixedPin"));
  int pos = input.indexOf(fixed_pin);
  
  if (pos > 0) {
    // fixed_pin stimmt
    switchToState(awaiting_dyn_code);
    return sendNewDynCode();
  }
  else {
    // fixed_pin falsch
    
    // vielleicht ist es ja die masterpin
    int pos_masterpin = input.indexOf(master_pin);
    
    if (pos_masterpin > 0) {
      // masterpin stimmt
      openDoorNow();
      switchToState(awaiting_fixed_pin);
      return "OFFEN";
    }
    
    switchToState(awaiting_fixed_pin);
    return F("bad fixed_pin");
  }
}

String sendNewDynCode()
{
  Serial.println(F("sendNewDynCode"));
  int randNumber4digits = random(1000,9999);

  dyn_code = String(randNumber4digits);
  return "dyn_code "+dyn_code;
}

String checkDynCode(String input)
{ 
  Serial.println(F("checkDynCode"));
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
    sendEMail();
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


void sendEMail()
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
  client.print(F("Subject: Tuer geoeffnet\r\n"));  // xD
  client.print(F("Tuer wurde geoeffnet\r\n"));  // Lines of text
  if (doorRequestCameFromIP != NULL) {
    Serial.print(F("doorRequestCameFromIP=")); Serial.println(doorRequestCameFromIP);
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
