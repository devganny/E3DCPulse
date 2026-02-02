# E3DC Pulse - Xcode Projekt Setup

## Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15.0 oder neuer
- iOS 17.0 SDK (in Xcode enthalten)
- Ein E3DC S10e System im lokalen Netzwerk

## Schritt 1: Repository klonen

```bash
git clone https://github.com/devganny/E3DCPulse.git
cd E3DCPulse
```

## Schritt 2: Projekt in Xcode öffnen

Das Xcode-Projekt ist im Repository enthalten. Einfach per Doppelklick öffnen:

```bash
open E3DCPulse.xcodeproj
```

Oder in Xcode: `File > Open...` und die Datei `E3DCPulse.xcodeproj` auswählen.

## Schritt 3: Signing konfigurieren

1. In Xcode: Wähle das **Target** `E3DCPulse` (linke Seitenleiste, blaues Icon anklicken)
2. Tab **Signing & Capabilities**
3. **Team** auswählen (dein Personal Team oder Developer Account)
4. Xcode passt den Bundle Identifier automatisch an

## Schritt 4: Build & Run

1. Wähle ein verbundenes **iPhone** als Zielgerät (oben in der Toolbar)
2. `Cmd+R` zum Ausführen
3. **Wichtig**: Auf dem Simulator funktioniert keine TCP-Verbindung zum E3DC im lokalen Netzwerk. Teste auf einem echten Gerät!

## Projektstruktur

```
E3DCPulse/
├── E3DCPulse.xcodeproj/        # Xcode Projekt (fertig konfiguriert)
└── E3DCPulse/
    ├── E3DCPulseApp.swift       # App Entry Point
    ├── ContentView.swift        # Root View mit NavigationStack
    ├── Assets.xcassets/         # App Icons und Farben
    ├── Views/
    │   └── ConnectionView.swift # Verbindungs-UI und Batterie-Anzeige
    ├── Models/
    │   ├── BatteryInfo.swift        # Batterie- und DCB-Datenmodelle
    │   └── ConnectionSettings.swift # Verbindungseinstellungen (persistent)
    └── RSCP/
        ├── Rijndael256.swift    # Rijndael-256 Verschlüsselung (32-Byte Blöcke)
        ├── RSCPType.swift       # RSCP Datentypen
        ├── RSCPTag.swift        # RSCP Tag-Definitionen
        ├── RSCPFrame.swift      # Frame Encoder/Decoder + CRC32
        └── RSCPConnection.swift # TCP-Verbindung + Authentifizierung + Abfragen
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
