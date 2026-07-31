import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:upgrade/utils/detector_view.dart';
import 'package:upgrade/utils/exercise_detector.dart';
import 'package:upgrade/utils/pose_painter.dart';


enum ExerciseType { squat, pushup, bicep }

class PoseDetectorView extends StatefulWidget {
  final ExerciseType? exerciseType;

  const PoseDetectorView({super.key, this.exerciseType});

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  final ExerciseCounter _counter = ExerciseCounter();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text = "Loading camera...";
  var _cameraLensDirection = CameraLensDirection.back;

  String get _exerciseName {
    switch (widget.exerciseType) {
      case ExerciseType.squat:
        return "Squats";
      case ExerciseType.pushup:
        return "Push-ups";
      case ExerciseType.bicep:
        return "Bicep Curls";
      case null:
        return "Workout Tracker";
    }
  }

  int get _currentCount {
    switch (widget.exerciseType) {
      case ExerciseType.squat:
        return _counter.squatCount;
      case ExerciseType.pushup:
        return _counter.pushupCount;
      case ExerciseType.bicep:
        return _counter.bicepCount;
      case null:
        return 0;
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking: $_exerciseName"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Finish Workout',
            onPressed: () {
              Navigator.of(context).pop(_currentCount);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          DetectorView(
            title: 'Workout Tracker',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) =>
                _cameraLensDirection = value,
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$_currentCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "reps",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;

    _isBusy = true;
    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isNotEmpty) {
      final pose = poses.first;

      if (widget.exerciseType == null) {
        _counter.detectBicepCurl(pose);
        _counter.detectSquat(pose);
        _counter.detectPushUp(pose);
        _text =
            "Bicep Curls: ${_counter.bicepCount}\nSquats: ${_counter.squatCount}\nPush-ups: ${_counter.pushupCount}";
      } else {
        switch (widget.exerciseType!) {
          case ExerciseType.squat:
            _counter.detectSquat(pose);
            break;
          case ExerciseType.pushup:
            _counter.detectPushUp(pose);
            break;
          case ExerciseType.bicep:
            _counter.detectBicepCurl(pose);
            break;
        }
        _text = "$_exerciseName: $_currentCount";
      }
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = PosePainter(
        poses,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }
}
