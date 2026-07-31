import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/features/widgets/workouts_section.dart';
import 'package:upgrade/pose_detec.dart';
import 'package:upgrade/services/daily_goals_service.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestHive();
  });

  tearDownAll(() async {
    await closeTestHive();
  });

  testWidgets('workout card shows squat info', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutCard(
            title: 'Squats',
            subtitle: '0 / 30 Reps',
            progressPercent: 0,
            color: Color(0xFFAB47BC),
            buttonText: 'Start',
            exerciseType: ExerciseType.squat,
          ),
        ),
      ),
    );

    expect(find.text('Squats'), findsOneWidget);
    expect(find.text('0 / 30 Reps'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  test('workout keys match hive fields', () {
    expect(DailyGoalsService.workoutKeyFor(ExerciseType.squat), 'squats');
    expect(DailyGoalsService.workoutKeyFor(ExerciseType.pushup), 'pushups');
    expect(DailyGoalsService.workoutKeyFor(ExerciseType.bicep), 'bicep_curls');
  });

  test('addWorkoutReps saves to hive', () async {
    await DailyGoalsService.addWorkoutReps('squats', 5);
    expect(DailyGoalsService.getWorkoutCounts()['squats'], 5);

    await DailyGoalsService.addWorkoutReps('squats', 3);
    expect(DailyGoalsService.getWorkoutCounts()['squats'], 8);
  });
}
