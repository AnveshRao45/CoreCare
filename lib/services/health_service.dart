import 'dart:io';
import 'package:health/health.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_vitals.dart';

/// Central service wrapping the `health` package for wearable data access.
///
/// Handles permissions, reading health data from Google Health Connect
/// (Android) and Apple HealthKit (iOS), and writing hydration data.
class HealthService {
  static final _log = Logger('HealthService');
  static final Health _health = Health();
  static bool _isConfigured = false;

  // ──────────────────────────── Data Types ────────────────────────────

  /// Types we need to READ from the health platform.
  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
  ];

  /// Types we need to WRITE to the health platform.
  static const List<HealthDataType> _writeTypes = [
    HealthDataType.WATER,
    HealthDataType.STEPS,
  ];

  // ──────────────────────────── Init ────────────────────────────

  /// Configure the health plugin. Must be called before any data access.
  static Future<void> configure() async {
    if (_isConfigured) return;
    try {
      await _health.configure();
      _isConfigured = true;
      _log.info('✅ Health plugin configured');
    } catch (e) {
      _log.severe('❌ Failed to configure health plugin: $e');
    }
  }

  // ──────────────────────────── Permissions ────────────────────────────

  /// Check if we already have read permissions for all needed types.
  static Future<bool> hasPermissions() async {
    await configure();
    try {
      final types = _readTypes;
      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      final result = await _health.hasPermissions(types, permissions: permissions);
      _log.info('🔐 Has health permissions: $result');
      return result ?? false;
    } catch (e) {
      _log.severe('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Request read + write permissions for all needed health data types.
  static Future<bool> requestPermissions() async {
    await configure();
    try {
      // Request activity recognition on Android
      if (Platform.isAndroid) {
        final activityStatus = await Permission.activityRecognition.request();
        _log.info('📱 Activity recognition permission: $activityStatus');
      }

      // Combine read and write types with appropriate access levels
      final allTypes = <HealthDataType>[];
      final allPermissions = <HealthDataAccess>[];

      // Read-only types
      for (final type in _readTypes) {
        if (!_writeTypes.contains(type)) {
          allTypes.add(type);
          allPermissions.add(HealthDataAccess.READ);
        }
      }

      // Read + write types
      for (final type in _writeTypes) {
        allTypes.add(type);
        allPermissions.add(HealthDataAccess.READ_WRITE);
      }

      final authorized = await _health.requestAuthorization(
        allTypes,
        permissions: allPermissions,
      );

      _log.info('🔐 Authorization result: $authorized');
      return authorized;
    } catch (e) {
      _log.severe('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Revoke all health data permissions.
  static Future<void> revokePermissions() async {
    try {
      await _health.revokePermissions();
      _log.info('🔓 Permissions revoked');
    } catch (e) {
      _log.severe('❌ Error revoking permissions: $e');
    }
  }

  // ──────────────────────────── Data Fetching ────────────────────────────

  /// Fetch all vitals for today and return a [HealthVitals] snapshot.
  static Future<HealthVitals> fetchAllVitals() async {
    await configure();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final yesterdayMidnight = midnight.subtract(const Duration(days: 1));

    try {
      // Fetch all data concurrently for performance
      final results = await Future.wait([
        _fetchTodaySteps(midnight, now),                   // 0
        _fetchYesterdaySteps(yesterdayMidnight, midnight),  // 1
        _fetchLatestHeartRate(midnight, now),               // 2
        _fetchAverageHeartRate(midnight, now),              // 3
        _fetchTodayCalories(midnight, now),                 // 4
        _fetchSleepDuration(yesterdayMidnight, now),        // 5
        _fetchYesterdaySleep(yesterdayMidnight.subtract(const Duration(days: 1)), yesterdayMidnight), // 6
        _fetchTodayHydration(midnight, now),                // 7
      ]);

      final todaySteps = results[0] as int;
      final yesterdaySteps = results[1] as int;
      final latestHR = results[2] as double;
      final avgHR = results[3] as double;
      final calories = results[4] as int;
      final sleepDuration = results[5] as Duration;
      final yesterdaySleep = results[6] as Duration;
      final hydration = results[7] as double;

      // Calculate heart rate status
      String hrStatus = 'N/A';
      if (latestHR > 0) {
        if (latestHR < 60) {
          hrStatus = 'Low';
        } else if (latestHR <= 100) {
          hrStatus = 'Normal';
        } else {
          hrStatus = 'High';
        }
      }

      // Calculate sleep change
      Duration? sleepChange;
      if (sleepDuration > Duration.zero && yesterdaySleep > Duration.zero) {
        sleepChange = sleepDuration - yesterdaySleep;
      }

      final vitals = HealthVitals(
        steps: todaySteps,
        heartRate: latestHR,
        heartRateAvg: avgHR,
        heartRateStatus: hrStatus,
        caloriesBurned: calories,
        sleepDuration: sleepDuration,
        sleepChange: sleepChange,
        hydrationLiters: hydration,
        stepsChange: todaySteps - yesterdaySteps,
        lastSyncTime: now,
        isConnected: true,
      );

      _log.info('📊 Vitals fetched: steps=$todaySteps, hr=$latestHR, '
          'cal=$calories, sleep=${sleepDuration.inMinutes}min, '
          'hydration=${hydration.toStringAsFixed(2)}L');

      return vitals;
    } catch (e) {
      _log.severe('❌ Error fetching vitals: $e');
      return HealthVitals(
        lastSyncTime: now,
        isConnected: false,
      );
    }
  }

  // ──────────────────────── Individual Fetchers ────────────────────────

  /// Fetch total step count for today.
  static Future<int> _fetchTodaySteps(DateTime from, DateTime to) async {
    try {
      final steps = await _health.getTotalStepsInInterval(from, to);
      return steps ?? 0;
    } catch (e) {
      _log.warning('⚠️ Steps fetch error: $e');
      return 0;
    }
  }

  /// Fetch yesterday's step count for comparison.
  static Future<int> _fetchYesterdaySteps(DateTime from, DateTime to) async {
    try {
      final steps = await _health.getTotalStepsInInterval(from, to);
      return steps ?? 0;
    } catch (e) {
      _log.warning('⚠️ Yesterday steps fetch error: $e');
      return 0;
    }
  }

  /// Fetch the most recent heart rate reading.
  static Future<double> _fetchLatestHeartRate(
      DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: from,
        endTime: to,
      );
      if (data.isEmpty) return 0;

      // Sort by time descending and get the latest
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = data.first;
      if (latest.value is NumericHealthValue) {
        return (latest.value as NumericHealthValue).numericValue.toDouble();
      }
      return 0;
    } catch (e) {
      _log.warning('⚠️ Heart rate fetch error: $e');
      return 0;
    }
  }

  /// Calculate average heart rate for today.
  static Future<double> _fetchAverageHeartRate(
      DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: from,
        endTime: to,
      );
      if (data.isEmpty) return 0;

      double sum = 0;
      int count = 0;
      for (final point in data) {
        if (point.value is NumericHealthValue) {
          sum += (point.value as NumericHealthValue).numericValue.toDouble();
          count++;
        }
      }
      return count > 0 ? sum / count : 0;
    } catch (e) {
      _log.warning('⚠️ Avg heart rate fetch error: $e');
      return 0;
    }
  }

  /// Fetch total calories burned today (active + basal).
  static Future<int> _fetchTodayCalories(DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.TOTAL_CALORIES_BURNED,
        ],
        startTime: from,
        endTime: to,
      );

      if (data.isEmpty) return 0;

      // Remove duplicates
      final cleaned = _health.removeDuplicates(data);

      double total = 0;

      // Prefer TOTAL_CALORIES_BURNED if available
      final totalCalData = cleaned
          .where((p) => p.type == HealthDataType.TOTAL_CALORIES_BURNED);
      if (totalCalData.isNotEmpty) {
        for (final point in totalCalData) {
          if (point.value is NumericHealthValue) {
            total += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
      } else {
        // Fall back to active energy burned
        for (final point in cleaned) {
          if (point.value is NumericHealthValue) {
            total += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
      }

      return total.round();
    } catch (e) {
      _log.warning('⚠️ Calories fetch error: $e');
      return 0;
    }
  }

  /// Fetch sleep duration (searches across last night into today).
  static Future<Duration> _fetchSleepDuration(
      DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_SESSION,
          HealthDataType.SLEEP_ASLEEP,
        ],
        startTime: from,
        endTime: to,
      );

      if (data.isEmpty) return Duration.zero;

      final cleaned = _health.removeDuplicates(data);

      // Prefer SLEEP_SESSION for total duration
      final sessions =
          cleaned.where((p) => p.type == HealthDataType.SLEEP_SESSION).toList();

      if (sessions.isNotEmpty) {
        // Sum all sleep session durations
        Duration total = Duration.zero;
        for (final session in sessions) {
          total += session.dateTo.difference(session.dateFrom);
        }
        return total;
      }

      // Fallback to SLEEP_ASLEEP
      final asleepData =
          cleaned.where((p) => p.type == HealthDataType.SLEEP_ASLEEP).toList();
      if (asleepData.isNotEmpty) {
        Duration total = Duration.zero;
        for (final sleep in asleepData) {
          total += sleep.dateTo.difference(sleep.dateFrom);
        }
        return total;
      }

      return Duration.zero;
    } catch (e) {
      _log.warning('⚠️ Sleep fetch error: $e');
      return Duration.zero;
    }
  }

  /// Fetch yesterday's sleep for comparison.
  static Future<Duration> _fetchYesterdaySleep(
      DateTime from, DateTime to) async {
    return _fetchSleepDuration(from, to);
  }

  /// Fetch today's hydration (water intake in liters).
  static Future<double> _fetchTodayHydration(
      DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: from,
        endTime: to,
      );

      if (data.isEmpty) return 0;

      final cleaned = _health.removeDuplicates(data);

      double totalLiters = 0;
      for (final point in cleaned) {
        if (point.value is NumericHealthValue) {
          totalLiters +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      return totalLiters;
    } catch (e) {
      _log.warning('⚠️ Hydration fetch error: $e');
      return 0;
    }
  }

  // ──────────────────────────── Writing Data ────────────────────────────

  /// Write hydration data (in liters) to the health platform.
  static Future<bool> writeWater(double liters) async {
    await configure();
    try {
      final now = DateTime.now();
      final success = await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: now,
        endTime: now,
      );
      _log.info('💧 Water written (${liters}L): $success');
      return success;
    } catch (e) {
      _log.severe('❌ Error writing water: $e');
      return false;
    }
  }

  /// Write workout data to the health platform.
  static Future<bool> writeWorkout({
    required HealthWorkoutActivityType type,
    required DateTime start,
    required DateTime end,
    int? totalEnergyBurned,
  }) async {
    await configure();
    try {
      final success = await _health.writeWorkoutData(
        activityType: type,
        start: start,
        end: end,
        totalEnergyBurned: totalEnergyBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
      _log.info('🏋️ Workout written: $success');
      return success;
    } catch (e) {
      _log.severe('❌ Error writing workout: $e');
      return false;
    }
  }

  // ──────────────────────────── Utility ────────────────────────────

  /// Check if Health Connect is available on Android.
  static Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true; // iOS always has HealthKit
    try {
      await configure();
      // Try to check permissions as a way to verify Health Connect is available
      final result = await _health.hasPermissions([HealthDataType.STEPS]);
      return result != null;
    } catch (e) {
      _log.warning('⚠️ Health Connect not available: $e');
      return false;
    }
  }
}
