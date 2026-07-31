import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:upgrade/utils/exercise_detector.dart';

void main() {
  test('squat rep counted after full movement', () {
    final counter = ExerciseCounter();
    final up = _legPose(straight: true);
    final down = _legPose(straight: false);

    for (var i = 0; i < 5; i++) {
      counter.detectSquat(up);
    }
    for (var i = 0; i < 12; i++) {
      counter.detectSquat(down);
    }

    expect(counter.squatCount, 1);
  });

  test('rep cooldown blocks duplicate count', () {
    final counter = ExerciseCounter();

    void doRep() {
      for (var i = 0; i < 5; i++) {
        counter.detectSquat(_legPose(straight: true));
      }
      for (var i = 0; i < 12; i++) {
        counter.detectSquat(_legPose(straight: false));
      }
    }

    doRep();
    doRep();

    expect(counter.squatCount, 1);
  });
}

Pose _legPose({required bool straight}) {
  const hip = PoseLandmarkType.leftHip;
  const knee = PoseLandmarkType.leftKnee;
  const ankle = PoseLandmarkType.leftAnkle;

  final ankleX = straight ? 300.0 : 200.0;
  final ankleY = straight ? 300.0 : 200.0;

  return Pose(
    landmarks: {
      hip: PoseLandmark(type: hip, x: 100, y: 300, z: 0, likelihood: 0.99),
      knee: PoseLandmark(type: knee, x: 200, y: 300, z: 0, likelihood: 0.99),
      ankle: PoseLandmark(
        type: ankle,
        x: ankleX,
        y: ankleY,
        z: 0,
        likelihood: 0.99,
      ),
    },
  );
}
