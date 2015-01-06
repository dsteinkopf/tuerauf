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
 
 */

#include <SPI.h>
#include <Ethernet.h>
#include <Timer.h>


byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFD, 0xEC };
// jetzt via DHCP: IPAddress ip(192,168,40,14);
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
  while (1) {
    Serial.println("doing DHCP...");
    int dhcpok = Ethernet.begin(mac);
    if (dhcpok) {
      Serial.println("DHCP ok");
      break;
    }
    else {
      Serial.println("DHCP failed");
      delay(5*1000);
    }
  }
  
  server.begin();
  Serial.print("server is at ");
  IPAddress myIp = Ethernet.localIP();
  Serial.println(myIp);
  myNet = IPAddress(myIp[0], myIp[1], myIp[2], 0);
}


void loop() {
  timer.update();
  
  EthernetClient client = server.available();
  if (client) {
    int charcount = 0;
    Serial.println("new client");
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
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println("Connection: close");  // the connection will be closed after completion of the response
	  // client.println("Refresh: 5");  // refresh the page automatically every 5 sec
          client.println();
          client.println("<!DOCTYPE HTML>");
          client.println("<html>");
          // client.print("line:");
          // client.print(line);
          client.println("<br/>");

          client.print(result);          
          client.println("<br/>");       

          client.println("</html>");

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
    Serial.println("client disconnected");
  }
}

String processRequest(EthernetClient client, String input)
{
  // check remote ip first - only local net allowed:
  byte rip[] = {0,0,0,0 };
  client.getRemoteIP(rip);
  IPAddress remoteNet(rip[0], rip[1], rip[2], 0); 
  if (myNet != remoteNet) {
      return "bad client ip";
  }
  
  Serial.println("processRequest");
  switch (mystate) {
    case awaiting_fixed_pin: return checkFixedPin(input); break;
    case awaiting_dyn_code:  return checkDynCode(input); break;
    default: 
      switchToState(awaiting_fixed_pin);
      return "bad internal state";
  }
}

String checkFixedPin(String input)
{
  Serial.println("checkFixedPin");
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
    return "bad fixed_pin";
  }
}

String sendNewDynCode()
{
  Serial.println("sendNewDynCode");
  int randNumber4digits = random(0,9999);

  dyn_code = String(randNumber4digits);
  return "dyn_code "+dyn_code;
}

String checkDynCode(String input)
{ 
  Serial.println("checkDynCode");
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
  Serial.println("openDoorNow");
  digitalWrite(pinTuer, LOW);   // Relais AN
  // delay(1000);              // wait for a second
  relaisOffEventId = timer.after(3000, closeRalais); // call closeRalais with delay
}

void closeRalais()
{
  Serial.println("closeRalais");
  digitalWrite(pinTuer, HIGH);   // Tür-Relaus aus
  relaisOffEventId = -1;
}

void switchToState(int newState)
{
  Serial.print("switchToState "); Serial.println(newState);
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
  Serial.println("resetState");
  switchToState(awaiting_fixed_pin);
  resetStateEventId = -1;
}

