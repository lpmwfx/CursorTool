import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart' show run;
import '../models/chat.dart';
import 'settings_service.dart';

// Forenklet version uden isolates for at sikre stabilitet
class ChatService extends ChangeNotifier {
  final SettingsService _settings;
  List<Chat> _chats = [];
  bool _isLoading = false;
  String _lastError = '';

  ChatService(this._settings);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  // Kør CLI-kommando på en sikker måde
  Future<ProcessResult> _runCliCommand(List<String> arguments) async {
    print('Kører CLI-kommando: ${_settings.cliPath} ${arguments.join(' ')}');
    try {
      return await compute(_computeRunner, {
        'cliPath': _settings.cliPath,
        'arguments': arguments,
      });
    } catch (e) {
      print('Fejl ved kørsel af CLI-kommando: $e');
      // Returnerer en dummy ProcessResult ved fejl
      return ProcessResult(
          -1, -1, 'Kunne ikke køre kommando: $e', 'Process kunne ikke startes');
    }
  }

  // Kør en CLI-kommando direkte og returner resultatet
  Future<ProcessResult> runDirectCliCommand(List<String> arguments) async {
    try {
      // Tjek at CLI-værktøjet eksisterer
      final cliPath = _settings.cliPath;
      final cliFile = File(cliPath);

      // Kontroller om filen eksisterer og er eksekverbar
      if (await cliFile.exists()) {
        print('CLI-værktøj fundet på disk: $cliPath');

        // Tjek om filen er eksekverbar på Unix-systemer
        if (!Platform.isWindows) {
          try {
            final stat = await cliFile.stat();
            final isExecutable =
                stat.mode & 0x1 != 0; // Check if executable bit is set

            if (!isExecutable) {
              print(
                  'Advarsel: CLI-værktøjet er ikke markeret som eksekverbart');
            }
          } catch (e) {
            print('Fejl ved tjek af eksekverbar status: $e');
          }
        }
      } else {
        print(
            'CLI-værktøj ikke fundet som fil. Prøver som system-kommando: $cliPath');
      }

      // Kør kommandoen med alle argumenter
      print('Kører kommando: $cliPath med args: $arguments');

      return await Process.run(
        cliPath,
        arguments,
        workingDirectory: _settings.workspacePath,
        runInShell: true,
      );
    } catch (e) {
      print('Fejl ved kørsel af CLI-kommando: $e');
      throw Exception('Fejl ved kørsel af CLI-kommando: $e');
    }
  }

  // Hent alle chats via CLI-værktøjet - MED COMPUTE
  Future<void> loadChats() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      print('Starter indlæsning af chats direkte fra CLI-output');

      // Tjek om output-mappen eksisterer
      final outputDir = Directory(_settings.outputPath);
      if (!await outputDir.exists()) {
        print('Output-mappen findes ikke. Opretter: ${_settings.outputPath}');
        await outputDir.create(recursive: true);
      }

      // Kør CLI-kommando direkte med --list i compute
      print('Kører CLI-kommando: ${_settings.cliPath} --list');
      final result = await _runCliCommand(['--list']);

      print('CLI-kommando afsluttet med kode: ${result.exitCode}');

      if (result.exitCode != 0) {
        _lastError = 'Fejl ved indlæsning af chats: ${result.stderr}';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Parse stdout direkte
      final stdoutStr = result.stdout.toString();
      print('Stdout længde: ${stdoutStr.length} tegn');

      // Extract chat information fra stdout
      _chats = [];

      // Find alle linjer der indeholder chat information
      final lines = stdoutStr.split('\n');
      final chatLines = <String>[];

      bool startedChats = false;
      for (final line in lines) {
        if (line.contains('ID | Titel | Dato | Antal')) {
          startedChats = true;
          continue;
        }
        if (startedChats &&
            line.trim().isNotEmpty &&
            !line.contains('Fandt') &&
            !line.contains('-------')) {
          chatLines.add(line.trim());
        }
      }

      print('Fandt ${chatLines.length} chat-linjer i output');

      // Parse hver chat-linje
      for (final line in chatLines) {
        try {
          // Format: ID | Titel | Dato | Antal
          final parts = line.split('|');
          if (parts.length >= 4) {
            final id = parts[0].trim();
            final title = parts[1].trim();
            final dato = parts[2].trim();
            final antalStr = parts[3].trim();
            final antal = int.tryParse(antalStr) ?? 0;

            print(
                'Parsede chat: ID=$id, Titel=$title, Dato=$dato, Antal=$antal');

            // Opret en liste af beskeder
            final messages = <ChatMessage>[];

            // Sikre at vi altid har mindst én besked for at indikere at dette er en forenklet visning
            messages.add(
              ChatMessage(
                content:
                    'Denne chat viser kun oversigten. Klik på chat for at se komplet indhold.',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );

            // Tilføj også en bruger-besked for at sikre visning af begge roller
            if (antal > 1) {
              messages.add(
                ChatMessage(
                  content:
                      'Denne chat indeholder $antal beskeder i alt. Klik for at se dem alle.',
                  isUser: true,
                  timestamp:
                      DateTime.now().subtract(const Duration(minutes: 5)),
                ),
              );
            }

            // Opret Chat objekt med fejlhåndtering
            try {
              final chat = Chat(
                id: id,
                title: title,
                messages: messages,
              );
              _chats.add(chat);
            } catch (e) {
              print('Fejl ved oprettelse af Chat objekt: $e');
            }
          }
        } catch (e) {
          print('Fejl ved parsing af chat-linje: $e, Linje: $line');
        }
      }

      // Sorter chats efter ID (da vi ikke har rigtige lastMessageTime)
      if (_chats.isNotEmpty) {
        print('Sorterer ${_chats.length} chats');
        // Sorter med højeste ID først (nyeste chats øverst)
        _chats.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
      } else {
        print('Ingen chats at sortere');
      }
    } catch (e) {
      print('Fejl i loadChats: $e');
      _lastError = 'Fejl: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Udtræk en specifik chat
  Future<bool> extractChat(String chatId, String format) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      print('Starter udtrækning af chat ID $chatId i format $format');

      // Tjek om output-mappen eksisterer
      final outputDir = Directory(_settings.outputPath);
      if (!await outputDir.exists()) {
        print('Output-mappen findes ikke. Opretter: ${_settings.outputPath}');
        await outputDir.create(recursive: true);
      }

      // Kør extract kommandoen
      print(
          'Kører extract kommando: ${_settings.cliPath} --extract $chatId --format $format --output ${_settings.outputPath}');
      final result = await _runCliCommand([
        '--extract',
        chatId,
        '--format',
        format,
        '--output',
        _settings.outputPath
      ]);

      print('CLI-kommando afsluttet med kode: ${result.exitCode}');
      if (result.stdout.toString().isNotEmpty) {
        print(
            'Stdout første 100 tegn: ${result.stdout.toString().substring(0, math.min(100, result.stdout.toString().length))}...');
      }

      if (result.exitCode != 0) {
        _lastError = 'Fejl ved udtrækning af chat: ${result.stderr}';
        print('Stderr: ${result.stderr}');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check stdout for filnavne - CLI udskriver normalt "Chat udtrukket til: /sti/til/fil.format"
      String outputFilePath = '';
      final stdoutStr = result.stdout.toString();
      final regExp = RegExp(r'Chat udtrukket til: ([^\r\n]+)');
      final match = regExp.firstMatch(stdoutStr);

      if (match != null && match.groupCount >= 1) {
        outputFilePath = match.group(1)!.trim();
        print('Fandt output-fil fra CLI output: $outputFilePath');

        // Tjek om filen eksisterer
        final outputFile = File(outputFilePath);
        if (await outputFile.exists()) {
          print('Output-fil bekræftet: $outputFilePath');

          // Hvis formatet er JSON, kopiér til standardnavnet chatId.json i output-mappen
          if (format == 'json') {
            final standardOutputFile =
                File('${_settings.outputPath}/$chatId.json');
            try {
              final jsonContent = await outputFile.readAsString();
              // Forsøg at validere JSON
              json.decode(jsonContent); // Vil fejle hvis ikke valid JSON
              await standardOutputFile.writeAsString(jsonContent);
              print(
                  'Kopieret JSON til standard filnavn: ${standardOutputFile.path}');
            } catch (e) {
              print('Fejl ved kopiering eller validering af JSON: $e');
            }
          }

          return true;
        }
      }

      // Alternativ: Tjek standard placeringen chatId.format i output-mappen
      final standardOutputFile =
          File('${_settings.outputPath}/$chatId.$format');
      if (await standardOutputFile.exists()) {
        print('Fandt standard output-fil: ${standardOutputFile.path}');
        return true;
      }

      // Forsøg at gemme stdout til fil som sidste udvej
      if (stdoutStr.trim().isNotEmpty && !stdoutStr.contains('Brug:')) {
        // Fjern CLI outputtekst som "Chat udtrukket til:" fra begyndelsen
        String contentToSave = stdoutStr;

        // Hvis det er JSON, forsøg at finde JSON indhold (første "{" til sidste "}")
        if (format == 'json') {
          final jsonStartIdx = stdoutStr.indexOf('{');
          final jsonEndIdx = stdoutStr.lastIndexOf('}');

          if (jsonStartIdx >= 0 && jsonEndIdx > jsonStartIdx) {
            contentToSave = stdoutStr.substring(jsonStartIdx, jsonEndIdx + 1);
            print('Ekstraheret mulig JSON-indhold fra output');

            // Valider JSON
            try {
              json.decode(contentToSave);
              print('JSON valideret og er gyldig');
            } catch (e) {
              print('Ekstraheret indhold er ikke gyldig JSON: $e');
              contentToSave =
                  '{"error": "Kunne ikke udtrække gyldig JSON", "rawOutput": ${json.encode(stdoutStr)}}';
            }
          } else {
            // Ingen JSON fundet, opret et simpelt JSON-objekt med outputtet
            contentToSave =
                '{"error": "Ingen JSON data fundet", "rawOutput": ${json.encode(stdoutStr)}}';
          }
        }

        print('Gemmer manuelt indhold til fil: ${standardOutputFile.path}');
        try {
          await standardOutputFile.writeAsString(contentToSave);
          print('Gemt indhold til fil');
          return true;
        } catch (e) {
          print('Fejl ved manuel gemning af output: $e');
          _lastError = 'Kunne ikke gemme output til fil: $e';
        }
      } else {
        // Fejlbesked baseret på indhold
        if (stdoutStr.contains('Brug:')) {
          _lastError =
              'CLI-værktøjet kunne ikke forstå kommandoen. Tjek at værktøjet er den rette version.';
        } else {
          _lastError = 'Ingen output genereret ved udtrækning.';
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Fejl ved udtrækning: $e';
      print('Extract fejl: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vis TUI browseren
  Future<bool> showTuiBrowser() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      print('Forsøger at starte CLI-værktøjet: ${_settings.cliPath}');

      // Tjek om CLI-værktøjet eksisterer
      final cliFile = File(_settings.cliPath);
      if (!cliFile.existsSync()) {
        print('CLI-værktøj ikke fundet på stien: ${_settings.cliPath}');

        // Let's check few obvious paths
        final homeDir = Platform.environment['HOME'] ?? '';
        final possiblePaths = [
          path.join(homeDir, '.cursor', 'cursor_chat_tool'),
          path.join(homeDir, 'Repo på HDD', 'CursorTool', 'cursor_chat_cli',
              'cursor_chat_tool'),
          '/usr/local/bin/cursor_chat_tool',
        ];

        bool found = false;
        for (final testPath in possiblePaths) {
          if (File(testPath).existsSync()) {
            print('Fandt CLI-værktøj på alternativ sti: $testPath');
            await _settings.updateCliPath(testPath);
            found = true;
            break;
          }
        }

        if (!found) {
          throw Exception(
              'CLI-værktøj kunne ikke findes: ${_settings.cliPath}');
        }
      }

      // Kører CLI-værktøjet med --list for at undgå TUI-mode der låser terminalen
      print('Kører CLI-værktøj med --list i stedet for TUI browseren');
      final result = await _runCliCommand(['--list']);

      print('CLI kommando returnerede med kode: ${result.exitCode}');

      if (result.exitCode != 0) {
        throw Exception(
            'CLI returnerede fejlkode ${result.exitCode}: ${result.stderr}');
      }

      // Auto-opdater chat-listen med det samme
      print('Genindlæser chats efter vellykket kommando');
      await loadChats();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Fejl ved start af CLI-værktøj: $e';
      print('CLI fejl: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

// Helper function til at køre CLI-kommandoer i en isoleret tråd
Future<ProcessResult> _computeRunner(Map<String, dynamic> params) async {
  final cliPath = params['cliPath'] as String;
  final arguments = params['arguments'] as List<dynamic>;

  try {
    return await run(
      cliPath,
      arguments.cast<String>(),
      runInShell: true,
      stdoutEncoding: const Utf8Codec(),
      stderrEncoding: const Utf8Codec(),
    );
  } catch (e) {
    // Returnerer en dummy ProcessResult ved fejl
    return ProcessResult(
        -1, -1, 'Compute fejl: $e', 'Compute kunne ikke køre processen');
  }
}
