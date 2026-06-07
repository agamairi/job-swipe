import 'package:flutter/material.dart';
import 'package:job_swipe/api/job_search_api.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/widgets/footer_navigation_bar.dart';
import 'package:job_swipe/widgets/job_swipe.dart';
import 'package:job_swipe/widgets/search_bar.dart';
import 'package:job_swipe/widgets/filters_menu.dart';
import 'package:job_swipe/screens/job_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Job> _jobs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  // Pagination
  String? _nextPageUrl;

  // Stats
  int _rightSwipes = 0;
  int _leftSwipes = 0;
  static const String _rightSwipesKey = 'rightSwipes';
  static const String _leftSwipesKey = 'leftSwipes';

  // Filters & state
  String _locationFilter = 'Canada';
  String _dateFilter = '';
  String _lastSearchQuery = '';
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadPersistentStats();
    _loadApiKey();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSearchQuery = prefs.getString('lastSearchQuery') ?? '';

    if (_lastSearchQuery.isNotEmpty) {
      _searchJobs(_lastSearchQuery);
    } else {
      setState(() => _isLoading = false);
    }
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
      _rightSwipes = prefs.getInt(_rightSwipesKey) ?? 0;
      _leftSwipes = prefs.getInt(_leftSwipesKey) ?? 0;
    });
  }

  Future<void> _savePersistentStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rightSwipesKey, _rightSwipes);
    await prefs.setInt(_leftSwipesKey, _leftSwipes);
  }

  /// Fetches page 1 of jobs (1 API credit). No daily hard limit.
  Future<void> _searchJobs(String query) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSearchQuery', query);
    _lastSearchQuery = query;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _jobs = [];
      _nextPageUrl = null;
    });

    try {
      final result = await JobSearchAPI.fetchRecentJobs(
        query,
        _locationFilter,
        _dateFilter,
        _apiKey ?? '',
      );
      if (mounted) {
        setState(() {
          _jobs = result.jobs;
          _nextPageUrl = result.nextPageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Lazy load: only called when user swipes to the last 2 cards.
  /// Costs 1 additional credit.
  Future<void> _loadMoreJobs() async {
    if (_nextPageUrl == null || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await JobSearchAPI.fetchNextPage(_nextPageUrl!);
      if (mounted) {
        setState(() {
          _jobs.addAll(result.jobs);
          _nextPageUrl = result.nextPageUrl;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _showFiltersMenu() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FiltersMenu(
              scrollController: scrollController,
              currentLocation: _locationFilter,
              currentDateFilter: _dateFilter,
              onFiltersApplied: (newLocation, newDateFilter) {
                setState(() {
                  _locationFilter = newLocation;
                  _dateFilter = newDateFilter;
                });
                if (_lastSearchQuery.isNotEmpty) {
                  _searchJobs(_lastSearchQuery);
                }
              },
            );
          },
        );
      },
    );
  }

  void _handleSwipe(Job job, bool isRightSwipe) {
    if (isRightSwipe) {
      _rightSwipes++;
      _openJobWebView(job);
    } else {
      _leftSwipes++;
    }
    _savePersistentStats();
  }

  void _openJobWebView(Job job) {
    if (job.applyLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application link available for this job')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobWebViewScreen(
          url: job.applyLink,
          title: job.company.isNotEmpty ? job.company : 'Job Application',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Swipe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFiltersMenu,
          ),
        ],
      ),
      bottomNavigationBar: const FooterNavigationBar(currentIndex: 0),
        body: Column(
          children: [
            CustomSearchBar(
              onSearch: _searchJobs,
              initialQuery: _lastSearchQuery,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      : _jobs.isEmpty && _lastSearchQuery.isEmpty
                          ? const Center(
                              child: Text(
                                'Ready to find your dream job?\nEnter a search above!',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _jobs.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                          'No jobs found or API key not set.'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _jobs = sampleJobs;
                                          });
                                        },
                                        child:
                                            const Text('Use Sample Jobs'),
                                      ),
                                    ],
                                  ),
                                )
                              : JobSwipe(
                                  jobs: _jobs,
                                  onSwipe: _handleSwipe,
                                  onTap: (job) {},
                                  onRefresh: () => _searchJobs(_lastSearchQuery),
                                  onLoadMore: _nextPageUrl != null ? _loadMoreJobs : null,
                                  isLoadingMore: _isLoadingMore,
                                ),
            ),
          ],
        ),
    );
  }
}
