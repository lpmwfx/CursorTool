import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;  // Korrekt import til path funktioner
import '../services/settings_service.dart';
import '../services/chat_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Advarsel om sandboxing på macOS
          if (Platform.isMacOS)
            Card(
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'macOS Sandboxing Begrænsning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'macOS tillader ikke appen at læse Cursor\'s chatfiler direkte fra Library/Application Support.',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _showMacOSGuide(context),
                          child: const Text('Vis vejledning til løsning'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _importCursorChats(context),
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Importér Chats'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          _buildSectionTitle(context, 'Generelt'),
          _buildSettingItem(
            context: context,
            title: 'Mørkt tema',
            description: 'Skift mellem lyst og mørkt tema',
            trailing: Switch(
              value: settings.isDarkMode,
              onChanged: (_) => settings.toggleDarkMode(),
            ),
            onTap: () => settings.toggleDarkMode(),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Placeringer'),
          _buildSettingItem(
            context: context,
            title: 'CLI Værktøj',
            description: settings.cliPath,
            trailing: const Icon(Icons.edit),
            onTap: () => _selectCliPath(context),
          ),
          _buildSettingItem(
            context: context,
            title: 'Workspace mappe',
            description: settings.workspacePath,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: () => _selectWorkspacePath(context),
                  tooltip: 'Vælg mappe',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editWorkspacePath(context),
                  tooltip: 'Indtast sti manuelt',
                ),
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  onPressed: () => _debugWorkspacePath(context),
                  tooltip: 'Debug sti',
                ),
              ],
            ),
            onTap: () => _editWorkspacePath(context),
          ),
          _buildSettingItem(
            context: context,
            title: 'Output mappe',
            description: settings.outputPath,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: () => _selectOutputPath(context),
                  tooltip: 'Vælg mappe',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editOutputPath(context),
                  tooltip: 'Indtast sti manuelt',
                ),
              ],
            ),
            onTap: () => _selectOutputPath(context),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Eksport indstillinger'),
          _buildSettingItem(
            context: context,
            title: 'Standard format',
            description: _formatDescription(settings.defaultFormat),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _selectDefaultFormat(context),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Om'),
          _buildSettingItem(
            context: context,
            title: 'Version',
            description: '1.0.0',
            trailing: null,
            onTap: null,
          ),
          _buildSettingItem(
            context: context,
            title: 'Udviklet af',
            description: 'Lars med hjælp fra Claude 3.7 AI',
            trailing: null,
            onTap: null,
          ),
          const Divider(),
          _buildSectionTitle(context, 'Database'),
          _buildSettingItem(
            context: context,
            title: 'Importér Cursor Chats',
            description: 'Importér chats fra Cursor\'s SQLite databaser',
            trailing: IconButton(
              icon: const Icon(Icons.import_export),
              onPressed: () => _importCursorChats(context),
            ),
            onTap: () => _importCursorChats(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required String description,
    required Widget? trailing,
    required Function()? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _formatDescription(String format) {
    switch (format) {
      case 'text':
        return 'Tekst (.txt)';
      case 'markdown':
        return 'Markdown (.md)';
      case 'html':
        return 'HTML (.html)';
      case 'json':
        return 'JSON (.json)';
      default:
        return format;
    }
  }

  Future<void> _selectCliPath(BuildContext context) async {
    final settings = context.read<SettingsService>();
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = File(result.files.single.path!);
      if (await file.exists()) {
        await settings.updateCliPath(file.path);
      }
    }
  }

  Future<void> _selectWorkspacePath(BuildContext context) async {
    final settings = context.read<SettingsService>();
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final directory = Directory(result);
      if (await directory.exists()) {
        await settings.updateWorkspacePath(directory.path);
      }
    }
  }

  Future<void> _editWorkspacePath(BuildContext context, {String? prefill}) async {
    final settings = context.read<SettingsService>();
    final controller = TextEditingController(text: prefill ?? settings.workspacePath);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Indtast workspace sti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Fuld sti til Cursor workspaceStorage',
                hintText: '/Users/navn/Documents/CursorChats',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: På macOS bør du kopiere filerne til Documents-mappen.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Gem'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await settings.updateWorkspacePath(result);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace sti opdateret')),
        );
      }
    }
  }

  Future<void> _selectOutputPath(BuildContext context) async {
    final settings = context.read<SettingsService>();
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final directory = Directory(result);
      if (await directory.exists()) {
        await settings.updateOutputPath(directory.path);
      }
    }
  }

  Future<void> _editOutputPath(BuildContext context) async {
    final settings = context.read<SettingsService>();
    final controller = TextEditingController(text: settings.outputPath);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Indtast output sti'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Fuld sti til output-mappe',
            hintText: '/Users/navn/Documents/CursorChats',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Gem'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      final directory = Directory(result);
      
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kunne ikke oprette mappen: $e')),
            );
          }
          return;
        }
      }
      
      await settings.updateOutputPath(result);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Output sti opdateret')),
        );
      }
    }
  }

  Future<void> _selectDefaultFormat(BuildContext context) async {
    final settings = context.read<SettingsService>();

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vælg standardformat'),
        children: [
          _buildFormatOption(context, settings, 'text', 'Tekst (.txt)'),
          _buildFormatOption(context, settings, 'markdown', 'Markdown (.md)'),
          _buildFormatOption(context, settings, 'html', 'HTML (.html)'),
          _buildFormatOption(context, settings, 'json', 'JSON (.json)'),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context,
    SettingsService settings,
    String value,
    String label,
  ) {
    return SimpleDialogOption(
      onPressed: () async {
        await settings.updateDefaultFormat(value);
        Navigator.pop(context);
      },
      child: Text(label),
    );
  }

  Future<void> _debugWorkspacePath(BuildContext context) async {
    final chatService = context.read<ChatService>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Tjekker workspace sti...'),
          ],
        ),
      ),
    );
    
    final result = await chatService.debugWorkspacePath();
    
    if (context.mounted) {
      Navigator.pop(context);
    }
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Workspace Debug Info'),
          content: SingleChildScrollView(
            child: SelectableText(result),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Luk'),
            ),
          ],
        ),
      );
    }
  }

  // Viser vejledning om macOS sandboxing problem
  void _showMacOSGuide(BuildContext context) {
    final homeDir = Platform.environment['HOME'] ?? '';
    final cursorPath = '${homeDir}/Library/Application Support/Cursor/User/workspaceStorage';
    final docsPath = '${homeDir}/Documents/CursorChats';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Løsning på macOS Sandboxing'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'På grund af macOS sikkerhedsbegrænsninger kan appen ikke læse filer direkte fra Cursor\'s mappe.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Følg disse trin for at løse problemet:'),
              const SizedBox(height: 8),
              _buildStep(1, 'Åbn Finder'),
              _buildStep(2, 'Tryk på ⌘+Shift+G eller vælg "Gå til mappe" fra Gå-menuen'),
              _buildStep(3, 'Indtast og gå til denne sti:'),
              SelectableText(
                cursorPath,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              _buildStep(4, 'Opret en ny mappe i Documents kaldet "CursorChats":'),
              SelectableText(
                docsPath,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              _buildStep(5, 'Kopier alle mapper fra Cursor\'s workspaceStorage til den nye mappe'),
              _buildStep(6, 'Opdater workspace-stien i denne app til den nye placering'),
              const SizedBox(height: 16),
              const Text(
                'Nu burde appen kunne læse dine Cursor chat-filer fra Documents-mappen, som er tilgængelig inden for macOS sandboxing.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editWorkspacePath(context, prefill: docsPath);
            },
            child: const Text('Opsæt sti nu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luk'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // Funktion til at importere chats fra Cursor
  Future<void> _importCursorChats(BuildContext context) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // Hent stier til Cursor databaser
    final cursorDbFiles = await _findCursorDbFiles();
    
    if (cursorDbFiles.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingen Cursor database filer fundet')),
        );
      }
      return;
    }
    
    // Vis dialog med valg af filer
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ImportCursorDbDialog(
          dbFiles: cursorDbFiles, 
          dbService: dbService,
          chatService: chatService,
        ),
      );
    }
  }
  
  // Find Cursor database filer
  Future<List<File>> _findCursorDbFiles() async {
    List<File> result = [];
    
    try {
      // Prøv først med FilePicker - giver brugeren kontrol
      FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['vscdb'],
        allowMultiple: true,
      );
      
      if (pickerResult != null && pickerResult.files.isNotEmpty) {
        // Bruger har valgt filer
        for (final file in pickerResult.files) {
          if (file.path != null) {
            result.add(File(file.path!));
          }
        }
        return result;
      }
      
      // Alternativt, prøv at finde Cursor databaser automatisk
      if (Platform.isMacOS) {
        final homeDir = Platform.environment['HOME'] ?? '';
        final cursorDir = Directory(path.join(
          homeDir, 'Library', 'Application Support', 'Cursor', 'User', 'workspaceStorage'
        ));
        
        if (await cursorDir.exists()) {
          // List alle mapper i workspaceStorage
          await for (final entry in cursorDir.list()) {
            if (entry is Directory) {
              final dbFile = File(path.join(entry.path, 'state.vscdb'));
              if (await dbFile.exists()) {
                result.add(dbFile);
              }
            }
          }
        }
      } else if (Platform.isLinux) {
        final homeDir = Platform.environment['HOME'] ?? '';
        final cursorDir = Directory(path.join(
          homeDir, '.config', 'Cursor', 'User', 'workspaceStorage'
        ));
        
        if (await cursorDir.exists()) {
          await for (final entry in cursorDir.list()) {
            if (entry is Directory) {
              final dbFile = File(path.join(entry.path, 'state.vscdb'));
              if (await dbFile.exists()) {
                result.add(dbFile);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Fejl ved søgning efter Cursor database filer: $e');
    }
    
    return result;
  }
}

/// Dialog til at importere Cursor database filer
class _ImportCursorDbDialog extends StatefulWidget {
  final List<File> dbFiles;
  final DatabaseService dbService;
  final ChatService chatService;
  
  const _ImportCursorDbDialog({
    required this.dbFiles, 
    required this.dbService,
    required this.chatService,
  });

  @override
  State<_ImportCursorDbDialog> createState() => _ImportCursorDbDialogState();
}

class _ImportCursorDbDialogState extends State<_ImportCursorDbDialog> {
  bool _importing = false;
  double _progress = 0.0;
  String _status = 'Klar til import';
  int _importedCount = 0;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importér Cursor Chats'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fundet ${widget.dbFiles.length} Cursor database filer'),
            const SizedBox(height: 16),
            if (!_importing)
              Text('Tryk på Start for at importere chatdata fra disse filer.'),
            if (_importing) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_status),
            ],
            if (_importedCount > 0) ...[
              const SizedBox(height: 16),
              Text('Importeret $_importedCount chats'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.pop(context),
          child: const Text('Annuller'),
        ),
        ElevatedButton(
          onPressed: _importing ? null : _startImport,
          child: Text(_importing ? 'Importerer...' : 'Start Import'),
        ),
      ],
    );
  }
  
  Future<void> _startImport() async {
    setState(() {
      _importing = true;
      _progress = 0.0;
      _status = 'Starter import...';
    });
    
    try {
      // Lyt til ændringer i import-tilstand
      void listenerCallback() {
        if (mounted) {
          setState(() {
            _progress = widget.dbService.importProgress;
            _status = widget.dbService.isImporting
                ? 'Importerer...'
                : 'Import afsluttet';
          });
        }
      }
      
      // Tilføj lytter
      widget.dbService.addListener(listenerCallback);
      
      // Start import
      _importedCount = await widget.dbService.importFromCursorDb(widget.dbFiles);
      
      // Fjern lytter
      widget.dbService.removeListener(listenerCallback);
      
      // Opdater chat liste
      await widget.chatService.loadChats();  // Brug den eksisterende loadChats metode
      
      if (mounted) {
        setState(() {
          _importing = false;
          _progress = 1.0;
          _status = 'Import afsluttet';
        });
      }
      
      // Luk dialogen efter et kort øjeblik
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        Navigator.pop(context);
        
        // Vis snackbar med resultat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Importerede $_importedCount chats fra Cursor')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importing = false;
          _status = 'Fejl: $e';
        });
      }
    }
  }
}
