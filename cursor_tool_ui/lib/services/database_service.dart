import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/chat.dart';

class DatabaseService extends ChangeNotifier {
  static const String dbName = 'cursor_chats.db';
  static const int dbVersion = 1;
  
  sqflite.Database? _db;
  bool _isInitialized = false;
  bool _isImporting = false;
  String _lastError = '';
  double _importProgress = 0.0;
  
  bool get isInitialized => _isInitialized;
  bool get isImporting => _isImporting;
  String get lastError => _lastError;
  double get importProgress => _importProgress;
  
  /// Initialiser databasen ved appstart
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final dbPath = await _getDatabasePath();
      
      // Åbn eller opret databasen
      _db = await sqflite.openDatabase(
        dbPath,
        version: dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _onUpgrade,
      );
      
      _isInitialized = true;
      print('Database initialiseret');
      notifyListeners();
    } catch (e) {
      _lastError = 'Kunne ikke initialisere database: $e';
      print('Fejl ved initialisering af database: $_lastError');
    }
  }
  
  /// Opret databasetabeller ved første kørsel
  Future<void> _createDatabase(sqflite.Database db, int version) async {
    // Chats tabel
    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        last_message_time INTEGER NOT NULL
      )
    ''');
    
    // Beskeder tabel
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id TEXT NOT NULL,
        content TEXT,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id)
      )
    ''');
    
    // Tags tabel
    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    
    // Relation mellem chats og tags
    await db.execute('''
      CREATE TABLE chat_tags(
        chat_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (chat_id, tag_id),
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
    
    // Indeks for hurtigere søgning
    await db.execute('CREATE INDEX idx_messages_chat_id ON messages(chat_id)');
    await db.execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp)');
    await db.execute('CREATE INDEX idx_chats_last_message_time ON chats(last_message_time)');
  }
  
  /// Opgrader databasen hvis skemaet ændres
  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    // Håndter fremtidige skemaopgraderinger her
    if (oldVersion < 2) {
      // Tilføj nye tabeller/kolonner for version 2
    }
  }
  
  /// Henter alle chats fra databasen
  Future<List<Chat>> getAllChats() async {
    if (!_isInitialized) return [];
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('chats', orderBy: 'last_message_time DESC');
      
      final List<Chat> chats = [];
      
      for (var chatMap in maps) {
        // Hent beskederne for denne chat
        final messages = await _getMessagesForChat(chatMap['id'] as String);
        
        chats.add(Chat(
          id: chatMap['id'] as String,
          title: chatMap['title'] as String,
          messages: messages,
        ));
      }
      
      return chats;
    } catch (e) {
      print('Fejl ved hentning af chats fra databasen: $e');
      return [];
    }
  }
  
  /// Henter en specifik chat fra databasen
  Future<Chat?> getChat(String chatId) async {
    if (!_isInitialized) return null;
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'chats',
        where: 'id = ?',
        whereArgs: [chatId],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      // Hent beskederne for denne chat
      final messages = await _getMessagesForChat(chatId);
      
      return Chat(
        id: maps.first['id'] as String,
        title: maps.first['title'] as String,
        messages: messages,
      );
    } catch (e) {
      print('Fejl ved hentning af chat $chatId fra databasen: $e');
      return null;
    }
  }
  
  /// Gemmer en chat til databasen
  Future<bool> saveChat(Chat chat) async {
    if (!_isInitialized || _db == null) {
      await init();
    }
    
    try {
      // Start en transaktion
      return await _db!.transaction((txn) async {
        // Indsæt eller opdatér chat
        await txn.rawInsert(
          '''INSERT OR REPLACE INTO chats(
               id, title, last_message_time
             ) VALUES(?, ?, ?)
          ''',
          [
            chat.id,
            chat.title,
            chat.lastMessageTime.millisecondsSinceEpoch,
          ],
        );
        
        // Slet evt. eksisterende beskeder for denne chat (for at undgå dubletter)
        await txn.delete(
          'messages',
          where: 'chat_id = ?',
          whereArgs: [chat.id],
        );
        
        // Indsæt alle beskeder
        for (final message in chat.messages) {
          await txn.insert(
            'messages',
            {
              'chat_id': chat.id,
              'content': message.content ?? '',
              'is_user': message.isUser ? 1 : 0,
              'timestamp': message.timestamp.millisecondsSinceEpoch,
            },
          );
        }
        
        return true;
      });
    } catch (e) {
      _lastError = 'Kunne ikke gemme chat: $e';
      print('Fejl ved gemning af chat: $_lastError');
      return false;
    }
  }
  
  /// Importér chats fra JSON data (f.eks. fra Cursor's database)
  Future<bool> importFromJson(String jsonData) async {
    if (!_isInitialized || _db == null) {
      await init();
    }
    
    _isImporting = true;
    _importProgress = 0.0;
    notifyListeners();
    
    try {
      final data = jsonDecode(jsonData);
      
      // Håndter forskellige JSON-formater
      if (data is List) {
        // Hvis det er et array, antag at det er chat-beskeder
        final messagesData = data;
        
        // Opret en chat fra beskederne
        final messages = messagesData.map((msgJson) {
          return ChatMessage(
            content: msgJson['text'] ?? msgJson['content'] ?? '',
            isUser: msgJson['role'] == 'user' || msgJson['isUser'] == true,
            timestamp: msgJson['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(msgJson['timestamp'])
                : DateTime.now(),
          );
        }).toList();
        
        if (messages.isNotEmpty) {
          final chatTitle = _generateTitle(messages.first.content ?? '');
          final chatId = DateTime.now().millisecondsSinceEpoch.toString();
          
          final chat = Chat(
            id: chatId,
            title: chatTitle,
            messages: messages,
          );
          
          _importProgress = 1.0;
          notifyListeners();
          
          return await saveChat(chat);
        }
      } else if (data is Map) {
        // Håndter forskellige map-formater
        if (data.containsKey('messages')) {
          // Format: { messages: [...] }
          final messagesJson = data['messages'] as List;
          
          // Konverter beskeder
          final messages = messagesJson.map((msgJson) {
            return ChatMessage(
              content: msgJson['text'] ?? msgJson['content'] ?? '',
              isUser: msgJson['role'] == 'user' || msgJson['isUser'] == true,
              timestamp: msgJson['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(msgJson['timestamp'])
                  : DateTime.now(),
            );
          }).toList();
          
          if (messages.isNotEmpty) {
            final chatTitle = data['title'] ?? _generateTitle(messages.first.content ?? '');
            final chatId = data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
            
            final chat = Chat(
              id: chatId,
              title: chatTitle,
              messages: messages,
            );
            
            _importProgress = 1.0;
            notifyListeners();
            
            return await saveChat(chat);
          }
        } 
        // Håndter flere formater efter behov
      }
      
      _lastError = 'Ukendt JSON-format';
      return false;
    } catch (e) {
      _lastError = 'Kunne ikke importere fra JSON: $e';
      print('Fejl ved import: $_lastError');
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
  
  /// Importér chats fra Cursor SQLite databaser
  Future<int> importFromCursorDb(List<File> dbFiles) async {
    if (!_isInitialized || _db == null) {
      await init();
    }
    
    _isImporting = true;
    _importProgress = 0.0;
    notifyListeners();
    
    int importedCount = 0;
    
    try {
      int totalFiles = dbFiles.length;
      int processedFiles = 0;
      
      for (final dbFile in dbFiles) {
        try {
          // Åbn Cursor's database i læse-kun tilstand
          final cursorDb = await sqflite.openDatabase(
            dbFile.path, 
            readOnly: true,
          );
          
          // Hent chat data fra databasen
          final result = await cursorDb.query(
            'ItemTable',
            where: "[key] IN ('aiService.prompts', 'workbench.panel.aichat.view.aichat.chatdata')",
          );
          
          // Luk databasen igen
          await cursorDb.close();
          
          // Opret et unikt ID baseret på filnavn
          final fileId = path.basename(dbFile.path);
          
          // Behandl hver række
          for (final row in result) {
            final key = row['key'] as String;
            final value = row['value'] as String;
            final rowId = row['rowid'] ?? 0;
            
            // Forsøg at importere JSON data
            final cursorChatId = '${fileId}_$rowId';
            if (await _importCursorChatData(cursorChatId, value)) {
              importedCount++;
            }
          }
        } catch (e) {
          print('Kunne ikke læse database ${dbFile.path}: $e');
          // Fortsæt med næste fil
        }
        
        // Opdater fremskridt
        processedFiles++;
        _importProgress = processedFiles / totalFiles;
        notifyListeners();
      }
      
      return importedCount;
    } catch (e) {
      _lastError = 'Kunne ikke importere fra Cursor databaser: $e';
      print('Fejl ved Cursor DB import: $_lastError');
      return importedCount;
    } finally {
      _isImporting = false;
      _importProgress = 1.0;
      notifyListeners();
    }
  }
  
  /// Hjælpefunktion til at importere Cursor chat data
  Future<bool> _importCursorChatData(String chatId, String jsonValue) async {
    try {
      final data = jsonDecode(jsonValue);
      
      // Håndter forskellige JSON-formater
      if (data is List) {
        // Hvis det er et array, antag at det er beskeder
        final messages = data.map((msgJson) {
          return ChatMessage(
            content: msgJson['text'] ?? msgJson['content'] ?? '',
            isUser: msgJson['role'] == 'user' ||
                msgJson['role'] == 'user_edited' ||
                msgJson['isUser'] == true,
            timestamp: msgJson['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(msgJson['timestamp'])
                : DateTime.now(),
          );
        }).toList();

        if (messages.isNotEmpty) {
          final title = _generateTitle(messages.first.content ?? '');
          
          final chat = Chat(
            id: chatId,
            title: title,
            messages: messages,
          );
          
          return await saveChat(chat);
        }
      } else if (data is Map) {
        // Hvis det er et objekt, undersøg strukturen
        if (data.containsKey('messages')) {
          // Antagelse: { messages: [...] }
          final messagesJson = data['messages'] as List?;
          if (messagesJson != null && messagesJson.isNotEmpty) {
            final messages = messagesJson.map((msgJson) {
              return ChatMessage(
                content: msgJson['text'] ?? msgJson['content'] ?? '',
                isUser: msgJson['role'] == 'user' ||
                    msgJson['role'] == 'user_edited' ||
                    msgJson['isUser'] == true,
                timestamp: msgJson['timestamp'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(msgJson['timestamp'])
                    : DateTime.now(),
              );
            }).toList();
            
            final title = data['title'] ?? 
                (messages.isNotEmpty ? _generateTitle(messages.first.content ?? '') : 'Chat $chatId');
            
            final chat = Chat(
              id: chatId,
              title: title,
              messages: messages,
            );
            
            return await saveChat(chat);
          }
        } else if (data.containsKey('sessions')) {
          // Antagelse: { sessions: [{messages: [...]}] }
          final sessionsJson = data['sessions'] as List?;
          if (sessionsJson != null && sessionsJson.isNotEmpty) {
            final sessionData = sessionsJson.last;
            final messagesJson = sessionData['messages'] as List?;
            
            if (messagesJson != null && messagesJson.isNotEmpty) {
              final messages = messagesJson.map((msgJson) {
                return ChatMessage(
                  content: msgJson['text'] ?? msgJson['content'] ?? '',
                  isUser: msgJson['role'] == 'user' ||
                      msgJson['role'] == 'user_edited' ||
                      msgJson['isUser'] == true,
                  timestamp: msgJson['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(msgJson['timestamp'])
                      : DateTime.now(),
                );
              }).toList();
              
              final title = sessionData['title'] ?? 
                  (messages.isNotEmpty ? _generateTitle(messages.first.content ?? '') : 'Chat $chatId');
              
              final chat = Chat(
                id: chatId,
                title: title,
                messages: messages,
              );
              
              return await saveChat(chat);
            }
          }
        } else if (data.containsKey('chats')) {
          // Antagelse: { chats: [{title, messages: [...]}] }
          final chatsJson = data['chats'] as List?;
          if (chatsJson != null && chatsJson.isNotEmpty) {
            final chatData = chatsJson.last;
            final messagesJson = chatData['messages'] as List?;
            
            if (messagesJson != null && messagesJson.isNotEmpty) {
              final messages = messagesJson.map((msgJson) {
                return ChatMessage(
                  content: msgJson['text'] ?? msgJson['content'] ?? '',
                  isUser: msgJson['role'] == 'user' ||
                      msgJson['role'] == 'user_edited' ||
                      msgJson['isUser'] == true,
                  timestamp: msgJson['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(msgJson['timestamp'])
                      : DateTime.now(),
                );
              }).toList();
              
              final title = chatData['title'] ?? 
                  (messages.isNotEmpty ? _generateTitle(messages.first.content ?? '') : 'Chat $chatId');
              
              final chat = Chat(
                id: chatId,
                title: title,
                messages: messages,
              );
              
              return await saveChat(chat);
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Fejl ved import af chat data: $e');
      return false;
    }
  }
  
  /// Generer en titel baseret på den første besked
  String _generateTitle(String content) {
    // Begræns til de første 50 tegn
    final truncated =
        content.length > 50 ? '${content.substring(0, 47)}...' : content;

    // Fjern newlines
    return truncated.replaceAll('\n', ' ').trim();
  }
  
  /// Hent stien til databasefilen
  Future<String> _getDatabasePath() async {
    // Gem databasen i Documents-mappen, som er tilgængelig inden for sandbox
    final documentsDir = await getApplicationDocumentsDirectory();
    return path.join(documentsDir.path, dbName);
  }
  
  /// Luk databasen ved app-afslutning
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _isInitialized = false;
    }
  }

  /// Giver adgang til databasen
  Future<sqflite.Database> get database async {
    if (_db == null || !_isInitialized) {
      await init();
    }
    return _db!;
  }

  /// Henter alle beskederne for en specifik chat
  Future<List<ChatMessage>> _getMessagesForChat(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    
    return maps.map((map) {
      return ChatMessage(
        content: map['content'] as String?,
        isUser: map['is_user'] == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
    }).toList();
  }

  /// Ryd alle chats fra databasen
  Future<void> clearAllChats() async {
    if (!isInitialized) {
      throw Exception('Database er ikke initialiseret');
    }
    
    try {
      // Slet alle chats
      await _db!.delete('chats');
      print('Alle chats slettet fra databasen');
      
      // Slet alle beskedindeks hvis vi har en vector database
      await _db!.delete('message_embeddings');
      print('Alle beskedindeks slettet fra databasen');
    } catch (e) {
      print('Fejl ved sletning af chats: $e');
      throw Exception('Fejl ved sletning af chats: $e');
    }
  }
} 