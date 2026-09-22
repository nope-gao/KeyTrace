# KeyTrace

[简体中文](README.md) | [繁體中文](README.zh-Hant.md) | [English](README.en.md) | [日本語](README.ja.md) | [Español](README.es.md) | [Français](README.fr.md) | **Deutsch**

Lokales macOS-Werkzeug zum Aufzeichnen von Tastatur- und Mausaktivität und zum Exportieren animierter Videos mit einer 3D-Heatmap.

Die Funktionen und Ideen stammen von [xuhk/XAssistant](https://github.com/xuhk/XAssistant) und wurden nativ in Swift neu umgesetzt. Dies ist eine inoffizielle macOS-Version ohne Verbindung zum ursprünglichen Autor. Quellcode und Grafiken des Windows-Projekts wurden nicht kopiert. Veröffentlicht unter der [MIT-Lizenz](LICENSE).

## Funktionen

- Aufzeichnung im Hintergrund über die Menüleiste, mit Tagesstatistik und Tastatur-Heatmap.
- Erkennung integrierter und externer Tastaturen; MacBook- und Mac-Vollformatlayouts mit manueller Auswahl.
- Start- und Endzeit mit Kurzbefehlen zur ersten Aufzeichnung und zur aktuellen Zeit.
- Export animierter Anschläge und kumulierter Heatmaps als MP4 mit 1080p und 30 Bildern/s in Downloads; Leerlauf wird automatisch verkürzt.
- Maus ein- oder ausschließen; Geschwindigkeiten von 0.5× bis 256×, einschließlich 128×.
- Dynamische Farbskala anhand der aktuell höchsten kumulierten Anzahl oder feste Skala anhand des endgültigen Maximums im gewählten Zeitraum.
- Fünf Sekunden Schlussbild mit langsam rotierender Kamera.
- Synchroner Klang für jeden Anschlag mit unterschiedlicher Klangfarbe pro physischer Taste; Tastatur-, mechanischer, sanfter oder stummer Modus.

## Installation

Öffentliche Beta **v0.4.2-beta.1**; App **0.4.2, Build 14**. Erfordert **Apple Silicon (arm64), macOS 13+**. Intel wird nicht unterstützt. **Ad-hoc-signiert, nicht von Apple notarisiert; Updates können eine erneute Freigabe erfordern.**

Lade das [App-ZIP](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.2-beta.1/KeyTrace-arm64.zip) und [SHA256SUMS](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.2-beta.1/SHA256SUMS) von der [öffentlichen Beta](https://github.com/nope-gao/KeyTrace/releases/tag/v0.4.2-beta.1) und prüfe sie mit dem folgenden Befehl. Das automatisch erzeugte Source code ZIP ist nicht die App. Entpacke **KeyTrace.app** und verschiebe sie vor dem Öffnen nach `~/Applications`.

```bash
# In the folder containing the downloaded ZIP and SHA256SUMS
awk '$2 == "KeyTrace-arm64.zip"' SHA256SUMS | shasum -a 256 -c -
```

Terminal-Installation dieser konkreten Pre-release, ohne `/latest`:

```bash
curl -fsSL https://raw.githubusercontent.com/nope-gao/KeyTrace/v0.4.2-beta.1/install.sh -o /tmp/keytrace-install.sh
bash /tmp/keytrace-install.sh --version v0.4.2-beta.1
```

Der Installer prüft SHA-256, Version und Signatur ohne sudo. Bei laufender App stoppt er, identische Installationen bleiben unverändert und inkompatible Signaturen werden vor dem Ersetzen abgewiesen. Zur Migration die alte App beenden und sichern, manuell ersetzen und erneut freigeben. Aufzeichnungen bleiben erhalten.

Blockiert macOS den ersten Start, prüfe die Herkunft und nutze **Systemeinstellungen → Datenschutz & Sicherheit → Dennoch öffnen** nur für diese App. Gatekeeper, SIP und systemweite Schutzfunktionen nicht deaktivieren. Erlaubt die Geräteverwaltung keine Ausnahme, Installation abbrechen.

Unter **Datenschutz & Sicherheit → Eingabeüberwachung** die App am tatsächlichen Installationsort hinzufügen und erlauben, dann beenden und erneut öffnen. Bei Pause fortsetzen. Tasten drücken und klicken: Zeit des letzten Ereignisses und Zähler müssen steigen. Ein aktivierter Schalter reicht nicht aus. Bei Problemen nach einem Update die App beenden, den alten Eintrag entfernen und die neue App hinzufügen. Bei Bedarf den untenstehenden, auf diese App begrenzten Reset ausführen und manuell erneut erlauben.

```bash
tccutil reset ListenEvent app.keytrace.mac
```

KeyTrace verwendet einen eigenen Datenordner und importiert keine Aufzeichnungen anderer Apps automatisch. Erlaube bei der ersten Installation die Eingabeüberwachung.

## Sprache

Die Voreinstellung lautet **Systemsprache**. Die App durchsucht die geordnete macOS-Sprachliste nach einer unterstützten Sprache: **简体中文, 繁體中文, English, 日本語, Español, Français, Deutsch**. Ohne passende Sprache wird Englisch verwendet. Unten im Fenster kannst du die Sprache wählen oder zur Systemsprache zurückkehren; die Einstellung wird gespeichert.

Oberfläche, Menüs, bereits angezeigte Meldungen, Datums- und Zahlenformate, Mausbeschriftungen, Funktionstastennamen und Videotexte folgen dieser Auswahl. Buchstabentasten behalten das physische ANSI-Layout. Das Video behält die Sprache vom Beginn des Exports; währenddessen ist die manuelle Umschaltung deaktiviert. Die Sprache eigener Berechtigungsdialoge und technischer Systemfehler bestimmt macOS.

## Videoklang

Wähle **Tastenanschläge** (Standard), **Mechanisch**, **Sanfte Anschläge** oder **Stumm**. Jede physische Taste hat eine eigene kurze Klangfarbe. Der Klang wird nur beim Drücken ausgelöst und auf das erste Videobild mit dem sichtbaren Anschlag ausgerichtet. Bei hoher Geschwindigkeit überlagern sich dicht aufeinanderfolgende Klänge. Ohne Maus werden auch keine Mausklicks vertont. Die letzten fünf Sekunden bleiben still.

Der Ton wird lokal synthetisiert. Mikrofon, Aufnahmen deiner echten Tastatur und externe Klangdateien werden nicht verwendet. Videos mit Ton enthalten eine AAC-Spur mit 48 kHz; Stumm erzeugt keine Audiospur.

## Aus dem Quellcode bauen

```bash
xcode-select --install
bash build.sh
```

Lokale Builds sind ad-hoc-signiert; nach dem Ersetzen der App kann eine erneute Freigabe erforderlich sein.

## Verwendung

Wähle Zeitraum, Tempo, Mausoption, Farbskala und Klang und klicke auf **In Downloads exportieren**. Aktivität aus nicht aufgezeichneten Zeiträumen lässt sich nicht wiederherstellen.

## Lokale Daten und Datenschutz

Die Daten liegen unter `~/Library/Application Support/KeyTrace/`. Die App lädt sie nicht hoch und enthält keine Telemetrie. Das Installationsskript greift zum Herunterladen auf GitHub zu.

Für die animierte Wiedergabe werden Druck- und Loslasszeitpunkte, physische Tastenkennungen, Geräteinformationen und Ereignisreihenfolge gespeichert. Hinzu kommen Anwendungsnamen, Bundle IDs und Nutzungsdauer. Fertiger Text aus Eingabemethoden, Fenstertitel, Webadressen und Mauskoordinaten werden nicht gelesen. **Tasten und ihre Reihenfolge können dennoch Rückschlüsse auf eingegebenen Text zulassen. Aufzeichnungen sind sensible Daten; veröffentliche den Datenordner nicht.**

Die Pause stoppt neue Eingaben und Nutzungszeitstatistiken, behält jedoch den Verlauf. Daten werden lokal im Klartext gespeichert und nicht automatisch gelöscht. Vor dem Verschieben von Daten, Export-Caches und unerwünschten Videos in den Papierkorb die App beenden.

`~/Library/Application Support/KeyTrace/` · `~/Library/Caches/KeyTrace/VideoJobs/` · `~/Downloads/KeyTrace-*.mp4`

## Bekannte Einschränkungen

- Hauptsächlich ANSI-Layouts. ISO/JIS sind nicht vollständig unterstützt; die automatische Erkennung deckt möglicherweise nicht alle Drittgeräte ab.
- Fn-, Medien- und sichere Eingaben werden möglicherweise nicht vollständig aufgezeichnet. Touch ID wird nicht als normale Taste erfasst.
- Bei mehreren Tastaturen kann die Zuordnung zur Quelle eingeschränkt sein. Automatische Wiederholungen beim Gedrückthalten zählen nicht als einzelne Anschläge.
- Videos werden direkt mit SceneKit, Metal und AVFoundation erzeugt; Blender wird nicht benötigt.
