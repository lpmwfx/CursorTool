import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:cursor_tool_ui/cli/chat_browser.dart';
import 'package:cursor_tool_ui/cli/chat_extractor.dart';
import 'package:cursor_tool_ui/cli/config.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Vis hjælp')
    ..addFlag(
      'list',
      abbr: 'l',
      negatable: false,
      help: 'List alle chat historikker',
    )
    ..addOption(
      'extract',
      abbr: 'e',
      help: 'Udtræk en specifik chat (id eller alle)',
    )
    ..addOption(
      'format',
      abbr: 'f',
      help: 'Output format (text, markdown, html, json)',
      defaultsTo: 'text',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output mappe',
      defaultsTo: './output',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Sti til konfigurationsfil',
      defaultsTo: '~/.cursor_chat_tool.conf',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      return;
    }

    final config = Config.load(results['config'] as String);

    if (results['list'] as bool) {
      final browser = ChatBrowser(config);
      await browser.listChats();
    } else if (results['extract'] != null) {
      final chatId = results['extract'] as String;
      final outputPath = results['output'] as String;
      final format = results['format'] as String;
      
      final browser = ChatBrowser(config);
      final chat = await browser.getChat(chatId);
      
      if (chat != null) {
        final outputDir = Directory(outputPath);
        if (!outputDir.existsSync()) {
          outputDir.createSync(recursive: true);
        }
        
        final outputFile = File(path.join(outputPath, '${chat.id}.$format'));
        outputFile.writeAsStringSync(chat.toString());
        print('Chat gemt til ${outputFile.path}');
      } else {
        print('Chat med ID $chatId ikke fundet');
      }
    } else {
      // Som standard viser vi TUI browser
      final browser = ChatBrowser(config);
      await browser.showTUI();
    }
  } catch (e) {
    print('Fejl: ${e.toString()}');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('Cursor Chat Browser & Extractor');
  print('');
  print('Brug: cursor_chat_tool [options]');
  print('');
  print(parser.usage);
}
