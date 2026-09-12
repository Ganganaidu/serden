import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/utils/onboarding_prefs.dart';
import 'core/widgets/app_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace Flutter's red-screen widget with Serden's branded error screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorScreen(
      message: kDebugMode ? details.summary.toString() : null,
    );
  };

  // Log framework errors (and re-present in debug so the console still shows them).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Catch uncaught async / Dart errors from PlatformDispatcher.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true; // mark as handled — prevents OS-level crash dialogs
  };

  // Lock to portrait on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await OnboardingPrefs.init();
  Injection.init();

  runApp(const SerdenApp());
}
