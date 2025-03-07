import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
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
            trailing: const Icon(Icons.folder),
            onTap: () => _selectWorkspacePath(context),
          ),
          _buildSettingItem(
            context: context,
            title: 'Output mappe',
            description: settings.outputPath,
            trailing: const Icon(Icons.folder),
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
}
