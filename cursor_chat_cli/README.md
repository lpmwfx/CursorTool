# Cursor Chat Værktøj

Et simpelt kommandolinjeværktøj til at browse og udtrække chat historikker fra Cursor AI IDE's SQLite databaser.

## Funktioner

- TUI (Text User Interface) til at browse alle chat historikker
- Udtrække chat historikker til forskellige formater (tekst, JSON, Markdown, HTML)
- Liste alle tilgængelige chat historikker
- Gennemsøge dine Cursor AI chat historikker

## Installation

### Metode 1: Installér fra kildekode (kræver Dart SDK)

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
4. Byg og installér:
   ```
   dart compile exe bin/cursor_chat_tool.dart -o cursor_chat_tool
   mkdir -p ~/.cursor
   cp cursor_chat_tool ~/.cursor/
   chmod +x ~/.cursor/cursor_chat_tool
   ln -sf ~/.cursor/cursor_chat_tool ~/.cursor/cursorchat
   ```
5. Tilføj til PATH i din .bashrc:
   ```
   echo -e '\n# Tilføj cursor_chat_tool til PATH\nexport PATH="$HOME/.cursor:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

### Metode 2: Kør direkte fra kildekode

Hvis du foretrækker at køre værktøjet direkte uden at bygge det:

```
cd cursor_chat_tool
dart run bin/cursor_chat_tool.dart [options]
```

## Brug

### Kommandolinje argumenter

```
Cursor Chat Browser & Extractor

Brug: cursorchat [options]

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
cursorchat
```

**List alle chat historikker:**
```
cursorchat --list
```

**Udtræk en specifik chat som Markdown:**
```
cursorchat --extract 1 --format markdown --output ./mine_chats
```

**Udtræk alle chats som HTML:**
```
cursorchat --extract alle --format html --output ./mine_chats
```

## Konfiguration

Værktøjet vil som standard forsøge at finde Cursor AI chat historikker i følgende placeringer:

- **Linux:** `~/.config/Cursor/User/workspaceStorage`
- **macOS:** `~/Library/Application Support/Cursor/User/workspaceStorage`
- **Windows:** `%APPDATA%\Cursor\User\workspaceStorage`

Du kan oprette en konfigurationsfil `~/.cursor_chat_tool.conf` med følgende indhold for at angive en anden placering:

```json
{
  "workspaceStoragePath": "/sti/til/cursor/workspaceStorage"
}
```

## Sådan virker det

Værktøjet:
1. Finder alle `state.vscdb` SQLite databaser i Cursor's workspace storage mapper
2. Udtrækker chat data fra disse databaser ved at søge efter specifikke nøgler
3. Parser JSON-dataene og strukturerer dem til et forståeligt format
4. Viser dem i en TUI eller eksporterer dem til de ønskede formater

## Understøttede filformater

- **Text (.txt)**: Simpel, læsbar tekstformat
- **Markdown (.md)**: Formateret med Markdown, egnet til visning på platforme som GitHub
- **HTML (.html)**: Formateret med CSS, kan åbnes direkte i en browser
- **JSON (.json)**: Rå dataformat, egnet til yderligere databehandling

## Fejlfinding

### Værktøjet finder ikke mine chats
- Sørg for at Cursor IDE er installeret på standardplaceringen
- Tjek sti-formatet i konfigurationen (`workspaceStoragePath`)
- På Linux, sørg for korrekt case-sensitiv sti (bemærk stort "C" i "Cursor")

### Installation problemer
- Sørg for at Dart SDK er korrekt installeret og tilgængeligt i PATH
- Tjek rettigheder til ~/.cursor mappen og eksekverbare filer

## Udviklet af

Dette værktøj er udviklet af Lars med hjælp fra Claude 3.7 AI. 