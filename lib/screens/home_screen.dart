import 'package:flutter/material.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/widgets/job_swipe.dart';
import 'package:job_swipe/widgets/search_bar.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  List<Job> _filterJobs(List<Job> jobs, String query) {
    if (query.isEmpty) return jobs;
    final lowerQuery = query.toLowerCase();
    return jobs.where((job) {
      return job.title.toLowerCase().contains(lowerQuery) ||
          job.company.toLowerCase().contains(lowerQuery) ||
          job.location.toLowerCase().contains(lowerQuery) ||
          job.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchProvider>(
      create: (_) => SearchProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Application App'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search Bar at the top
            CustomSearchBar(),
            // Expanded area for job swipe cards
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, child) {
                  // Filter sampleJobs based on the search query
                  List<Job> filteredJobs = _filterJobs(
                    sampleJobs,
                    searchProvider.searchQuery,
                  );
                  return JobSwipe(
                    jobs: filteredJobs,
                    onSwipe: (job, isRightSwipe) {
                      // Add functionality based on swipe direction (e.g., auto apply on right swipe)
                      if (isRightSwipe) {
                        // For now, simply show a snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Applied for ${job.title} at ${job.company}',
                            ),
                          ),
                        );
                      } else {
                        // Optionally track dismissed jobs
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dismissed ${job.title}')),
                        );
                      }
                    },
                    onTap: (job) {
                      // Navigate to detailed view later on
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped on ${job.title}')),
                      );
                    },
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
