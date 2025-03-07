import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/vector_database_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  String _errorMessage = '';
  bool _showImportBanner = false;

  @override
  void initState() {
    super.initState();
    _checkVectorDb();
  }

  Future<void> _checkVectorDb() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // Tjek om der er nogle søgeresultater i forvejen
    if (chatService.searchResults.isNotEmpty) {
      setState(() {
        _results = chatService.searchResults;
      });
    } else {
      // Vis banner om import hvis vector DB ikke er importeret endnu
      setState(() {
        _showImportBanner = true;
      });
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      return;
    }
    
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final results = await chatService.semanticSearch(query);
      
      setState(() {
        _results = results;
        _isSearching = false;
        _showImportBanner = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fejl ved søgning: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _importToVectorDb() async {
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final importCount = await chatService.importToVectorDb();
      
      setState(() {
        _isSearching = false;
        if (importCount > 0) {
          _showImportBanner = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Importerede $importCount chats til vector databasen. Du kan nu søge i dem.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _errorMessage = 'Ingen chats at importere, eller fejl under import';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fejl ved import: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Søg i Chats'),
      ),
      body: Column(
        children: [
          if (_showImportBanner)
            Material(
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import påkrævet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Du skal importere dine chats til vector databasen for at kunne søge i dem. Dette gøres kun én gang.',
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _importToVectorDb,
                      child: const Text('Importér'),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Søg i dine chats...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Søg'),
                ),
              ],
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text('Ingen resultater. Prøv at søge efter noget.'),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _buildSearchResultItem(result);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.chatTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(result.score * 100).toStringAsFixed(0)}% match',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              '${result.isUser ? 'Dig' : 'AI'}: ${_formatTimestamp(result.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              result.content ?? '',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('Vis Chat'),
                  onPressed: () {
                    _openChatDetails(result.chatId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChatDetails(String chatId) {
    // Naviger til chat detaljer
    Navigator.pushNamed(
      context, 
      '/chats',
      arguments: {'chatId': chatId},
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 