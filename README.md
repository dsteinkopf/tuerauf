# Tür auf

Die Tür (z.B. die Haustür) mit dem Handy auf Knopfdruck öffnen!

Im Kern steht ein Arduino, der an einem Output-Pin an ein Relais angeschlossen ist und damit die Tür öffnet.
Ziel ist es, dass ich Personen meines Vertrauens ermöglichen möchte, über die App die Tür zu öffnen. Dies soll natürlich so sicher sein, dass niemand sonst Zugriff hat.

## Aufbau

* **Arduino** (mit Relais) zum Tür öffnen. Nicht von "außen" (Internet) erreichbar.
  enthält eine einfache PIN-Logik. Die PINs (4 Ziffern) werden nur hier gespeichert. Der Benutzer muss sie sich merken. Dadurch entsteht auch dann ein zusätzlicher Schutz für den Fall des Handy-Verlusts.

* **Web-Server** mit PHP-Logik. Von "außen" (Internet) erreichbar.
  enthält Logik zum Registrieren der Benutzer-Apps. Reicht erfolgreich authentifizierte Aufrufe an den Arduino weiter.

* **App**
