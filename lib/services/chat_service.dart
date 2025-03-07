import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart' show run;
import '../models/chat.dart';
import '../cli/chat_browser.dart';
import '../cli/chat_extractor.dart';
import '../cli/chat_model.dart' as cli;
import '../cli/config.dart';
import 'settings_service.dart';

// Opdateret version der bruger integreret CLI-kode
class ChatService extends ChangeNotifier {
  final SettingsService _settings;
  List<Chat> _chats = [];
  bool _isLoading = false;
  String _lastError = '';

  ChatService(this._settings);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  // Hent alle chats via integreret CLI-kode
  Future<void> loadChats() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      // Opret config med indstillinger
      final config = Config(
        dbPath: _settings.workspacePath,
        outputPath: _settings.outputPath,
        outputFormat: _settings.defaultFormat,
      );
      
      // Brug ChatBrowser direkte
      final browser = ChatBrowser(config);
      final chatHistories = await browser.listChatHistories();
      
      if (chatHistories.isEmpty) {
        _lastError = 'Ingen chats fundet i ${_settings.workspacePath}';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Konverter til vores Chat-model
      _chats = chatHistories.map((history) {
        final messages = history.messages.map((msg) => 
          ChatMessage(
            content: msg.content,
            isUser: msg.role == 'user',
            timestamp: DateTime.fromMillisecondsSinceEpoch(msg.timestamp),
          )
        ).toList();
        
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
      
    } catch (e) {
      _lastError = 'Fejl ved indlæsning af chats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Udtræk en specifik chat
  Future<bool> extractChat(String chatId, [String format = '']) async {
    try {
      final config = Config(
        dbPath: _settings.workspacePath,
        outputPath: _settings.outputPath,
        outputFormat: format.isNotEmpty ? format : _settings.defaultFormat,
      );
      
      final extractor = ChatExtractor(config);
      await extractor.extractChat(chatId);
      return true;
    } catch (e) {
      _lastError = 'Fejl ved udtrækning af chat: $e';
      notifyListeners();
      return false;
    }
  }

  // Åbn TUI browser (denne funktion kan fjernes eller erstattes)
  Future<void> showTuiBrowser() async {
    _lastError = 'TUI browser er ikke tilgængelig i den integrerede version';
    notifyListeners();
  }

  // Kør CLI-kommando
  Future<dynamic> _runCliCommand(List<String> arguments) async {
    return await run(_settings.cliPath, arguments);
  }
}
