import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:upgrade/pose_detec.dart';
import 'package:upgrade/services/daily_goals_service.dart';

class WorkoutsSection extends StatefulWidget {
  final VoidCallback? onWorkoutCompleted;

  const WorkoutsSection({super.key, this.onWorkoutCompleted});

  @override
  State<WorkoutsSection> createState() => _WorkoutsSectionState();
}

class _WorkoutsSectionState extends State<WorkoutsSection> {
  @override
  Widget build(BuildContext context) {
    final counts = DailyGoalsService.getWorkoutCounts();
    final squats = counts['squats'] ?? 0;
    final pushups = counts['pushups'] ?? 0;
    final curls = counts['bicep_curls'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workouts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              children: [
                WorkoutCard(
                  title: 'Squats',
                  subtitle:
                      '$squats / ${DailyGoalsService.targetSquats} Reps',
                  progressPercent: (squats / DailyGoalsService.targetSquats)
                      .clamp(0.0, 1.0),
                  color: const Color(0xFFAB47BC),
                  buttonText: squats > 0 ? 'Continue' : 'Start',
                  exerciseType: ExerciseType.squat,
                  onWorkoutCompleted: () {
                    widget.onWorkoutCompleted?.call();
                    setState(() {});
                  },
                  backgroundUrl:
                      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop&crop=center',
                ),
                WorkoutCard(
                  title: 'Pushups',
                  subtitle:
                      '$pushups / ${DailyGoalsService.targetPushups} Reps',
                  progressPercent: (pushups / DailyGoalsService.targetPushups)
                      .clamp(0.0, 1.0),
                  color: const Color(0xFFF57C00),
                  buttonText: pushups > 0 ? 'Continue' : 'Start',
                  exerciseType: ExerciseType.pushup,
                  onWorkoutCompleted: () {
                    widget.onWorkoutCompleted?.call();
                    setState(() {});
                  },
                  backgroundUrl:
                      'https://images.unsplash.com/photo-1581009146145-b5ef050c1494?w=400&h=300&fit=crop&crop=center',
                ),
                WorkoutCard(
                  title: 'Bicep Curls',
                  subtitle:
                      '$curls / ${DailyGoalsService.targetBicepCurls} Reps',
                  progressPercent: (curls / DailyGoalsService.targetBicepCurls)
                      .clamp(0.0, 1.0),
                  color: const Color(0xFF42A5F5),
                  buttonText: curls > 0 ? 'Continue' : 'Start',
                  exerciseType: ExerciseType.bicep,
                  onWorkoutCompleted: () {
                    widget.onWorkoutCompleted?.call();
                    setState(() {});
                  },
                  backgroundUrl:
                      'https://images.unsplash.com/photo-1594744329834-2d5c2f1a4c9f?w=400&h=300&fit=crop&crop=center',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progressPercent;
  final Color color;
  final String buttonText;
  final String? backgroundUrl;
  final ExerciseType exerciseType;
  final VoidCallback? onWorkoutCompleted;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progressPercent,
    required this.color,
    required this.buttonText,
    required this.exerciseType,
    this.backgroundUrl,
    this.onWorkoutCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: backgroundUrl != null
            ? DecorationImage(
                image: NetworkImage(backgroundUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.15),
                  BlendMode.dstATop,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (backgroundUrl != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F5F5F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircularProgressIndicatorWidget(
                      progress: progressPercent,
                      color: color,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PoseDetectorView(
                                exerciseType: exerciseType,
                              ),
                            ),
                          );
                          if (result is int && result > 0) {
                            await DailyGoalsService.addWorkoutReps(
                              DailyGoalsService.workoutKeyFor(exerciseType),
                              result,
                            );
                            onWorkoutCompleted?.call();
                          }
                        },
                        icon: Icon(
                          buttonText == 'Start'
                              ? Icons.play_arrow
                              : Icons.refresh,
                          size: 18,
                        ),
                        label: Text(buttonText),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgressIndicatorWidget extends StatelessWidget {
  final double progress;
  final Color color;

  const CircularProgressIndicatorWidget({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _CircularProgressPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = 4.0;
    final radius = (size.width / 2) - (strokeWidth / 2);

    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    final angle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
