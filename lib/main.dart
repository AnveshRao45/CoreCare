import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:upgrade/features/splash/splash_screen.dart';
import 'package:upgrade/routes/navigation.dart';
import 'package:upgrade/routes/router.dart';
import 'package:upgrade/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    debugPrint(
      '${rec.loggerName}>${rec.level.name}: ${rec.time}: ${rec.message}',
    );
  });

  await HiveService.init();

  runApp(const ProviderScope(child: CoreCareApp()));
}

class CoreCareApp extends StatelessWidget {
  const CoreCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoreCare',
      debugShowCheckedModeBanner: false,
      navigatorKey: Navigation.instance.navigationKey,
      onGenerateRoute: AppRouter.generateRoute,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9947EB)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
