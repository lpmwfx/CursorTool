import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Konfigurationsklasse til at håndtere indstillinger
class Config {
  /// Stien til mappen hvor Cursor gemmer chat historikker
  final String chatHistoryPath;

  Config({required this.chatHistoryPath});

  /// Indlæs konfiguration fra en angivet sti
  static Config load(String configPath) {
    final expandedPath = configPath.replaceFirst(
      '~',
      Platform.environment['HOME'] ?? '',
    );

    // Standardplaceringer af Cursor AI chat historik baseret på OS
    String defaultChatPath;
    if (Platform.isWindows) {
      defaultChatPath = path.join(
        Platform.environment['APPDATA'] ?? '',
        'cursor',
        'chat_history',
      );
    } else if (Platform.isMacOS) {
      defaultChatPath = path.join(
        Platform.environment['HOME'] ?? '',
        'Library',
        'Application Support',
        'cursor',
        'chat_history',
      );
    } else {
      // Linux
      defaultChatPath = path.join(
        Platform.environment['HOME'] ?? '',
        '.config',
        'cursor',
        'chat_history',
      );
    }

    try {
      final configFile = File(expandedPath);
      if (configFile.existsSync()) {
        final jsonData = jsonDecode(configFile.readAsStringSync());
        return Config(
          chatHistoryPath: jsonData['chatHistoryPath'] ?? defaultChatPath,
        );
      }
    } catch (e) {
      print('Advarsel: Kunne ikke læse konfiguration fra $configPath: $e');
      print('Bruger standardværdier i stedet.');
    }

    // Returner standardkonfiguration
    return Config(chatHistoryPath: defaultChatPath);
  }

  /// Gem konfigurationen til fil
  void save(String configPath) {
    final expandedPath = configPath.replaceFirst(
      '~',
      Platform.environment['HOME'] ?? '',
    );

    final configFile = File(expandedPath);
    final configDir = path.dirname(expandedPath);

    if (!Directory(configDir).existsSync()) {
      Directory(configDir).createSync(recursive: true);
    }

    final jsonData = {'chatHistoryPath': chatHistoryPath};

    configFile.writeAsStringSync(jsonEncode(jsonData));
  }
}
