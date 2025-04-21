import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsMenu extends StatefulWidget {
  final int searchesLeft;
  final int rightSwipes;
  final int leftSwipes;
  final int apiSearches;
  final String currentLocation;
  final Function(String) onLocationChanged;

  const StatsMenu({
    super.key,
    required this.searchesLeft,
    required this.rightSwipes,
    required this.leftSwipes,
    required this.apiSearches,
    required this.currentLocation,
    required this.onLocationChanged,
  });

  @override
  State<StatsMenu> createState() => _StatsMenuState();
}

class _StatsMenuState extends State<StatsMenu> {
  late String _selectedCountry;
  final _apiKeyController = TextEditingController();
  final _searchLimitController = TextEditingController();
  final _urlController = TextEditingController();

  String? _storedApiKey;
  int? _storedSearchLimit;
  String? _storedUrl;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.currentLocation;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedApiKey = prefs.getString('apiKey');
      _apiKeyController.text = _storedApiKey ?? '';
      _storedSearchLimit = prefs.getInt('searchLimit');
      _searchLimitController.text =
          _storedSearchLimit?.toString() ?? '5'; // Default to 5
      _storedUrl = prefs.getString('apiUrl');
      _urlController.text = _storedUrl ?? ''; // Default URL
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', key);
    setState(() {
      _storedApiKey = key;
    });
  }

  Future<void> _saveSearchLimit(String limit) async {
    final prefs = await SharedPreferences.getInstance();
    final parsedLimit = int.tryParse(limit);
    if (parsedLimit != null && parsedLimit > 0) {
      await prefs.setInt('searchLimit', parsedLimit);
      // You might want to trigger an update in HomeScreen here if the limit changed
    }
  }

  Future<void> _saveApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiUrl', url);
    setState(() {
      _storedUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('API Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Enter API URL',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _saveApiUrl(value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Enter your API Key',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _saveApiKey(value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchLimitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Search Limit',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _saveSearchLimit(value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Search Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Searches Left Today: ${widget.searchesLeft} / ${_storedSearchLimit ?? 5} (customizable)',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Location Filter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
            items:
                <String>['Canada', 'USA', 'UK', 'Australia'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _selectedCountry) {
                setState(() {
                  _selectedCountry = newValue;
                });
                widget.onLocationChanged(newValue);
              }
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Swipe Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Applied Jobs: '),
              for (int i = 0; i < widget.rightSwipes; i++)
                const Icon(Icons.favorite, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Dismissed Jobs: '),
              for (int i = 0; i < widget.leftSwipes; i++)
                const Icon(Icons.close, color: Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'API Searches (customizable limit):',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              _storedSearchLimit ?? 5,
              (index) => Icon(
                index < widget.apiSearches
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Swipe Ratio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 5,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: widget.rightSwipes.toDouble(),
                    color: Colors.green,
                    title:
                        widget.rightSwipes > 0 ? '${widget.rightSwipes}' : '',
                    radius: 40,
                  ),
                  PieChartSectionData(
                    value: widget.leftSwipes.toDouble(),
                    color: Colors.red,
                    title: widget.leftSwipes > 0 ? '${widget.leftSwipes}' : '',
                    radius: 40,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
