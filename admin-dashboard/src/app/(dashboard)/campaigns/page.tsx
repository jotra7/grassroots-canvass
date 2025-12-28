import { createClient } from "@/lib/supabase/server";
import { CampaignsClient } from "./campaigns-client";
import { POSITIVE_RESULTS } from "@/types/database";
import type { CampaignWithStats } from "@/types/campaigns";

async function getCampaignsData() {
  const supabase = await createClient();

  // Try to get campaigns - if table doesn't exist, return empty with flag
  const { data: campaigns, error } = await supabase
    .from("campaigns")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    // Table likely doesn't exist yet
    if (error.code === "42P01" || error.message.includes("does not exist")) {
      return { campaigns: [], tableExists: false, cutLists: [] };
    }
    console.error("Error fetching campaigns:", error);
    return { campaigns: [], tableExists: true, cutLists: [] };
  }

  // Get cut lists for assignment
  const { data: cutLists } = await supabase
    .from("cut_lists")
    .select("id, name, voter_count")
    .order("name", { ascending: true });

  // Get campaign-cut list associations
  const { data: campaignCutLists } = await supabase
    .from("campaign_cut_lists")
    .select("campaign_id, cut_list_id");

  // Build campaign stats
  const campaignsWithStats: CampaignWithStats[] = await Promise.all(
    (campaigns || []).map(async (campaign) => {
      // Get cut lists for this campaign
      const campaignListIds =
        campaignCutLists
          ?.filter((ccl) => ccl.campaign_id === campaign.id)
          .map((ccl) => ccl.cut_list_id) || [];

      // Get voter IDs from cut lists
      let voterIds: string[] = [];
      if (campaignListIds.length > 0) {
        const { data: cutListVoters } = await supabase
          .from("cut_list_voters")
          .select("voter_unique_id")
          .in("cut_list_id", campaignListIds);

        voterIds = cutListVoters?.map((v) => v.voter_unique_id) || [];
      }

      // Get contact stats for these voters within campaign date range
      let totalContacts = 0;
      let positiveResponses = 0;

      if (voterIds.length > 0) {
        let query = supabase
          .from("contact_history")
          .select("result", { count: "exact" })
          .in("voter_unique_id", voterIds)
          .gte("contacted_at", campaign.start_date);

        if (campaign.end_date) {
          query = query.lte("contacted_at", campaign.end_date);
        }

        const { count } = await query;
        totalContacts = count || 0;

        // Get positive responses
        const { count: positiveCount } = await supabase
          .from("contact_history")
          .select("*", { count: "exact", head: true })
          .in("voter_unique_id", voterIds)
          .in("result", POSITIVE_RESULTS)
          .gte("contacted_at", campaign.start_date);

        positiveResponses = positiveCount || 0;
      }

      // Calculate voter count from assigned cut lists
      const voterCount =
        cutLists
          ?.filter((cl) => campaignListIds.includes(cl.id))
          .reduce((sum, cl) => sum + cl.voter_count, 0) || 0;

      return {
        ...campaign,
        totalContacts,
        positiveResponses,
        cutListCount: campaignListIds.length,
        voterCount,
      };
    })
  );

  return {
    campaigns: campaignsWithStats,
    tableExists: true,
    cutLists: cutLists || [],
  };
}

export default async function CampaignsPage() {
  const data = await getCampaignsData();

  return <CampaignsClient data={data} />;
}
