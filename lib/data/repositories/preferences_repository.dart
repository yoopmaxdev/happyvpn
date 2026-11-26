import '../../domain/models/app_preferences.dart';
import '../services/preferences_storage_service.dart';

class PreferencesRepository {
  PreferencesRepository({required this.storage});

  final PreferencesStorageService storage;
  AppPreferences _cached = AppPreferences.defaults;

  AppPreferences get current => _cached;

  Future<AppPreferences> load() async {
    _cached = await storage.load();
    return _cached;
  }

  Future<AppPreferences> update(AppPreferences next) async {
    _cached = next;
    await storage.save(next);
    return _cached;
  }

  Future<AppPreferences> resetPreferences() async {
    _cached = _cached.copyWith(
      themePreference: AppThemePreference.system,
      selectedServerId: 'auto',
      favoriteServerIds: const <String>{},
      showServerLatency: true,
      hapticFeedback: true,
      vpnNotifications: true,
      proxyAllApps: true,
      proxiedAppIds: const <String>{},
    );
    await storage.save(_cached);
    return _cached;
  }

  Future<AppPreferences> deleteAllAppData() async {
    await storage.clearAll();
    _cached = AppPreferences.defaults;
    return _cached;
  }
}
