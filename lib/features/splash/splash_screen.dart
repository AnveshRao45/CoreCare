import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/features/home.dart';
import 'package:upgrade/features/onboarding/onboarding.dart';
import 'package:upgrade/providers/llm_pro.dart';
import 'package:upgrade/routes/navigation.dart';
import 'package:upgrade/services/hive_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    try {
      await ref.read(llmProvider.notifier).checkAvailability();

      final complete = HiveService.isOnboardingComplete;
      final hasProfile = HiveService.hasUserProfile;

      if (!mounted) return;

      if (complete || hasProfile) {
        Navigation.instance.pushAndRemoveUntil(HomeScreen.id.path);
      } else {
        Navigation.instance.pushAndRemoveUntil(OnboardingFlow.id.path);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9947EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text(
              'CoreCare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your health & nutrition companion',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            else
              const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
