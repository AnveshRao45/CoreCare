import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/health_vitals.dart';

class HealthService {
  static const String _tag = '[HEALTH]';
  static const MethodChannel _channel =
      MethodChannel('com.mstech.corecare/health_connect');
  static final _log = Logger('HealthService');
  static final Health _health = Health();
  static bool _isConfigured = false;

  /// Cached result of the last connection diagnosis, useful for the UI.
  static Map<String, dynamic> lastDiagnosis = <String, dynamic>{};

  // ──────────────────────────── Logging Helpers ────────────────────────────

  /// Info-level log. Goes to logger, debugPrint, and developer.log
  /// so it shows up in the IDE console regardless of how logging is wired up.
  static void _debug(String message) {
    _log.info(message);
    debugPrint('$_tag $message');
    developer.log(message, name: 'HealthService');
  }

  /// Warning-level log (non-fatal issues, missing data, etc.).
  static void _warn(String message, [Object? error, StackTrace? stack]) {
    _log.warning(message, error, stack);
    debugPrint('$_tag ⚠️  $message${error != null ? ' — $error' : ''}');
    developer.log(message,
        name: 'HealthService', level: 900, error: error, stackTrace: stack);
  }

  /// Severe error log (fetch failures, permission errors, etc.).
  static void _error(String message, [Object? error, StackTrace? stack]) {
    _log.severe(message, error, stack);
    debugPrint('$_tag ❌ $message${error != null ? ' — $error' : ''}');
    if (stack != null) debugPrint('$_tag    stack: $stack');
    developer.log(message,
        name: 'HealthService', level: 1000, error: error, stackTrace: stack);
  }

  // ──────────────────────────── Data Types ────────────────────────────

  static const List<HealthDataType> _heartRateTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
  ];

  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
  ];

  static const List<HealthDataType> _writeTypes = [
    HealthDataType.WATER,
    HealthDataType.STEPS,
  ];

  // ──────────────────────────── Init ────────────────────────────

  /// Configure the health plugin. Must be called before any data access.
  static Future<void> configure() async {
    if (_isConfigured) {
      _debug('✓ Plugin already configured (skipping re-init)');
      return;
    }
    try {
      _debug('🔧 Configuring health plugin on ${Platform.operatingSystem}...');
      await _health.configure();
      _isConfigured = true;
      _debug('✅ Health plugin configured successfully '
          '(platform=${_health.platformType}, deviceId=${_health.deviceId})');
    } catch (e, st) {
      _error('Failed to configure health plugin', e, st);
    }
  }

  // ──────────────────────────── Health Connect ────────────────────────────

  /// Check the Google Health Connect SDK status on Android.
  ///
  /// On iOS this always returns `sdkAvailable` (HealthKit is built-in).
  static Future<HealthConnectSdkStatus> getSdkStatus() async {
    if (!Platform.isAndroid) {
      _debug('🍎 iOS detected — HealthKit available by default');
      return HealthConnectSdkStatus.sdkAvailable;
    }
    await configure();
    try {
      final status = await _health.getHealthConnectSdkStatus();
      final resolved = status ?? HealthConnectSdkStatus.sdkUnavailable;
      _debug('🔍 Health Connect SDK status: $resolved');
      switch (resolved) {
        case HealthConnectSdkStatus.sdkAvailable:
          _debug('   → Health Connect is installed and ready to use.');
          break;
        case HealthConnectSdkStatus.sdkUnavailable:
          _warn('Health Connect is NOT installed on this device. '
              'Ask the user to install it via installHealthConnect().');
          break;
        case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
          _warn('Health Connect provider needs an update from Play Store.');
          break;
      }
      return resolved;
    } catch (e, st) {
      _error('Failed to read Health Connect SDK status', e, st);
      return HealthConnectSdkStatus.sdkUnavailable;
    }
  }

  /// Returns true if Health Connect (Android) / HealthKit (iOS) is usable.
  static Future<bool> isHealthConnectAvailable() async {
    final status = await getSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Launch the Play Store so the user can install Health Connect.
  /// No-op on iOS.
  static Future<void> installHealthConnect() async {
    if (!Platform.isAndroid) return;
    try {
      _debug('📲 Launching Play Store to install Health Connect...');
      await _health.installHealthConnect();
    } catch (e, st) {
      _error('Failed to launch Health Connect install', e, st);
    }
  }

  /// Open Health Connect's "connected apps" settings page so the user can
  /// verify their watch's companion app is granted write permissions.
  ///
  /// This is what you should call when the diagnosis shows the watch app is
  /// not feeding data into Health Connect — the user needs to flip the
  /// permission toggle inside Health Connect itself, *not* in this app.
  ///
  /// Returns true if some intent was launched, false otherwise.
  /// No-op on iOS.
  static Future<bool> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      _debug('🛠  Opening Health Connect settings...');
      final result = await _channel.invokeMethod<bool>('openHealthConnect');
      _debug('   → launch result: $result');
      return result ?? false;
    } on PlatformException catch (e, st) {
      _error('PlatformException opening Health Connect', e, st);
      // Fall back to the Play Store flow built into the health package.
      await installHealthConnect();
      return false;
    } catch (e, st) {
      _error('Failed to open Health Connect settings', e, st);
      return false;
    }
  }

  // ──────────────────────────── Permissions ────────────────────────────

  /// Check if we already have read permissions for all needed types.
  static Future<bool> hasPermissions() async {
    await configure();
    try {
      final types = _readTypes;
      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      final result =
          await _health.hasPermissions(types, permissions: permissions);
      _debug('🔐 hasPermissions() = $result '
          '(checked ${types.length} READ types)');
      return result ?? false;
    } catch (e, st) {
      _error('Error checking permissions', e, st);
      return false;
    }
  }

  /// Request read + write permissions for all needed health data types.
  static Future<bool> requestPermissions() async {
    await configure();

    // 1. Verify Health Connect is installed (Android only)
    if (Platform.isAndroid) {
      final available = await isHealthConnectAvailable();
      if (!available) {
        _warn('Cannot request permissions: Health Connect is not available.');
        return false;
      }
    }

    try {
      // 2. Android: ask for activity-recognition first (needed for steps)
      if (Platform.isAndroid) {
        final activityStatus = await Permission.activityRecognition.request();
        _debug('🏃 Activity recognition permission: $activityStatus');
      }

      // 3. Build the type/permission pair list
      final allTypes = <HealthDataType>[];
      final allPermissions = <HealthDataAccess>[];

      for (final type in _readTypes) {
        if (!_writeTypes.contains(type)) {
          allTypes.add(type);
          allPermissions.add(HealthDataAccess.READ);
        }
      }
      for (final type in _writeTypes) {
        allTypes.add(type);
        allPermissions.add(HealthDataAccess.READ_WRITE);
      }

      _debug('🔑 Requesting authorization for ${allTypes.length} types:');
      for (var i = 0; i < allTypes.length; i++) {
        _debug('   • ${allTypes[i].name} → ${allPermissions[i].name}');
      }

      final authorized = await _health.requestAuthorization(
        allTypes,
        permissions: allPermissions,
      );

      if (authorized) {
        _debug('✅ Authorization granted by user');
        await ensureExtendedAccess();
      } else {
        _warn('Authorization NOT granted. The user either denied permissions '
            'or dismissed the Health Connect dialog.');
      }
      return authorized;
    } catch (e, st) {
      _error('Error requesting permissions', e, st);
      return false;
    }
  }

  /// Ensure read access specifically for heart-rate types (often granted
  /// separately from steps in Health Connect).
  static Future<void> ensureHeartRatePermissions() async {
    await configure();
    try {
      final permissions =
          _heartRateTypes.map((_) => HealthDataAccess.READ).toList();
      final granted = await _health.hasPermissions(
        _heartRateTypes,
        permissions: permissions,
      );
      if (granted == true) {
        _debug('💓 Heart-rate permissions already granted');
        return;
      }
      _debug('💓 Heart-rate read not granted — requesting authorization...');
      final ok = await _health.requestAuthorization(
        _heartRateTypes,
        permissions: permissions,
      );
      _debug('💓 Heart-rate authorization result: $ok');
    } catch (e, st) {
      _warn('Heart-rate permission request failed', e, st);
    }
  }

  /// Request extended Health Connect access (historical + background reads).
  /// Required on Android 14+ to read watch data that synced earlier today.
  static Future<void> ensureExtendedAccess() async {
    if (!Platform.isAndroid) return;
    try {
      final historyAvailable = await _health.isHealthDataHistoryAvailable();
      if (historyAvailable) {
        final historyOk = await _health.isHealthDataHistoryAuthorized();
        if (!historyOk) {
          _debug('📜 Requesting Health Connect history authorization...');
          await _health.requestHealthDataHistoryAuthorization();
        }
      }

      final bgAvailable = await _health.isHealthDataInBackgroundAvailable();
      if (bgAvailable) {
        final bgOk = await _health.isHealthDataInBackgroundAuthorized();
        if (!bgOk) {
          _debug('📜 Requesting Health Connect background read authorization...');
          await _health.requestHealthDataInBackgroundAuthorization();
        }
      }
    } catch (e, st) {
      _warn('Extended Health Connect access request failed', e, st);
    }
  }

  /// Revoke all health data permissions.
  static Future<void> revokePermissions() async {
    try {
      await _health.revokePermissions();
      _debug('🗑️  Permissions revoked');
    } catch (e, st) {
      _error('Error revoking permissions', e, st);
    }
  }

  // ──────────────────────────── Source Enumeration ────────────────────────────

  /// Types we want to enumerate sources for in the diagnosis screen.
  /// (WORKOUT is intentionally excluded — it queries differently and just
  ///  spams logs without adding useful information for typical wearables.)
  static const List<HealthDataType> _sourceProbeTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
  ];

  /// Probes Health Connect for each supported data type and returns a map
  /// telling you exactly which apps are writing data for each metric.
  ///
  /// Example return:
  /// ```
  /// {
  ///   "HEART_RATE": [],                       // ← watch app not connected!
  ///   "STEPS": ["Google Fit"],                // ← steps coming from phone
  ///   "TOTAL_CALORIES_BURNED": [],
  ///   "SLEEP_SESSION": ["Samsung Health"],
  /// }
  /// ```
  ///
  /// Use this to tell the user *why* their watch isn't showing up: if
  /// `HEART_RATE` is empty but their watch genuinely tracks HR, then the
  /// watch's companion app isn't connected to Health Connect.
  static Future<Map<String, List<String>>> getSourcesByType({
    Duration lookback = const Duration(days: 7),
  }) async {
    await configure();
    final now = DateTime.now();
    final start = now.subtract(lookback);
    final out = <String, List<String>>{};

    _debug('🔎 Probing data sources for the last ${lookback.inDays} days...');

    for (final type in _sourceProbeTypes) {
      try {
        final points = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: start,
          endTime: now,
        );
        final sources = points
            .map((p) => p.sourceName)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        out[type.name] = sources;
        _debug('   • ${type.name.padRight(24)} → '
            '${points.length} pts, sources=$sources');
      } catch (e) {
        // Known: STEPS can throw "startTime must be before endTime" on
        // Health Connect when a record has an equal start/end timestamp.
        // Recorded as an empty source list so the UI can still render.
        out[type.name] = const [];
        _warn('   • ${type.name} probe failed (treating as no data)', e);
      }
    }
    return out;
  }

  // ──────────────────────────── Connection Diagnosis ────────────────────────────

  /// Comprehensive check that tells you WHY data may or may not be flowing.
  ///
  /// Logs each step and returns a map that you can show in the UI.
  /// Use this whenever the vitals card shows "Not connected" — it will tell
  /// you whether the problem is:
  ///   • Health Connect not installed
  ///   • Permissions not granted
  ///   • No wearable syncing data
  ///   • Watch connected but data is stale
  static Future<Map<String, dynamic>> diagnoseConnection() async {
    _debug('═══════════════════════════════════════════════');
    _debug('🩺 Running health connection diagnosis...');
    _debug('═══════════════════════════════════════════════');

    await configure();

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final dayStart = DateTime(now.year, now.month, now.day);

    final result = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'configured': _isConfigured,
      'healthConnectInstalled': false,
      'hasPermissions': false,
      'recentHeartRateCount': 0,
      'todayHeartRateCount': 0,
      'todayStepsTotal': 0,
      'todayStepPoints': 0,
      'dataSources': <String>{},
      // Per-type source map: tells the user which app feeds each metric.
      // e.g. { "HEART_RATE": [], "STEPS": ["Google Fit"] }
      'sourcesByType': <String, List<String>>{},
      'wearableDetected': false,
      'mostRecentDataPoint': null as DateTime?,
      'minutesSinceLastSync': null as int?,
      'errors': <String>[],
    };

    // 1. Health Connect availability
    try {
      final sdkStatus = await getSdkStatus();
      result['healthConnectInstalled'] =
          sdkStatus == HealthConnectSdkStatus.sdkAvailable;
      result['sdkStatus'] = sdkStatus.toString();
    } catch (e) {
      (result['errors'] as List<String>).add('SDK status: $e');
    }

    // 2. Permissions
    try {
      result['hasPermissions'] = await hasPermissions();
    } catch (e) {
      (result['errors'] as List<String>).add('hasPermissions: $e');
    }

    // 3. Per-type source enumeration — this is the most useful single
    // piece of debugging info: it shows which apps are actually writing
    // each metric into Health Connect.
    if (result['hasPermissions'] == true) {
      try {
        final sourcesByType = await getSourcesByType();
        result['sourcesByType'] = sourcesByType;
        // Flatten into the legacy `dataSources` set for compatibility.
        for (final list in sourcesByType.values) {
          for (final name in list) {
            (result['dataSources'] as Set<String>).add(name);
          }
        }
      } catch (e) {
        (result['errors'] as List<String>).add('sourcesByType: $e');
      }

      try {
        final queryEnd = _queryEndTime(now);
        final recentHR = await _health.getHealthDataFromTypes(
          types: _heartRateTypes,
          startTime: oneHourAgo,
          endTime: queryEnd,
        );
        result['recentHeartRateCount'] = recentHR.length;
        _debug('💓 Heart-rate points in the last hour: ${recentHR.length}');

        final todayHR = await _health.getHealthDataFromTypes(
          types: _heartRateTypes,
          startTime: dayStart,
          endTime: queryEnd,
        );
        result['todayHeartRateCount'] = todayHR.length;
        _debug('💓 Heart-rate points today: ${todayHR.length}');

        // Track unique sources + most recent timestamp
        DateTime? latest;
        for (final p in todayHR) {
          if (p.sourceName.isNotEmpty) {
            (result['dataSources'] as Set<String>).add(p.sourceName);
          }
          if (latest == null || p.dateTo.isAfter(latest)) {
            latest = p.dateTo;
          }
        }
        result['mostRecentDataPoint'] = latest;
        if (latest != null) {
          result['minutesSinceLastSync'] =
              now.difference(latest).inMinutes;
        }

        // Steps — the granular per-record query (`getHealthDataFromTypes`)
        // sometimes throws `IllegalArgumentException: startTime must be
        // before endTime` on Health Connect when a record has equal
        // start/end timestamps (a known Health Connect quirk on some
        // devices). Wrap it separately so we can still trust the
        // aggregated step total below.
        try {
          final stepPoints = await _health.getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: dayStart,
            endTime: now,
          );
          result['todayStepPoints'] = stepPoints.length;
          for (final p in stepPoints) {
            if (p.sourceName.isNotEmpty) {
              (result['dataSources'] as Set<String>).add(p.sourceName);
            }
          }
        } catch (e) {
          _warn(
            'Per-record STEPS query failed (known Health Connect quirk) — '
            'aggregated step total below is still reliable.',
            e,
          );
          (result['errors'] as List<String>).add('step points: $e');
        }

        final totalSteps =
            await _health.getTotalStepsInInterval(dayStart, now) ?? 0;
        result['todayStepsTotal'] = totalSteps;

        // 4. Did we see anything from a watch?
        // Heart-rate data with RecordingMethod.automatic is almost always
        // from a sensor (wearable, phone PPG, etc.).
        final automaticHR = todayHR
            .where((p) => p.recordingMethod == RecordingMethod.automatic)
            .toList();
        result['wearableDetected'] = automaticHR.isNotEmpty;

        _debug('📡 Unique data sources today: ${result['dataSources']}');
        _debug('⌚ Wearable detected (automatic HR data): '
            '${result['wearableDetected']}');
        if (result['minutesSinceLastSync'] != null) {
          _debug('⏱️  Minutes since last data point: '
              '${result['minutesSinceLastSync']}');
        }
      } catch (e, st) {
        _error('Diagnosis fetch failed', e, st);
        (result['errors'] as List<String>).add('fetch: $e');
      }
    } else {
      _warn('Skipping data probe — no permissions granted yet.');
    }

    // 5. Final summary
    _debug('───────────────── Diagnosis ─────────────────');
    _debug(' Platform               : ${result['platform']}');
    _debug(' Health Connect ready   : ${result['healthConnectInstalled']}');
    _debug(' Permissions granted    : ${result['hasPermissions']}');
    _debug(' Today HR points        : ${result['todayHeartRateCount']}');
    _debug(' Today step points      : ${result['todayStepPoints']}');
    _debug(' Today total steps      : ${result['todayStepsTotal']}');
    _debug(' Data sources (any)     : ${result['dataSources']}');
    _debug(' Wearable detected      : ${result['wearableDetected']}');
    _debug(' Mins since last sync   : ${result['minutesSinceLastSync']}');
    final sbt =
        (result['sourcesByType'] as Map<String, List<String>>?) ?? const {};
    if (sbt.isNotEmpty) {
      _debug(' ── Sources by type ──');
      sbt.forEach((k, v) {
        final marker = v.isEmpty ? '⚠️ NO DATA' : v.join(', ');
        _debug('   ${k.padRight(24)} : $marker');
      });
    }
    if ((result['errors'] as List).isNotEmpty) {
      _debug(' Errors                 : ${result['errors']}');
    }
    // Actionable suggestion based on the diagnosis
    final hrSources = _mergeSourceLists(
      (sbt['HEART_RATE'] as List?)?.cast<String>(),
      (sbt['RESTING_HEART_RATE'] as List?)?.cast<String>(),
    );
    final todaySteps = result['todayStepsTotal'] as int? ?? 0;
    final todayHr = result['todayHeartRateCount'] as int? ?? 0;
    if (result['hasPermissions'] == true && todayHr == 0) {
      if (todaySteps > 0) {
        _debug('💡 SUGGESTION: Steps are syncing ($todaySteps) but heart rate '
            'is empty. Your watch app is likely sharing steps only. Open Health '
            'Connect → Apps and services → your watch app → enable Heart rate '
            'and Resting heart rate (read + write). Then sync the watch.');
      } else if (hrSources.isEmpty) {
        _debug('💡 SUGGESTION: Health Connect has no HEART_RATE source. Your '
            'watch\'s companion app (Samsung Health / Mi Fitness / etc.) is '
            'probably not connected to Health Connect. Open Health Connect → '
            'Apps and services → enable your watch app, and turn on Heart rate.');
      }
    }
    _debug('═════════════════════════════════════════════');

    lastDiagnosis = result;
    return result;
  }

  // ──────────────────────────── Data Fetching ────────────────────────────

  /// Fetch all vitals for today and return a [HealthVitals] snapshot.
  static Future<HealthVitals> fetchAllVitals() async {
    await configure();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final yesterdayMidnight = midnight.subtract(const Duration(days: 1));
    final queryEnd = _queryEndTime(now);

    _debug('📥 Fetching all vitals — window: '
        '${midnight.toIso8601String()} → ${queryEnd.toIso8601String()}');

    await ensureExtendedAccess();

    // Run diagnosis so logs + UI have source context (also updates lastDiagnosis).
    final diagnosis = await diagnoseConnection();

    final sbt = (diagnosis['sourcesByType'] as Map<String, List<String>>?) ??
        const <String, List<String>>{};
    final hrSources = _mergeSourceLists(
      sbt['HEART_RATE'],
      sbt['RESTING_HEART_RATE'],
    );
    final calSources = sbt['ACTIVE_ENERGY_BURNED'] ?? const <String>[];
    final sleepSources = sbt['SLEEP_SESSION'] ?? const <String>[];
    final todayHrCount = diagnosis['todayHeartRateCount'] as int? ?? 0;

    var watchSources = _collectWatchSources(
      sbt,
      hrSources,
      calSources,
      sleepSources,
    );

    try {
      await ensureHeartRatePermissions();

      // Recover watch app names from step records when HR source probe is empty.
      if (watchSources.isEmpty) {
        watchSources = await _extractNonPhoneStepSources(midnight, queryEnd);
        if (watchSources.isNotEmpty) {
          _debug('⌚ Watch sources from step records: $watchSources');
        }
      }

      // Fetch HR first so we can recover watch source names before steps/calories.
      final latestHR = await _fetchLatestHeartRate(midnight, queryEnd);
      final avgHR = await _fetchAverageHeartRate(midnight, queryEnd);

      if (watchSources.isEmpty && (latestHR > 0 || todayHrCount > 0)) {
        watchSources = await _extractHrSources(midnight, queryEnd);
        if (watchSources.isNotEmpty) {
          _debug('⌚ Watch sources recovered from HR points: $watchSources');
        }
      }

      final results = await Future.wait([
        _fetchStepsForSources(midnight, queryEnd, watchSources),
        _fetchStepsForSources(yesterdayMidnight, midnight, watchSources),
        _fetchCaloriesForSources(midnight, queryEnd, watchSources),
        _fetchSleepDuration(yesterdayMidnight, queryEnd),
        _fetchYesterdaySleep(
            yesterdayMidnight.subtract(const Duration(days: 1)),
            yesterdayMidnight),
        _fetchTodayHydration(midnight, queryEnd),
      ]);

      final todaySteps = results[0] as int;
      final yesterdaySteps = results[1] as int;
      final calories = results[2] as int;
      final sleepDuration = results[3] as Duration;
      final yesterdaySleep = results[4] as Duration;
      final hydration = results[5] as double;

      final isConnected = latestHR > 0 ||
          avgHR > 0 ||
          todayHrCount > 0 ||
          diagnosis['wearableDetected'] == true ||
          hrSources.isNotEmpty ||
          calSources.isNotEmpty ||
          sleepSources.isNotEmpty;

      if (!isConnected) {
        _debug('⌚ No wearable data in Health Connect after full fetch.');
        return HealthVitals(
          lastSyncTime: now,
          isConnected: false,
        );
      }

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

      _debug('✅ Vitals fetch complete:');
      _debug('   steps=$todaySteps (yesterday=$yesterdaySteps, '
          'Δ=${todaySteps - yesterdaySteps})');
      _debug('   heartRate=$latestHR bpm (avg=$avgHR, status=$hrStatus)');
      _debug('   calories=$calories kcal');
      _debug('   sleep=${sleepDuration.inMinutes} min '
          '(yesterday=${yesterdaySleep.inMinutes} min)');
      _debug('   hydration=${hydration.toStringAsFixed(2)} L');
      _debug('   isConnected=true '
          '(HR sources=$hrSources, todayHrCount=$todayHrCount, '
          'calorie sources=$calSources, sleep sources=$sleepSources)');

      return vitals;
    } catch (e, st) {
      _error('Error fetching vitals', e, st);
      return HealthVitals(
        lastSyncTime: now,
        isConnected: false,
      );
    }
  }

  // ──────────────────────── Source helpers ────────────────────────

  /// Avoid Health Connect edge case where endTime equals the latest record time.
  static DateTime _queryEndTime(DateTime now) =>
      now.add(const Duration(seconds: 1));

  static List<String> _mergeSourceLists(
    List<String>? a,
    List<String>? b,
  ) {
    return <String>{...?a, ...?b}.where((s) => s.isNotEmpty).toList();
  }

  /// Non-phone apps that wrote step data (likely the watch companion).
  static Future<List<String>> _extractNonPhoneStepSources(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: from,
        endTime: to,
      );
      return data
          .map((p) => p.sourceName)
          .where((s) => s.isNotEmpty && !_isPhoneOnlySource(s))
          .toSet()
          .toList();
    } catch (e, st) {
      _warn('Step source extraction failed', e, st);
      return const [];
    }
  }

  /// Collect non-phone source names from recent heart-rate readings.
  static Future<List<String>> _extractHrSources(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: _heartRateTypes,
        startTime: from,
        endTime: to,
      );
      final sources = data
          .map((p) => p.sourceName)
          .where((s) => s.isNotEmpty && !_isPhoneOnlySource(s))
          .toSet()
          .toList();
      return sources;
    } catch (e, st) {
      _warn('HR source extraction failed', e, st);
      return const [];
    }
  }

  /// Apps that commonly write phone-only metrics into Health Connect.
  static const List<String> _phoneOnlySourcePatterns = [
    'google fit',
    'com.google.android.apps.fitness',
    'digital wellbeing',
    'android system',
    'device sensors',
    'com.google.android.gms',
    'com.google.android.apps.wellbeing',
  ];

  static bool _isPhoneOnlySource(String sourceName) {
    final lower = sourceName.toLowerCase();
    return _phoneOnlySourcePatterns.any((p) => lower.contains(p));
  }

  /// Union of wearable-related source names from the diagnosis map.
  static List<String> _collectWatchSources(
    Map<String, List<String>> sbt,
    List<String> hrSources,
    List<String> calSources,
    List<String> sleepSources,
  ) {
    final sources = <String>{
      ...hrSources,
      ...calSources,
      ...sleepSources,
      ...?sbt['STEPS'],
      ...?sbt['TOTAL_CALORIES_BURNED'],
      ...?sbt['SLEEP_ASLEEP'],
    };
    sources.removeWhere((s) => s.isEmpty || _isPhoneOnlySource(s));
    return sources.toList();
  }

  static bool _matchesWatchSource(HealthDataPoint point, List<String> sources) {
    if (sources.isEmpty) return true;
    return sources.contains(point.sourceName);
  }

  static int _sumNumericPoints(
    List<HealthDataPoint> points,
    List<String> watchSources,
  ) {
    double total = 0;
    for (final point in points) {
      if (!_matchesWatchSource(point, watchSources)) continue;
      if (point.value is NumericHealthValue) {
        total += (point.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    return total.round();
  }

  // ──────────────────────── Individual Fetchers ────────────────────────

  /// Aggregate logging helper used by each fetcher to summarise the data
  /// it just received (count, sources, recording methods).
  static void _summarisePoints(String label, List<HealthDataPoint> points) {
    if (points.isEmpty) {
      _debug('   [$label] no data points returned');
      return;
    }
    final sources = points.map((p) => p.sourceName).toSet();
    final methods = points.map((p) => p.recordingMethod.name).toSet();
    _debug('   [$label] ${points.length} points '
        '— sources=$sources, methods=$methods');
  }

  /// Sum step records that originate from the watch companion app(s).
  static Future<int> _fetchStepsForSources(
    DateTime from,
    DateTime to,
    List<String> watchSources,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: from,
        endTime: to,
      );
      final cleaned = _health.removeDuplicates(data);
      _summarisePoints('steps-watch', cleaned);
      final fromPoints = _sumNumericPoints(cleaned, watchSources);
      if (fromPoints > 0) {
        _debug('🚶 Steps from watch sources: $fromPoints');
        return fromPoints;
      }

      // Last resort: aggregated API (may include phone data — log loudly).
      final aggregated = await _health.getTotalStepsInInterval(from, to) ?? 0;
      _warn('Granular watch steps empty; aggregated fallback=$aggregated');
      return aggregated;
    } catch (e, st) {
      _warn('Watch steps fetch error', e, st);
      return 0;
    }
  }

  static Future<int> _fetchCaloriesForSources(
    DateTime from,
    DateTime to,
    List<String> watchSources,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.TOTAL_CALORIES_BURNED,
        ],
        startTime: from,
        endTime: to,
      );
      _summarisePoints('calories-watch', data);
      if (data.isEmpty) return 0;

      final cleaned = _health.removeDuplicates(data);
      final totalCal = cleaned
          .where((p) => p.type == HealthDataType.TOTAL_CALORIES_BURNED)
          .toList();
      if (totalCal.isNotEmpty) {
        final v = _sumNumericPoints(totalCal, watchSources);
        _debug('🔥 Calories (total) from watch: $v kcal');
        return v;
      }

      final active = _sumNumericPoints(cleaned, watchSources);
      _debug('🔥 Calories (active) from watch: $active kcal');
      return active;
    } catch (e, st) {
      _warn('Watch calories fetch error', e, st);
      return 0;
    }
  }

  static double _bpmFromPoint(HealthDataPoint point) {
    if (point.value is NumericHealthValue) {
      return (point.value as NumericHealthValue).numericValue.toDouble();
    }
    return 0;
  }

  /// Valid resting/working heart rate range (filters garbage readings).
  static bool _isPlausibleBpm(double bpm) => bpm >= 30 && bpm <= 250;

  /// Query each HR type separately and merge (combined queries can fail on
  /// some OEM Health Connect builds).
  static Future<List<HealthDataPoint>> _fetchAllHeartRatePoints(
    DateTime from,
    DateTime to,
  ) async {
    final merged = <HealthDataPoint>[];
    for (final type in _heartRateTypes) {
      try {
        final points = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: from,
          endTime: to,
        );
        _debug('💓 ${type.name} query: ${points.length} points '
            '(${from.toIso8601String()} → ${to.toIso8601String()})');
        merged.addAll(points);
      } catch (e, st) {
        _warn('HR query for ${type.name} failed', e, st);
      }
    }
    if (merged.length > 1) {
      return _health.removeDuplicates(merged);
    }
    return merged;
  }

  static double _latestBpmFromPoints(List<HealthDataPoint> data) {
    if (data.isEmpty) return 0;
    data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    for (final point in data) {
      final bpm = _bpmFromPoint(point);
      if (_isPlausibleBpm(bpm)) {
        _debug('💓 Latest HR: $bpm bpm from ${point.sourceName} '
            'at ${point.dateTo} (${point.type.name})');
        return bpm;
      }
    }
    return 0;
  }

  /// Fetch the most recent heart-rate reading.
  ///
  /// Tries today, then 24h, 7d, and 30d windows — watches often sync HR
  /// in batches and OEM apps may lag behind step sync.
  static Future<double> _fetchLatestHeartRate(
      DateTime dayStart, DateTime to) async {
    try {
      final windows = <(DateTime, String)>[
        (dayStart, 'today'),
        (to.subtract(const Duration(hours: 24)), 'last-24h'),
        (to.subtract(const Duration(days: 7)), 'last-7d'),
        (to.subtract(const Duration(days: 30)), 'last-30d'),
      ];

      for (final (from, label) in windows) {
        final data = await _fetchAllHeartRatePoints(from, to);
        _summarisePoints('latest-HR-$label', data);
        final bpm = _latestBpmFromPoints(data);
        if (bpm > 0) {
          _debug('💓 Latest HR $bpm bpm from $label window');
          return bpm;
        }
      }

      _debug('💓 No heart-rate data in Health Connect (today / 24h / 7d / 30d). '
          'Steps may sync from phone while HR requires watch → Health Connect.');
      return 0;
    } catch (e, st) {
      _warn('Heart rate fetch error', e, st);
      return 0;
    }
  }

  static Future<double> _fetchAverageHeartRate(
      DateTime from, DateTime to) async {
    try {
      final data = await _fetchAllHeartRatePoints(from, to);
      _summarisePoints('avg-HR', data);
      if (data.isEmpty) return 0;

      double sum = 0;
      int count = 0;
      for (final point in data) {
        final bpm = _bpmFromPoint(point);
        if (_isPlausibleBpm(bpm)) {
          sum += bpm;
          count++;
        }
      }
      final avg = count > 0 ? sum / count : 0.0;
      _debug('💓 Avg HR: $avg over $count readings');
      return avg;
    } catch (e, st) {
      _warn('Avg heart rate fetch error', e, st);
      return 0;
    }
  }

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
      _summarisePoints('sleep', data);
      if (data.isEmpty) return Duration.zero;

      final cleaned = _health.removeDuplicates(data);

      final sessions = cleaned
          .where((p) => p.type == HealthDataType.SLEEP_SESSION)
          .toList();
      if (sessions.isNotEmpty) {
        Duration total = Duration.zero;
        for (final session in sessions) {
          total += session.dateTo.difference(session.dateFrom);
        }
        _debug('💤 Sleep (sessions): ${total.inMinutes} min '
            'over ${sessions.length} sessions');
        return total;
      }

      final asleepData = cleaned
          .where((p) => p.type == HealthDataType.SLEEP_ASLEEP)
          .toList();
      if (asleepData.isNotEmpty) {
        Duration total = Duration.zero;
        for (final sleep in asleepData) {
          total += sleep.dateTo.difference(sleep.dateFrom);
        }
        _debug('💤 Sleep (asleep): ${total.inMinutes} min');
        return total;
      }

      return Duration.zero;
    } catch (e, st) {
      _warn('Sleep fetch error', e, st);
      return Duration.zero;
    }
  }

  static Future<Duration> _fetchYesterdaySleep(
      DateTime from, DateTime to) async {
    return _fetchSleepDuration(from, to);
  }

  static Future<double> _fetchTodayHydration(
      DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: from,
        endTime: to,
      );
      _summarisePoints('hydration', data);
      if (data.isEmpty) return 0;

      final cleaned = _health.removeDuplicates(data);

      double totalLiters = 0;
      for (final point in cleaned) {
        if (point.value is NumericHealthValue) {
          totalLiters +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      _debug('💧 Hydration: ${totalLiters.toStringAsFixed(2)} L');
      return totalLiters;
    } catch (e, st) {
      _warn('Hydration fetch error', e, st);
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
        endTime: now.add(const Duration(seconds: 1)),
      );
      if (success) {
        _debug('💧 Wrote ${liters}L of water at $now');
      } else {
        _warn('💧 writeWater returned false for ${liters}L');
      }
      return success;
    } catch (e, st) {
      _error('Error writing water', e, st);
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
      if (success) {
        _debug('🏋️ Workout written: $type ($start → $end)');
      } else {
        _warn('🏋️ writeWorkout returned false for $type');
      }
      return success;
    } catch (e, st) {
      _error('Error writing workout', e, st);
      return false;
    }
  }
}
