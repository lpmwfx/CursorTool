# Bidrag til Cursor Udviklingsværktøjer

Tak for din interesse i at bidrage til Cursor Udviklingsværktøjer! Dette dokument indeholder retningslinjer for, hvordan du kan bidrage til projektet.

## Komme i gang

1. **Fork** projektet på GitHub
2. **Clone** din fork til din lokale maskine
3. **Installer** udviklingsmiljøet:
   ```bash
   # For CLI-delen
   cd cursor_chat_cli
   dart pub get
   
   # For UI-delen
   cd tools_ui
   flutter pub get
   ```

## Udvikling

### CLI-delen

CLI-delen er skrevet i ren Dart uden Flutter-afhængigheder. Den er designet til at køre som et kommandolinjeværktøj.

For at køre CLI-delen i udviklingstilstand:

```bash
cd cursor_chat_cli
dart run bin/cursor_chat_tool.dart
```

### UI-delen

UI-delen er bygget med Flutter og kræver Flutter SDK. Den bruger Provider til tilstandsstyring.

For at køre UI-delen i udviklingstilstand:

```bash
cd tools_ui
flutter run -d linux  # Eller windows/macos
```

## Pull Requests

1. **Opret en ny branch** for hver feature eller fejlrettelse
2. **Skriv tests** hvor det er relevant
3. **Opdater dokumentationen** hvis du ændrer API eller funktionalitet
4. **Send en Pull Request** med en klar beskrivelse af ændringerne

## Kodestil

- Følg [Dart's stilguide](https://dart.dev/guides/language/effective-dart/style)
- Brug `dart format` til at formatere koden
- Brug meningsfulde variabel- og funktionsnavne
- Skriv dokumentationskommentarer til offentlige metoder og klasser

## Rapportering af fejl

- Brug GitHub Issues til at rapportere fejl
- Inkluder trin til at reproducere fejlen
- Nævn din operativsystemversion og Dart/Flutter-version

## Funktionsanmodninger

Funktionsanmodninger er velkomne, men overvej følgende:

- Er funktionen i tråd med projektets mål?
- Kan funktionen implementeres generelt eller er den for specifik?
- Er du villig til at hjælpe med implementeringen?

## Kommunikation

- Hold diskussioner i GitHub Issues eller Pull Requests
- Vær respektfuld og konstruktiv i dine kommentarer
- Tag issues korrekt for at hjælpe med organisering

## Licens

Ved at bidrage til dette projekt accepterer du, at dine bidrag vil blive licenseret under projektets licens (MIT License). 