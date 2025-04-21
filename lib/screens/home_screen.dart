import 'package:flutter/material.dart';
import 'package:job_swipe/api/job_search_api.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/widgets/footer_navigation_bar.dart';
import 'package:job_swipe/widgets/job_swipe.dart';
import 'package:job_swipe/widgets/search_bar.dart';
import 'package:job_swipe/widgets/stats_menu.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Job> _jobs = []; // Initialize as empty
  bool _isLoading = false;
  String _errorMessage = '';

  int _searchesToday = 0;
  DateTime? _lastSearchTime;
  static const int _maxSearchesPerDay = 5;
  static const String _searchesTodayKey = 'searchesToday';
  static const String _lastSearchTimeKey = 'lastSearchTime';

  int _rightSwipes = 0;
  int _leftSwipes = 0;
  static const String _rightSwipesKey = 'rightSwipes';
  static const String _leftSwipesKey = 'leftSwipes';

  int _apiSearches = 0;
  static const String _apiSearchesKey = 'apiSearches';

  String _locationFilter = 'Canada'; // Default location filter
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadPersistentStats();
    _loadApiKey(); // Load API key on startup
    _loadInitialJobs(); // Load initial jobs on startup
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('API_KEY');
    });
  }

  Future<void> _loadPersistentStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchesToday = prefs.getInt(_searchesTodayKey) ?? 0;
      final lastSearchMillis = prefs.getInt(_lastSearchTimeKey);
      _lastSearchTime =
          lastSearchMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(lastSearchMillis)
              : null;
      _rightSwipes = prefs.getInt(_rightSwipesKey) ?? 0;
      _leftSwipes = prefs.getInt(_leftSwipesKey) ?? 0;
      _apiSearches = prefs.getInt(_apiSearchesKey) ?? 0;

      // Reset searches if it's a new day
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastSearchDay =
          _lastSearchTime != null
              ? DateTime(
                _lastSearchTime!.year,
                _lastSearchTime!.month,
                _lastSearchTime!.day,
              )
              : null;

      if (lastSearchDay != null && today.isAfter(lastSearchDay)) {
        _searchesToday = 0;
        _lastSearchTime = null;
        _savePersistentStats(); // Save the reset values
      }
    });
  }

  Future<void> _savePersistentStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_searchesTodayKey, _searchesToday);
    if (_lastSearchTime != null) {
      await prefs.setInt(
        _lastSearchTimeKey,
        _lastSearchTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_lastSearchTimeKey);
    }
    await prefs.setInt(_rightSwipesKey, _rightSwipes);
    await prefs.setInt(_leftSwipesKey, _leftSwipes);
    await prefs.setInt(_apiSearchesKey, _apiSearches);
  }

  Future<void> _loadInitialJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final jobs = await JobSearchAPI.fetchRecentJobs(
      'Software Developer',
      _locationFilter,
      _apiKey ?? '', // Pass the API key, default to empty string if null
      '',
    );
    setState(() {
      _jobs = jobs;
      _isLoading = false;
      print('Initial Jobs Loaded: ${_jobs.length}'); // ADD THIS LINE
    });
  }

  Future<void> _searchJobs(String query) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastSearchDay =
        _lastSearchTime != null
            ? DateTime(
              _lastSearchTime!.year,
              _lastSearchTime!.month,
              _lastSearchTime!.day,
            )
            : null;

    if (lastSearchDay != null && today.isAfter(lastSearchDay)) {
      setState(() {
        _searchesToday = 0;
        _lastSearchTime = null;
      });
    }

    if (_searchesToday < _maxSearchesPerDay) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _searchesToday++;
        _lastSearchTime = now;
      });
      _savePersistentStats(); // Save the updated search count and time
      final jobs = await JobSearchAPI.fetchRecentJobs(
        query,
        _locationFilter,
        _apiKey ?? '',
        '',
      );
      setState(() {
        _jobs = jobs; // Update the _jobs list with the new search results
        _isLoading = false;
        print('Search Results Loaded: ${_jobs.length}'); // ADD THIS LINE
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have reached your daily search limit (5 searches).',
          ),
        ),
      );
    }
  }

  void _showStatsMenu() async {
    await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return StatsMenu(
          searchesLeft: _maxSearchesPerDay - _searchesToday,
          rightSwipes: _rightSwipes,
          leftSwipes: _leftSwipes,
          apiSearches: _apiSearches,
          currentLocation: _locationFilter,
          onLocationChanged: (newLocation) {
            setState(() {
              _locationFilter = newLocation;
            });
            _loadInitialJobs(); // Reload jobs with the new filter
          },
        );
      },
    );
  }

  void _handleSwipe(Job job, bool isRightSwipe) {
    if (isRightSwipe) {
      _rightSwipes++;
      _launchApplyLink(job.applyLink);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied for ${job.title} at ${job.company}')),
      );
    } else {
      _leftSwipes++;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dismissed ${job.title}')));
    }
    _savePersistentStats(); // Save the updated swipe counts
  }

  Future<void> _launchApplyLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the apply link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchProvider>(
      create: (_) => SearchProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Swipe'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showStatsMenu,
            ),
          ],
        ),
        bottomNavigationBar: FooterNavigationBar(),
        body: Column(
          children: [
            CustomSearchBar(onSearch: _searchJobs),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : Consumer<SearchProvider>(
                        builder: (context, searchProvider, child) {
                          // Directly use the _jobs list fetched from the API
                          return JobSwipe(
                            jobs: _jobs,
                            onSwipe: _handleSwipe,
                            onTap: (job) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tapped on ${job.title}'),
                                ),
                              );
                            },
                            onRefresh:
                                () => _searchJobs(
                                  searchProvider.searchQuery,
                                ), // Refresh with current query
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
