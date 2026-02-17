# Quarkus Demo: Drei Microservices

Dieses Repository enthält drei Quarkus-Microservices:

1. **first-name-service**: liefert zufällige Vornamen.
2. **last-name-service**: liefert zufällige Nachnamen.
3. **hello-orchestrator-service**: ruft beide Services auf und liefert eine kombinierte Hello-Antwort.

## Voraussetzungen

- Java 17+
- Maven 3.9+

## Projektstruktur

- `first-name-service` (Port `8081`)
- `last-name-service` (Port `8082`)
- `hello-orchestrator-service` (Port `8080`)
- `scripts/services.sh` (Start/Stop/Status/Logs aller Services)

## Logging im JSON-Format

Alle drei Services sind so konfiguriert, dass Logs im JSON-Format auf die Konsole geschrieben werden:

- `quarkus.log.console.json=true`

Wenn die Services über das Script gestartet werden, findest du die JSON-Logs in:

- `logs/first-name-service.log`
- `logs/last-name-service.log`
- `logs/hello-orchestrator-service.log`

## Services über Script starten/stoppen (empfohlen)

Im Repository-Root:

### Start

```bash
./scripts/services.sh start
```

Was passiert bei `start`:

1. Es wird ein Build ausgeführt (`mvn -DskipTests package`).
2. Alle drei Services werden als Hintergrundprozesse gestartet.
3. PID-Dateien werden unter `.run/` abgelegt.
4. Logs landen unter `logs/`.

### Status prüfen

```bash
./scripts/services.sh status
```

### Stop (sauberes Beenden)

```bash
./scripts/services.sh stop
```

Das Script beendet zuerst regulär per `kill` und nutzt nur bei Bedarf ein `kill -9`.

### Neustart

```bash
./scripts/services.sh restart
```

### Logs anzeigen (wichtig für Logging-Tests)

Du kannst dir die Service-Logs jederzeit direkt in der Shell anzeigen lassen:

```bash
./scripts/services.sh logs
```

Live-Mitschnitt aller Services (fortlaufend, ideal für Library-Tests):

```bash
./scripts/services.sh logs --follow
```

Nur einen einzelnen Service ansehen:

```bash
./scripts/services.sh logs first-name-service
./scripts/services.sh logs last-name-service --follow
./scripts/services.sh logs hello-orchestrator-service --follow
```

Hinweis: Wenn noch keine Logdatei existiert, zeigt das Script einen Hinweis an, dass du die Services zuerst starten musst.

## Orchestrierungsservice aufrufen (Hauptendpoint)

Sobald alle drei Services laufen:

```bash
curl http://localhost:8080/hello
```

Beispielantwort:

```json
{
  "message": "Hallo Emma Becker!",
  "firstName": "Emma",
  "lastName": "Becker"
}
```

## Einzelne Services manuell in Dev Mode starten (optional)

Wenn du statt Script den Dev Mode verwenden willst, öffne **3 Terminals** im Repository-Root (`/workspace/demoservice`) und starte jeweils:

### 1) First Name Service

```bash
mvn -pl first-name-service quarkus:dev
```

Endpoint testen:

```bash
curl http://localhost:8081/first-name/random
```

### 2) Last Name Service

```bash
mvn -pl last-name-service quarkus:dev
```

Endpoint testen:

```bash
curl http://localhost:8082/last-name/random
```

### 3) Hello Orchestrator Service

```bash
mvn -pl hello-orchestrator-service quarkus:dev
```

## Optional: Build aller Module

```bash
mvn clean package
```

## Hinweise

- Wenn einer der Basis-Services nicht läuft, kann der `/hello`-Aufruf fehlschlagen.
- Ports können über die jeweiligen `application.properties` angepasst werden.
