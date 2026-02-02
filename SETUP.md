# E3DC Pulse - Xcode Projekt Setup

## Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15.0 oder neuer
- iOS 17.0 SDK (in Xcode enthalten)
- Ein E3DC S10e System im lokalen Netzwerk
- Git (in Xcode Command Line Tools enthalten)

## Schritt 1: Repository klonen

```bash
git clone https://github.com/devganny/E3DCPulse.git
cd E3DCPulse
```

## Schritt 2: Xcode Projekt erstellen

Da das Xcode-Projektfile (.xcodeproj) nicht im Git enthalten ist (es enthält maschinenspezifische Pfade), musst du es einmalig erstellen:

### Option A: Neues Xcode Projekt um die vorhandenen Dateien erstellen

1. **Xcode öffnen** und `File > New > Project...` wählen
2. Template: **iOS > App** auswählen, `Next` klicken
3. Projekt-Einstellungen:
   - **Product Name**: `E3DCPulse`
   - **Team**: Dein Apple Developer Account (oder Personal Team)
   - **Organization Identifier**: z.B. `com.deinname` (frei wählbar)
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`
   - Alle Checkboxen (Tests etc.) können an bleiben oder abgewählt werden
4. **Speicherort**: Wähle einen temporären Ordner (z.B. Desktop)
5. `Create` klicken

### Schritt 3: Quelldateien aus dem Git-Repo einbinden

1. Im Xcode Projekt-Navigator (linke Seitenleiste):
   - **Lösche** die automatisch erstellten Dateien:
     - `ContentView.swift` (die Standard-Datei)
     - `E3DCPulseApp.swift` (die Standard-Datei)
     - `Assets.xcassets` (den Standard-Ordner)
   - Wähle bei der Lösch-Nachfrage **"Move to Trash"**

2. **Dateien aus dem Git-Repo hinzufügen**:
   - Rechtsklick auf das `E3DCPulse` Ziel im Navigator > `Add Files to "E3DCPulse"...`
   - Navigiere zum geklonten Repository-Ordner: `E3DCPulse/E3DCPulse/`
   - Wähle **ALLE** Dateien und Ordner aus:
     - `E3DCPulseApp.swift`
     - `ContentView.swift`
     - `Views/` (Ordner)
     - `Models/` (Ordner)
     - `RSCP/` (Ordner)
     - `Assets.xcassets` (Ordner)
     - `Info.plist`
   - Einstellungen im Dialog:
     - **Copy items if needed**: ✅ Aktiviert
     - **Create groups**: ✅ Ausgewählt (nicht "Create folder references")
     - **Add to targets**: `E3DCPulse` ✅ angehakt
   - `Add` klicken

### Option B: Projekt direkt im Repository-Ordner erstellen (einfacher)

1. **Xcode öffnen** und `File > New > Project...` wählen
2. Template: **iOS > App**, `Next`
3. Projekt-Einstellungen wie in Option A
4. **Speicherort**: Wähle den übergeordneten Ordner des geklonten Repos
   - Also wenn das Repo unter `/Users/du/Developer/E3DCPulse` liegt,
     wähle `/Users/du/Developer/` als Speicherort
   - Xcode wird melden, dass der Ordner bereits existiert - bestätige dies
5. **Lösche** die Auto-generierten Standard-Dateien
6. Rechtsklick > `Add Files to "E3DCPulse"...` und füge alle Dateien aus dem `E3DCPulse/` Unterordner hinzu wie in Option A beschrieben

## Schritt 4: Projekt konfigurieren

### Info.plist einbinden
1. Wähle das **E3DCPulse** Target in den Projekt-Einstellungen
2. Gehe zum Tab **Info**
3. Unter **Custom iOS Target Properties**:
   - Falls die `Info.plist` Datei nicht automatisch erkannt wurde:
     - Gehe zu **Build Settings** > suche nach "Info.plist"
     - Setze **Info.plist File** auf: `E3DCPulse/Info.plist`

### Deployment Target
1. Target `E3DCPulse` auswählen > Tab **General**
2. **Minimum Deployments**: `iOS 17.0` (oder neuer)

### Signing
1. Target `E3DCPulse` > Tab **Signing & Capabilities**
2. **Team** auswählen (Personal Team oder Developer Account)
3. **Bundle Identifier**: z.B. `com.deinname.E3DCPulse`

### Network Permission (wichtig!)
Die `Info.plist` enthält bereits den `NSLocalNetworkUsageDescription` Key.
Falls Xcode diesen nicht automatisch erkennt:
1. Target > **Signing & Capabilities** > `+ Capability`
2. Suche und füge hinzu: **Local Network** (falls verfügbar)

## Schritt 5: Build & Run

1. Wähle ein **iPhone Simulator** oder ein verbundenes iPhone als Zielgerät
2. `Cmd+B` zum Bauen oder `Cmd+R` zum Ausführen
3. **Hinweis**: Auf dem Simulator kann keine echte TCP-Verbindung zum E3DC aufgebaut werden, da der Simulator keinen Zugang zum lokalen Netzwerk hat. Teste auf einem echten Gerät!

## Projektstruktur

```
E3DCPulse/
├── E3DCPulseApp.swift          # App Entry Point
├── ContentView.swift            # Root View mit NavigationStack
├── Info.plist                   # Netzwerk-Berechtigungen
├── Assets.xcassets/             # App Icons und Farben
├── Views/
│   └── ConnectionView.swift     # Verbindungs-UI und Batterie-Anzeige
├── Models/
│   ├── BatteryInfo.swift        # Batterie- und DCB-Datenmodelle
│   └── ConnectionSettings.swift # Verbindungseinstellungen (persistent)
└── RSCP/
    ├── Rijndael256.swift        # Rijndael-256 Verschlüsselung (32-Byte Blöcke)
    ├── RSCPEncryption.swift     # (in Rijndael256.swift enthalten) CBC-Modus
    ├── RSCPType.swift           # RSCP Datentypen
    ├── RSCPTag.swift            # RSCP Tag-Definitionen
    ├── RSCPFrame.swift          # Frame Encoder/Decoder + CRC32
    └── RSCPConnection.swift     # TCP-Verbindung + Authentifizierung + Abfragen
```

## Verwendung

1. App starten
2. Eingabefelder ausfüllen:
   - **IP-Adresse**: Lokale IP des E3DC Systems (z.B. `192.168.178.42`)
   - **Benutzername**: Dein E3DC-Portal Benutzername (E-Mail)
   - **Passwort**: Dein E3DC-Portal Passwort
   - **RSCP Passwort**: Das RSCP-Passwort (im E3DC System unter Einstellungen gesetzt)
3. **Verbinden** tippen
4. Die App zeigt:
   - Anzahl der erkannten Batterien
   - Pro Batterie: SOC, durchschnittlicher SOH, Ladezyklen, Kapazität
   - Pro Batteriemodul (DCB): SOH, SOC, Spannung, Strom, Zyklen, Kapazitäten

## Technische Details

### RSCP Protokoll
- **Port**: 5033 (TCP)
- **Verschlüsselung**: Rijndael-256-CBC (32-Byte Blockgröße, 32-Byte Key)
  - NICHT Standard-AES (das 16-Byte Blöcke verwendet)
  - Key wird mit 0xFF aufgefüllt
  - IV startet bei 0xFF...FF und wird verkettet (CBC-Chaining)
- **Frame-Format**: Magic(0xe3dc) + Ctrl + Timestamp + Length + Payload + CRC32
- **Daten-Format**: Tag(4B) + Type(1B) + Length(2B) + Data(NB)
- **Authentifizierung**: RSCP_REQ_AUTHENTICATION Container mit User + Password

### Batterie-Abfrage
1. BAT_REQ_DATA Container mit BAT_INDEX + BAT_REQ_DCB_COUNT für jede Batterie (Index 0-7)
2. Wenn DCB_COUNT > 0: Batterie ist vorhanden
3. BAT_REQ_DCB_INFO für jedes DCB-Modul liefert SOH, SOC, Spannung, etc.

## Fehlerbehebung

- **"Verbindung fehlgeschlagen"**: Prüfe ob die IP korrekt ist und das iPhone im selben WLAN wie das E3DC ist
- **"Authentifizierung fehlgeschlagen"**: Überprüfe Benutzername, Passwort und RSCP-Passwort
- **Keine Batterien gefunden**: Das System antwortet möglicherweise verzögert - versuche es erneut
- **Simulator funktioniert nicht**: TCP-Verbindungen im lokalen Netz funktionieren nur auf echten Geräten
