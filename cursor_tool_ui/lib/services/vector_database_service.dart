import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';
import 'package:http/http.dart' as http;
import '../models/chat.dart';

/// Service til at håndtere vector database operationer
class VectorDatabaseService {
  static const String _databaseName = 'cursor_chat_vectors.db';
  static const String _chatTable = 'chats';
  static const String _messagesTable = 'messages';
  static const String _vectorTable = 'message_vectors';
  static const int _vectorDimension = 1536; // Dimension for text-embedding-ada-002

  Database? _db;
  bool _isInitialized = false;
  String? _apiKey;

  bool get isInitialized => _isInitialized;

  /// Initialiserer vector database servicen
  /// 
  /// [apiKey] er OpenAI API nøglen. Hvis den ikke angives, forsøges der at hentes fra miljøvariablen OPENAI_API_KEY
  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;

    try {
      // Gem API nøglen
      _apiKey = apiKey ?? Platform.environment['OPENAI_API_KEY'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('OpenAI API nøgle er ikke angivet. Angiv den direkte eller via OPENAI_API_KEY miljøvariabel.');
      }
      
      // Åbn databasen
      final dbPath = await _getDatabasePath();
      _db = sqlite3.open(dbPath);
      
      // Opret tabeller hvis de ikke findes
      await _createTables();
      
      _isInitialized = true;
      print('Vector database service initialiseret med succes');
    } catch (e) {
      print('Fejl ved initialisering af vector database: $e');
      _closeDatabase();
      rethrow;
    }
  }

  /// Lukker databasen
  void dispose() {
    _closeDatabase();
  }

  /// Henter stien til databasefilen
  Future<String> _getDatabasePath() async {
    final dbDir = await getApplicationDocumentsDirectory();
    return path.join(dbDir.path, _databaseName);
  }

  /// Lukker databaseforbindelsen
  void _closeDatabase() {
    _db?.dispose();
    _db = null;
    _isInitialized = false;
  }

  /// Opretter de nødvendige tabeller i databasen
  Future<void> _createTables() async {
    if (_db == null) return;

    // Chat tabel
    _db!.execute('''
    CREATE TABLE IF NOT EXISTS $_chatTable (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      last_message_time INTEGER NOT NULL
    )
    ''');

    // Besked tabel
    _db!.execute('''
    CREATE TABLE IF NOT EXISTS $_messagesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id TEXT NOT NULL,
      content TEXT,
      is_user INTEGER NOT NULL,
      timestamp INTEGER NOT NULL,
      FOREIGN KEY (chat_id) REFERENCES $_chatTable(id)
    )
    ''');

    // Vector tabel - gemmer embeddings som blob
    _db!.execute('''
    CREATE TABLE IF NOT EXISTS $_vectorTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id INTEGER NOT NULL,
      chat_id TEXT NOT NULL,
      embedding BLOB NOT NULL,
      FOREIGN KEY (message_id) REFERENCES $_messagesTable(id),
      FOREIGN KEY (chat_id) REFERENCES $_chatTable(id)
    )
    ''');
  }

  /// Henter embedding fra OpenAI API
  Future<List<double>> _getEmbedding(String text) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenAI API nøgle er ikke angivet');
    }
    
    final url = Uri.parse('https://api.openai.com/v1/embeddings');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    
    final body = jsonEncode({
      'input': text,
      'model': 'text-embedding-ada-002',
    });
    
    try {
      final response = await http.post(url, headers: headers, body: body);
      
      if (response.statusCode != 200) {
        throw Exception('Fejl ved hentning af embedding: ${response.body}');
      }
      
      final jsonResponse = jsonDecode(response.body);
      final embedding = List<double>.from(jsonResponse['data'][0]['embedding']);
      
      return embedding;
    } catch (e) {
      print('Fejl ved hentning af embedding: $e');
      rethrow;
    }
  }

  /// Gemmer en chat med alle beskeder og deres vector embeddings
  Future<void> saveChat(Chat chat) async {
    if (!_isInitialized || _db == null) {
      throw Exception('Vector database er ikke initialiseret');
    }

    try {
      _db!.execute('BEGIN TRANSACTION');

      // Gem chat
      _db!.execute(
        'INSERT OR REPLACE INTO $_chatTable (id, title, last_message_time) VALUES (?, ?, ?)',
        [
          chat.id,
          chat.title,
          chat.lastMessageTime.millisecondsSinceEpoch,
        ],
      );

      // Først slet eksisterende beskeder og vektorer for denne chat
      _db!.execute('DELETE FROM $_vectorTable WHERE chat_id = ?', [chat.id]);
      _db!.execute('DELETE FROM $_messagesTable WHERE chat_id = ?', [chat.id]);

      // Indsæt nye beskeder og vektorer
      for (final message in chat.messages) {
        if (message.content == null || message.content!.isEmpty) {
          continue; // Spring tomme beskeder over
        }

        // Indsæt besked
        _db!.execute(
          'INSERT INTO $_messagesTable (chat_id, content, is_user, timestamp) VALUES (?, ?, ?, ?)',
          [
            chat.id,
            message.content,
            message.isUser ? 1 : 0,
            message.timestamp.millisecondsSinceEpoch,
          ],
        );
        final messageId = _db!.lastInsertRowId;

        // Generer embedding for beskedens indhold
        final embedding = await _getEmbedding(message.content!);
        
        // Konverter embedding til blob
        final embeddingBlob = _vectorToBlob(embedding);
        
        // Gem embedding i vector tabellen
        _db!.execute(
          'INSERT INTO $_vectorTable (message_id, chat_id, embedding) VALUES (?, ?, ?)',
          [messageId, chat.id, embeddingBlob],
        );
      }

      _db!.execute('COMMIT');
      print('Chat ${chat.id} gemt i vector databasen med ${chat.messages.length} beskeder');
    } catch (e) {
      _db!.execute('ROLLBACK');
      print('Fejl ved gemning af chat i vector database: $e');
      rethrow;
    }
  }

  /// Henter alle chats fra databasen
  Future<List<Chat>> getAllChats() async {
    if (!_isInitialized || _db == null) {
      throw Exception('Vector database er ikke initialiseret');
    }

    try {
      final chatResults = _db!.select(
        'SELECT * FROM $_chatTable ORDER BY last_message_time DESC'
      );

      final chats = <Chat>[];
      for (final row in chatResults) {
        final chatId = row['id'] as String;
        
        // Hent beskeder for denne chat
        final messagesResult = _db!.select(
          'SELECT * FROM $_messagesTable WHERE chat_id = ? ORDER BY timestamp ASC',
          [chatId],
        );
        
        final messages = messagesResult.map((row) {
          return ChatMessage(
            content: row['content'] as String?,
            isUser: row['is_user'] == 1,
            timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
          );
        }).toList();
        
        chats.add(Chat(
          id: chatId,
          title: row['title'] as String,
          messages: messages,
        ));
      }
      
      return chats;
    } catch (e) {
      print('Fejl ved hentning af chats fra vector database: $e');
      rethrow;
    }
  }

  /// Henter en specifik chat fra databasen
  Future<Chat?> getChat(String chatId) async {
    if (!_isInitialized || _db == null) {
      throw Exception('Vector database er ikke initialiseret');
    }

    try {
      final chatResult = _db!.select(
        'SELECT * FROM $_chatTable WHERE id = ?',
        [chatId],
      );
      
      if (chatResult.isEmpty) {
        return null;
      }
      
      // Hent beskeder for denne chat
      final messagesResult = _db!.select(
        'SELECT * FROM $_messagesTable WHERE chat_id = ? ORDER BY timestamp ASC',
        [chatId],
      );
      
      final messages = messagesResult.map((row) {
        return ChatMessage(
          content: row['content'] as String?,
          isUser: row['is_user'] == 1,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        );
      }).toList();
      
      return Chat(
        id: chatId,
        title: chatResult.first['title'] as String,
        messages: messages,
      );
    } catch (e) {
      print('Fejl ved hentning af chat fra vector database: $e');
      rethrow;
    }
  }

  /// Søger efter beskeder i alle chats baseret på en semantisk søgestreng
  Future<List<SearchResult>> semanticSearch(String query, {int limit = 10}) async {
    if (!_isInitialized || _db == null) {
      throw Exception('Vector database er ikke initialiseret');
    }

    try {
      // Generer embedding for søgestrengen
      final queryEmbedding = await _getEmbedding(query);
      
      // Hent alle vektorer og beregn cosine similarity
      final allVectorsResult = _db!.select('''
        SELECT 
          v.id,
          v.message_id,
          v.chat_id,
          v.embedding,
          m.content,
          m.is_user,
          m.timestamp,
          c.title as chat_title
        FROM $_vectorTable v
        JOIN $_messagesTable m ON v.message_id = m.id
        JOIN $_chatTable c ON v.chat_id = c.id
      ''');
      
      // Beregn similarity scores
      final results = <SearchResultWithScore>[];
      
      for (final row in allVectorsResult) {
        final embeddingBlob = row['embedding'] as Uint8List;
        final vector = _blobToVector(embeddingBlob);
        
        final similarity = _cosineSimilarity(queryEmbedding, vector);
        
        results.add(SearchResultWithScore(
          score: similarity,
          result: SearchResult(
            messageId: row['message_id'] as int,
            chatId: row['chat_id'] as String,
            chatTitle: row['chat_title'] as String,
            content: row['content'] as String?,
            isUser: row['is_user'] == 1,
            timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
            score: similarity,
          ),
        ));
      }
      
      // Sorter efter score og begræns antallet
      results.sort((a, b) => b.score.compareTo(a.score));
      
      return results
          .take(limit)
          .map((r) => r.result)
          .toList();
    } catch (e) {
      print('Fejl ved semantisk søgning: $e');
      rethrow;
    }
  }
  
  /// Beregner cosine similarity mellem to vektorer
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw Exception('Vektorer skal have samme dimension');
    }
    
    // Brug ml_linalg til at beregne cosine similarity
    final vecA = Vector.fromList(a);
    final vecB = Vector.fromList(b);
    
    // Cosine similarity = dot(A, B) / (||A|| * ||B||)
    final dotProduct = vecA.dot(vecB);
    final normA = vecA.norm();
    final normB = vecB.norm();
    
    if (normA == 0 || normB == 0) {
      return 0;
    }
    
    return dotProduct / (normA * normB);
  }
  
  /// Konverterer en liste af double til en blob til lagring i databasen
  Uint8List _vectorToBlob(List<double> vector) {
    final floatList = Float32List.fromList(vector);
    return Uint8List.view(floatList.buffer);
  }
  
  /// Konverterer en blob til en liste af double
  List<double> _blobToVector(Uint8List blob) {
    final floatList = Float32List.view(blob.buffer);
    return floatList.toList();
  }
}

/// Hjælpeklasse til at gemme search results med deres score
class SearchResultWithScore {
  final double score;
  final SearchResult result;
  
  SearchResultWithScore({
    required this.score,
    required this.result,
  });
}

/// Klasse til at repræsentere et søgeresultat
class SearchResult {
  final int messageId;
  final String chatId;
  final String chatTitle;
  final String? content;
  final bool isUser;
  final DateTime timestamp;
  final double score;

  SearchResult({
    required this.messageId,
    required this.chatId,
    required this.chatTitle,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.score,
  });
  
  /// Konverterer til String
  @override
  String toString() {
    return 'SearchResult(chatId: $chatId, messageId: $messageId, score: $score)';
  }
} 