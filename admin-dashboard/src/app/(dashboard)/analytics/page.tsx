import { createClient } from "@/lib/supabase/server";
import { AnalyticsClient } from "./analytics-client";
import {
  POSITIVE_RESULTS,
  NEGATIVE_RESULTS,
  NEUTRAL_RESULTS,
} from "@/types/database";

async function getAnalyticsData() {
  const supabase = await createClient();

  // Get contact history for trend data (last 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const { data: contactHistory } = await supabase
    .from("contact_history")
    .select("contacted_at, result, method, contacted_by")
    .gte("contacted_at", thirtyDaysAgo.toISOString())
    .order("contacted_at", { ascending: true });

  // Process contact history into daily data
  const dailyData: Record<
    string,
    { contacts: number; positive: number; negative: number }
  > = {};

  contactHistory?.forEach((contact) => {
    const date = new Date(contact.contacted_at).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    });

    if (!dailyData[date]) {
      dailyData[date] = { contacts: 0, positive: 0, negative: 0 };
    }

    dailyData[date].contacts++;

    if (POSITIVE_RESULTS.includes(contact.result)) {
      dailyData[date].positive++;
    } else if (NEGATIVE_RESULTS.includes(contact.result)) {
      dailyData[date].negative++;
    }
  });

  const trendData = Object.entries(dailyData).map(([date, data]) => ({
    date,
    ...data,
  }));

  // Get result breakdown from voters table
  const { data: voters } = await supabase
    .from("voters")
    .select("canvass_result")
    .not("canvass_result", "is", null)
    .neq("canvass_result", "Not Contacted");

  let positiveCount = 0;
  let negativeCount = 0;
  let neutralCount = 0;
  let otherCount = 0;

  voters?.forEach((voter) => {
    if (POSITIVE_RESULTS.includes(voter.canvass_result)) {
      positiveCount++;
    } else if (NEGATIVE_RESULTS.includes(voter.canvass_result)) {
      negativeCount++;
    } else if (NEUTRAL_RESULTS.includes(voter.canvass_result)) {
      neutralCount++;
    } else {
      otherCount++;
    }
  });

  const resultBreakdown = [
    { name: "Positive", value: positiveCount, color: "#587758" },
    { name: "Negative", value: negativeCount, color: "#C9512D" },
    { name: "Neutral", value: neutralCount, color: "#D0C1AA" },
    { name: "Other", value: otherCount, color: "#6b7280" },
  ].filter((item) => item.value > 0);

  // Get contact method breakdown
  const methodCounts: Record<string, number> = {};
  contactHistory?.forEach((contact) => {
    const method = contact.method || "unknown";
    methodCounts[method] = (methodCounts[method] || 0) + 1;
  });

  const methodData = [
    { method: "Door", count: methodCounts["door"] || 0, color: "#DE6D48" },
    { method: "Call", count: methodCounts["call"] || 0, color: "#587758" },
    { method: "Text", count: methodCounts["text"] || 0, color: "#D0C1AA" },
  ];

  // Get team performance
  const { data: userProfiles } = await supabase
    .from("user_profiles")
    .select("id, full_name, email")
    .in("role", ["canvasser", "team_lead", "admin"]);

  const userMap = new Map(
    userProfiles?.map((u) => [u.id, u.full_name || u.email]) || []
  );

  const teamStats: Record<
    string,
    { name: string; contacts: number; positive: number; negative: number }
  > = {};

  contactHistory?.forEach((contact) => {
    if (!contact.contacted_by) return;

    const name = userMap.get(contact.contacted_by) || "Unknown";

    if (!teamStats[contact.contacted_by]) {
      teamStats[contact.contacted_by] = {
        name,
        contacts: 0,
        positive: 0,
        negative: 0,
      };
    }

    teamStats[contact.contacted_by].contacts++;

    if (POSITIVE_RESULTS.includes(contact.result)) {
      teamStats[contact.contacted_by].positive++;
    } else if (NEGATIVE_RESULTS.includes(contact.result)) {
      teamStats[contact.contacted_by].negative++;
    }
  });

  const teamPerformance = Object.values(teamStats)
    .sort((a, b) => b.contacts - a.contacts)
    .slice(0, 10);

  // Get cut list progress
  const { data: cutLists } = await supabase
    .from("cut_lists")
    .select("id, name, voter_count");

  const cutListProgress = await Promise.all(
    (cutLists || []).slice(0, 5).map(async (cutList) => {
      // Get voters in this cut list
      const { data: cutListVoters } = await supabase
        .from("cut_list_voters")
        .select("voter_unique_id")
        .eq("cut_list_id", cutList.id);

      const voterIds = cutListVoters?.map((v) => v.voter_unique_id) || [];

      if (voterIds.length === 0) {
        return {
          name: cutList.name,
          total: cutList.voter_count,
          contacted: 0,
          positive: 0,
        };
      }

      // Get contacted count
      const { count: contacted } = await supabase
        .from("voters")
        .select("*", { count: "exact", head: true })
        .in("unique_id", voterIds)
        .not("canvass_result", "is", null)
        .neq("canvass_result", "Not Contacted");

      // Get positive count
      const { count: positive } = await supabase
        .from("voters")
        .select("*", { count: "exact", head: true })
        .in("unique_id", voterIds)
        .in("canvass_result", POSITIVE_RESULTS);

      return {
        name: cutList.name,
        total: cutList.voter_count,
        contacted: contacted || 0,
        positive: positive || 0,
      };
    })
  );

  return {
    trendData,
    resultBreakdown,
    methodData,
    teamPerformance,
    cutListProgress,
  };
}

export default async function AnalyticsPage() {
  const data = await getAnalyticsData();

  return <AnalyticsClient data={data} />;
}
