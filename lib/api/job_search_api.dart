import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:job_swipe/models/job_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Holds a page of job results plus the token needed to fetch the next page.
class JobSearchResult {
  final List<Job> jobs;
  final String? nextPageUrl;

  JobSearchResult({required this.jobs, this.nextPageUrl});
}

class JobSearchAPI {
  /// Fetches the first page of jobs. Returns results + next_page_token.
  /// Costs 1 API credit.
  static Future<JobSearchResult> fetchRecentJobs(
    String query,
    String locationFilter,
    String dateFilter,
    String apiKeyFromUi,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String apiUrl = prefs.getString('API_URL') ??
        dotenv.env['SERP_API_URL'] ??
        'https://serpapi.com/search.json';
    if (apiUrl.isEmpty) apiUrl = 'https://serpapi.com/search.json';

    String apiKey = prefs.getString('API_KEY') ?? '';
    if (apiKey.isEmpty) {
      apiKey = dotenv.env['SERP_API_KEY'] ?? '';
    }
    if (apiKey.isEmpty) {
      throw Exception(
          'API Key is missing. Please set it in Sources page or .env file.');
    }

    final parameters = <String, String>{
      'q': query,
      'location': locationFilter,
      'api_key': apiKey,
    };

    if (apiUrl.contains('serpapi.com')) {
      parameters['engine'] = 'google_jobs';
    }

    // SerpApi uses `chips` param for date_posted filtering
    if (dateFilter.isNotEmpty) {
      parameters['chips'] = 'date_posted:$dateFilter';
    }

    final uri = Uri.parse(apiUrl).replace(queryParameters: parameters);
    print('Fetching jobs: $uri');

    return _executeRequest(uri);
  }

  /// Fetches the next page of jobs using the URL from a previous response.
  /// Costs 1 API credit — only call this when the user actually needs more jobs.
  static Future<JobSearchResult> fetchNextPage(String nextPageUrl) async {
    // The next_page_url already contains all required parameters including q and start
    final uri = Uri.parse(nextPageUrl);
    print('Fetching next page URL: $uri');

    return _executeRequest(uri);
  }

  /// Shared request execution logic.
  static Future<JobSearchResult> _executeRequest(Uri uri) async {
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final jobs = _parseJobList(json);

        // Extract next_page_url from serpapi_pagination
        String? nextUrl;
        if (json.containsKey('serpapi_pagination') &&
            json['serpapi_pagination'] is Map) {
          nextUrl =
              json['serpapi_pagination']['next'] as String?;
        }

        print('Fetched ${jobs.length} jobs. Has next page: ${nextUrl != null}');
        return JobSearchResult(jobs: jobs, nextPageUrl: nextUrl);
      } else if (response.statusCode == 429) {
        throw Exception(
            'Rate Limit Exceeded (429). Please check your API usage or upgrade your plan.');
      } else {
        throw Exception(
            'Failed to fetch jobs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      rethrow;
    }
  }

  static Future<Job?> fetchJobDetails(String jobId, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    String apiUrl = prefs.getString('API_URL') ??
        dotenv.env['SERP_API_URL'] ??
        'https://serpapi.com/search.json';

    if (apiKey.isEmpty) {
      apiKey = dotenv.env['SERP_API_KEY'] ?? '';
    }

    final parameters = <String, String>{
      'q': jobId,
      'api_key': apiKey,
      'engine': 'google_jobs_listing',
    };

    final uri = Uri.parse(apiUrl).replace(queryParameters: parameters);
    print('Fetching job details for ID: $jobId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return _parseJobDetails(jsonDecode(response.body));
      } else if (response.statusCode == 429) {
        throw Exception(
            'Rate Limit Exceeded (429). Please check your API usage.');
      } else {
        throw Exception(
            'Failed to fetch job details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching job details: $e');
      rethrow;
    }
  }

  // ─── Salary regex patterns for smart extraction from description ───
  static final List<RegExp> _salaryPatterns = [
    // "$80,000 - $120,000" or "$80K - $120K"
    RegExp(
        r'\$[\d,]+(?:\.\d{2})?\s*[kK]?\s*[-–—to]+\s*\$[\d,]+(?:\.\d{2})?\s*[kK]?(?:\s*(?:per|a|/)\s*(?:year|yr|annum|hour|hr|month|mo))?',
        caseSensitive: false),
    // "CAD 80,000 - 120,000" or "USD 80k-120k"
    RegExp(
        r'(?:CAD|USD|GBP|AUD|EUR)\s*\$?[\d,]+(?:\.\d{2})?\s*[kK]?\s*[-–—to]+\s*\$?[\d,]+(?:\.\d{2})?\s*[kK]?',
        caseSensitive: false),
    // "$25/hour" or "$25 per hour"
    RegExp(
        r'\$[\d,]+(?:\.\d{2})?\s*(?:per|a|/)\s*(?:hour|hr|year|yr|annum|month|mo|week|wk)',
        caseSensitive: false),
    // "80,000 - 120,000 per year" (no $ sign, but with unit)
    RegExp(
        r'[\d,]+(?:\.\d{2})?\s*[-–—to]+\s*[\d,]+(?:\.\d{2})?\s*(?:per|a|/)\s*(?:year|yr|annum|hour|hr|month|mo)',
        caseSensitive: false),
    // Simple standalone: "$80,000" when near keywords like "salary", "compensation"
    RegExp(
        r'(?:salary|compensation|pay|wage|earning)[:\s]*\$[\d,]+(?:\.\d{2})?\s*[kK]?',
        caseSensitive: false),
  ];

  /// Try to extract a salary from the job description using regex.
  static String _extractSalaryFromDescription(String description) {
    for (final pattern in _salaryPatterns) {
      final match = pattern.firstMatch(description);
      if (match != null) {
        return match.group(0)!.trim();
      }
    }
    return '';
  }

  static List<Job> _parseJobList(Map<String, dynamic> jsonResponse) {
    final jobList = <Job>[];
    List<dynamic>? jobs;

    if (jsonResponse.containsKey('jobs_results')) {
      jobs = jsonResponse['jobs_results'] as List<dynamic>?;
    } else if (jsonResponse.containsKey('results')) {
      jobs = jsonResponse['results'] as List<dynamic>?;
    } else if (jsonResponse.containsKey('items')) {
      jobs = jsonResponse['items'] as List<dynamic>?;
    } else if (jsonResponse.containsKey('data')) {
      var data = jsonResponse['data'];
      if (data is Map && data.containsKey('jobs')) {
        jobs = data['jobs'] as List<dynamic>?;
      }
    }

    if (jobs != null) {
      for (var job in jobs) {
        final title = _extractString(job, ['title', 'job_title', 'name']);
        final company =
            _extractString(job, ['company_name', 'company', 'employer']);
        final logoUrl = _extractString(
                job, ['thumbnail', 'logo', 'company_logo', 'image']) ??
            '';
        final description = _extractString(
                job, ['description', 'snippet', 'summary']) ??
            'No description available.';
        final location =
            _extractString(job, ['location', 'address', 'city']) ??
                'Unknown location';

        String salary =
            _extractString(job, ['salary', 'base_salary', 'pay']) ?? '';
        String datePosted =
            _extractString(job, ['date_posted', 'posted_at']) ??
                'Not Available';

        if (job.containsKey('detected_extensions') &&
            job['detected_extensions'] is Map) {
          final ext = job['detected_extensions'] as Map;
          if (salary.isEmpty && ext.containsKey('salary')) {
            salary = ext['salary']?.toString() ?? '';
          }
          if (datePosted == 'Not Available' && ext.containsKey('posted_at')) {
            datePosted = ext['posted_at']?.toString() ?? 'Not Available';
          }
        }

        // Smart salary parsing: if no salary in structured data, try regex on description
        if (salary.isEmpty) {
          salary = _extractSalaryFromDescription(description);
        }
        if (salary.isEmpty) salary = 'Not specified';

        String applyLink =
            _extractString(job, ['url', 'link', 'job_url', 'apply_url']) ?? '';

        if (applyLink.isEmpty && job.containsKey('apply_options') && job['apply_options'] is List && (job['apply_options'] as List).isNotEmpty) {
          final applyOptions = job['apply_options'] as List;
          if (applyOptions[0] is Map) {
             applyLink = _extractString(applyOptions[0], ['link', 'url']) ?? '';
          }
        }
        
        if (applyLink.isEmpty && job.containsKey('related_links') && job['related_links'] is List && (job['related_links'] as List).isNotEmpty) {
           final relatedLinks = job['related_links'] as List;
           if (relatedLinks[0] is Map) {
             applyLink = _extractString(relatedLinks[0], ['link', 'url']) ?? '';
           }
        }

        if (applyLink.isEmpty && job.containsKey('share_link')) {
           applyLink = job['share_link']?.toString() ?? '';
        }

        String source =
            _extractString(job, ['via', 'source', 'job_board']) ??
                'Aggregator';
        if (source.toLowerCase().startsWith('via ')) {
          source = source.substring(4);
        }

        if (title != null && company != null) {
          jobList.add(
            Job(
              title: title,
              company: company,
              logoUrl: logoUrl,
              description: description,
              location: location,
              salary: salary,
              datePosted: datePosted,
              source: source,
              applyLink: applyLink,
            ),
          );
        }
      }
    }
    print('Jobs parsed this page: ${jobList.length}');
    return jobList;
  }

  static Job? _parseJobDetails(Map<String, dynamic> jsonResponse) {
    Map<String, dynamic>? jobData = jsonResponse['job_result_state'] ??
        jsonResponse['details'] ??
        jsonResponse;

    if (jobData != null) {
      final title = _extractString(jobData, ['title', 'job_title', 'name']);
      final company =
          _extractString(jobData, ['company', 'company_name', 'employer']);
      final logoUrl =
          _extractString(jobData, ['logo', 'company_logo', 'image']) ?? '';
      final description = _extractString(
              jobData, ['description', 'full_description', 'details']) ??
          'No description available.';
      final location =
          _extractString(jobData, ['location', 'address', 'city']) ??
              'Unknown location';
      final salary =
          _extractString(jobData, ['salary', 'base_salary', 'pay']) ??
              'Not specified';
      final datePosted =
          _extractString(jobData, ['date_posted', 'posted_at']) ??
              'Not Available';
      final applyLink =
          _extractString(jobData, ['url', 'link', 'job_url', 'apply_url']) ??
              '';
      final source = 'Custom Source';

      if (title != null && company != null) {
        return Job(
          title: title,
          company: company,
          logoUrl: logoUrl,
          description: description,
          location: location,
          salary: salary,
          datePosted: datePosted,
          source: source,
          applyLink: applyLink,
        );
      }
    }
    return null;
  }

  static String? _extractString(
      Map<dynamic, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      if (map.containsKey(key) && map[key] is String) {
        return map[key] as String;
      }
    }
    return null;
  }
}
