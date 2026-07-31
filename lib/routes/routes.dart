enum AppRoutes {
  onboardingScreen('onboarding_screen'),
  homeScreen('home_screen'),
  chatScreen('chat_screen'),
  editProfileScreen('edit_profile_screen'),
  recommendationsScreen('recommendations_screen');

  const AppRoutes(this.path);

  final String path;
}
