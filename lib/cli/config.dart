import 'dart:io';
import 'package:path/path.dart' as path;

class Config {
  String dbPath;
  String outputPath;
  String outputFormat;
  bool verbose;

  Config({
    required this.dbPath,
    required this.outputPath,
    this.outputFormat = 'text',
    this.verbose = false,
  }) {
    // Standardværdier hvis ikke angivet
    if (dbPath.isEmpty) {
      final homeDir = Platform.environment['HOME'] ?? '';
      dbPath = path.join(homeDir, '.cursor', 'cursor-chat.db');
    }

    if (outputPath.isEmpty) {
      final homeDir = Platform.environment['HOME'] ?? '';
      outputPath = path.join(homeDir, 'Documents', 'CursorChats');
    }

    // Opret output-mappen hvis den ikke findes
    final outputDir = Directory(outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
  }

  // Find Cursor chat database
  String findCursorChatDb() {
    // Hvis dbPath er en mappe, så find databasen i den
    final dbFile = File(dbPath);
    if (dbFile.existsSync() && dbFile.statSync().type == FileSystemEntityType.file) {
      return dbPath;
    }

    // Hvis dbPath er en mappe, så prøv at finde databasen i den
    final dbDir = Directory(dbPath);
    if (dbDir.existsSync()) {
      final files = dbDir.listSync();
      for (final file in files) {
        if (file is File && path.basename(file.path) == 'cursor-chat.db') {
          return file.path;
        }
      }
    }

    // Prøv standardplaceringer
    final homeDir = Platform.environment['HOME'] ?? '';
    final possiblePaths = [
      path.join(homeDir, '.cursor', 'cursor-chat.db'),
      path.join(homeDir, 'Library', 'Application Support', 'cursor', 'cursor-chat.db'),
      path.join(homeDir, 'AppData', 'Roaming', 'cursor', 'cursor-chat.db'),
    ];

    for (final possiblePath in possiblePaths) {
      final file = File(possiblePath);
      if (file.existsSync()) {
        return possiblePath;
      }
    }

    throw Exception('Kunne ikke finde Cursor chat database. Angiv stien med --db-path.');
  }
} 