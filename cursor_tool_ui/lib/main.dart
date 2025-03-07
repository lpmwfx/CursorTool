import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/chat_service.dart';
import 'services/settings_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser tjenester
  final settingsService = SettingsService();
  await settingsService.init();

  final databaseService = DatabaseService();
  await databaseService.init();
  
  final chatService = ChatService(settingsService, databaseService);
  
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
    
    // Nordiske minimalistiske farvetemaer
    return MaterialApp(
      title: 'Cursor Værktøjer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF3A6EA5),         // Mørkeblå
          secondary: Color(0xFFA3C9D9),       // Lyseblå
          tertiary: Color(0xFFE5EFF5),        // Meget lyseblå/grå
          background: Colors.white,
          surface: Color(0xFFF8F9FA),
          onSurface: Color(0xFF21272A),       // Mørk grå
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF3A6EA5),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3A6EA5),
            foregroundColor: Colors.white,
            minimumSize: Size(120, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF3A6EA5),
        ),
        fontFamily: 'SF Pro Display', // Apple-lignende font
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF81A1C1),        // Nordisk blå
          secondary: Color(0xFF5E81AC),      // Mørkere nordisk blå
          tertiary: Color(0xFF434C5E),       // Meget mørk blå/grå
          background: Color(0xFF2E3440),     // Nordisk mørk baggrund
          surface: Color(0xFF3B4252),        // Lidt lysere overflade
          onSurface: Color(0xFFECEFF4),      // Næsten hvid tekst
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2E3440),
          foregroundColor: Color(0xFF81A1C1),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF3B4252),
          elevation: 1,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF81A1C1),
            foregroundColor: Color(0xFF2E3440),
            minimumSize: Size(120, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF81A1C1),
        ),
        fontFamily: 'SF Pro Display', // Apple-lignende font
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
