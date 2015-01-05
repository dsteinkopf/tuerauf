/*

  Dirk Steinkopf
  
  Türöffner
 
 */

#include <SPI.h>
#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFD, 0xEC };
IPAddress ip(192,168,40,14);
const int ip_port = 1080;
int pinTuer = 8;

const String fixed_pin = "4242";
String dyn_code;

const int bufsize = 50;
char line[bufsize];

enum serverstate {
  awaiting_fixed_pin,
  awaiting_dyn_code,
};
serverstate mystate = awaiting_fixed_pin;


EthernetServer server(ip_port);

void setup() {
  
  pinMode(pinTuer, OUTPUT);
  digitalWrite(pinTuer, HIGH);   // Tür-Relaus aus

  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }

  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
}


void loop() {
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
          
          String result = processRequest(line);

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

String processRequest(String input)
{
  switch (mystate) {
    case awaiting_fixed_pin: return checkFixedPin(input); break;
    case awaiting_dyn_code:  return checkDynCode(input); break;
    default: 
      mystate = awaiting_fixed_pin;
      return "bad internal state";
  }
}

String checkFixedPin(String input)
{
  int pos = input.indexOf(fixed_pin);
  
  if (pos > 0) {
    // fixed_pin stimmt
    mystate = awaiting_dyn_code;
    return sendNewDynCode();
  }
  else {
    // fixed_pin falsch
    mystate = awaiting_fixed_pin;
    return "bad fixed_pin";
  }
}

String sendNewDynCode()
{
  int randNumber4digits = random(0,9999);

  dyn_code = String(randNumber4digits);
  return "dyn_code "+dyn_code;
}

String checkDynCode(String input)
{ 
  int pos = input.indexOf(dyn_code);
  
  if (pos > 0) {
    // dyn_code stimmt
    openDoorNow();
    mystate = awaiting_fixed_pin;
    return "OFFEN";
  }
  else {
    // dyn_code falsch - einfach von vorne
    mystate = awaiting_fixed_pin;
    return "bad dyn_code";
  }
}

void openDoorNow()
{
    digitalWrite(pinTuer, LOW);   // Relais AN
    delay(1000);              // wait for a second
    digitalWrite(pinTuer, HIGH);    // Relais AUS
}

