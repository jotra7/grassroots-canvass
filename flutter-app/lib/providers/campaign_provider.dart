import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign.dart';
import '../services/supabase_service.dart';

class CampaignStateData {
  final bool isLoading;
  final String? errorMessage;
  final List<Campaign> campaigns;
  final Campaign? activeCampaign;

  const CampaignStateData({
    this.isLoading = false,
    this.errorMessage,
    this.campaigns = const [],
    this.activeCampaign,
  });

  CampaignStateData copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Campaign>? campaigns,
    Campaign? activeCampaign,
    bool clearActiveCampaign = false,
  }) {
    return CampaignStateData(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      campaigns: campaigns ?? this.campaigns,
      activeCampaign: clearActiveCampaign ? null : (activeCampaign ?? this.activeCampaign),
    );
  }

  bool get hasCampaigns => campaigns.isNotEmpty;
  bool get hasActiveCampaign => activeCampaign != null;
  bool get needsCampaignSelection => hasCampaigns && !hasActiveCampaign;

  /// Check if user can manage the active campaign (admin or team_lead)
  bool get canManageActiveCampaign => activeCampaign?.canManage ?? false;

  /// Check if user is admin of active campaign
  bool get isActiveCampaignAdmin => activeCampaign?.isAdmin ?? false;
}

class CampaignNotifier extends Notifier<CampaignStateData> {
  @override
  CampaignStateData build() {
    return const CampaignStateData();
  }

  /// Load user's campaigns from Supabase
  Future<void> loadCampaigns() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = SupabaseService();

    try {
      final campaigns = await supabase.getUserCampaigns();

      Campaign? active;

      // Try to restore previously active campaign
      final activeId = await supabase.getActiveCampaignId();
      if (activeId != null) {
        active = campaigns.where((c) => c.id == activeId).firstOrNull;
      }

      // If no active campaign set, and only one campaign exists, auto-select it
      if (active == null && campaigns.length == 1) {
        active = campaigns.first;
        await supabase.setActiveCampaignId(active.id);
      }

      state = state.copyWith(
        isLoading: false,
        campaigns: campaigns,
        activeCampaign: active,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Set the active campaign
  Future<void> setActiveCampaign(Campaign campaign) async {
    final supabase = SupabaseService();

    try {
      await supabase.setActiveCampaignId(campaign.id);
      state = state.copyWith(activeCampaign: campaign);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Clear active campaign (go back to campaign selector)
  Future<void> clearActiveCampaign() async {
    final supabase = SupabaseService();

    try {
      await supabase.setActiveCampaignId(null);
      state = state.copyWith(clearActiveCampaign: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Refresh campaigns list
  Future<void> refresh() async {
    await loadCampaigns();
  }

  /// Create a new campaign (admin only)
  Future<Campaign?> createCampaign({
    required String name,
    String? description,
    String? organizationName,
    String? candidateName,
    DateTime? electionDate,
    String? district,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = SupabaseService();

    try {
      final campaign = await supabase.createCampaign(
        name: name,
        description: description,
        organizationName: organizationName,
        candidateName: candidateName,
        electionDate: electionDate,
        district: district,
      );

      // Add to local list and set as active
      final updatedCampaigns = [...state.campaigns, campaign];
      state = state.copyWith(
        isLoading: false,
        campaigns: updatedCampaigns,
        activeCampaign: campaign,
      );

      return campaign;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Update campaign settings
  Future<bool> updateCampaign(Campaign campaign) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final supabase = SupabaseService();

    try {
      await supabase.updateCampaign(campaign);

      // Update local list
      final updatedCampaigns = state.campaigns.map((c) {
        return c.id == campaign.id ? campaign : c;
      }).toList();

      // Update active if this is the active campaign
      final updatedActive = state.activeCampaign?.id == campaign.id
          ? campaign
          : state.activeCampaign;

      state = state.copyWith(
        isLoading: false,
        campaigns: updatedCampaigns,
        activeCampaign: updatedActive,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Clear all state (on logout)
  void clear() {
    state = const CampaignStateData();
  }
}

final campaignProvider = NotifierProvider<CampaignNotifier, CampaignStateData>(() {
  return CampaignNotifier();
});

/// Convenience provider for just the active campaign
final activeCampaignProvider = Provider<Campaign?>((ref) {
  return ref.watch(campaignProvider).activeCampaign;
});

/// Convenience provider for campaign ID (used in queries)
final activeCampaignIdProvider = Provider<String?>((ref) {
  return ref.watch(campaignProvider).activeCampaign?.id;
});
