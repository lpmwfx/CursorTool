import 'package:isar/isar.dart';
import 'package:ml_linalg/linalg.dart';

part 'chat_database.g.dart';

/// Representerer en chat i databasen
@collection
class DbChat {
  Id id = Isar.autoIncrement;

  /// Cursor's oprindelige chat ID
  @Index(unique: true)
  late String cursorId;

  /// Titlen på chatten
  late String title;

  /// Tidspunkt for sidste besked
  late DateTime lastMessageTime;

  /// Henvisning til alle beskeder i denne chat
  @Backlink(to: 'chat')
  final messages = IsarLinks<DbMessage>();

  /// Gemte embeddings til søgninger
  @ignore
  Vector? titleEmbedding;

  /// Liste af tags til chatten
  final tags = IsarLinks<DbTag>();

  /// Om chatten er markeret som favorit
  bool isFavorite = false;

  /// Feltforespørgsler der kan hjælpe med at finde lignende chats
  List<String>? contextQueries;
}

/// Representerer en enkelt besked i en chat
@collection
class DbMessage {
  Id id = Isar.autoIncrement;

  /// Indholdet af beskeden
  late String content;

  /// Om beskeden er fra brugeren (true) eller assistenten (false)
  late bool isUser;

  /// Tidspunkt for beskeden
  late DateTime timestamp;

  /// Beskedens embedding vektor til søgning
  @ignore
  Vector? embedding;

  /// Relationen til den chat, beskeden tilhører
  final chat = IsarLink<DbChat>();

  /// Eventuelt et kort resumé af beskeden genereret ved import
  String? summary;
}

/// Tag model til kategorisering af chats
@collection
class DbTag {
  Id id = Isar.autoIncrement;

  /// Navn på tagget
  @Index(unique: true)
  late String name;

  /// Farve på tagget (gemt som int)
  late int color;

  /// Chats med dette tag
  final chats = IsarLinks<DbChat>();
}

/// Søgeindeks for vektorsøgning
@collection
class SearchIndex {
  Id id = Isar.autoIncrement;

  /// ID til relateret besked eller chat
  late int refId;

  /// Angiver om dette er en chat eller besked
  late bool isChat;

  /// Vektor data gemt som bytes
  late List<double> vector;

  /// Metadata for at hjælpe med søgning uden at skulle hente hele objektet
  late String text;
} 