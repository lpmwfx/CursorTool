import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/chat.dart';
import '../cli/chat_browser.dart';
import '../cli/chat_extractor.dart';
import '../cli/config.dart';
import 'settings_service.dart';
import 'database_service.dart';
import 'package:process_run/process_run.dart';

// Integreret version der bruger både CLI-kode, extern proces og lokal database
class ChatService extends ChangeNotifier {
  final SettingsService _settings;
  final DatabaseService? _dbService; // Optional for backward compatibility
  List<Chat> _chats = [];
  bool _isLoading = false;
  String _lastError = '';
  String _debugInfo = '';

  ChatService(this._settings, [this._dbService]);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;
  String get debugInfo => _debugInfo;

  // Kør CLI tool som ekstern proces
  Future<ProcessResult> runCliTool(List<String> args) async {
    try {
      final cliPath = _settings.cliPath;
      final cliFile = File(cliPath);
      
      if (!await cliFile.exists()) {
        throw Exception('CLI værktøjet blev ikke fundet på stien: $cliPath');
      }
      
      // Sikr at CLI værktøjet er eksekverbart
      if (Platform.isMacOS || Platform.isLinux) {
        try {
          await Process.run('chmod', ['+x', cliPath]);
        } catch (e) {
          print('Advarsel: Kunne ikke gøre CLI værktøjet eksekverbart: $e');
        }
      }
      
      print('Kører CLI kommando: $cliPath ${args.join(' ')}');
      final result = await Process.run(
        cliPath,
        args,
        workingDirectory: _settings.workspacePath, 
        runInShell: true,
      );
      
      print('CLI kommando afsluttet med kode ${result.exitCode}');
      if (result.exitCode != 0) {
        print('Stderr: ${result.stderr}');
      }
      
      return result;
    } catch (e) {
      print('Fejl ved kørsel af CLI værktøj: $e');
      rethrow;
    }
  }

  // Hent alle chats - primært via database, ellers via CLI
  Future<void> loadChats() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      // Hvis database service findes og er initialiseret, brug den
      if (_dbService != null && _dbService!.isInitialized) {
        print('Indlæser chats fra lokal database');
        _chats = await _dbService!.getAllChats();
        
        if (_chats.isNotEmpty) {
          print('Indlæste ${_chats.length} chats fra databasen');
          return;
        }
        
        print('Ingen chats fundet i databasen, prøver CLI værktøjet');
      }
      
      // Forsøg at bruge CLI værktøjet ekstern
      try {
        final result = await runCliTool(['--list']);
        
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          print('Chats indlæst fra CLI værktøj');
          
          // Parse output fra CLI
          _parseCliOutput(result.stdout.toString());
          
          // Gem chats til databasen hvis tilgængelig
          if (_dbService != null && _dbService!.isInitialized) {
            _saveChatsToDatabase();
          }
          
          return;
        }
      } catch (e) {
        print('Fejl ved brug af eksternt CLI værktøj: $e');
      }
      
      // Hvis både database og eksternt CLI fejler, brug indbygget CLI kode
      print('Indlæser chats via indbygget CLI-kode (fallback)');
      await _loadChatsFromCli();
      
    } catch (e, stackTrace) {
      print('Fejl ved indlæsning af chats: $e');
      print('Stack trace: $stackTrace');
      _lastError = 'Fejl ved indlæsning af chats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Parse output fra CLI værktøjet
  void _parseCliOutput(String output) {
    try {
      // Reset chats list
      _chats = [];
      
      // Find alle linjer der indeholder chat information
      final lines = output.split('\n');
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
            
            print('Parsede chat: ID=$id, Titel=$title, Dato=$dato, Antal=$antal');
            
            // Opret en liste af beskeder
            final messages = <ChatMessage>[];
            
            // Sikre at vi altid har mindst én besked for at indikere at dette er en forenklet visning
            messages.add(
              ChatMessage(
                content: 'Denne chat viser kun oversigten. Klik på chat for at se komplet indhold.',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            
            // Opret Chat objekt
            final chat = Chat(
              id: id,
              title: title,
              messages: messages,
            );
            
            _chats.add(chat);
          }
        } catch (e) {
          print('Fejl ved parsing af chat-linje: $e');
        }
      }
      
      // Sorter chats efter ID (da vi ikke har rigtige lastMessageTime)
      if (_chats.isNotEmpty) {
        print('Sorterer ${_chats.length} chats');
        // Sorter med højeste ID først (nyeste chats øverst)
        _chats.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
      }
    } catch (e) {
      print('Fejl ved parsing af CLI output: $e');
    }
  }
  
  // Gem chats til lokal database
  Future<void> _saveChatsToDatabase() async {
    if (_dbService == null || !_dbService!.isInitialized || _chats.isEmpty) {
      return;
    }
    
    try {
      print('Gemmer ${_chats.length} chats til databasen');
      
      for (final chat in _chats) {
        // Først hent den fulde chat via CLI værktøj
        try {
          final result = await runCliTool(['--extract', chat.id, '--format', 'json', '--output', '/tmp']);
          
          if (result.exitCode == 0) {
            // Find JSON i output
            final output = result.stdout.toString();
            int jsonStart = output.indexOf('{');
            if (jsonStart >= 0) {
              final jsonStr = output.substring(jsonStart);
              
              // Parse JSON
              final jsonData = jsonDecode(jsonStr);
              
              // Opret chat model
              final chatData = Chat.fromJson(jsonData);
              
              // Gem til database
              await _dbService!.saveChat(chatData);
              
              print('Gemt chat ${chat.id} til databasen');
            }
          }
        } catch (e) {
          print('Fejl ved hentning/gemning af chat ${chat.id}: $e');
        }
      }
    } catch (e) {
      print('Fejl ved gemning af chats til databasen: $e');
    }
  }

  // Oprindelig metode til at indlæse chats via CLI
  Future<void> _loadChatsFromCli() async {
    try {
      // Opret config med indstillinger
      print('Opretter Config med workspacePath: ${_settings.workspacePath}');
      final config = Config(workspaceStoragePath: _settings.workspacePath);
      
      // Brug ChatBrowser direkte
      print('Opretter ChatBrowser og indlæser chats');
      final browser = ChatBrowser(config);
      final chatHistories = await browser.loadAllChats();
      
      if (chatHistories.isEmpty) {
        _lastError = 'Ingen chats fundet i ${_settings.workspacePath}';
        return;
      }
      
      print('Fandt ${chatHistories.length} chats, konverterer til model');
      
      // Konverter til vores Chat-model
      _chats = chatHistories.map((history) {
        final messages = history.messages.map((msg) {
          return ChatMessage(
            content: msg.content,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
          );
        }).toList();
        
        return Chat(
          id: history.id,
          title: history.title.length > 50 
              ? '${history.title.substring(0, 47)}...' 
              : history.title,
          messages: messages,
        );
      }).toList();
      
      // Sorter efter seneste besked
      _chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      print('Færdig med at indlæse ${_chats.length} chats');
      
    } catch (e, stackTrace) {
      print('Fejl ved CLI indlæsning af chats: $e');
      print('Stack trace: $stackTrace');
      throw e; // Videresend fejl til kaldende funktion
    }
  }

  // Udtræk en specifik chat
  Future<bool> extractChat(String chatId, String format) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    try {
      // Opret config
      final config = Config(
        workspaceStoragePath: _settings.workspacePath,
      );
      
      // Hent chat med ChatBrowser
      final browser = ChatBrowser(config);
      final chat = await browser.getChat(chatId);
      
      if (chat == null) {
        _lastError = 'Chat med ID $chatId blev ikke fundet';
        return false;
      }
      
      // Opret output-mappen hvis den ikke findes
      final outputDir = Directory(_settings.outputPath);
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }
      
      // Generer filnavn baseret på format
      final fileName = '${chat.id}.$format';
      final outputFile = path.join(_settings.outputPath, fileName);
      
      // Gem chat i det ønskede format
      String content;
      switch (format.toLowerCase()) {
        case 'json':
          content = jsonEncode(chat.toJson());
          break;
        case 'markdown':
        case 'md':
          content = _formatAsMarkdown(chat);
          break;
        case 'html':
          content = _formatAsHtml(chat);
          break;
        case 'text':
        default:
          content = _formatAsText(chat);
          break;
      }
      
      // Skriv til fil
      File(outputFile).writeAsStringSync(content);
      
      return true;
    } catch (e) {
      _lastError = 'Fejl ved udtrækning af chat: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Formater chat som tekst
  String _formatAsText(dynamic chat) {
    final buffer = StringBuffer();
    buffer.writeln('Chat: ${chat.title}');
    buffer.writeln('ID: ${chat.id}');
    buffer.writeln('');

    for (final message in chat.messages) {
      final timestamp = message.timestamp;
      buffer.writeln('${message.isUser ? "USER" : "ASSISTANT"} (${timestamp.toString()}):');
      buffer.writeln(message.content);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Formater chat som markdown
  String _formatAsMarkdown(dynamic chat) {
    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('');
    buffer.writeln('*Chat ID: ${chat.id}*');
    buffer.writeln('');

    for (final message in chat.messages) {
      final timestamp = message.timestamp;
      buffer.writeln('## ${message.isUser ? "USER" : "ASSISTANT"} - ${timestamp.toString()}');
      buffer.writeln('');
      buffer.writeln(message.content);
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Formater chat som HTML
  String _formatAsHtml(dynamic chat) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${chat.title}</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }');
    buffer.writeln('    .message { margin-bottom: 20px; padding: 10px; border-radius: 5px; }');
    buffer.writeln('    .user { background-color: #e6f7ff; }');
    buffer.writeln('    .assistant { background-color: #f0f0f0; }');
    buffer.writeln('    .timestamp { font-size: 0.8em; color: #666; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>${chat.title}</h1>');
    buffer.writeln('  <p><em>Chat ID: ${chat.id}</em></p>');

    for (final message in chat.messages) {
      final timestamp = message.timestamp;
      final isUser = message.isUser;
      buffer.writeln('  <div class="message ${isUser ? 'user' : 'assistant'}">');
      buffer.writeln('    <div class="timestamp">${isUser ? "USER" : "ASSISTANT"} - ${timestamp.toString()}</div>');
      buffer.writeln('    <div class="content">${_htmlEscape(message.content)}</div>');
      buffer.writeln('  </div>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  // Escape HTML special characters
  String _htmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;')
        .replaceAll('\n', '<br>');
  }

  // Åbn TUI browser (denne funktion kan erstattes med UI-navigation)
  Future<void> showTuiBrowser() async {
    _lastError = 'TUI browser er integreret i appen - brug UI i stedet';
    notifyListeners();
  }

  // Funktion til at kopiere chatfiler fra Cursor's mappe til Documents
  Future<String> copyChatFilesToDocuments() async {
    final buffer = StringBuffer();
    final homeDir = Platform.environment['HOME'] ?? '';
    final cursorWorkspace = path.join(homeDir, 'Library', 'Application Support', 'Cursor', 'User', 'workspaceStorage');
    final documentsPath = path.join(homeDir, 'Documents', 'CursorChats');
    
    buffer.writeln('Forsøger at kopiere chatfiler fra:');
    buffer.writeln(cursorWorkspace);
    buffer.writeln('til:');
    buffer.writeln(documentsPath);
    buffer.writeln('');
    
    try {
      // Tjek om kilde-mappen eksisterer
      final cursorDir = Directory(cursorWorkspace);
      if (!await cursorDir.exists()) {
        buffer.writeln('FEJL: Cursor workspace mappe findes ikke!');
        _debugInfo = buffer.toString();
        notifyListeners();
        return buffer.toString();
      }
      
      // Opret mål-mappen hvis den ikke eksisterer
      final docsDir = Directory(documentsPath);
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
        buffer.writeln('Oprettede mål-mappe: $documentsPath');
      }
      
      // List alle mapper i Cursor workspace
      List<FileSystemEntity> cursorDirs = [];
      try {
        cursorDirs = await cursorDir.list().where((e) => e is Directory).toList();
        buffer.writeln('Fandt ${cursorDirs.length} mapper i Cursor workspace.');
      } catch (e) {
        buffer.writeln('FEJL: Kunne ikke læse Cursor workspace: $e');
        _debugInfo = buffer.toString();
        notifyListeners();
        return buffer.toString();
      }
      
      if (cursorDirs.isEmpty) {
        buffer.writeln('Ingen mapper fundet i Cursor workspace.');
        _debugInfo = buffer.toString();
        notifyListeners();
        return buffer.toString();
      }
      
      // Kopier hver mappe til Documents
      int successCount = 0;
      for (var dir in cursorDirs) {
        final dirName = path.basename(dir.path);
        final targetDir = path.join(documentsPath, dirName);
        
        try {
          // Tjek om mål-mappen allerede eksisterer
          final targetDirCheck = Directory(targetDir);
          if (await targetDirCheck.exists()) {
            buffer.writeln('Mappe $dirName eksisterer allerede i mål-mappen, springer over.');
            continue;
          }
          
          // Kopier mappe
          await _copyDirectory(dir.path, targetDir);
          successCount++;
          buffer.writeln('✓ Kopierede mappe: $dirName');
        } catch (e) {
          buffer.writeln('✗ Fejl ved kopiering af $dirName: $e');
        }
      }
      
      buffer.writeln('');
      buffer.writeln('Kopieringsresultat: $successCount af ${cursorDirs.length} mapper kopieret.');
      
      if (successCount > 0) {
        // Opdater sti til den nye mappe
        await _settings.updateWorkspacePath(documentsPath);
        buffer.writeln('');
        buffer.writeln('✓ Opdaterede workspace sti til: $documentsPath');
        buffer.writeln('Du kan nu genindlæse chats fra den nye placering.');
      }
    } catch (e) {
      buffer.writeln('Generel fejl under kopiering: $e');
    }
    
    final result = buffer.toString();
    _debugInfo = result;
    notifyListeners();
    return result;
  }
  
  // Hjælpefunktion til at kopiere en mappe rekursivt
  Future<void> _copyDirectory(String source, String destination) async {
    final sourceDir = Directory(source);
    final destDir = Directory(destination);
    
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    
    await for (final entity in sourceDir.list(recursive: false)) {
      final newPath = path.join(destination, path.basename(entity.path));
      
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      }
    }
  }

  // Forsøg at automatisk importere chats fra Cursor's databases
  Future<int> autoImportFromCursor() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    try {
      // Første prioritet: Brug CLI værktøjet hvis det findes
      try {
        final cliPath = _settings.cliPath;
        if (File(cliPath).existsSync()) {
          print('CLI værktøj fundet på $cliPath - forsøger at importere chats');
          
          // Bekræft at CLI-værktøjet virker ved at tjekke version
          try {
            final versionResult = await runCliTool(['--version']);
            if (versionResult.exitCode == 0) {
              print('CLI version: ${versionResult.stdout}');
              
              // Kør --list for at hente chats
              final result = await runCliTool(['--list']);
              
              if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
                print('Chats indlæst fra CLI værktøj');
                
                // Parse output fra CLI
                _parseCliOutput(result.stdout.toString());
                
                // Gem chats til databasen hvis tilgængelig
                if (_dbService != null && _dbService!.isInitialized) {
                  await _saveChatsToDatabase();
                  
                  // Returner antal importerede chats
                  return _chats.length;
                }
              }
            }
          } catch (e) {
            print('Fejl ved kørsel af CLI værktøj: $e');
          }
        }
      } catch (e) {
        print('Fejl ved brug af CLI værktøj: $e');
      }
      
      // Anden prioritet: Brug internt CLI kode
      try {
        print('Forsøger med indbygget CLI kode');
        await _loadChatsFromCli();
        
        // Gem chats til databasen hvis tilgængelig
        if (_dbService != null && _dbService!.isInitialized && _chats.isNotEmpty) {
          for (final chat in _chats) {
            await _dbService!.saveChat(chat);
          }
          
          print('Importerede ${_chats.length} chats til databasen via indbygget CLI kode');
          return _chats.length;
        }
      } catch (e) {
        print('Fejl ved brug af indbygget CLI kode: $e');
      }
      
      // Tredje prioritet: Søg efter SQLite databaser
      if (_dbService != null && _dbService!.isInitialized) {
        final homeDir = Platform.environment['HOME'] ?? '';
        String cursorPath;
        
        if (Platform.isMacOS) {
          cursorPath = path.join(homeDir, 'Library', 'Application Support', 'Cursor', 'User', 'workspaceStorage');
        } else if (Platform.isLinux) {
          cursorPath = path.join(homeDir, '.config', 'Cursor', 'User', 'workspaceStorage');
        } else {
          cursorPath = _settings.workspacePath;
        }
        
        print('Forsøger at importere fra: $cursorPath');
        
        // Find alle state.vscdb filer
        final cursorDir = Directory(cursorPath);
        if (await cursorDir.exists()) {
          List<File> dbFiles = [];
          
          try {
            // List alle mapper i workspaceStorage
            await for (final entry in cursorDir.list()) {
              if (entry is Directory) {
                final dbFile = File(path.join(entry.path, 'state.vscdb'));
                if (await dbFile.exists()) {
                  dbFiles.add(dbFile);
                }
              }
            }
            
            if (dbFiles.isNotEmpty) {
              print('Fandt ${dbFiles.length} database filer. Starter import...');
              
              // Importér fra fundne databaser
              final importedCount = await _dbService!.importFromCursorDb(dbFiles);
              
              if (importedCount > 0) {
                // Genindlæs chats fra databasen
                _chats = await _dbService!.getAllChats();
                print('Indlæste ${_chats.length} chats fra databasen');
              }
              
              return importedCount;
            }
          } catch (e) {
            _lastError = 'Kunne ikke læse mappen: $e';
            print('Fejl ved læsning af cursor workspace: $e');
          }
        }
      }
      
      if (_chats.isEmpty) {
        _lastError = 'Kunne ikke finde Cursor chats med nogen metode';
      }
      
      return _chats.length;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debug funktion til at tjekke workspace sti
  Future<String> debugWorkspacePath() async {
    final buffer = StringBuffer();
    final workspacePath = _settings.workspacePath;
    
    buffer.writeln('Debug info for workspace sti:');
    buffer.writeln('-----------------------------');
    buffer.writeln('Konfigureret sti: $workspacePath');
    buffer.writeln('Kører på: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    buffer.writeln('CLI værktøj: ${_settings.cliPath}');
    
    if (Platform.isMacOS) {
      buffer.writeln('\nMacOS App Info:');
      buffer.writeln('App bundle: ${Platform.resolvedExecutable}');
      try {
        final homeDir = Platform.environment['HOME'] ?? '';
        buffer.writeln('Home dir: $homeDir');
        
        // Tjek CLI værktøj
        try {
          final cliFile = File(_settings.cliPath);
          final cliExists = await cliFile.exists();
          buffer.writeln('\nCLI værktøj eksisterer: ${cliExists ? 'JA' : 'NEJ'}');
          
          if (cliExists) {
            try {
              final result = await Process.run(_settings.cliPath, ['--version']);
              buffer.writeln('CLI version: ${result.stdout}');
            } catch (e) {
              buffer.writeln('Fejl ved kørsel af CLI version: $e');
            }
          }
        } catch (e) {
          buffer.writeln('Fejl ved tjek af CLI: $e');
        }
      } catch (e) {
        buffer.writeln('Fejl ved tjek af system info: $e');
      }
    }
    
    // Tjek om mappen eksisterer
    final workspaceDir = Directory(workspacePath);
    bool exists = false;
    try {
      exists = await workspaceDir.exists();
      buffer.writeln('\nMappe eksisterer: ${exists ? 'JA' : 'NEJ'}');
    } catch (e) {
      buffer.writeln('\nFejl ved tjek om mappe eksisterer: $e');
    }
    
    if (exists) {
      try {
        // List indhold i mappen
        buffer.writeln('Indhold i mappen:');
        final entities = await workspaceDir.list().toList();
        
        if (entities.isEmpty) {
          buffer.writeln('  (Tom mappe)');
        } else {
          for (var entity in entities) {
            final type = entity is Directory ? '[D]' : '[F]';
            buffer.writeln('  $type ${path.basename(entity.path)}');
            
            // Hvis det er en mappe, tjek om den indeholder state.vscdb
            if (entity is Directory) {
              try {
                final dbFile = File(path.join(entity.path, 'state.vscdb'));
                final dbExists = await dbFile.exists();
                if (dbExists) {
                  buffer.writeln('    ✓ Indeholder state.vscdb');
                }
              } catch (e) {
                buffer.writeln('    Fejl ved tjek af state.vscdb: $e');
              }
            }
          }
        }
      } catch (e) {
        buffer.writeln('Fejl ved læsning af mappens indhold: $e');
      }
    }
    
    // Alternativ metode - prøv CLI værktøjet
    buffer.writeln('\nTest af CLI værktøj:');
    try {
      final result = await runCliTool(['--list']);
      if (result.exitCode == 0) {
        buffer.writeln('CLI værktøj kørte med success (kode ${result.exitCode})');
        buffer.writeln('Output: ${result.stdout.toString().substring(0, math.min(result.stdout.toString().length, 200))}...');
      } else {
        buffer.writeln('CLI værktøj fejlede med kode ${result.exitCode}');
        buffer.writeln('Stderr: ${result.stderr}');
      }
    } catch (e) {
      buffer.writeln('Fejl ved kørsel af CLI værktøj: $e');
    }
    
    final result = buffer.toString();
    _debugInfo = result;
    notifyListeners();
    return result;
  }

  // Gem chat til databasen
  Future<bool> saveChatToDatabase(Chat chat) async {
    if (_dbService == null || !_dbService!.isInitialized) {
      return false;
    }
    
    try {
      await _dbService!.saveChat(chat);
      print('Gemt chat ${chat.id} til databasen');
      return true;
    } catch (e) {
      print('Fejl ved gemning af chat ${chat.id} til databasen: $e');
      return false;
    }
  }
}
