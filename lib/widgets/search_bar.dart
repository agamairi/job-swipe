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

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const CustomSearchBar({super.key, required this.onSearch});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the text field with the current search query from the provider
    _searchController.text =
        Provider.of<SearchProvider>(context, listen: false).searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => searchProvider.updateSearch(value),
            onSubmitted: (value) {
              widget.onSearch(value); // Call the onSearch callback
            },
            decoration: InputDecoration(
              hintText: 'Search jobs...',
              filled: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  searchProvider.searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchProvider.clearSearch();
                          _searchController.clear();
                          widget.onSearch(
                            '',
                          ); // Optionally trigger a refresh with an empty query
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
