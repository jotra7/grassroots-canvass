export interface Campaign {
  id: string;
  name: string;
  description: string | null;
  organization_name: string | null;
  candidate_name: string | null;
  election_date: string | null;
  district: string | null;
  default_latitude: number;
  default_longitude: number;
  default_zoom: number;
  primary_color: string;
  secondary_color: string;
  is_active: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampaignMember {
  id: string;
  campaign_id: string;
  user_id: string;
  role: 'admin' | 'team_lead' | 'canvasser';
  invited_by: string | null;
  joined_at: string;
  // Joined data
  user_profiles?: {
    email: string;
    full_name: string | null;
  };
}

export interface CampaignWithStats extends Campaign {
  totalContacts: number;
  positiveResponses: number;
  cutListCount: number;
  voterCount: number;
  memberCount: number;
}

export interface CampaignCreateInput {
  name: string;
  description?: string;
  organization_name?: string;
  candidate_name?: string;
  election_date?: string;
  district?: string;
  default_latitude?: number;
  default_longitude?: number;
  default_zoom?: number;
  primary_color?: string;
  secondary_color?: string;
}

export interface CampaignUpdateInput extends Partial<CampaignCreateInput> {
  is_active?: boolean;
}
