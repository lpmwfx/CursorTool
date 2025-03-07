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

// Integreret version der bruger den integrerede CLI-kode og lokal database
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

  // Debug funktion til at tjekke workspace sti
  Future<String> debugWorkspacePath() async {
    final buffer = StringBuffer();
    final workspacePath = _settings.workspacePath;
    
    buffer.writeln('Debug info for workspace sti:');
    buffer.writeln('-----------------------------');
    buffer.writeln('Konfigureret sti: $workspacePath');
    buffer.writeln('Kører på: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    
    if (Platform.isMacOS) {
      buffer.writeln('\nMacOS Sandbox Info:');
      buffer.writeln('App bundle: ${Platform.resolvedExecutable}');
      try {
        final homeDir = Platform.environment['HOME'] ?? '';
        final containerDir = Directory(homeDir);
        buffer.writeln('Sandbox home: $homeDir');
        
        // List directories der er tilgængelige
        buffer.writeln('Tilgængelige mapper i HOME:');
        final homeDirs = await containerDir.list().toList();
        for (var dir in homeDirs) {
          buffer.writeln('  ${dir.path}');
        }
        
        // Vis Documents og Library directories hvis de eksisterer
        final docsDir = Directory(path.join(homeDir, 'Documents'));
        final libDir = Directory(path.join(homeDir, 'Library'));
        
        if (await docsDir.exists()) {
          buffer.writeln('Documents mappe: ${docsDir.path} (tilgængelig)');
        } else {
          buffer.writeln('Documents mappe: ikke tilgængelig');
        }
        
        if (await libDir.exists()) {
          buffer.writeln('Library mappe: ${libDir.path} (tilgængelig)');
          
          // Tjek om vi kan tilgå Application Support
          final appSupportDir = Directory(path.join(libDir.path, 'Application Support'));
          if (await appSupportDir.exists()) {
            buffer.writeln('Application Support mappe: ${appSupportDir.path} (tilgængelig)');
          } else {
            buffer.writeln('Application Support mappe: ikke tilgængelig');
          }
        } else {
          buffer.writeln('Library mappe: ikke tilgængelig');
        }
      } catch (e) {
        buffer.writeln('Fejl ved tjek af sandbox: $e');
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
    
    // Tjek alternativer
    buffer.writeln('\nTjekker alternative stier:');
    
    final possiblePaths = <String>[];
    final homeDir = Platform.environment['HOME'] ?? '';
    
    if (Platform.isMacOS) {
      possiblePaths.addAll([
        path.join(homeDir, 'Library', 'Application Support', 'Cursor', 'User', 'workspaceStorage'),
        path.join(homeDir, 'Library', 'Application Support', 'Cursor', 'User'),
        path.join(homeDir, 'Library', 'Application Support', 'Cursor'),
        path.join('/Applications/Cursor.app/Contents/Resources/app/extensions'),
        // Sandboxed app locations
        path.join(homeDir, 'Documents', 'CursorChats'),
        path.join(homeDir, 'Documents'),
      ]);
    } else if (Platform.isLinux) {
      possiblePaths.addAll([
        path.join(homeDir, '.config', 'Cursor', 'User', 'workspaceStorage'),
        path.join(homeDir, '.cursor', 'workspaceStorage'),
      ]);
    }
    
    for (final testPath in possiblePaths) {
      if (testPath == workspacePath) continue; // Skip den nuværende sti
      
      final dir = Directory(testPath);
      bool testExists = false;
      try {
        testExists = await dir.exists();
        buffer.writeln('$testPath: ${testExists ? 'Eksisterer' : 'Findes ikke'}');
      } catch (e) {
        buffer.writeln('$testPath: Fejl ved tjek: $e');
        continue;
      }
      
      if (testExists) {
        try {
          final entities = await dir.list().toList();
          buffer.writeln('  Indeholder ${entities.length} elementer');
          
          // Vis op til 5 elementer
          int count = 0;
          for (var entity in entities) {
            if (count++ >= 5) {
              buffer.writeln('  ... og ${entities.length - 5} flere');
              break;
            }
            final type = entity is Directory ? '[D]' : '[F]';
            buffer.writeln('  $type ${path.basename(entity.path)}');
          }
        } catch (e) {
          buffer.writeln('  Fejl ved læsning: $e');
        }
      }
    }
    
    // Tilføj en anbefaling
    buffer.writeln('\nAnbefaling:');
    if (Platform.isMacOS) {
      buffer.writeln('På macOS anbefales det at kopiere dine chat-filer fra:');
      buffer.writeln('${path.join(homeDir, 'Library', 'Application Support', 'Cursor', 'User', 'workspaceStorage')}');
      buffer.writeln('til en mappe i Documents, f.eks:');
      buffer.writeln('${path.join(homeDir, 'Documents', 'CursorChats')}');
      buffer.writeln('\nSandbox-begrænsninger forhindrer adgang til mange system-mapper.');
    }
    
    final result = buffer.toString();
    _debugInfo = result;
    notifyListeners();
    return result;
  }

  // Hent alle chats - enten fra databasen eller via CLI
  Future<void> loadChats() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      // Hvis database service findes og er initialiseret, brug den
      if (_dbService != null && _dbService!.isInitialized) {
        print('Indlæser chats fra lokal database');
        _chats = await _dbService!.getAllChats();
        
        if (_chats.isEmpty) {
          _lastError = 'Ingen chats fundet i databasen. Importér chats fra indstillinger.';
        } else {
          print('Indlæste ${_chats.length} chats fra databasen');
        }
      } else {
        // Ellers brug den oprindelige CLI-metode
        print('Indlæser chats via CLI-metode (fallback)');
        await _loadChatsFromCli();
      }
    } catch (e, stackTrace) {
      print('Fejl ved indlæsning af chats: $e');
      print('Stack trace: $stackTrace');
      _lastError = 'Fejl ved indlæsning af chats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
    if (_dbService == null || !_dbService!.isInitialized) {
      _lastError = 'Database service er ikke initialiseret';
      return 0;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final homeDir = Platform.environment['HOME'] ?? '';
      final cursorPath = path.join(homeDir, 'Library', 'Application Support', 'Cursor', 'User', 'workspaceStorage');
      
      print('Forsøger at importere fra: $cursorPath');
      
      // Find alle state.vscdb filer
      final cursorDir = Directory(cursorPath);
      if (!await cursorDir.exists()) {
        _lastError = 'Cursor workspace mappe ikke fundet';
        return 0;
      }
      
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
      } catch (e) {
        _lastError = 'Kunne ikke læse mappen: $e';
        print('Fejl ved læsning af cursor workspace: $e');
        return 0;
      }
      
      if (dbFiles.isEmpty) {
        _lastError = 'Ingen database filer fundet';
        return 0;
      }
      
      print('Fandt ${dbFiles.length} database filer. Starter import...');
      
      // Importér fra fundne databaser
      final importedCount = await _dbService!.importFromCursorDb(dbFiles);
      
      if (importedCount > 0) {
        // Genindlæs chats
        await loadChats();
      }
      
      return importedCount;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
