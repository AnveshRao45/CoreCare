import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:upgrade/features/home.dart';
import 'package:upgrade/features/search.dart';
import 'package:upgrade/features/chat_screen.dart';
import 'package:upgrade/routes/routes.dart';
// import 'package:upgrade/features/login.dart'; // assuming you have a LoginScreen

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings route) {
    const PageTransitionType style = PageTransitionType.fade;

    PageTransition pageTransition(Widget child) {
      return PageTransition(child: child, type: style, settings: route);
    }

    if (route.name == AppRoutes.homeScreen.path) {
      return pageTransition(const HomeScreen());
    } else if (route.name == AppRoutes.searchScreen.path) {
      return pageTransition(const SearchScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('No view defined for this route')),
        ),
      );
    }
  }
}
