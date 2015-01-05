/*

  Dirk Steinkopf
  
  Türöffner
 
 */

#include <SPI.h>
#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFD, 0xEC };
IPAddress ip(192,168,40,14);
int pinTuer = 8;

const int bufsize = 50;
char line[bufsize];


EthernetServer server(80);

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
          
          String lineString = line;
          int pos = lineString.indexOf("abc");
          
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
          if (pos > 0) {
            client.println("OFFEN<br/>");       
            digitalWrite(pinTuer, LOW);   // Relais AN
            delay(1000);              // wait for a second
            digitalWrite(pinTuer, HIGH);    // Relais AUS
          }
          
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

