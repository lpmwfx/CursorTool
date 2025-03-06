import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart' show run;
import '../models/chat.dart';
import 'settings_service.dart';

class ChatService extends ChangeNotifier {
  final SettingsService _settings;
  List<Chat> _chats = [];
  bool _isLoading = false;
  String _lastError = '';

  ChatService(this._settings);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  // Hent alle chats via CLI-værktøjet
  Future<void> loadChats() async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      final result = await _runCliCommand(
          ['--list', '--format', 'json', '--output', _settings.outputPath]);

      if (result.exitCode != 0) {
        _lastError = 'Fejl ved indlæsning af chats: ${result.stderr}';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Indlæs chats fra output-filen, hvis de blev udtrukket
      final chatFolder = Directory(_settings.outputPath);
      if (await chatFolder.exists()) {
        final jsonFiles = await chatFolder
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.json'))
            .toList();

        _chats = [];

        for (final file in jsonFiles) {
          try {
            final content = await File(file.path).readAsString();
            final chatData = json.decode(content);
            _chats.add(Chat.fromJson(chatData));
          } catch (e) {
            print('Fejl ved indlæsning af chat-fil ${file.path}: $e');
          }
        }

        // Sorter chats efter seneste besked
        _chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      }
    } catch (e) {
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
      final result = await _runCliCommand([
        '--extract',
        chatId,
        '--format',
        format,
        '--output',
        _settings.outputPath
      ]);

      if (result.exitCode != 0) {
        _lastError = 'Fejl ved udtrækning af chat: ${result.stderr}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'Fejl: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vis TUI browseren
  Future<bool> showTuiBrowser() async {
    try {
      await _runCliCommand([]);
      return true;
    } catch (e) {
      _lastError = 'Fejl ved start af TUI browser: $e';
      notifyListeners();
      return false;
    }
  }

  // Kør CLI-kommando
  Future<dynamic> _runCliCommand(List<String> arguments) async {
    return await run(_settings.cliPath, arguments);
  }
}
