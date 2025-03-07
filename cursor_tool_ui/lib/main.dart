import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/chat_service.dart';
import 'services/settings_service.dart';
import 'services/database_service.dart';
import 'services/vector_database_service.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/search_screen.dart';
import 'themes.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser tjenester
  final settingsService = SettingsService();
  await settingsService.init();

  final databaseService = DatabaseService();
  await databaseService.init();
  
  // Opret vector database-tjenesten
  final vectorDatabaseService = VectorDatabaseService();
  
  // Opret chatService med både database og vector database
  final chatService = ChatService(settingsService, databaseService, vectorDatabaseService);
  
  // Indlæs chats efter app er startet
  Future.delayed(Duration(milliseconds: 500), () {
    chatService.loadChats();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsService),
        ChangeNotifierProvider(create: (_) => databaseService),
        ChangeNotifierProvider(create: (_) => chatService),
        Provider<VectorDatabaseService>.value(value: vectorDatabaseService),
      ],
      child: const CursorToolsApp(),
    ),
  );
}

class CursorToolsApp extends StatelessWidget {
  const CursorToolsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<SettingsService>().isDarkMode;
    
    // Vis dialog til OpenAI API nøgle hvis vector søgning aktiveres
    _checkApiKey(context);
    
    return MaterialApp(
      title: 'Cursor Chat',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/chats': (context) => const ChatListScreen(),
        '/search': (context) => const SearchScreen(),
      },
      onGenerateRoute: (settings) {
        return null;
      },
    );
  }
  
  // Tjek om OpenAI API nøgle er nødvendig og vis dialog
  void _checkApiKey(BuildContext context) {
    // Kør efter bygning af UI er færdig
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vectorDb = Provider.of<VectorDatabaseService>(context, listen: false);
      
      // Tjek efter miljøvariabel først
      final envKey = const String.fromEnvironment('OPENAI_API_KEY');
      if (envKey.isNotEmpty) {
        try {
          await vectorDb.initialize(apiKey: envKey);
          return;
        } catch (e) {
          print('Fejl ved brug af miljøvariabel API nøgle: $e');
        }
      }
      
      // Vis dialog til indtastning af API nøgle
      if (context.mounted) {
        final apiKey = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ApiKeyDialog(),
        );
        
        if (apiKey != null && apiKey.isNotEmpty) {
          try {
            await vectorDb.initialize(apiKey: apiKey);
          } catch (e) {
            print('Fejl ved initialisering med API nøgle: $e');
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fejl ved initialisering af vector database: $e'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }
    });
  }
}

// Dialog til indtastning af OpenAI API nøgle
class _ApiKeyDialog extends StatefulWidget {
  @override
  _ApiKeyDialogState createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('OpenAI API Nøgle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'For at bruge semantisk søgning i dine chats skal du angive en OpenAI API nøgle. '
            'Denne bruges til at generere embeddings for søgning.',
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'API Nøgle',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            obscureText: _obscureText,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data != null && data.text != null) {
                    setState(() {
                      _controller.text = data.text!.trim();
                    });
                  }
                },
                child: Text('Indsæt fra udklipsholder'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, '');
          },
          child: Text('Spring over'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _controller.text.trim());
          },
          child: Text('Gem'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
