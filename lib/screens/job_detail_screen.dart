import 'package:flutter/material.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/database/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;
  final bool isApplied;

  const JobDetailScreen({super.key, required this.job, this.isApplied = false});

  Future<void> _applyToJob(BuildContext context) async {
    if (job.applyLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application link available')),
      );
      return;
    }

    // Update status in DB to 'applied' if the user applied from saved
    final db = DatabaseHelper();
    await db.updateJobStatus(job.id, 'applied');

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
        title: const Text('Job Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    job.logoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.business,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.company,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.location,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (job.salary != 'Not specified') ...[
              Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.salary,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('via ${job.source}'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  side: BorderSide.none,
                ),
                if (job.datePosted != 'Not Available')
                  Chip(
                    label: Text(job.datePosted),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Job Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: isApplied 
        ? null 
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _applyToJob(context),
                child: const Text('Apply Now'),
              ),
            ),
          ),
    );
  }
}
