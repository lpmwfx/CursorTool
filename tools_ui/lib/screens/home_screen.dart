import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
        title: const Text('Cursor Værktøjer'),
        actions: [
          IconButton(
            icon: Icon(settingsService.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => settingsService.toggleDarkMode(),
            tooltip: 'Skift tema',
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                // Start TUI browseren
                await chatService.showTuiBrowser();
                // Genindlæs chats
                await chatService.loadChats();
              },
              tooltip: 'Åbn TUI Browser',
              child: const Icon(Icons.terminal),
            )
          : null,
    );
  }
}
