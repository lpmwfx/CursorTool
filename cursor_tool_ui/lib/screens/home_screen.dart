import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const SearchScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Indlæs chats, når appen starter
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatService = context.read<ChatService>();
      
      // Forsøg først at indlæse eksisterende chats
      await chatService.loadChats();
      
      // Hvis ingen chats blev fundet, forsøg automatisk import
      if (chatService.chats.isEmpty) {
        _showAutoImportDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final settingsService = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cursor Chat',
          style: TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Genindlæs knap
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              // Vis indlæsningsindikator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Genindlæser chats...'),
                  duration: Duration(seconds: 1),
                ),
              );
              // Genindlæs chats
              context.read<ChatService>().loadChats();
            },
            tooltip: 'Genindlæs chats',
            constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
            padding: EdgeInsets.zero,
          ),
          // Mørkt tema knap
          IconButton(
            icon: Icon(
              settingsService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onPressed: () => settingsService.toggleDarkMode(),
            constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Søg',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Indstillinger',
          ),
        ],
      ),
    );
  }

  // Vis dialog med mulighed for auto-import
  void _showAutoImportDialog() {
    // Giv lidt tid til at UI'en er klar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ingen chats fundet'),
          content: const Text(
            'Vil du forsøge at importere chats direkte fra Cursor?\n\n'
            'Dette kræver at appen har adgang til Cursors mappe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nej tak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startAutoImport();
              },
              child: const Text('Ja, importér'),
            ),
          ],
        ),
      );
    });
  }
  
  // Start auto-import
  Future<void> _startAutoImport() async {
    final chatService = context.read<ChatService>();
    
    // Vis loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Importerer chats fra Cursor...'),
          ],
        ),
      ),
    );
    
    try {
      // Forsøg at importere
      final importCount = await chatService.autoImportFromCursor();
      
      // Luk dialog
      if (mounted) Navigator.pop(context);
      
      // Vis resultat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              importCount > 0
                  ? 'Importerede $importCount chats fra Cursor'
                  : 'Kunne ikke importere chats: ${chatService.lastError}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Luk dialog ved fejl
      if (mounted) Navigator.pop(context);
      
      // Vis fejl
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
