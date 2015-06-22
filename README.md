# Tür auf

Die Tür (z.B. die Haustür) mit dem Handy auf Knopfdruck öffnen!

Im Kern steht ein Arduino, der an einem Output-Pin an ein Relais angeschlossen ist und damit die Tür öffnet.
Ziel ist es, dass ich Personen meines Vertrauens ermöglichen möchte, über die App die Tür zu öffnen. Dies soll natürlich so sicher sein, dass niemand sonst Zugriff hat.

## Aufbau

* **Arduino** (mit Relais und Ethernet-Shield) zum Tür öffnen. Per Internet/HTTP nicht direkt von "außen" erreichbar. (Steht bei mir im gut geschützten internen Netz.) Enthält eine einfache PIN-Logik. Die PINs (4 Ziffern) werden nur hier (im Arduino intenen Speicher) gespeichert. Der Benutzer muss sie sich merken. Dadurch entsteht auch dann ein zusätzlicher Schutz für den Fall des Handy-Verlusts. Der Arduino-Sketch findet sich hier im Repo unter "Tuerauf_arduino".

* **Web-Server** mit PHP-Logik. Von "außen" (Internet) erreichbar.
  enthält Logik zum Registrieren der Benutzer-Apps. Reicht erfolgreich authentifizierte Aufrufe an den Arduino weiter.

* **App** (hier im Repo im Basis-Verzeichnis) greift über das Internet auf den Web-Server zu.

mehr im Wiki: https://github.com/dsteinkopf/tuerauf/wiki
