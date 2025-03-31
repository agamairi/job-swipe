import 'package:flutter/material.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:job_swipe/widgets/job_card.dart';

typedef SwipeCallback = void Function(Job job, bool isRightSwipe);
typedef JobTapCallback = void Function(Job job);

class JobSwipe extends StatefulWidget {
  final List<Job> jobs;
  final SwipeCallback onSwipe;
  final JobTapCallback onTap;

  const JobSwipe({
    super.key,
    required this.jobs,
    required this.onSwipe,
    required this.onTap,
  });

  @override
  createState() => _JobSwipeState();
}

class _JobSwipeState extends State<JobSwipe> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.jobs.isEmpty || currentIndex >= widget.jobs.length) {
      return Center(child: Text("No more jobs"));
    }

    List<Widget> cardStack = [];

    for (int i = currentIndex; i < widget.jobs.length; i++) {
      final job = widget.jobs[i];
      Widget card = Positioned(
        top: 10.0 * (i - currentIndex),
        left: 10.0 * (i - currentIndex),
        right: 10.0 * (i - currentIndex),
        child:
            i == currentIndex
                ? Draggable<Job>(
                  data: job,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: JobCard(job: job, onTap: () {}),
                    ),
                  ),
                  childWhenDragging: Container(),
                  onDragEnd: (details) {
                    bool isRightSwipe = details.velocity.pixelsPerSecond.dx > 0;
                    setState(() {
                      widget.onSwipe(job, isRightSwipe);
                      currentIndex++;
                    });
                  },
                  child: JobCard(job: job, onTap: () => widget.onTap(job)),
                )
                : JobCard(job: job, onTap: () => widget.onTap(job)),
      );

      cardStack.add(card);
    }

    return Stack(children: cardStack.reversed.toList());
  }
}
