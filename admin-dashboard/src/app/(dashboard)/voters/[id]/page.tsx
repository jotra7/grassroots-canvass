import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { VoterDetailClient } from "./voter-detail-client";
import type { VoiceNote } from "@/types/database";

interface PageProps {
  params: Promise<{ id: string }>;
}

async function getVoterData(id: string) {
  const supabase = await createClient();

  // Get voter details
  const { data: voter, error } = await supabase
    .from("voters")
    .select("*")
    .eq("unique_id", id)
    .single();

  if (error || !voter) {
    return null;
  }

  // Get contact history
  const { data: contactHistory } = await supabase
    .from("contact_history")
    .select("*")
    .eq("unique_id", id)
    .order("created_at", { ascending: false });

  // Get voice notes
  const { data: voiceNotes } = await supabase
    .from("voice_notes")
    .select(`
      id,
      voter_unique_id,
      user_id,
      audio_url,
      duration_seconds,
      transcription,
      created_at,
      user_profiles!user_id(full_name, email)
    `)
    .eq("voter_unique_id", id)
    .order("created_at", { ascending: false });

  // Transform Supabase array joins to single objects
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const transformedVoiceNotes = ((voiceNotes || []) as any[]).map((item) => ({
    ...item,
    user_profiles: Array.isArray(item.user_profiles) ? item.user_profiles[0] : item.user_profiles,
  })) as VoiceNote[];

  return {
    voter,
    contactHistory: contactHistory || [],
    voiceNotes: transformedVoiceNotes,
  };
}

export default async function VoterDetailPage({ params }: PageProps) {
  const { id } = await params;
  const data = await getVoterData(id);

  if (!data) {
    notFound();
  }

  return <VoterDetailClient data={data} />;
}
