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
  final ScrollController scrollController;

  const StatsMenu({
    super.key,
    required this.searchesLeft,
    required this.rightSwipes,
    required this.leftSwipes,
    required this.apiSearches,
    required this.currentLocation,
    required this.onLocationChanged,
    required this.scrollController,
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
      _searchLimitController.text = _storedSearchLimit?.toString() ?? '5';
      _storedUrl = prefs.getString('apiUrl');
      _urlController.text = _storedUrl ?? '';
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              _buildCard(
                title: 'API Settings',
                children: [
                  _buildInputField('API URL', _urlController, _saveApiUrl),
                  const SizedBox(height: 12),
                  _buildInputField('API Key', _apiKeyController, _saveApiKey),
                  const SizedBox(height: 12),
                  _buildInputField(
                    'Daily Search Limit',
                    _searchLimitController,
                    _saveSearchLimit,
                    isNumber: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildCard(
                title: 'Search Statistics',
                children: [
                  Text(
                    'Searches Left Today: ${widget.searchesLeft} / ${_storedSearchLimit ?? 5}',
                    style: textTheme.bodyMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildCard(
                title: 'Location Filter',
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ['Canada', 'USA', 'UK', 'Australia'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != _selectedCountry) {
                        setState(() => _selectedCountry = newValue);
                        widget.onLocationChanged(newValue);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildCard(
                title: 'Swipe Stats',
                children: [
                  _buildIconRow(
                    'Applied Jobs',
                    widget.rightSwipes,
                    Icons.favorite,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildIconRow(
                    'Dismissed Jobs',
                    widget.leftSwipes,
                    Icons.close,
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildCard(
                title: 'API Searches (Usage)',
                children: [
                  Row(
                    children: List.generate(
                      _storedSearchLimit ?? 5,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          index < widget.apiSearches
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildCard(
                title: 'Swipe Ratio',
                children: [
                  SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 5,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: widget.rightSwipes.toDouble(),
                            color: Colors.green,
                            title:
                                widget.rightSwipes > 0
                                    ? '${widget.rightSwipes}'
                                    : '',
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: widget.leftSwipes.toDouble(),
                            color: Colors.red,
                            title:
                                widget.leftSwipes > 0
                                    ? '${widget.leftSwipes}'
                                    : '',
                            radius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildIconRow(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        ...List.generate(count, (_) => Icon(icon, color: color, size: 20)),
      ],
    );
  }
}
