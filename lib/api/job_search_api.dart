import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:job_swipe/models/job_model.dart'; // Assuming your Job model is here
import 'package:shared_preferences/shared_preferences.dart';

class JobSearchAPI {
  static Future<List<Job>> fetchRecentJobs(
    String query,
    String locationFilter,
    String dateFilter, // Can be 'today', '3days', 'week', 'month', or empty
    String apiKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString('apiUrl') ?? ''; // Get stored URL

    final parameters = <String, String>{
      'q': query,
      'location': locationFilter,
      'api_key': apiKey,
    };

    if (dateFilter.isNotEmpty) {
      parameters['date_posted'] = dateFilter;
    }

    final uri = Uri.parse(apiUrl).replace(queryParameters: parameters);

    print('Fetching URL: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('Fetch successful from: $apiUrl');
        return _parseJobList(
          jsonDecode(response.body),
        ); // Use the general parse method
      } else {
        print(
          'Failed to fetch jobs from $apiUrl: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error fetching jobs from $apiUrl: $e');
      return [];
    }
  }

  static Future<Job?> fetchJobDetails(String jobId, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString('apiUrl') ?? ''; // Get stored URL

    final parameters = <String, String>{
      'q': jobId,
      'api_key': apiKey,
      'engine':
          'google_jobs_listing', // Assuming detail view might still be specific
    };

    final uri = Uri.parse(apiUrl).replace(queryParameters: parameters);

    print('Fetching job details for ID: $jobId, URL: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('Fetch job details successful from: $apiUrl');
        return _parseJobDetails(
          jsonDecode(response.body),
        ); // Use the general parse method
      } else {
        print(
          'Failed to fetch job details from $apiUrl: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching job details from $apiUrl: $e');
      return null;
    }
  }

  static List<Job> _parseJobList(Map<String, dynamic> jsonResponse) {
    final jobList = <Job>[];
    // Try to find a common list of job items across different API responses
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
        final company = _extractString(job, [
          'company',
          'company_name',
          'employer',
        ]);
        final logoUrl =
            _extractString(job, ['logo', 'company_logo', 'image']) ?? '';
        final description =
            _extractString(job, ['description', 'snippet', 'summary']) ??
            'No description available.';
        final location =
            _extractString(job, ['location', 'address', 'city']) ??
            'Unknown location';
        final salary =
            _extractString(job, ['salary', 'base_salary', 'pay']) ??
            'Not specified';
        final applyLink =
            _extractString(job, ['url', 'link', 'job_url', 'apply_url']) ?? '';
        final source = 'Custom Source'; // Indicate a custom source

        if (title != null && company != null) {
          jobList.add(
            Job(
              title: title,
              company: company,
              logoUrl: logoUrl,
              description: description,
              location: location,
              salary: salary,
              source: source,
              applyLink: applyLink,
            ),
          );
        }
      }
    }
    print('Total jobs parsed (generalized): ${jobList.length}');
    return jobList;
  }

  static Job? _parseJobDetails(Map<String, dynamic> jsonResponse) {
    // Try to extract details from the top level or a common 'details' section
    Map<String, dynamic>? jobData =
        jsonResponse['job_result_state'] ??
        jsonResponse['details'] ??
        jsonResponse;

    if (jobData != null) {
      final title = _extractString(jobData, ['title', 'job_title', 'name']);
      final company = _extractString(jobData, [
        'company',
        'company_name',
        'employer',
      ]);
      final logoUrl =
          _extractString(jobData, ['logo', 'company_logo', 'image']) ?? '';
      final description =
          _extractString(jobData, [
            'description',
            'full_description',
            'details',
          ]) ??
          'No description available.';
      final location =
          _extractString(jobData, ['location', 'address', 'city']) ??
          'Unknown location';
      final salary =
          _extractString(jobData, ['salary', 'base_salary', 'pay']) ??
          'Not specified';
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
          source: source,
          applyLink: applyLink,
        );
      }
    }
    return null;
  }

  // Helper function to safely extract a string from a map based on a list of keys
  static String? _extractString(Map<dynamic, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      if (map.containsKey(key) && map[key] is String) {
        return map[key] as String;
      }
    }
    return null;
  }
}
