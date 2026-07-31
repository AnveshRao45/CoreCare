import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'dart:math' as math;
import '../../models/health_vitals.dart';
import '../../providers/health_provider.dart';
import '../../services/health_service.dart';

class VitalsSection extends ConsumerWidget {
  const VitalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(healthVitalsProvider);
    final hasPermission = ref.watch(healthPermissionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Vitals from Wearables",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  if (!hasPermission) {
                    final granted = await ref
                        .read(healthVitalsProvider.notifier)
                        .requestPermissions();
                    if (!granted) return;
                  }
                  await ref.read(healthVitalsProvider.notifier).refresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vitals refreshed from Health Connect'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: 'Refresh vitals',
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF718096),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          vitalsAsync.when(
            loading: () => _buildLoadingState(),
            error: (error, _) => _buildErrorState(error, ref),
            data: (vitals) {
              if (!vitals.isConnected) {
                return _buildNotConnectedState(context, ref);
              }
              return _buildConnectedState(vitals, ref);
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────── Connected State ───────────────────

  Widget _buildConnectedState(HealthVitals vitals, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(height: 120, child: HydrationCard(vitals: vitals, ref: ref)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          // 0.95 gives slightly taller cells than wide so the
          // progress-ring + label + value + footer column always fits
          // without RenderFlex overflow on smaller phones.
          childAspectRatio: 0.95,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            HeartRateCard(vitals: vitals),
            StepsCard(vitals: vitals),
            CaloriesCard(vitals: vitals),
            SleepCard(vitals: vitals),
          ],
        ),
        const SizedBox(height: 8),
        _buildDeviceChip(ref),
        _buildLastSyncInfo(vitals),
      ],
    );
  }

  /// Tiny chip that shows the names of the data sources currently feeding
  /// the app (e.g. "Galaxy Watch", "Mi Fitness"). Helps the user (and you,
  /// during debugging) confirm a wearable is actually connected.
  ///
  /// We specifically surface HEART_RATE sources when available because
  /// they're the strongest signal that a wearable (not just the phone) is
  /// pushing data. Falls back to step / general sources otherwise.
  Widget _buildDeviceChip(WidgetRef ref) {
    final diagnosis = ref.watch(healthDiagnosisProvider);
    final sbt = (diagnosis['sourcesByType'] as Map?)
            ?.cast<String, List<dynamic>>() ??
        const {};

    final hrSources = [
      ...?sbt['HEART_RATE']?.cast<String>(),
      ...?sbt['RESTING_HEART_RATE']?.cast<String>(),
    ];
    final stepSources =
        sbt['STEPS']?.cast<String>() ?? const <String>[];
    final allSources =
        (diagnosis['dataSources'] as Set?)?.cast<String>() ?? const <String>{};

    final shown =
        hrSources.isNotEmpty ? hrSources : (allSources.toList());
    if (shown.isEmpty) {
      // Permissions OK but no source — show a warning chip so the user can
      // tap "Run diagnosis" to see exactly which metric is missing.
      if (diagnosis['hasPermissions'] == true) {
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 12, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                'No watch connected to Health Connect',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final wearable = hrSources.isNotEmpty;
    final minutes = diagnosis['minutesSinceLastSync'] as int?;

    // If steps and HR come from different apps, show both so the user can
    // see e.g. "Galaxy Watch (HR)  ·  Google Fit (steps)".
    String label;
    if (hrSources.isNotEmpty &&
        stepSources.isNotEmpty &&
        !stepSources.toSet().containsAll(hrSources.toSet())) {
      label =
          '${hrSources.join(", ")} (HR) · ${stepSources.join(", ")} (steps)';
    } else {
      label = shown.join(', ');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            wearable ? Icons.watch : Icons.phone_android,
            size: 12,
            color: wearable ? Colors.green : Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              minutes != null && minutes < 120
                  ? '$label  ·  ${minutes}m ago'
                  : label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSyncInfo(HealthVitals vitals) {
    final diff = DateTime.now().difference(vitals.lastSyncTime);
    String syncText;
    if (diff.inMinutes < 1) {
      syncText = 'Just now';
    } else if (diff.inMinutes < 60) {
      syncText = '${diff.inMinutes}m ago';
    } else {
      syncText = '${diff.inHours}h ago';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sync, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          'Last synced: $syncText',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // ─────────────────── Not Connected State ───────────────────

  Widget _buildNotConnectedState(BuildContext context, WidgetRef ref) {
    final sdkAsync = ref.watch(healthConnectSdkStatusProvider);
    final diagnosis = ref.watch(healthDiagnosisProvider);
    final hasPermission = ref.watch(healthPermissionProvider);

    return sdkAsync.when(
      loading: () => _buildShimmerCard(height: 220),
      error: (e, _) => _buildNotConnectedShell(
        context: context,
        ref: ref,
        title: 'Health setup failed',
        subtitle: 'Could not check Health Connect status.\n$e',
        buttonLabel: 'Retry',
        onPressed: () => ref.invalidate(healthConnectSdkStatusProvider),
      ),
      data: (status) {
        // 1. Health Connect missing on Android → offer install
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          return _buildNotConnectedShell(
            context: context,
            ref: ref,
            title: 'Install Health Connect',
            subtitle:
                'Google Health Connect is required to read data from your '
                'smartwatch or fitness band on Android.',
            buttonLabel: 'Install Health Connect',
            buttonIcon: Icons.shop,
            onPressed: () async {
              await ref
                  .read(healthVitalsProvider.notifier)
                  .installHealthConnect();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'After installing, return to the app and tap "Connect Health Data".',
                    ),
                    backgroundColor: Color(0xFF9947EB),
                  ),
                );
              }
            },
          );
        }
        if (status ==
            HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          return _buildNotConnectedShell(
            context: context,
            ref: ref,
            title: 'Update Health Connect',
            subtitle:
                'Your version of Health Connect needs updating before the '
                'app can read wearable data.',
            buttonLabel: 'Update Health Connect',
            buttonIcon: Icons.system_update,
            onPressed: () =>
                ref.read(healthVitalsProvider.notifier).installHealthConnect(),
          );
        }

        // 2. SDK available but app permissions missing → ask for permissions
        if (!hasPermission) {
          return _buildNotConnectedShell(
            context: context,
            ref: ref,
            title: 'Connect Your Wearable',
            subtitle:
                'Link your smartwatch or fitness band to see real-time vitals '
                'like heart rate, steps, and sleep.',
            buttonLabel: 'Connect Health Data',
            buttonIcon: Icons.link,
            extraDiagnostics: diagnosis,
            onPressed: () async {
              final granted = await ref
                  .read(healthVitalsProvider.notifier)
                  .requestPermissions();
              if (!granted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Health permissions required. Open Health Connect in Settings to grant access.',
                    ),
                    backgroundColor: Color(0xFFFF8A50),
                  ),
                );
              }
            },
          );
        }

        // 3. App permissions are granted but no wearable is currently
        // feeding HR/calorie/sleep data into Health Connect.
        //    → user's watch companion app isn't connected to Health Connect.
        return _buildNotConnectedShell(
          context: context,
          ref: ref,
          title: 'No watch detected',
          subtitle: 'Your watch shows HR on its face but it isn\'t sharing '
              'that data with Health Connect yet. The watch\'s companion app '
              '(Samsung Health, Mi Fitness, Huawei Health, HeyTap Health, '
              'Garmin Connect, etc.) has to explicitly turn the Health '
              'Connect bridge on. Tap "How do I do this?" below for '
              'step-by-step instructions.',
          buttonLabel: 'Open Health Connect',
          buttonIcon: Icons.open_in_new,
          extraDiagnostics: diagnosis,
          phoneOnlyDataBanner: _buildPhoneOnlyDataBanner(ref),
          extraContent: _buildHowToConnectGuide(),
          onPressed: () async {
            await HealthService.openHealthConnectSettings();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'After enabling your watch app inside Health Connect, return here and tap Refresh.',
                  ),
                  backgroundColor: Color(0xFF9947EB),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
        );
      },
    );
  }

  /// Small banner shown inside the "No watch detected" state that surfaces
  /// any phone-only data Health Connect already has (typically steps from
  /// Google Fit / the system step counter). Lets the user know their phone
  /// is still tracking *something*, even if a watch isn't connected.
  Widget? _buildPhoneOnlyDataBanner(WidgetRef ref) {
    final diagnosis = ref.watch(healthDiagnosisProvider);
    final steps = diagnosis['todayStepsTotal'] as int? ?? 0;
    final sbt = (diagnosis['sourcesByType'] as Map?)
            ?.cast<String, List<dynamic>>() ??
        const {};
    final stepSources =
        sbt['STEPS']?.cast<String>() ?? const <String>[];
    if (steps <= 0) return null;
    final sourceLabel =
        stepSources.isNotEmpty ? stepSources.join(', ') : 'phone';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 11, height: 1.4),
                children: [
                  const TextSpan(
                    text: 'Phone is tracking ',
                    style: TextStyle(color: Color(0xFF2D2D2D)),
                  ),
                  TextSpan(
                    text: '$steps steps',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  TextSpan(
                    text: ' today via $sourceLabel.',
                    style: const TextStyle(color: Color(0xFF2D2D2D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Brand-specific "how do I do this?" expandable section.
  ///
  /// Most users get stuck because each watch brand hides the Health Connect
  /// toggle in a different place. This widget shows step-by-step
  /// instructions per brand so the user can find the toggle in seconds.
  Widget _buildHowToConnectGuide() {
    final guides = const <_BrandGuide>[
      _BrandGuide(
        brand: 'Samsung Galaxy Watch',
        app: 'Samsung Health',
        steps: [
          'Open Samsung Health on your phone.',
          'Tap the ☰ menu (top-left) → Settings.',
          'Tap "Health Connect".',
          'Toggle ON the data types you want to share (Heart rate, '
              'Steps, Sleep, Active calories).',
          'Wait a minute and tap Refresh in this app.',
        ],
      ),
      _BrandGuide(
        brand: 'Xiaomi / Mi Band / Redmi Watch',
        app: 'Mi Fitness  (or Zepp Life)',
        steps: [
          'Open Mi Fitness on your phone.',
          'Tap Profile (bottom-right) → Settings.',
          'Tap "Privacy" → "Health Connect" → "Authorize".',
          'Turn ON every data type your band tracks.',
          'Pull-to-refresh inside Mi Fitness to push the data.',
          'Return to this app and tap Refresh.',
        ],
      ),
      _BrandGuide(
        brand: 'Huawei Watch / Band',
        app: 'Huawei Health',
        steps: [
          'Open Huawei Health.',
          'Tap "Me" → "Settings" → "Data sharing".',
          'Tap "Health Connect" and turn it on.',
          'Grant write permissions for HR, Steps, Sleep, Calories.',
          'Return to this app and tap Refresh.',
        ],
      ),
      _BrandGuide(
        brand: 'OPPO / Realme / OnePlus Watch',
        app: 'HeyTap Health',
        steps: [
          'Open HeyTap Health on your phone.',
          'Tap "Me" → "Settings" → "Permission".',
          'Tap "Health Connect" → enable it.',
          'Allow it to write all data types.',
          'Return to this app and tap Refresh.',
        ],
      ),
      _BrandGuide(
        brand: 'Google Pixel Watch / Fitbit',
        app: 'Fitbit',
        steps: [
          'Open Fitbit on your phone.',
          'Tap "You" tab (bottom-right) → tap your profile photo.',
          'Tap "Manage data" → "Health Connect".',
          'Toggle ON "Sync to Health Connect".',
          'Pull-to-refresh on the Fitbit Today tab.',
          'Return to this app and tap Refresh.',
        ],
      ),
      _BrandGuide(
        brand: 'Garmin watch / band',
        app: 'Garmin Connect',
        steps: [
          'Open Garmin Connect on your phone.',
          'Tap "More" (bottom-right) → Settings → "Connected Apps".',
          'Tap "Health Connect" → Sign in / Authorize.',
          'Allow it to write HR, Steps, Sleep, Calories.',
          'Return to this app and tap Refresh.',
        ],
      ),
      _BrandGuide(
        brand: 'Amazfit / Zepp watch',
        app: 'Zepp',
        steps: [
          'Open Zepp on your phone.',
          'Tap "Profile" → "Settings" → "Privacy".',
          'Tap "Health Connect" → enable.',
          'Grant write permissions.',
          'Return to this app and tap Refresh.',
        ],
      ),
      _BrandGuide(
        brand: 'Other / unsure',
        app: 'Your watch\'s companion app',
        steps: [
          'Open the app that came with your watch / band.',
          'Look under: Settings → Data / Privacy / Connections.',
          'Find "Health Connect" — turn it on and allow writes for Heart '
              'rate, Steps, Sleep, Calories.',
          'If you don\'t see a Health Connect option, the watch brand '
              'probably doesn\'t support Health Connect yet (some cheap '
              'no-name brands).',
          'Return to this app and tap Refresh.',
        ],
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DBFF)),
      ),
      child: Theme(
        // Hide the default ExpansionTile divider lines.
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(Icons.help_outline, color: Color(0xFF9947EB)),
          title: const Text(
            'How do I do this?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          subtitle: Text(
            'Step-by-step for your watch brand',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          children: guides
              .map(
                (g) => Theme(
                  data: ThemeData(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(20, 0, 8, 8),
                    title: Text(
                      g.brand,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    subtitle: Text(
                      'Companion app: ${g.app}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    children: [
                      for (var i = 0; i < g.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                margin:
                                    const EdgeInsets.only(top: 1, right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF9947EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  g.steps[i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color: Color(0xFF3D3D3D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Shared "not connected" card chrome. Customisable title, subtitle and
  /// button so we can reuse it for the install/update/permission flows.
  Widget _buildNotConnectedShell({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
    IconData buttonIcon = Icons.link,
    Map<String, dynamic>? extraDiagnostics,
    Widget? phoneOnlyDataBanner,
    Widget? extraContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF0E6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.watch,
              color: Color(0xFF9947EB),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          if (phoneOnlyDataBanner != null) phoneOnlyDataBanner,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 20),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9947EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Open Health Connect settings directly — most useful when the
          // user's watch app is installed but not connected to HC yet.
          if (Theme.of(context).platform == TargetPlatform.android)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await HealthService.openHealthConnectSettings();
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open Health Connect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9947EB),
                  side: const BorderSide(color: Color(0xFF9947EB)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Diagnosis button — opens a dialog showing per-type sources so
          // the user can see *which* apps are feeding Health Connect.
          TextButton.icon(
            onPressed: () async {
              final d = await HealthService.diagnoseConnection();
              ref.read(healthDiagnosisProvider.notifier).update(d);
              if (context.mounted) _showDiagnosisDialog(context, d);
            },
            icon: const Icon(Icons.bug_report_outlined, size: 14),
            label: const Text('Run diagnosis'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              textStyle: const TextStyle(fontSize: 11),
            ),
          ),
          if (extraContent != null) extraContent,
          if (extraDiagnostics != null && extraDiagnostics.isNotEmpty)
            _buildDiagnosticsLine(extraDiagnostics),
          Text(
            'Supports Google Health Connect & Apple HealthKit',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsLine(Map<String, dynamic> d) {
    final sources =
        (d['dataSources'] as Set?)?.cast<String>() ?? const <String>{};
    final lines = <String>[];
    if (d['hasPermissions'] != null) {
      lines.add('Permissions: ${d['hasPermissions'] == true ? "OK" : "missing"}');
    }
    if (sources.isNotEmpty) {
      lines.add('Found sources: ${sources.join(", ")}');
    } else if (d['hasPermissions'] == true) {
      lines.add('No data sources visible yet.');
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        lines.join('  ·  '),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Detailed diagnosis dialog. For each metric, shows which apps are
  /// feeding data into Health Connect — the smoking-gun for "why doesn't
  /// my watch show up?".
  void _showDiagnosisDialog(BuildContext context, Map<String, dynamic> d) {
    final sourcesByType =
        (d['sourcesByType'] as Map?)?.cast<String, List<dynamic>>() ?? const {};
    final hrSources =
        sourcesByType['HEART_RATE']?.cast<String>() ?? const <String>[];
    final hasPerms = d['hasPermissions'] == true;
    final hcReady = d['healthConnectInstalled'] == true;

    String advice;
    if (!hcReady) {
      advice =
          'Health Connect is not installed. Tap "Install Health Connect" first.';
    } else if (!hasPerms) {
      advice =
          'This app does not have permission to read Health Connect data. '
          'Tap "Connect Health Data" to grant access.';
    } else if (hrSources.isEmpty) {
      advice =
          'Health Connect has no heart-rate source. Your watch shows HR in '
          'its own app, but that app is not sharing data with Health Connect. '
          'Open your watch\'s companion app (Samsung Health / Mi Fitness / '
          'Huawei Health / Garmin / Fitbit etc.) and turn on the Health '
          'Connect integration, then come back here and tap Refresh.';
    } else {
      advice =
          'All looks good. If a value is still wrong, open Health Connect → '
          '"Data and access" → check which apps are writing each metric and '
          'disable any duplicates.';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report_outlined,
                  size: 18, color: Color(0xFF5C6BC0)),
              SizedBox(width: 8),
              Text('Health diagnosis', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _diagRow('Health Connect installed', hcReady),
                _diagRow('Permissions granted', hasPerms),
                _diagRow('Wearable detected',
                    d['wearableDetected'] == true),
                if (d['minutesSinceLastSync'] != null)
                  _diagRow(
                      'Minutes since last data',
                      true,
                      detail: '${d['minutesSinceLastSync']} min ago'),
                const SizedBox(height: 12),
                const Text(
                  'Sources by data type:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                if (sourcesByType.isEmpty)
                  Text(
                    hasPerms
                        ? 'No data of any kind is being written to Health Connect.'
                        : 'Grant permissions first to enumerate sources.',
                    style: const TextStyle(fontSize: 11),
                  )
                else
                  ...sourcesByType.entries.map(
                    (e) {
                      final names = e.value.cast<String>();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              names.isEmpty
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle,
                              size: 14,
                              color: names.isEmpty
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${_humanizeType(e.key)}: ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11),
                                    ),
                                    TextSpan(
                                      text: names.isEmpty
                                          ? 'no source'
                                          : names.join(', '),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: names.isEmpty
                                              ? Colors.orange.shade800
                                              : Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          advice,
                          style: const TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await HealthService.openHealthConnectSettings();
              },
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open Health Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9947EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _diagRow(String label, bool ok, {String? detail}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
          if (detail != null) ...[
            const Spacer(),
            Text(detail,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  /// Turn a HealthDataType.name into a friendlier label
  /// (e.g. "TOTAL_CALORIES_BURNED" → "Total calories").
  String _humanizeType(String name) {
    final lower = name.toLowerCase().replaceAll('_', ' ');
    return lower[0].toUpperCase() + lower.substring(1);
  }

  // ─────────────────── Loading State ───────────────────

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildShimmerCard(height: 120),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (_) => _buildShimmerCard()),
        ),
      ],
    );
  }

  Widget _buildShimmerCard({double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Error State ───────────────────

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Could not load vitals',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.read(healthVitalsProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Individual Vital Cards — now driven by HealthVitals data
// ════════════════════════════════════════════════════════════

// Heart Rate
class HeartRateCard extends StatelessWidget {
  final HealthVitals vitals;
  const HeartRateCard({super.key, required this.vitals});

  @override
  Widget build(BuildContext context) {
    final hasData = vitals.heartRate > 0;
    final stepsWithoutHr = vitals.steps > 0 && !hasData;
    final hrText = hasData ? vitals.heartRate.round().toString() : '--';
    final avgText = vitals.heartRateAvg > 0
        ? 'Avg: ${vitals.heartRateAvg.round()}'
        : hasData
            ? 'Last reading'
            : stepsWithoutHr
                ? 'HR not in Health Connect'
                : 'No watch data';
    final statusText = hasData
        ? vitals.heartRateStatus
        : stepsWithoutHr
            ? 'Enable HR sync'
            : 'Connect watch';
    final statusColor = vitals.heartRateStatus == 'Normal'
        ? Colors.green
        : vitals.heartRateStatus == 'High'
            ? Colors.red
            : vitals.heartRateStatus == 'Low'
                ? Colors.blue
                : Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: stepsWithoutHr
            ? () => HealthService.openHealthConnectSettings()
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFEE2E2), Color(0xFFF8D0D0)],
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFEF5350),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Heart Rate",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: "$hrText ",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  children: [
                    TextSpan(
                      text: hasData ? "bpm" : "",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  avgText,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// Steps
class StepsCard extends StatelessWidget {
  final HealthVitals vitals;
  const StepsCard({super.key, required this.vitals});

  @override
  Widget build(BuildContext context) {
    final changeColor =
        vitals.stepsChange >= 0 ? Colors.green : Colors.red;
    final changeText = vitals.stepsChange != 0
        ? vitals.stepsChangeFormatted
        : 'No data yet';

    return _vitalCard(
      icon: Icons.directions_walk,
      iconColor: const Color(0xFF66BB6A),
      label: "Steps",
      mainValue: _formatNumber(vitals.steps),
      subValue: "/${_formatNumber(vitals.stepGoal)}",
      footer: changeText,
      footerColor: changeColor,
      progress: vitals.stepsProgress,
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

// Calories
class CaloriesCard extends StatelessWidget {
  final HealthVitals vitals;
  const CaloriesCard({super.key, required this.vitals});

  @override
  Widget build(BuildContext context) {
    return _vitalCardWithBar(
      icon: Icons.local_fire_department,
      iconColor: const Color(0xFFFFA726),
      label: "Calories Burned",
      mainValue: _formatNumber(vitals.caloriesBurned),
      subValue: "/${_formatNumber(vitals.caloriesGoal)}",
      footer: vitals.caloriesProgress >= 0.6 ? "Great progress!" : "Keep going!",
      footerColor: Colors.amber.shade700,
      progress: vitals.caloriesProgress,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }
}

// Sleep
class SleepCard extends StatelessWidget {
  final HealthVitals vitals;
  const SleepCard({super.key, required this.vitals});

  @override
  Widget build(BuildContext context) {
    final sleepHours = vitals.sleepDuration.inHours;
    final idealSleep = 8.0;
    final progress = (sleepHours / idealSleep).clamp(0.0, 1.0);
    final changeText = vitals.sleepChangeFormatted.isNotEmpty
        ? vitals.sleepChangeFormatted
        : 'No comparison data';

    return _vitalCardWithBar(
      icon: Icons.bedtime,
      iconColor: const Color(0xFF5C6BC0),
      label: "Sleep",
      mainValue: vitals.sleepFormatted,
      subValue: "",
      footer: changeText,
      footerColor: Colors.green,
      progress: progress,
      gradient: const LinearGradient(
        colors: [Color(0xFF7986CB), Color(0xFF5C6BC0)],
      ),
    );
  }
}

// Hydration
class HydrationCard extends StatelessWidget {
  final HealthVitals vitals;
  final WidgetRef ref;
  const HydrationCard({super.key, required this.vitals, required this.ref});

  @override
  Widget build(BuildContext context) {
    final fillFactor = vitals.hydrationProgress.clamp(0.0, 1.0);

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hydration",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text.rich(
                    TextSpan(
                      text: vitals.hydrationLiters.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: "/${vitals.hydrationGoal.toStringAsFixed(0)}L",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  ref.read(healthVitalsProvider.notifier).addWater(0.25);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('+250ml logged'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xFF42A5F5),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF42A5F5), size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Icon(
                  Icons.water_drop,
                  size: 50,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: fillFactor,
                    child: const Icon(
                      Icons.water_drop,
                      size: 50,
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _hydrationButton(context, "+250ml", 0.25),
              _hydrationButton(context, "+500ml", 0.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hydrationButton(BuildContext context, String label, double liters) {
    return TextButton(
      onPressed: () {
        ref.read(healthVitalsProvider.notifier).addWater(liters);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label logged'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF42A5F5),
          ),
        );
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF42A5F5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════ Shared Helpers ═══════════════════════════════

Widget _vitalCard({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String mainValue,
  required String subValue,
  required String footer,
  required Color footerColor,
  required double progress,
}) {
  return Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(10),
    // LayoutBuilder lets the ring scale down on small cells; Flexible
    // children + FittedBox guarantee we can never overflow vertically.
    child: LayoutBuilder(
      builder: (context, constraints) {
        final ringSize =
            (constraints.maxHeight * 0.45).clamp(40.0, 60.0).toDouble();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(
                  size: Size(ringSize, ringSize),
                  painter: _ProgressRingPainter(
                      progress: progress, color: iconColor),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: ringSize * 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    text: mainValue,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: subValue,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                footer,
                style: TextStyle(
                  fontSize: 9,
                  color: footerColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _vitalCardWithBar({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String mainValue,
  required String subValue,
  required String footer,
  required Color footerColor,
  required double progress,
  required Gradient gradient,
}) {
  return Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: mainValue,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: subValue,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            footer,
            style: TextStyle(
              fontSize: 10,
              color: footerColor,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(2, 4),
        ),
      ],
    );

// ═══════════════════════════ Custom Painters ═══════════════════════════

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

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
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Brand-specific guide entry used by the "How do I do this?" accordion
/// inside the "No watch detected" card.
class _BrandGuide {
  final String brand;
  final String app;
  final List<String> steps;

  const _BrandGuide({
    required this.brand,
    required this.app,
    required this.steps,
  });
}
