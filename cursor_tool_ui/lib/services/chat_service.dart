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
import 'vector_database_service.dart';
import 'package:process_run/process_run.dart';

// Integreret version der bruger både CLI-kode, extern proces og lokal database
class ChatService extends ChangeNotifier {
  final SettingsService _settings;
  final DatabaseService? _dbService; // Optional for backward compatibility
  final VectorDatabaseService? _vectorDb; // Vector database service
  List<Chat> _chats = [];
  bool _isLoading = false;
  String _lastError = '';
  String _debugInfo = '';
  List<SearchResult> _searchResults = [];

  ChatService(this._settings, [this._dbService, this._vectorDb]);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;
  String get debugInfo => _debugInfo;
  List<SearchResult> get searchResults => _searchResults;
  
  // Tilføj getters til settings-værdier for debugging
  String get cliPath => _settings.cliPath;
  String get workspacePath => _settings.workspacePath;

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
  
  // Offentlig metode til at hente en fuld chat via CLI (wrapper for den private metode)
  Future<Chat?> getFullChatFromCli(String chatId) async {
    return await _getFullChatFromCli(chatId);
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
            
            // Hvis titlen er tom eller er lig med ID'et, generer en beskrivende titel
            String title = parts[1].trim();
            bool isIdBasedChat = false;
            
            if (title.isEmpty || title == id) {
              isIdBasedChat = true;
              // Generer en mere beskrivende titel baseret på dato eller andet
              final dato = parts[2].trim();
              if (dato.isNotEmpty) {
                title = 'Chat fra $dato'; // Brug datoen i titlen
              } else {
                title = 'Chat $id'; // Fallback til ID
              }
            }
            
            final dato = parts[2].trim();
            final antalStr = parts[3].trim();
            final antal = int.tryParse(antalStr) ?? 0;
            
            print('Parsede chat: ID=$id, Titel=$title, Dato=$dato, Antal=$antal, ID-baseret=${isIdBasedChat}');
            
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
            
            // Tilføj metainformation om chat
            if (isIdBasedChat) {
              (chat as dynamic).idBasedTitle = true;
              (chat as dynamic).originalDate = dato;
              (chat as dynamic).messageCount = antal;
            }
            
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
        _chats.sort((a, b) => b.id.compareTo(a.id));
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
  
  /// Udtrækker chat til fil i det valgte format
  Future<String?> extractChat(String chatId, String format) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    try {
      // Først find chatten
      Chat? chat;
      
      // Prøv først database
      if (_dbService != null && _dbService!.isInitialized) {
        chat = await _dbService!.getChat(chatId);
      }
      
      // Hvis ikke fundet, prøv CLI
      if (chat == null) {
        chat = await _getFullChatFromCli(chatId);
      }
      
      if (chat == null) {
        _lastError = 'Chat med ID $chatId blev ikke fundet';
        return null;
      }
      
      // Opret output-mappen hvis den ikke findes
      final outputDir = Directory(_settings.outputPath);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // Generer et konsistent filnavn
      final fileNameBase = chat.title.isEmpty || chat.title == 'Chat $chatId' || chat.title == chatId
        ? 'Chat_${chatId}'
        : '${_sanitizeFilename(chat.title)}_${chatId}';
        
      final fileName = '$fileNameBase.$format';
      final outputFile = path.join(outputDir.path, fileName);
      
      // For diagnostik
      print('Gemmer chat med ID "$chatId" til fil: $outputFile');
      print('Chat titel: "${chat.title}"');
      print('Filnavn: $fileName');
      
      // Generer indhold i det ønskede format
      String content;
      switch (format.toLowerCase()) {
        case 'json':
          content = jsonEncode(chat);
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
      await File(outputFile).writeAsString(content);
      
      print('Chat udtrukket til: $outputFile');
      return outputFile;
    } catch (e) {
      _lastError = 'Fejl ved udtrækning af chat: $e';
      print(_lastError);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Formater chat som tekst
  String _formatAsText(Chat chat) {
    final buffer = StringBuffer();
    buffer.writeln('Chat: ${chat.title}');
    buffer.writeln('ID: ${chat.id}');
    buffer.writeln('');

    for (final message in chat.messages) {
      final timestamp = message.timestamp;
      buffer.writeln('${message.isUser ? "USER" : "ASSISTANT"} (${timestamp.toString()}):');
      buffer.writeln(message.content ?? '');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Formater chat som markdown
  String _formatAsMarkdown(Chat chat) {
    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('');
    buffer.writeln('*Chat ID: ${chat.id}*');
    buffer.writeln('');

    for (final message in chat.messages) {
      final timestamp = message.timestamp;
      buffer.writeln('## ${message.isUser ? "USER" : "ASSISTANT"} - ${timestamp.toString()}');
      buffer.writeln('');
      buffer.writeln(message.content ?? '');
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Formater chat som HTML
  String _formatAsHtml(Chat chat) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${_htmlEscape(chat.title)}</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }');
    buffer.writeln('    .message { margin-bottom: 20px; padding: 10px; border-radius: 5px; }');
    buffer.writeln('    .user { background-color: #e6f7ff; }');
    buffer.writeln('    .assistant { background-color: #f0f0f0; }');
    buffer.writeln('    .timestamp { font-size: 0.8em; color: #666; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>${_htmlEscape(chat.title)}</h1>');
    buffer.writeln('  <p><em>Chat ID: ${chat.id}</em></p>');

    for (final message in chat.messages) {
      final timestamp = message.timestamp;
      final isUser = message.isUser;
      buffer.writeln('  <div class="message ${isUser ? 'user' : 'assistant'}">');
      buffer.writeln('    <div class="timestamp">${isUser ? "USER" : "ASSISTANT"} - ${timestamp.toString()}</div>');
      buffer.writeln('    <div class="content">${_htmlEscape(message.content ?? '')}</div>');
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
  
  // Sanitize filename
  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
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

  // Udfør semantisk søgning i chats
  Future<List<SearchResult>> semanticSearch(String query) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    try {
      if (_vectorDb != null && _vectorDb!.isInitialized) {
        print('Udfører semantisk søgning: "$query"');
        final results = await _vectorDb!.semanticSearch(query);
        
        _searchResults = results;
        print('Fandt ${results.length} resultater');
        return results;
      } else {
        _lastError = 'Vector database er ikke tilgængelig for søgning';
        print(_lastError);
        return [];
      }
    } catch (e) {
      _lastError = 'Fejl ved semantisk søgning: $e';
      print(_lastError);
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Import alle chats til vector database
  Future<int> importToVectorDb() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    
    try {
      if (_vectorDb == null || !_vectorDb!.isInitialized) {
        _lastError = 'Vector database er ikke initialiseret';
        return 0;
      }
      
      // Først sørg for, at vi har alle chats indlæst
      if (_chats.isEmpty) {
        await loadChats();
      }
      
      int importCount = 0;
      
      // For hver chat, importér til vector database
      for (final chat in _chats) {
        try {
          // Hvis det er et overfladisk chat objekt, hent den fulde chat først
          Chat fullChat;
          
          if (chat.messages.length <= 1) {
            print('Henter fuld chat ${chat.id} til vector import');
            
            if (_dbService != null && _dbService!.isInitialized) {
              // Prøv fra database først
              final dbChat = await _dbService!.getChat(chat.id);
              if (dbChat != null && dbChat.messages.length > 1) {
                fullChat = dbChat;
              } else {
                // Ellers prøv CLI
                fullChat = await _getFullChatFromCli(chat.id) ?? chat;
              }
            } else {
              // Ingen database, brug CLI
              fullChat = await _getFullChatFromCli(chat.id) ?? chat;
            }
          } else {
            fullChat = chat;
          }
          
          // Gem chatten i vector databasen
          if (fullChat.messages.length > 1) {
            await _vectorDb!.saveChat(fullChat);
            importCount++;
            print('Importerede chat ${fullChat.id} til vector database (${fullChat.messages.length} beskeder)');
          } else {
            print('Sprang chat ${fullChat.id} over - ingen beskeder at importere');
          }
        } catch (e) {
          print('Fejl ved import af chat ${chat.id} til vector database: $e');
        }
      }
      
      print('Vector database import fuldført: $importCount chats importeret');
      return importCount;
    } catch (e) {
      _lastError = 'Fejl ved import til vector database: $e';
      print(_lastError);
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hent fuld chat fra CLI værktøj
  Future<Chat?> _getFullChatFromCli(String chatId) async {
    try {
      print('\n===== Forsøger at hente chat med ID: $chatId =====');
      
      // Opret en output-mappe
      final outputDir = path.join(_settings.workspacePath, 'output');
      Directory(outputDir).createSync(recursive: true);
      print('Output mappe: $outputDir');
      
      // For chats med numeriske ID'er, lad os være særligt omhyggelige
      final isNumericId = int.tryParse(chatId) != null;
      print('Numerisk ID: $isNumericId');
      
      // Hent chatten via CLI
      print('Kører CLI kommando: --extract $chatId --format json --output $outputDir');
      final result = await runCliTool(['--extract', chatId, '--format', 'json', '--output', outputDir]);
      
      print('CLI returnerede kode: ${result.exitCode}');
      print('CLI stderr: ${result.stderr}');
      
      if (result.exitCode == 0) {
        // Find filsti i output
        final output = result.stdout.toString();
        print('CLI stdout længde: ${output.length}');
        String? jsonFilePath;
        
        // 1. Prøv først at finde filsti direkte via regex
        final regex = RegExp(r'Chat udtrukket til: (.+\.json)');
        final match = regex.firstMatch(output);
        
        if (match != null) {
          jsonFilePath = match.group(1)!;
          print('1. Fandt JSON fil via regex: $jsonFilePath');
        } else {
          // 2. Søg i output-mappen efter filer, der matcher chatId
          print('2. Søger i output-mappen efter filer der matcher ID: $chatId');
          final dir = Directory(outputDir);
          if (await dir.exists()) {
            // List alle filer i mappen for debugging
            final files = await dir.list().toList();
            print('Filer i output-mappen:');
            for (var file in files) {
              print('- ${file.path}');
            }
            
            // Søg efter filer der matcher chatId
            for (var entity in files) {
              if (entity is File && 
                  (entity.path.contains(chatId) || 
                   path.basename(entity.path).contains(chatId))) {
                jsonFilePath = entity.path;
                print('2. Fandt JSON fil via mappegennemsøgning: $jsonFilePath');
                break;
              }
            }
          }
          
          // 3. Prøv forskellige navnekonventioner som CLI-værktøjet kunne bruge
          if (jsonFilePath == null) {
            print('3. Prøver forskellige filnavnsmønstre');
            final filePatterns = [
              // Forskellige mønstre som CLI-værktøjet kan bruge
              'Chat_${chatId}.json',
              'Chat_${chatId}_${chatId}.json',
              '${chatId}.json',
              'chat_${chatId}.json',
            ];
            
            // For numeriske ID'er, tilføj nogle yderligere mønstre
            if (isNumericId) {
              filePatterns.addAll([
                'Chat_$chatId.json',
                '$chatId.json',
                'output_$chatId.json',
                'chat_$chatId.json',
                'cursor_chat_$chatId.json',
              ]);
            }
            
            for (final pattern in filePatterns) {
              final testPath = path.join(outputDir, pattern);
              print('Tester filsti: $testPath');
              if (await File(testPath).exists()) {
                jsonFilePath = testPath;
                print('3. Fandt JSON-fil via navnemønster: $jsonFilePath');
                break;
              }
            }
          }
          
          // 4. Som sidste udvej, tag den nyeste json-fil i mappen
          if (jsonFilePath == null) {
            print('4. Søger efter nyeste JSON-fil i mappen');
            final dir = Directory(outputDir);
            if (await dir.exists()) {
              File? newestFile;
              DateTime newestTime = DateTime(1970);
              
              await for (final entity in dir.list()) {
                if (entity is File && entity.path.endsWith('.json')) {
                  final stat = await entity.stat();
                  if (stat.modified.isAfter(newestTime)) {
                    newestTime = stat.modified;
                    newestFile = entity;
                  }
                }
              }
              
              if (newestFile != null) {
                jsonFilePath = newestFile.path;
                print('4. Bruger nyeste JSON-fil: $jsonFilePath (${newestTime.toString()})');
              }
            }
          }
        }
        
        // Hvis en fil blev fundet, læs og parsér den
        if (jsonFilePath != null && await File(jsonFilePath).exists()) {
          try {
            final jsonFile = File(jsonFilePath);
            final fileSize = await jsonFile.length();
            print('Fundet JSON-fil: $jsonFilePath (størrelse: $fileSize bytes)');
            
            if (fileSize == 0) {
              print('FEJL: JSON-filen er tom!');
              return null;
            }
            
            final jsonStr = await jsonFile.readAsString();
            print('Læste ${jsonStr.length} tegn fra JSON-filen');
            
            if (jsonStr.isEmpty) {
              print('FEJL: JSON-strengen er tom!');
              return null;
            }
            
            try {
              final jsonData = jsonDecode(jsonStr);
              print('JSON dekodet successfuldt');
              print('JSON indeholder følgende nøgler: ${jsonData is Map ? jsonData.keys.join(', ') : 'Ikke et Map objekt'}');
              
              // Generer en bedre titel end bare ID
              String title = jsonData['title'] ?? 'Chat $chatId';
              if (title == chatId || title == 'Chat $chatId') {
                // Prøv at genere en bedre titel baseret på indholdet
                final messages = jsonData['messages'];
                if (messages is List && messages.isNotEmpty) {
                  final firstMsg = messages[0];
                  if (firstMsg is Map && firstMsg.containsKey('content')) {
                    String content = firstMsg['content'] ?? '';
                    if (content.length > 30) {
                      title = content.substring(0, 27) + '...';
                    } else if (content.isNotEmpty) {
                      title = content;
                    }
                  }
                }
              }
              
              // Opret et nyt Chat objekt med den forbedrede titel
              final chat = Chat.fromJson(jsonData);
              if (chat.title == chatId || chat.title == 'Chat $chatId') {
                (chat as dynamic).title = title;
              }
              
              print('Chat objekt oprettet med ${chat.messages.length} beskeder og titel: "${chat.title}"');
              return chat;
            } catch (e) {
              print('FEJL ved parsing af JSON: $e');
              print('JSON indhold (første 100 tegn): ${jsonStr.substring(0, math.min(100, jsonStr.length))}...');
            }
          } catch (e) {
            print('FEJL ved læsning af JSON-fil: $e');
          }
        } else {
          print('Ingen JSON-fil fundet for chat $chatId');
          
          // Hvis det er en numerisk ID, prøv at returnere en dummy chat
          if (isNumericId) {
            print('Forsøger at oprette en dummy chat for numerisk ID');
            final dummyChat = Chat(
              id: chatId,
              title: 'Chat $chatId',
              messages: [
                ChatMessage(
                  content: 'Kunne ikke indlæse chat indhold. Dette er en placeholder besked.',
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
                ChatMessage(
                  content: 'Prøv at eksportere chatten via udtræk-menuen i stedet.',
                  isUser: false,
                  timestamp: DateTime.now().add(Duration(seconds: 1)),
                ),
              ],
            );
            return dummyChat;
          }
        }
      } else {
        print('CLI kommando fejlede med kode ${result.exitCode}: ${result.stderr}');
      }
      
      print('===== Afslutter forsøg på at hente chat med ID: $chatId =====\n');
    } catch (e) {
      print('FEJL ved hentning af chat fra CLI: $e');
    }
    
    return null;
  }
}
