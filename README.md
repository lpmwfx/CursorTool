# Cursor Chat Værktøj

Et simpelt kommandolinjeværktøj til at browse og udtrække chat historikker fra Cursor AI IDE.

## Funktioner

- TUI (Text User Interface) til at browse alle chat historikker
- Udtrække chat historikker til forskellige formater (tekst, JSON, Markdown, HTML)
- Liste alle tilgængelige chat historikker
- Søge i chat historik

## Installation

1. Installer [Dart SDK](https://dart.dev/get-dart) hvis du ikke allerede har det.
2. Klon repositoriet:
   ```
   git clone https://github.com/username/cursor_chat_tool.git
   cd cursor_chat_tool
   ```
3. Installer afhængigheder:
   ```
   dart pub get
   ```
4. (Valgfrit) Byg en eksekverbar fil:
   ```
   dart compile exe bin/cursor_chat_tool.dart -o cursor_chat_tool
   ```

## Brug

### Kommandolinje argumenter

```
Cursor Chat Browser & Extractor

Brug: cursor_chat_tool [options]

-h, --help       Vis hjælp
-l, --list       List alle chat historikker
-e, --extract    Udtræk en specifik chat (id eller alle)
-f, --format     Output format (text, markdown, html, json), standard: text
-o, --output     Output mappe, standard: ./output
-c, --config     Sti til konfigurationsfil, standard: ~/.cursor_chat_tool.conf
```

### Eksempler

**Start TUI browser:**
```
dart run bin/cursor_chat_tool.dart
```

**List alle chat historikker:**
```
dart run bin/cursor_chat_tool.dart --list
```

**Udtræk en specifik chat som Markdown:**
```
dart run bin/cursor_chat_tool.dart --extract 1 --format markdown --output ./mine_chats
```

**Udtræk alle chats som HTML:**
```
dart run bin/cursor_chat_tool.dart --extract alle --format html
```

## Konfiguration

Værktøjet vil som standard forsøge at finde Cursor AI chat historikker i følgende placeringer:

- **Linux:** `~/.config/cursor/chat_history`
- **macOS:** `~/Library/Application Support/cursor/chat_history`
- **Windows:** `%APPDATA%\cursor\chat_history`

Du kan oprette en konfigurationsfil `~/.cursor_chat_tool.conf` med følgende indhold for at angive en anden placering:

```json
{
  "chatHistoryPath": "/sti/til/mine/chat/historikker"
}
```

## Udviklet af

Dette værktøj er udviklet af [Dit Navn] med hjælp fra Claude AI. 