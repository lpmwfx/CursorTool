import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:cursor_tool_ui/cli/lib/chat_browser.dart';
import 'package:cursor_tool_ui/cli/lib/chat_extractor.dart';
import 'package:cursor_tool_ui/cli/lib/config.dart';

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
      final extractor = ChatExtractor(config);
      final outputPath = results['output'] as String;
      final format = results['format'] as String;

      await extractor.extract(results['extract'] as String, outputPath, format);
    } else {
      // Som standard viser vi TUI browser
      final browser = ChatBrowser(config);
      await browser.showTUI();
    }
  } catch (e) {
    print('Fejl: \${e.toString()}');
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
