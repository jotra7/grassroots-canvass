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
      return { campaigns: [], tableExists: false };
    }
    console.error("Error fetching campaigns:", error);
    return { campaigns: [], tableExists: true };
  }

  // Build campaign stats
  const campaignsWithStats: CampaignWithStats[] = await Promise.all(
    (campaigns || []).map(async (campaign) => {
      // Get voter count for this campaign
      const { count: voterCount } = await supabase
        .from("voters")
        .select("*", { count: "exact", head: true })
        .eq("campaign_id", campaign.id);

      // Get cut list count for this campaign
      const { count: cutListCount } = await supabase
        .from("cut_lists")
        .select("*", { count: "exact", head: true })
        .eq("campaign_id", campaign.id);

      // Get member count for this campaign
      const { count: memberCount } = await supabase
        .from("campaign_members")
        .select("*", { count: "exact", head: true })
        .eq("campaign_id", campaign.id);

      // Get contact stats for this campaign
      const { count: totalContacts } = await supabase
        .from("contact_history")
        .select("*", { count: "exact", head: true })
        .eq("campaign_id", campaign.id);

      // Get positive responses
      const { count: positiveResponses } = await supabase
        .from("contact_history")
        .select("*", { count: "exact", head: true })
        .eq("campaign_id", campaign.id)
        .in("result", POSITIVE_RESULTS);

      return {
        ...campaign,
        totalContacts: totalContacts || 0,
        positiveResponses: positiveResponses || 0,
        cutListCount: cutListCount || 0,
        voterCount: voterCount || 0,
        memberCount: memberCount || 0,
      };
    })
  );

  return {
    campaigns: campaignsWithStats,
    tableExists: true,
  };
}

export default async function CampaignsPage() {
  const data = await getCampaignsData();

  return <CampaignsClient data={data} />;
}
