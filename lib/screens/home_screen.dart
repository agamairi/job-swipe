import 'package:flutter/material.dart';
import 'package:job_swipe/api/job_search_api.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/widgets/footer_navigation_bar.dart';
import 'package:job_swipe/widgets/job_swipe.dart';
import 'package:job_swipe/widgets/search_bar.dart';
import 'package:job_swipe/widgets/filters_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_swipe/database/database_helper.dart';

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
  List<String> _providerFilters = [];
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
      final db = DatabaseHelper();
      final providerFilterStr = _providerFilters.join(',');
      final history = await db.getRecentSearchHistory(_lastSearchQuery, _locationFilter, _dateFilter, providerFilterStr);
      if (history != null) {
        final cached = await db.getCachedJobs(_lastSearchQuery, _locationFilter, _dateFilter, providerFilterStr);
        if (cached.isNotEmpty) {
          setState(() {
            _jobs = cached;
            _nextPageUrl = history['nextPageUrl'] as String?;
            _isLoading = false;
          });
          return;
        } else if (history['nextPageUrl'] != null && history['nextPageUrl'].toString().isNotEmpty) {
          _nextPageUrl = history['nextPageUrl'] as String?;
          _loadMoreJobs();
          return;
        }
      }
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
  Future<void> _searchJobs(String query, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSearchQuery', query);
    _lastSearchQuery = query;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _jobs = [];
      _nextPageUrl = null;
    });

    final db = DatabaseHelper();
    final providerFilterStr = _providerFilters.join(',');
    if (!forceRefresh) {
      final history = await db.getRecentSearchHistory(query, _locationFilter, _dateFilter, providerFilterStr);
      if (history != null) {
        final cached = await db.getCachedJobs(query, _locationFilter, _dateFilter, providerFilterStr);
        if (cached.isNotEmpty) {
          if (mounted) {
            setState(() {
              _jobs = cached;
              _nextPageUrl = history['nextPageUrl'] as String?;
              _isLoading = false;
            });
          }
          return;
        }
      }
    }

    try {
      final result = await JobSearchAPI.fetchRecentJobs(
        query,
        _locationFilter,
        _dateFilter,
        _apiKey ?? '',
        providerFilters: _providerFilters,
      );
      
      await db.clearCachedJobs(
        query: query,
        locationFilter: _locationFilter,
        dateFilter: _dateFilter,
        providerFilter: providerFilterStr,
      );
      await db.insertCachedJobs(result.jobs, query, _locationFilter, _dateFilter, providerFilterStr);
      await db.saveSearchHistory(query, _locationFilter, _dateFilter, result.nextPageUrl, providerFilterStr);
      
      final savedJobs = await db.getCachedJobs(query, _locationFilter, _dateFilter, providerFilterStr); // Load back from DB to ensure status is handled

      if (mounted) {
        setState(() {
          _jobs = savedJobs.isNotEmpty ? savedJobs : result.jobs;
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
      final result = await JobSearchAPI.fetchNextPage(
        _nextPageUrl!,
        dateFilter: _dateFilter,
        providerFilters: _providerFilters,
      );
      final db = DatabaseHelper();
      final providerFilterStr = _providerFilters.join(',');
      await db.insertCachedJobs(result.jobs, _lastSearchQuery, _locationFilter, _dateFilter, providerFilterStr);
      await db.saveSearchHistory(_lastSearchQuery, _locationFilter, _dateFilter, result.nextPageUrl, providerFilterStr);
      
      final allCached = await db.getCachedJobs(_lastSearchQuery, _locationFilter, _dateFilter, providerFilterStr);

      if (mounted) {
        setState(() {
          _jobs = allCached; // Replace with all cached so we don't duplicate
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
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FiltersMenu(
              scrollController: scrollController,
              currentLocation: _locationFilter,
              currentDateFilter: _dateFilter,
              currentProviderFilters: _providerFilters,
              onFiltersApplied: (newLocation, newDateFilter, newProviderFilters) {
                setState(() {
                  _locationFilter = newLocation;
                  _dateFilter = newDateFilter;
                  _providerFilters = newProviderFilters;
                });
                if (_lastSearchQuery.isNotEmpty) {
                  _searchJobs(_lastSearchQuery, forceRefresh: true);
                }
              },
            );
          },
        );
      },
    );
  }

  void _handleSwipe(Job job, bool isRightSwipe) async {
    final db = DatabaseHelper();
    if (isRightSwipe) {
      _rightSwipes++;
      await db.updateJobStatus(job.id, 'applied');
      _openJobWebView(job);
    } else {
      _leftSwipes++;
      await db.updateJobStatus(job.id, 'discarded');
    }
    _savePersistentStats();
  }

  void _handleSave(Job job) async {
    final db = DatabaseHelper();
    await db.updateJobStatus(job.id, 'saved');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job saved!')),
    );
  }

  void _openJobWebView(Job job) async {
    if (job.applyLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application link available for this job')),
      );
      return;
    }
    
    final uri = Uri.parse(job.applyLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch the application link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Swipe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Search',
            onPressed: () {
              if (_lastSearchQuery.isNotEmpty) {
                _searchJobs(_lastSearchQuery, forceRefresh: true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a search query first')),
                );
              }
            },
          ),
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
                                  onSave: _handleSave,
                                  onRefresh: () async {
                                    final db = DatabaseHelper();
                                    await db.clearCachedJobs(
                                      query: _lastSearchQuery,
                                      locationFilter: _locationFilter,
                                      dateFilter: _dateFilter,
                                      providerFilter: _providerFilters.join(','),
                                    );
                                    _searchJobs(_lastSearchQuery, forceRefresh: true);
                                  },
                                  onLoadMore: _nextPageUrl != null ? _loadMoreJobs : null,
                                  isLoadingMore: _isLoadingMore,
                                ),
            ),
          ],
        ),
    );
  }
}
