# Cursor Værktøjer - UI

En grafisk brugergrænseflade til Cursor-udviklingsværktøjer.

## Funktioner

- **Chat Browser**: Gennemse og søg i dine Cursor AI chat historikker
- **Chat Eksport**: Udtræk chat historikker til forskellige formater
- **Editor**: Redigér og arbejd med udtrukne chats
- **Værktøjsplatform**: Fungerer som platform for flere udviklingsværktøjer

## Krav

- Flutter SDK (seneste version anbefales)
- Cursor Chat Værktøj CLI installeret i `~/.cursor/`

## Installation og kørsel

1. Installer Flutter SDK fra [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Sørg for at CLI-værktøjet er installeret (se cursor_chat_cli mappen)
3. Kør følgende kommandoer:

```bash
cd tools_ui
flutter pub get
flutter run -d linux  # Eller flutter run -d windows for Windows, flutter run -d macos for macOS
```

## Opbygning

Applikationen har følgende struktur:

- **lib/models/**: Datamodeller
- **lib/screens/**: Skærme/visninger i applikationen
- **lib/services/**: Tjenester og hjælpeklasser
- **lib/widgets/**: Genbrugelige UI-komponenter

## Integration med CLI-værktøjet

UI-applikationen integrerer med CLI-værktøjet på følgende måder:

1. **Direkte proces-kald**: Kalder CLI-værktøjet med process_run
2. **Delt kode**: Genanvender datamodeller og parsere fra CLI-koden
3. **Konfigurationsdeling**: Deler konfigurationsindstillinger

## Udvikler noter

- Applikationen er bygget med Flutter og Provider for tilstandsstyring
- SQLite-adgang sker gennem CLI-værktøjet eller direkte via sqlite3-pakken

## Komme i gang med udvikling

Se [CONTRIBUTING.md](CONTRIBUTING.md) for vejledning om hvordan man bidrager til projektet. 