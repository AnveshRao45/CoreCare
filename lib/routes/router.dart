import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:upgrade/features/ai_chat_screen.dart';
import 'package:upgrade/features/edit_profile_screen.dart';
import 'package:upgrade/features/home.dart';
import 'package:upgrade/features/onboarding/onboarding.dart';
import 'package:upgrade/features/recommendations_screen.dart';
import 'package:upgrade/routes/routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings route) {
    const PageTransitionType style = PageTransitionType.fade;

    PageTransition pageTransition(Widget child) {
      return PageTransition(child: child, type: style, settings: route);
    }

    if (route.name == AppRoutes.homeScreen.path) {
      return pageTransition(const HomeScreen());
    } else if (route.name == AppRoutes.chatScreen.path) {
      return pageTransition(const AiChatScreen());
    } else if (route.name == AppRoutes.onboardingScreen.path) {
      return pageTransition(const OnboardingFlow());
    } else if (route.name == AppRoutes.editProfileScreen.path) {
      return pageTransition(const EditProfileScreen());
    } else if (route.name == AppRoutes.recommendationsScreen.path) {
      return pageTransition(const RecommendationsScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('No view defined for this route')),
        ),
      );
    }
  }
}
