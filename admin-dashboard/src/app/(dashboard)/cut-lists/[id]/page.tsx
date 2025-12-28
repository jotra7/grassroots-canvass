import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { CutListDetailClient } from "./cut-list-detail-client";
import type { Voter, CutList } from "@/types/database";

interface PageProps {
  params: Promise<{ id: string }>;
}

async function getCutListData(id: string) {
  const supabase = await createClient();

  // Get cut list details
  const { data: cutList, error } = await supabase
    .from("cut_lists")
    .select("*")
    .eq("id", id)
    .single();

  if (error || !cutList) {
    return null;
  }

  // Get voters in this cut list
  const { data: cutListVoters } = await supabase
    .from("cut_list_voters")
    .select("voter_unique_id")
    .eq("cut_list_id", id);

  const voterIds = cutListVoters?.map((v) => v.voter_unique_id) || [];

  let voters: Voter[] = [];
  if (voterIds.length > 0) {
    const { data } = await supabase
      .from("voters")
      .select("*")
      .in("unique_id", voterIds);
    voters = (data as Voter[]) || [];
  }

  return {
    cutList: cutList as CutList,
    voters,
  };
}

export default async function CutListDetailPage({ params }: PageProps) {
  const { id } = await params;
  const data = await getCutListData(id);

  if (!data) {
    notFound();
  }

  return <CutListDetailClient data={data} />;
}
