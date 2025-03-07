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
                      'macOS tillader ikke appen at læse Cursor\'s chatfiler direkte. Du skal installere CLI-værktøjet for at få adgang til dine chats.',
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _installCliTool(context),
                      icon: const Icon(Icons.install_desktop),
                      label: const Text('Installér CLI Værktøj'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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
          _buildSectionTitle(context, 'CLI Indstillinger'),
          _buildSettingItem(
            context: context,
            title: 'CLI Værktøj',
            description: settings.cliPath,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _selectCliPath(context),
                  tooltip: 'Vælg CLI-fil',
                ),
                IconButton(
                  icon: const Icon(Icons.install_desktop),
                  onPressed: () => _installCliTool(context),
                  tooltip: 'Installér CLI-værktøj',
                ),
              ],
            ),
            onTap: () => _selectCliPath(context),
          ),
          _buildSettingItem(
            context: context,
            title: 'Cursor Workspace',
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
                  icon: const Icon(Icons.bug_report),
                  onPressed: () => _debugWorkspacePath(context),
                  tooltip: 'Debug sti',
                ),
              ],
            ),
            onTap: () => _editWorkspacePath(context),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Database'),
          _buildSettingItem(
            context: context,
            title: 'Importér Cursor Chats',
            description: 'Importér chats automatisk fra Cursor',
            trailing: IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _autoImportCursorChats(context),
            ),
            onTap: () => _autoImportCursorChats(context),
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

  // Automatisk importering af chats
  Future<void> _autoImportCursorChats(BuildContext context) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Importerer chats...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 16),
            Text('Forbinder til Cursor og importerer chats...'),
          ],
        ),
      ),
    );
    
    try {
      // Forsøg at importere chats automatisk
      final importedCount = await chatService.autoImportFromCursor();
      
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        if (importedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Importerede $importedCount chats fra Cursor')),
          );
        } else {
          // Fejlhåndtering - vis dialog med flere muligheder
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Automatisk import fejlede'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appen kunne ikke automatisk importere chats.'),
                  const SizedBox(height: 8),
                  const Text('Mulige årsager:'),
                  const SizedBox(height: 4),
                  const Text('• CLI-værktøjet er ikke installeret korrekt'),
                  const Text('• Cursor\'s mappe blev ikke fundet'),
                  const Text('• Ingen chat-filer fundet i Cursors mappe'),
                  const SizedBox(height: 16),
                  const Text('Prøv at installere CLI-værktøjet igen eller vælg Cursor\'s mappe manuelt.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Luk'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _installCliTool(context);
                  },
                  child: const Text('Installér CLI Værktøj'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _selectWorkspacePath(context);
                  },
                  child: const Text('Vælg Cursor Mappe'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved import: $e')),
        );
      }
    }
  }

  // Installer CLI-værktøjet til standardplacering
  Future<void> _installCliTool(BuildContext context) async {
    final settings = context.read<SettingsService>();
    
    // Definer målsti baseret på platform
    String targetDir;
    if (Platform.isLinux) {
      targetDir = path.join(Platform.environment['HOME'] ?? '', '.cursor');
    } else if (Platform.isMacOS) {
      targetDir = path.join(
        Platform.environment['HOME'] ?? '', 
        'Library', 
        'Application Support', 
        'Cursor'
      );
    } else {
      // Fallback for Windows eller andre platforme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Installation ikke understøttet på denne platform'))
      );
      return;
    }
    
    // Vis dialog om at vælge CLI-værktøj
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Installér CLI-værktøj'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vælg CLI-værktøj til installation:'),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.file_copy),
              label: const Text('Vælg eksisterende CLI-fil'),
              onPressed: () async {
                Navigator.of(context).pop('pick');
              },
            ),
            if (Platform.isMacOS || Platform.isLinux)
              TextButton.icon(
                icon: const Icon(Icons.folder),
                label: const Text('Brug indbygget CLI-værktøj'),
                onPressed: () {
                  Navigator.of(context).pop('bundled');
                },
              ),
            TextButton.icon(
              icon: const Icon(Icons.build),
              label: const Text('Kompilér CLI-værktøj fra kildekode'),
              onPressed: () {
                Navigator.of(context).pop('compile');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuller'),
          ),
        ],
      ),
    );
    
    if (result == null) return;
    
    String? cliPath;
    
    if (result == 'pick') {
      final fileResult = await FilePicker.platform.pickFiles();
      if (fileResult != null) {
        cliPath = fileResult.files.single.path;
      } else {
        return;
      }
    } else if (result == 'bundled') {
      // Søg efter CLI-værktøj i app-mappen og assets
      final appDir = path.dirname(Platform.resolvedExecutable);
      final assetBundle = DefaultAssetBundle.of(context);
      
      // Forsøg at læse CLI-værktøj fra assets
      try {
        final tempDir = await Directory.systemTemp.createTemp('cursor_tools');
        final tempPath = path.join(tempDir.path, 'cursor_chat_tool');
        
        // Forsøg at ekstrahere CLI-værktøjet fra assets
        bool foundInAssets = false;
        try {
          // Check for OS specifikke versioner
          String assetPath;
          if (Platform.isMacOS) {
            assetPath = 'assets/bin/cli_chat_tool_macos';
          } else if (Platform.isLinux) {
            assetPath = 'assets/bin/cli_chat_tool_linux';
          } else {
            assetPath = 'assets/bin/cli_chat_tool';
          }
          
          final byteData = await assetBundle.load(assetPath);
          
          // Skriv bytedataen til midlertidig fil
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes, byteData.lengthInBytes);
          await File(tempPath).writeAsBytes(bytes);
          
          // Gør filen eksekverbar
          await Process.run('chmod', ['+x', tempPath]);
          
          cliPath = tempPath;
          foundInAssets = true;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CLI-værktøj fundet i app-pakken'))
          );
        } catch (e) {
          print('Kunne ikke læse CLI-værktøj fra assets: $e');
        }
        
        if (!foundInAssets) {
          // Hvis vi ikke fandt i assets, tjek standard placeringer
          final possiblePaths = [
            path.join(appDir, 'cursor_chat_tool'),
            path.join(appDir, 'Resources', 'cursor_chat_tool'),
            path.join(appDir, 'Resources', 'flutter_assets', 'assets', 'bin', 'cursor_chat_tool'),
          ];
          
          for (final possiblePath in possiblePaths) {
            if (await File(possiblePath).exists()) {
              cliPath = possiblePath;
              break;
            }
          }
        }
        
        if (cliPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunne ikke finde CLI-værktøj i app-pakken'))
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved læsning af CLI-værktøj fra assets: $e'))
        );
        return;
      }
    } else if (result == 'compile') {
      // Vis dialog med besked om at dette ikke er implementeret endnu
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ikke implementeret'),
            content: const Text('Denne funktion er ikke implementeret endnu. Vælg venligst en anden installationsmetode.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    if (cliPath == null) return;
    
    // Vis dialog med fremgang
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Installerer CLI-værktøj...'),
        content: LinearProgressIndicator(),
      ),
    );
    
    try {
      // Opret målmappe hvis den ikke findes
      final targetDirObj = Directory(targetDir);
      if (!await targetDirObj.exists()) {
        await targetDirObj.create(recursive: true);
      }
      
      // Definer målfilsti
      final targetPath = path.join(targetDir, 'cli_chat_tool');
      
      // Kopier filen
      await File(cliPath).copy(targetPath);
      
      // Gør filen eksekverbar (på Unix)
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', targetPath]);
      }
      
      // Opdater indstillinger
      await settings.updateCliPath(targetPath);
      
      // Luk fremgangsdialogen
      Navigator.of(context).pop();
      
      // Vis bekræftelsesbesked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CLI-værktøj installeret til $targetPath'))
      );
    } catch (e) {
      // Luk fremgangsdialogen
      Navigator.of(context).pop();
      
      // Vis fejlbesked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl ved installation: $e'))
      );
    }
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
