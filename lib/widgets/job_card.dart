import 'package:flutter/material.dart';
import 'package:job_swipe/models/job_model.dart';

class JobCard extends StatefulWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onSave;

  const JobCard({super.key, required this.job, required this.onTap, this.onSave});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox.expand(
        // Makes the card take up all available space
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max, // Ensures it takes full height
              children: [
                Expanded(
                  // Makes the inner content take all available space and scrollable
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.job.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (widget.onSave != null)
                                        IconButton(
                                          icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
                                          color: _isSaved ? Theme.of(context).primaryColor : null,
                                          onPressed: () {
                                            setState(() => _isSaved = true);
                                            widget.onSave!();
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.job.company,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                widget.job.logoUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.business,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(child: Text(widget.job.location, style: TextStyle(color: Colors.grey[800]))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (widget.job.salary != 'Not specified')
                          Row(
                            children: [
                              Icon(Icons.monetization_on, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Expanded(child: Text(widget.job.salary, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500))),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text('via ${widget.job.source}', style: const TextStyle(fontSize: 12)),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              side: BorderSide.none,
                            ),
                            if (widget.job.datePosted != 'Not Available')
                              Chip(
                                label: Text(widget.job.datePosted, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          widget.job.description,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
