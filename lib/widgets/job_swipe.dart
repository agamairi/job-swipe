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
        child: SizedBox.expand(
          // Ensure it takes all available space
          child: JobCard(job: widget.job, onTap: widget.onTap),
        ),
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

    return Stack(
      children:
          List.generate(
            (widget.jobs.length - currentIndex).clamp(
              0,
              3,
            ), // Show up to 3 stacked cards
            (i) => Positioned.fill(
              // Ensures cards take up full space
              child: SwipeableJobCard(
                key: ValueKey(currentIndex + i),
                job: widget.jobs[currentIndex + i],
                onSwipeRight: () {
                  widget.onSwipe(widget.jobs[currentIndex + i], true);
                  setState(() => currentIndex++);
                },
                onSwipeLeft: () {
                  widget.onSwipe(widget.jobs[currentIndex + i], false);
                  setState(() => currentIndex++);
                },
                onTap: () => widget.onTap(widget.jobs[currentIndex + i]),
              ),
            ),
          ).reversed.toList(), // Ensure the top card is last in the stack
    );
  }
}
