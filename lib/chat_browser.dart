import 'dart:io';
import 'dart:convert';
import 'package:dart_console/dart_console.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
import 'config.dart';
import 'chat_model.dart';

/// Klasse til at browse og vise chat historikker
class ChatBrowser {
  final Config config;
  final console = Console();
  List<Chat> _chats = [];

  ChatBrowser(this.config);

  /// Indlæser alle chats fra historik-mappen
  Future<List<Chat>> _loadChats() async {
    final chatDir = Directory(config.chatHistoryPath);

    if (!chatDir.existsSync()) {
      print(
        'Advarsel: Chat historik mappe ikke fundet: ${config.chatHistoryPath}',
      );
      return [];
    }

    final chats = <Chat>[];

    try {
      await for (final entity in chatDir.list()) {
        if (entity is File && path.extension(entity.path) == '.json') {
          try {
            final content = await File(entity.path).readAsString();
            final data = jsonDecode(content);
            final chat = Chat.fromJson(
              data,
              path.basenameWithoutExtension(entity.path),
            );
            chats.add(chat);
          } catch (e) {
            print('Kunne ikke indlæse ${entity.path}: $e');
          }
        }
      }

      // Sorter efter dato, nyeste først
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    } catch (e) {
      print('Fejl ved indlæsning af chats: $e');
      return [];
    }
  }

  /// Viser liste over alle chats i konsollen
  Future<void> listChats() async {
    _chats = await _loadChats();

    if (_chats.isEmpty) {
      print('Ingen chat historikker fundet i ${config.chatHistoryPath}');
      return;
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    print('Fandt ${_chats.length} chat historikker:');
    print('');
    print('ID | Titel | Dato | Antal beskeder');
    print('----------------------------------------');

    for (var i = 0; i < _chats.length; i++) {
      final chat = _chats[i];
      final dateStr = dateFormat.format(chat.lastMessageTime);
      print('${i + 1} | ${chat.title} | $dateStr | ${chat.messages.length}');
    }
  }

  /// Viser Text User Interface (TUI) til at browse og se chats
  Future<void> showTUI() async {
    _chats = await _loadChats();

    if (_chats.isEmpty) {
      print('Ingen chat historikker fundet i ${config.chatHistoryPath}');
      return;
    }

    console.clearScreen();
    var selectedIndex = 0;
    var viewingChat = false;
    var scrollOffset = 0;

    while (true) {
      console.clearScreen();
      console.resetCursorPosition();

      if (!viewingChat) {
        _drawChatList(selectedIndex);
      } else {
        _drawChatView(_chats[selectedIndex], scrollOffset);
      }

      final key = console.readKey();

      if (key.controlChar == ControlCharacter.ctrlC) {
        console.clearScreen();
        console.resetCursorPosition();
        return;
      }

      if (!viewingChat) {
        // Navigation i chat listen
        if (key.controlChar == ControlCharacter.arrowDown) {
          selectedIndex = (selectedIndex + 1) % _chats.length;
        } else if (key.controlChar == ControlCharacter.arrowUp) {
          selectedIndex = (selectedIndex - 1 + _chats.length) % _chats.length;
        } else if (key.controlChar == ControlCharacter.enter) {
          viewingChat = true;
          scrollOffset = 0;
        } else if (key.char == 'q') {
          console.clearScreen();
          console.resetCursorPosition();
          return;
        }
      } else {
        // Navigation i chat visning
        if (key.controlChar == ControlCharacter.arrowDown) {
          scrollOffset += 1;
        } else if (key.controlChar == ControlCharacter.arrowUp) {
          scrollOffset = (scrollOffset - 1).clamp(0, double.infinity).toInt();
        } else if (key.char == 'q' ||
            key.controlChar == ControlCharacter.escape) {
          viewingChat = false;
        }
      }
    }
  }

  /// Tegner chat listen
  void _drawChatList(int selectedIndex) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final width = console.windowWidth;

    console.writeLine(
      '=== Cursor Chat Historik Browser ==='.padRight(width),
      TextAlignment.center,
    );
    console.writeLine('');
    console.writeLine(
      'Tryk ↑/↓ for at navigere, Enter for at se chat, Q for at afslutte',
    );
    console.writeLine('');

    final titleWidth = 40;
    final dateWidth = 20;

    console.writeLine(
      'ID | ${_padTruncate('Titel', titleWidth)} | Dato | Antal',
    );
    console.writeLine(''.padRight(width, '-'));

    for (var i = 0; i < _chats.length; i++) {
      final chat = _chats[i];
      final dateStr = dateFormat.format(chat.lastMessageTime);
      final line =
          '${_padTruncate((i + 1).toString(), 3)} | '
          '${_padTruncate(chat.title, titleWidth)} | '
          '${_padTruncate(dateStr, dateWidth)} | '
          '${chat.messages.length}';

      if (i == selectedIndex) {
        console.setForegroundColor(ConsoleColor.white);
        console.setBackgroundColor(ConsoleColor.blue);
        console.writeLine(line.padRight(width));
        console.resetColorAttributes();
      } else {
        console.writeLine(line);
      }
    }

    console.writeLine('');
    console.writeLine('Fandt ${_chats.length} chat historikker');
  }

  /// Tegner chat visning
  void _drawChatView(Chat chat, int scrollOffset) {
    final width = console.windowWidth;
    final height = console.windowHeight - 5;

    console.writeLine(
      '=== ${chat.title} ==='.padRight(width),
      TextAlignment.center,
    );
    console.writeLine('');
    console.writeLine('Tryk ↑/↓ for at rulle, Q for at gå tilbage');
    console.writeLine(''.padRight(width, '-'));

    final visibleMessages = chat.messages.skip(scrollOffset).take(height);

    for (final message in visibleMessages) {
      final sender = message.isUser ? 'User' : 'AI';
      console.writeLine(
        '[$sender - ${DateFormat('HH:mm:ss').format(message.timestamp)}]',
      );

      // Del indholdet op i linjer der passer til skærmen
      final contentLines = _wrapText(message.content, width);
      for (final line in contentLines) {
        console.writeLine(line);
      }

      console.writeLine('');
    }

    console.writeLine(''.padRight(width, '-'));
    console.writeLine(
      'Besked ${scrollOffset + 1}-${(scrollOffset + visibleMessages.length).clamp(1, chat.messages.length)} af ${chat.messages.length}',
    );
  }

  /// Hjælpefunktion til at formattere tekst
  String _padTruncate(String text, int width) {
    if (text.length > width) {
      return text.substring(0, width - 3) + '...';
    }
    return text.padRight(width);
  }

  /// Hjælpefunktion til at wrappe tekst til en bestemt bredde
  List<String> _wrapText(String text, int width) {
    final result = <String>[];
    final words = text.split(' ');

    String currentLine = '';
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + word.length + 1 <= width) {
        currentLine += ' $word';
      } else {
        result.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      result.add(currentLine);
    }

    return result;
  }
}
