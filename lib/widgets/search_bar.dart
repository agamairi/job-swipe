import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchProvider extends ChangeNotifier {
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) => searchProvider.updateSearch(value),
            decoration: InputDecoration(
              hintText: 'Search jobs...',
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon:
                  searchProvider.searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          searchProvider.clearSearch();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        );
      },
    );
  }
}
