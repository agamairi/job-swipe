import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:job_swipe/widgets/footer_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isLoading = false;

  int _rightSwipes = 0;
  int _leftSwipes = 0;

  // SerpApi account info
  int? _searchesPerMonth;
  int? _searchesUsed;
  int? _searchesLeft;
  String? _planName;
  bool _isLoadingAccount = false;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('API_KEY') ?? '';
      _apiUrlController.text =
          prefs.getString('API_URL') ?? 'https://serpapi.com/search.json';

      _rightSwipes = prefs.getInt('rightSwipes') ?? 0;
      _leftSwipes = prefs.getInt('leftSwipes') ?? 0;

      _isLoading = false;
    });

    // Auto-fetch account info if API key is available
    if (_apiKeyController.text.isNotEmpty) {
      _fetchAccountInfo(_apiKeyController.text);
    }
  }

  /// Fetches remaining credits from SerpApi account endpoint (free, no credit cost).
  Future<void> _fetchAccountInfo(String apiKey) async {
    if (apiKey.isEmpty) {
      // Try from .env
      apiKey = dotenv.env['SERP_API_KEY'] ?? '';
    }
    if (apiKey.isEmpty) {
      setState(() => _accountError = 'No API key configured.');
      return;
    }

    setState(() {
      _isLoadingAccount = true;
      _accountError = null;
    });

    try {
      final uri = Uri.parse(
          'https://serpapi.com/account.json?api_key=$apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchesPerMonth = data['total_searches_per_month'] as int?;
          _searchesUsed =
              (_searchesPerMonth != null && data['searches_remaining'] != null)
                  ? (_searchesPerMonth! - (data['searches_remaining'] as int))
                  : null;
          _searchesLeft = data['searches_remaining'] as int?;
          _planName = data['plan_name'] as String?;
          _isLoadingAccount = false;
        });
      } else {
        setState(() {
          _accountError = 'Failed to fetch account info (${response.statusCode})';
          _isLoadingAccount = false;
        });
      }
    } catch (e) {
      setState(() {
        _accountError = 'Error: $e';
        _isLoadingAccount = false;
      });
    }
  }

  Future<void> _saveCredentials() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('API_KEY', _apiKeyController.text.trim());
    await prefs.setString('API_URL', _apiUrlController.text.trim());
    setState(() => _isLoading = false);

    // Refresh account info with new key
    _fetchAccountInfo(_apiKeyController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Credentials Saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources & Usage'),
        centerTitle: true,
      ),
      bottomNavigationBar: const FooterNavigationBar(currentIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: 'API Settings',
                    children: [
                      const Text(
                        'Configure your third-party job aggregator API here. We recommend SerpApi for Google Jobs.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _apiUrlController,
                        decoration: const InputDecoration(
                          labelText: 'API Base URL',
                          border: OutlineInputBorder(),
                          helperText:
                              'Default: https://serpapi.com/search.json',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          border: OutlineInputBorder(),
                          helperText:
                              'Your private key (BYOK). Kept locally.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveCredentials,
                          child: const Text('Save Credentials'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // API Usage / Credits card
                  _buildCard(
                    title: 'API Usage',
                    children: [
                      if (_isLoadingAccount)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_accountError != null)
                        Text(
                          _accountError!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        )
                      else if (_searchesLeft != null) ...[
                        if (_planName != null)
                          Chip(
                            label: Text(_planName!),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            side: BorderSide.none,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn(
                              'Remaining',
                              '$_searchesLeft',
                              Colors.green,
                            ),
                            _buildStatColumn(
                              'Used',
                              '${_searchesUsed ?? '-'}',
                              Colors.orange,
                            ),
                            _buildStatColumn(
                              'Total',
                              '${_searchesPerMonth ?? '-'}',
                              Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_searchesPerMonth != null &&
                            _searchesPerMonth! > 0)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (_searchesUsed ?? 0) /
                                  _searchesPerMonth!,
                              minHeight: 12,
                              backgroundColor: Colors.green.withValues(alpha: 0.2),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                (_searchesUsed ?? 0) /
                                            _searchesPerMonth! >
                                        0.8
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                      ] else
                        const Text(
                          'Save your API key above to see usage stats.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              _fetchAccountInfo(_apiKeyController.text),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Swipe Stats',
                    children: [
                      _buildIconRow('Applied Jobs', _rightSwipes,
                          Icons.favorite, Colors.green),
                      const SizedBox(height: 8),
                      _buildIconRow('Dismissed Jobs', _leftSwipes,
                          Icons.close, Colors.red),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 5,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: _rightSwipes.toDouble(),
                                color: Colors.green,
                                title: _rightSwipes > 0
                                    ? '$_rightSwipes'
                                    : '',
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: _leftSwipes.toDouble(),
                                color: Colors.red,
                                title: _leftSwipes > 0
                                    ? '$_leftSwipes'
                                    : '',
                                radius: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow(
      String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text('$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )),
      ],
    );
  }
}
