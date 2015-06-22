# Tür auf

Die Tür (z.B. die Haustür) mit dem Handy auf Knopfdruck öffnen!

Im Kern steht ein Arduino, der an einem Output-Pin an ein Relais angeschlossen ist und damit die Tür öffnet.
Ziel ist es, dass ich Personen meines Vertrauens ermöglichen möchte, über die App die Tür zu öffnen. Dies soll natürlich so sicher sein, dass niemand sonst Zugriff hat.

## Aufbau

* **Arduino** (mit Relais und Ethernet-Shield) zum Tür öffnen.
* **Web-Server** Von "außen" (Internet) erreichbar.
  enthält Logik zum Registrieren der Benutzer-Apps. Reicht erfolgreich authentifizierte Aufrufe an den Arduino weiter.
* **App** (hier im Repo im Basis-Verzeichnis) greift über das Internet auf den Web-Server zu.

mehr im Wiki: https://github.com/dsteinkopf/tuerauf/wiki

# Hinweis

Diese App, jeglicher Code und Informationen dienen lediglich zu Informations- und Weiterbildungszwecken. Sie sind nicht für den Produktivbetrieb gedacht. Der Anbieter der App stellt sie, so wie sie sind, zur Verfügung - ohne jeglichen Support oder Haftung für etwaige direkte oder indirekte Schäden.
