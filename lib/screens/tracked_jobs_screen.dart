import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:job_swipe/database/database_helper.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/widgets/footer_navigation_bar.dart';
import 'package:job_swipe/screens/job_detail_screen.dart';

class TrackedJobsScreen extends StatefulWidget {
  const TrackedJobsScreen({super.key});

  @override
  State<TrackedJobsScreen> createState() => _TrackedJobsScreenState();
}

class _TrackedJobsScreenState extends State<TrackedJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Job> _savedJobs = [];
  List<Job> _appliedJobs = [];
  bool _isLoading = true;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadJobs();
  }

  Future<void> _exportToCsv() async {
    if (_appliedJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No applied jobs to export')),
      );
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(['Job Title', 'Link', 'Company Name', 'Salary', 'Location']); // Header row

    for (var job in _appliedJobs) {
      rows.add([
        job.title,
        job.applyLink,
        job.company,
        job.salary,
        job.location,
      ]);
    }

    String csvData = const CsvEncoder().convert(rows);

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/applied_jobs.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)], 
          text: 'Exported Applied Jobs',
        )
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper();
    final saved = await db.getJobsByStatus('saved');
    final applied = await db.getJobsByStatus('applied');
    
    if (mounted) {
      setState(() {
        _savedJobs = saved;
        _appliedJobs = applied;
        _isLoading = false;
      });
    }
  }

  void _openJob(Job job, bool isApplied) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job, isApplied: isApplied),
      ),
    );
    // Reload jobs after returning, in case a saved job was applied to
    _loadJobs();
  }

  Widget _buildJobList(List<Job> jobs, String emptyMessage, bool isApplied) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (jobs.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                job.logoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.business,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
            ),
            title: Text(
              job.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(job.company, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(job.location, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            onTap: () => _openJob(job, isApplied),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracked Jobs'),
        centerTitle: true,
        actions: [
          if (_currentTabIndex == 1) // Only show on Applied tab
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: _exportToCsv,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
            Tab(icon: Icon(Icons.check_circle), text: 'Applied'),
          ],
        ),
      ),
      bottomNavigationBar: const FooterNavigationBar(currentIndex: 2), // Index 2 for Tracked Jobs
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobList(_savedJobs, 'No saved jobs yet.', false),
          _buildJobList(_appliedJobs, 'No applied jobs yet.', true),
        ],
      ),
    );
  }
}
