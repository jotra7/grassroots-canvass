import { createClient } from "@/lib/supabase/server";
import { TemplatesClient } from "./templates-client";

async function getTemplatesData() {
  const supabase = await createClient();

  // Get all templates with candidate data and assignment counts
  const { data: templates } = await supabase
    .from("text_templates")
    .select(`
      *,
      candidate:candidates(*)
    `)
    .order("category")
    .order("display_order");

  // Get user assignment counts
  const { data: userAssignments } = await supabase
    .from("text_template_user_assignments")
    .select("template_id");

  // Get cut list assignment counts
  const { data: cutListAssignments } = await supabase
    .from("text_template_cut_list_assignments")
    .select("template_id");

  // Calculate counts per template
  const userCounts: Record<string, number> = {};
  const cutListCounts: Record<string, number> = {};

  userAssignments?.forEach((a) => {
    userCounts[a.template_id] = (userCounts[a.template_id] || 0) + 1;
  });

  cutListAssignments?.forEach((a) => {
    cutListCounts[a.template_id] = (cutListCounts[a.template_id] || 0) + 1;
  });

  const templatesWithCounts = templates?.map((t) => ({
    ...t,
    user_count: userCounts[t.id] || 0,
    cut_list_count: cutListCounts[t.id] || 0,
  })) || [];

  // Get all candidates
  const { data: candidates } = await supabase
    .from("candidates")
    .select("*")
    .order("name");

  // Get users for assignment dialog
  const { data: users } = await supabase
    .from("user_profiles")
    .select("id, email, full_name, role")
    .neq("role", "pending")
    .order("full_name");

  // Get cut lists for assignment dialog
  const { data: cutLists } = await supabase
    .from("cut_lists")
    .select("id, name, voter_count")
    .order("name");

  // Get call scripts
  const { data: callScripts } = await supabase
    .from("call_scripts")
    .select("*")
    .order("section")
    .order("display_order");

  return {
    templates: templatesWithCounts,
    candidates: candidates || [],
    users: users || [],
    cutLists: cutLists || [],
    callScripts: callScripts || [],
  };
}

export default async function TemplatesPage() {
  const data = await getTemplatesData();
  return <TemplatesClient data={data} />;
}
