import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefs {
  static const _key = 'onboarding_seen';
  static bool _seen = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool(_key) ?? false;
  }

  static bool get seen => _seen;

  static Future<void> markSeen() async {
    _seen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
