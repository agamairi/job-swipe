import 'package:flutter/material.dart';
import 'package:job_swipe/models/job_model.dart';
import 'job_card.dart';

typedef SwipeCallback = void Function(Job job, bool isRightSwipe);
typedef JobTapCallback = void Function(Job job);

/// A custom widget that handles the swipe animation for the top card.
class SwipeableJobCard extends StatefulWidget {
  final Job job;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onTap;

  const SwipeableJobCard({
    super.key,
    required this.job,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onTap,
  });

  @override
  createState() => _SwipeableJobCardState();
}

class _SwipeableJobCardState extends State<SwipeableJobCard>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  bool _swiped = false;
  final double _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          )
          ..addListener(() {
            setState(() {
              _offset = _animation.value;
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _swiped) {
              if (_offset.dx > 0) {
                widget.onSwipeRight();
              } else {
                widget.onSwipeLeft();
              }
            }
          });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateCard(Offset endOffset) {
    _animation = Tween<Offset>(begin: _offset, end: endOffset).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0);
  }

  void _resetCard() {
    _animation = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: (details) {
        setState(() {
          _offset += details.delta;
        });
      },
      onPanEnd: (details) {
        if (_offset.dx.abs() > _swipeThreshold) {
          _swiped = true;
          final screenWidth = MediaQuery.of(context).size.width;
          final endOffset = Offset(
            _offset.dx > 0 ? screenWidth : -screenWidth,
            _offset.dy,
          );
          _animateCard(endOffset);
        } else {
          _resetCard();
        }
      },
      child: Transform.translate(
        offset: _offset,
        child: JobCard(job: widget.job, onTap: widget.onTap),
      ),
    );
  }
}

/// The JobSwipe widget stacks job cards and provides swipe functionality.
class JobSwipe extends StatefulWidget {
  final List<Job> jobs;
  final SwipeCallback onSwipe;
  final JobTapCallback onTap;
  final VoidCallback onRefresh;

  const JobSwipe({
    super.key,
    required this.jobs,
    required this.onSwipe,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  createState() => _JobSwipeState();
}

class _JobSwipeState extends State<JobSwipe> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.jobs.isEmpty || currentIndex >= widget.jobs.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No more jobs"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onRefresh();
                setState(() {
                  currentIndex = 0;
                });
              },
              child: const Text("Refresh"),
            ),
          ],
        ),
      );
    }

    // Determine the number of cards to show in the stack.
    int remainingJobs = widget.jobs.length - currentIndex;
    int cardsToShow = remainingJobs > 3 ? 3 : remainingJobs;

    List<Widget> cardStack = [];
    for (int i = 0; i < cardsToShow; i++) {
      final job = widget.jobs[currentIndex + i];
      if (i == 0) {
        // Add a unique key here to ensure fresh state for each top card.
        cardStack.add(
          Positioned(
            top: 10.0 * i,
            left: 10.0 * i,
            right: 10.0 * i,
            child: SwipeableJobCard(
              key: ValueKey(currentIndex),
              job: job,
              onSwipeRight: () {
                widget.onSwipe(job, true);
                setState(() {
                  currentIndex++;
                });
              },
              onSwipeLeft: () {
                widget.onSwipe(job, false);
                setState(() {
                  currentIndex++;
                });
              },
              onTap: () => widget.onTap(job),
            ),
          ),
        );
      } else {
        cardStack.add(
          Positioned(
            top: 10.0 * i,
            left: 10.0 * i,
            right: 10.0 * i,
            child: JobCard(job: job, onTap: () => widget.onTap(job)),
          ),
        );
      }
    }

    return Stack(children: cardStack.reversed.toList());
  }
}
