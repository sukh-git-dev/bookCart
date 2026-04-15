import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesRepository {
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _themePaletteIdKey = 'theme_palette_id';

  SharedPreferences? _preferences;

  Future<SharedPreferences?> _instance() async {
    if (_preferences != null) {
      return _preferences;
    }

    try {
      _preferences = await SharedPreferences.getInstance();
      return _preferences;
    } catch (_) {
      return null;
    }
  }

  Future<bool> readOnboardingCompleted() async {
    final preferences = await _instance();
    return preferences?.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> writeOnboardingCompleted(bool value) async {
    final preferences = await _instance();
    await preferences?.setBool(_onboardingCompletedKey, value);
  }

  Future<String?> readThemePaletteId() async {
    final preferences = await _instance();
    return preferences?.getString(_themePaletteIdKey);
  }

  Future<void> writeThemePaletteId(String paletteId) async {
    final preferences = await _instance();
    await preferences?.setString(_themePaletteIdKey, paletteId);
  }
}
