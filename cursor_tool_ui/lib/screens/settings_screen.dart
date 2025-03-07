import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/settings_service.dart';
import '../services/chat_service.dart';

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
                    ElevatedButton(
                      onPressed: () => _showMacOSGuide(context),
                      child: const Text('Vis vejledning til løsning'),
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
}
