import { createClient } from "@/lib/supabase/server";
import { CutListsClient } from "./cut-lists-client";
import { POSITIVE_RESULTS } from "@/types/database";

export interface CutListWithStats {
  id: string;
  name: string;
  description: string | null;
  voter_count: number;
  created_at: string;
  created_by: string | null;
  contactedCount: number;
  positiveCount: number;
  assignedUsers: number;
}

async function getCutListsData() {
  const supabase = await createClient();

  // Get all cut lists
  const { data: cutLists } = await supabase
    .from("cut_lists")
    .select("id, name, description, voter_count, created_at, created_by")
    .order("name", { ascending: true });

  if (!cutLists) {
    return { cutLists: [], users: [] };
  }

  // Get user assignments count per cut list
  const { data: assignments } = await supabase
    .from("user_cut_list_assignments")
    .select("cut_list_id, user_id");

  const assignmentCounts: Record<string, number> = {};
  assignments?.forEach((a) => {
    assignmentCounts[a.cut_list_id] = (assignmentCounts[a.cut_list_id] || 0) + 1;
  });

  // Get stats for each cut list
  const cutListsWithStats: CutListWithStats[] = await Promise.all(
    cutLists.map(async (cutList) => {
      // Get voters in this cut list
      const { data: cutListVoters } = await supabase
        .from("cut_list_voters")
        .select("voter_unique_id")
        .eq("cut_list_id", cutList.id);

      const voterIds = cutListVoters?.map((v) => v.voter_unique_id) || [];

      let contactedCount = 0;
      let positiveCount = 0;

      if (voterIds.length > 0) {
        // Get contacted count
        const { count: contacted } = await supabase
          .from("voters")
          .select("*", { count: "exact", head: true })
          .in("unique_id", voterIds)
          .not("canvass_result", "is", null)
          .neq("canvass_result", "Not Contacted");

        contactedCount = contacted || 0;

        // Get positive count
        const { count: positive } = await supabase
          .from("voters")
          .select("*", { count: "exact", head: true })
          .in("unique_id", voterIds)
          .in("canvass_result", POSITIVE_RESULTS);

        positiveCount = positive || 0;
      }

      return {
        ...cutList,
        contactedCount,
        positiveCount,
        assignedUsers: assignmentCounts[cutList.id] || 0,
      };
    })
  );

  // Get users for assignment
  const { data: users } = await supabase
    .from("user_profiles")
    .select("id, full_name, email, role")
    .in("role", ["canvasser", "team_lead", "admin"])
    .order("full_name", { ascending: true });

  return {
    cutLists: cutListsWithStats,
    users: users || [],
  };
}

export default async function CutListsPage() {
  const data = await getCutListsData();

  return <CutListsClient data={data} />;
}
