import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/features/home.dart';
import 'package:upgrade/features/onboarding/onboarding.dart';
import 'package:upgrade/llm_model_check.dart';
import 'package:upgrade/providers/llm_pro.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/routes/navigation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    checkModelAndIntialize();
    super.initState();
  }

  checkModelAndIntialize() async {
    await ref.read(llmProvider.notifier).checkAvailability();

    final isUserDataAvailable = ref.read(userProfileProvider).build() != null;

    if (isUserDataAvailable) {
      Navigation.instance.pushAndRemoveUntil(HomeScreen.id.path);
    } else {
      Navigation.instance.pushAndRemoveUntil(OnboardingFlow.id.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
