import { createClient } from "@/lib/supabase/server";
import { TeamClient } from "./team-client";

export interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  created_at: string;
}

export interface CutList {
  id: string;
  name: string;
  voter_count: number;
}

export interface UserAssignment {
  user_id: string;
  cut_list_id: string;
}

async function getTeamData() {
  const supabase = await createClient();

  // Get all users
  const { data: users } = await supabase
    .from("user_profiles")
    .select("id, email, full_name, role, created_at")
    .order("created_at", { ascending: false });

  // Get all cut lists
  const { data: cutLists } = await supabase
    .from("cut_lists")
    .select("id, name, voter_count")
    .order("name", { ascending: true });

  // Get user assignments
  const { data: assignments } = await supabase
    .from("user_cut_list_assignments")
    .select("user_id, cut_list_id");

  // Get recent activity (last 7 days)
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const { data: recentActivity } = await supabase
    .from("contact_history")
    .select("contacted_by, contacted_at, result, method")
    .gte("contacted_at", sevenDaysAgo.toISOString())
    .order("contacted_at", { ascending: false })
    .limit(50);

  // Build activity stats per user
  const activityStats: Record<string, { contacts: number; lastActive: string | null }> = {};

  recentActivity?.forEach((activity) => {
    if (!activity.contacted_by) return;

    if (!activityStats[activity.contacted_by]) {
      activityStats[activity.contacted_by] = { contacts: 0, lastActive: null };
    }

    activityStats[activity.contacted_by].contacts++;

    if (!activityStats[activity.contacted_by].lastActive) {
      activityStats[activity.contacted_by].lastActive = activity.contacted_at;
    }
  });

  return {
    users: users || [],
    cutLists: cutLists || [],
    assignments: assignments || [],
    activityStats,
  };
}

export default async function TeamPage() {
  const data = await getTeamData();

  return <TeamClient data={data} />;
}
