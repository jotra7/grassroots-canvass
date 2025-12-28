import '../config/analytics_config.dart';

enum AnalyticsEvent {
  signUp('sign_up'),
  signIn('sign_in'),
  signOut('sign_out'),
  votersLoaded('voters_loaded'),
  voterViewed('voter_viewed'),
  votersLoadedFromArea('voters_loaded_from_area'),
  canvassResultSaved('canvass_result_saved'),
  voterInfoUpdated('voter_info_updated'),
  callInitiated('call_initiated'),
  textInitiated('text_initiated'),
  directionsOpened('directions_opened'),
  filterApplied('filter_applied'),
  sortApplied('sort_applied'),
  searchPerformed('search_performed'),
  mapAreaLoaded('map_area_loaded'),
  mapPinTapped('map_pin_tapped'),
  dataExported('data_exported');

  final String name;
  const AnalyticsEvent(this.name);
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Skip if using placeholder key
    if (AnalyticsConfig.apiKey.contains('XXXX')) {
      print('Analytics: Skipping initialization (placeholder API key)');
      return;
    }

    // TODO: Initialize PostHog when package is added
    // For now, just log locally
    _initialized = true;
    print('Analytics: Initialized');
  }

  void identify({required String userId, String? email, String? role}) {
    if (!_initialized) return;
    print('Analytics: identify user=$userId email=$email role=$role');
    // TODO: PostHog identify
  }

  void reset() {
    print('Analytics: reset');
    // TODO: PostHog reset
  }

  void track(AnalyticsEvent event, [Map<String, dynamic>? properties]) {
    print('Analytics: ${event.name} ${properties ?? {}}');
    // TODO: PostHog capture
  }

  void screen(String screenName, [Map<String, dynamic>? properties]) {
    print('Analytics: screen=$screenName ${properties ?? {}}');
    // TODO: PostHog screen
  }

  // Convenience methods
  void trackCanvassResult(String result, String voterId) {
    track(AnalyticsEvent.canvassResultSaved, {
      'result': result,
      'voter_id': voterId,
    });
  }

  void trackVotersLoaded(int count, String source) {
    track(AnalyticsEvent.votersLoaded, {
      'count': count,
      'source': source,
    });
  }

  void trackMapAreaLoaded(int newVoters, int totalFetched) {
    track(AnalyticsEvent.mapAreaLoaded, {
      'new_voters': newVoters,
      'total_fetched': totalFetched,
    });
  }

  void trackFilter(String filter, String screen) {
    track(AnalyticsEvent.filterApplied, {
      'filter': filter,
      'screen': screen,
    });
  }

  void trackAction(String action, [Map<String, dynamic>? properties]) {
    print('Analytics: action=$action ${properties ?? {}}');
    // TODO: PostHog capture
  }

  void trackScreen(String screenName) {
    screen(screenName);
  }

  void trackContact(String method, dynamic result) {
    track(AnalyticsEvent.callInitiated, {
      'method': method,
      'result': result.toString(),
    });
  }
}
