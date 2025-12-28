import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';
import '../models/user_profile.dart';

class AuthStateData {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isPendingApproval;
  final String? errorMessage;
  final UserProfile? user;
  final bool isDemoMode;
  final bool isAdmin;
  final bool isTeamLead;
  final bool canManageCutLists;

  const AuthStateData({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isPendingApproval = false,
    this.errorMessage,
    this.user,
    this.isDemoMode = false,
    this.isAdmin = false,
    this.isTeamLead = false,
    this.canManageCutLists = false,
  });

  AuthStateData copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isPendingApproval,
    String? errorMessage,
    UserProfile? user,
    bool? isDemoMode,
    bool? isAdmin,
    bool? isTeamLead,
    bool? canManageCutLists,
  }) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPendingApproval: isPendingApproval ?? this.isPendingApproval,
      errorMessage: errorMessage,
      user: user ?? this.user,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isAdmin: isAdmin ?? this.isAdmin,
      isTeamLead: isTeamLead ?? this.isTeamLead,
      canManageCutLists: canManageCutLists ?? this.canManageCutLists,
    );
  }
}

class AuthNotifier extends Notifier<AuthStateData> {
  @override
  AuthStateData build() {
    _checkAuthState();
    return const AuthStateData();
  }

  Future<void> _checkAuthState() async {
    final supabase = SupabaseService();

    if (supabase.isAuthenticated) {
      if (supabase.currentProfile == null) {
        await supabase.fetchCurrentProfile();
      }
      if (supabase.isPending) {
        state = state.copyWith(
          isPendingApproval: true,
          isAuthenticated: false,
          user: supabase.currentProfile,
        );
      } else if (supabase.isApproved) {
        // Start periodic sync for offline updates
        SyncService.instance.startPeriodicSync();

        state = state.copyWith(
          isAuthenticated: true,
          isPendingApproval: false,
          user: supabase.currentProfile,
          isDemoMode: supabase.isDemoMode,
          isAdmin: supabase.isAdmin,
          isTeamLead: supabase.isTeamLead,
          canManageCutLists: supabase.canManageCutLists,
        );
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = SupabaseService();
    final analytics = AnalyticsService();
    final cache = CacheService.instance;

    try {
      // Clear any existing cache before logging in new user
      // This prevents cross-user data leakage
      try {
        await cache.clearAllCache();
      } catch (_) {}

      await supabase.signIn(email, password);

      if (supabase.isDemoMode || supabase.isApproved) {
        analytics.identify(
          userId: supabase.currentProfile?.id ?? 'demo',
          email: email,
          role: supabase.currentProfile?.role,
        );
        analytics.track(AnalyticsEvent.signIn);

        // Start periodic sync for offline updates
        SyncService.instance.startPeriodicSync();

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: supabase.currentProfile,
          isDemoMode: supabase.isDemoMode,
          isAdmin: supabase.isAdmin,
          isTeamLead: supabase.isTeamLead,
          canManageCutLists: supabase.canManageCutLists,
        );
      } else if (supabase.isPending) {
        state = state.copyWith(
          isLoading: false,
          isPendingApproval: true,
          user: supabase.currentProfile,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Account not approved',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUp(String email, String password, {String? fullName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = SupabaseService();
    final analytics = AnalyticsService();

    try {
      await supabase.signUp(email, password, fullName: fullName);
      analytics.track(AnalyticsEvent.signUp);
      state = state.copyWith(
        isLoading: false,
        isPendingApproval: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    final supabase = SupabaseService();
    final analytics = AnalyticsService();
    final cache = CacheService.instance;
    final sync = SyncService.instance;

    // Stop periodic sync
    sync.stopPeriodicSync();

    analytics.track(AnalyticsEvent.signOut);
    analytics.reset();

    // Clear cached data to prevent next user from seeing previous user's data
    // Note: Pending updates are preserved until synced!
    try {
      await cache.clearAllCache();
      print('[AuthProvider] Cache cleared on logout');
    } catch (e) {
      print('[AuthProvider] Failed to clear cache: $e');
    }

    await supabase.signOut();
    state = const AuthStateData();
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    final supabase = SupabaseService();
    final analytics = AnalyticsService();

    try {
      await supabase.deleteAccount();
      analytics.reset();
      state = const AuthStateData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refreshProfile() async {
    final supabase = SupabaseService();
    await supabase.fetchCurrentProfile();
    await _checkAuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStateData>(() {
  return AuthNotifier();
});
