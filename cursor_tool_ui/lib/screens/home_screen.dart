import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Indlæs chats, når appen starter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().loadChats();
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Indstillinger',
          ),
        ],
      ),
    );
  }
}
