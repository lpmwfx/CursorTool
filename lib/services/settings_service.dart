import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class SettingsService extends ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  static const String _cliPathKey = 'cliPath';
  static const String _workspacePathKey = 'workspacePath';
  static const String _outputPathKey = 'outputPath';
  static const String _defaultFormatKey = 'defaultFormat';

  late SharedPreferences _prefs;

  bool _isDarkMode = false;
  String _cliPath = '';
  String _workspacePath = '';
  String _outputPath = '';
  String _defaultFormat = 'markdown';

  bool get isDarkMode => _isDarkMode;
  String get cliPath => _cliPath;
  String get workspacePath => _workspacePath;
  String get outputPath => _outputPath;
  String get defaultFormat => _defaultFormat;

  // Initialiser indstillingstjenesten
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Indlæs gemte indstillinger
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? false;
    _cliPath = _prefs.getString(_cliPathKey) ?? _findDefaultCliPath();
    _workspacePath =
        _prefs.getString(_workspacePathKey) ?? _findDefaultWorkspacePath();
    _outputPath = _prefs.getString(_outputPathKey) ??
        '${Platform.environment['HOME'] ?? ''}/Documents/CursorChats';
    _defaultFormat = _prefs.getString(_defaultFormatKey) ?? 'markdown';
  }

  // Find standardstien til CLI-værktøjet
  String _findDefaultCliPath() {
    final homeDir = Platform.environment['HOME'] ?? '';

    // Liste over mulige stier at tjekke
    final pathsToCheck = [
      path.join(homeDir, '.cursor', 'cursorchat'), // symlink
      path.join(homeDir, '.cursor', 'cursor_chat_tool'), // eksekverbar
      path.join(homeDir, 'Repo på HDD', 'CursorTool',
          'cursor_chat_tool'), // projekt-sti
    ];

    // Tjek hver sti
    for (final pathToCheck in pathsToCheck) {
      try {
        final file = File(pathToCheck);
        if (file.existsSync()) {
          // Tjek om filen er eksekverbar (kun på Linux/Mac)
          if (!Platform.isWindows) {
            try {
              final stat = file.statSync();
              final isExecutable =
                  stat.mode & 0x49 != 0; // Check for executable bit
              if (isExecutable) {
                print('Fandt eksekverbar CLI-fil på: $pathToCheck');
                return pathToCheck;
              }
            } catch (e) {
              print(
                  'Fejl ved tjek af eksekveringsrettigheder for $pathToCheck: $e');
            }
          } else {
            // På Windows kan vi ikke nemt tjekke for eksekveringsrettigheder
            print('Fandt CLI-fil på Windows: $pathToCheck');
            return pathToCheck;
          }
        }
      } catch (e) {
        print('Fejl ved søgning efter CLI-værktøj på $pathToCheck: $e');
      }
    }

    // Alternativt, se om det er i PATH
    print(
        'CLI-værktøj ikke fundet i kendte stier, bruger \'cursorchat\' fra PATH');
    return 'cursorchat';
  }

  // Find standardstien til workspace storage
  String _findDefaultWorkspacePath() {
    final homeDir = Platform.environment['HOME'] ?? '';
    String workspacePath;

    if (Platform.isLinux) {
      workspacePath =
          path.join(homeDir, '.config', 'Cursor', 'User', 'workspaceStorage');
    } else if (Platform.isMacOS) {
      workspacePath = path.join(homeDir, 'Library', 'Application Support',
          'Cursor', 'User', 'workspaceStorage');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      workspacePath = path.join(appData, 'Cursor', 'User', 'workspaceStorage');
    } else {
      // Fallback
      workspacePath =
          path.join(homeDir, '.config', 'Cursor', 'User', 'workspaceStorage');
    }

    return workspacePath;
  }

  // Skift mørkt tema til/fra
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  // Opdater CLI-stien
  Future<void> updateCliPath(String newPath) async {
    _cliPath = newPath;
    await _prefs.setString(_cliPathKey, newPath);
    notifyListeners();
  }

  // Opdater workspace-stien
  Future<void> updateWorkspacePath(String newPath) async {
    _workspacePath = newPath;
    await _prefs.setString(_workspacePathKey, newPath);
    notifyListeners();
  }

  // Opdater output-stien
  Future<void> updateOutputPath(String newPath) async {
    _outputPath = newPath;
    await _prefs.setString(_outputPathKey, newPath);
    notifyListeners();
  }

  // Opdater standardformat
  Future<void> updateDefaultFormat(String format) async {
    _defaultFormat = format;
    await _prefs.setString(_defaultFormatKey, format);
    notifyListeners();
  }
}
