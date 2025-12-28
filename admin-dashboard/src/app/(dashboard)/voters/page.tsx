import { createClient } from "@/lib/supabase/server";
import { VotersClient } from "./voters-client";

export interface Voter {
  unique_id: string;
  first_name: string | null;
  last_name: string | null;
  owner_name: string | null;
  phone: string | null;
  cell_phone: string | null;
  street_num: string | null;
  street_name: string | null;
  city: string | null;
  zip: string | null;
  canvass_result: string | null;
  canvass_date: string | null;
  party: string | null;
  latitude: number | null;
  longitude: number | null;
  voter_age: number | null;
  is_mail_voter: boolean | null;
  contact_attempts: number | null;
}

async function getVotersData() {
  const supabase = await createClient();

  // Get voters with pagination (first 100 for initial load)
  const { data: voters, count } = await supabase
    .from("voters")
    .select(
      "unique_id, first_name, last_name, owner_name, phone, cell_phone, street_num, street_name, city, zip, canvass_result, canvass_date, party, latitude, longitude, voter_age, is_mail_voter, contact_attempts",
      { count: "exact" }
    )
    .order("last_name", { ascending: true })
    .limit(100);

  // Get cut lists for filtering
  const { data: cutLists } = await supabase
    .from("cut_lists")
    .select("id, name")
    .order("name", { ascending: true });

  return {
    voters: voters || [],
    totalCount: count || 0,
    cutLists: cutLists || [],
  };
}

export default async function VotersPage() {
  const data = await getVotersData();

  return <VotersClient data={data} />;
}
