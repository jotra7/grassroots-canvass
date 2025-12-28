// Database types matching Supabase schema (from Flutter app)

export type UserRole = "pending" | "canvasser" | "team_lead" | "admin";

export interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: UserRole;
  approved_at: string | null;
  created_at: string | null;
}

export interface Voter {
  unique_id: string;
  visitor_id: string | null;
  owner_name: string | null;
  first_name: string | null;
  middle_name: string | null;
  last_name: string | null;
  phone: string | null;
  cell_phone: string | null;
  street_num: string | null;
  street_dir: string | null;
  street_name: string | null;
  city: string | null;
  zip: string | null;
  party_description: string | null;
  voter_age: number;
  gender: string | null;
  registration_date: string | null;
  residence_address: string | null;
  latitude: number;
  longitude: number;
  canvass_result: string | null;
  canvass_notes: string | null;
  canvass_date: string | null;
  contact_attempts: number;
  last_contact_attempt: string | null;
  last_contact_method: string | null;
  voicemail_left: boolean;
  mail_address: string | null;
  mail_city: string | null;
  mail_state: string | null;
  mail_zip: string | null;
  lives_elsewhere: boolean;
  is_mail_voter: boolean;
}

export interface ContactHistory {
  id: string;
  unique_id: string; // Voter unique_id
  method: "call" | "text" | "door";
  result: string;
  notes: string | null;
  contacted_at: string;
  contacted_by: string | null;
}

export interface CutList {
  id: string;
  name: string;
  description: string | null;
  boundary_polygon: string | null; // JSON string
  voter_count: number;
  created_at: string;
  updated_at: string;
}

export interface CutListAssignment {
  cut_list_id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
}

export interface AppNotification {
  id: string;
  user_id: string | null;
  type: string;
  title: string;
  message: string;
  read: boolean;
  created_at: string;
}

export interface CallbackReminder {
  id: string;
  user_id: string;
  voter_unique_id: string;
  reminder_at: string;
  sent: boolean;
  created_at: string;
  // Joined fields
  user_profiles?: {
    full_name: string | null;
    email: string;
  };
  voters?: {
    first_name: string | null;
    last_name: string | null;
    owner_name: string | null;
    street_num: string | null;
    street_name: string | null;
    city: string | null;
    phone: string | null;
  };
}

export interface VoiceNote {
  id: string;
  voter_unique_id: string;
  user_id: string;
  audio_url: string;
  duration_seconds: number;
  transcription: string | null;
  created_at: string;
  // Joined fields
  user_profiles?: {
    full_name: string | null;
    email: string;
  };
}

// Analytics types
export interface CanvassStats {
  totalVoters: number;
  contacted: number;
  positive: number;
  negative: number;
  neutral: number;
  notContacted: number;
}

export interface TeamMemberStats {
  userId: string;
  userName: string;
  email: string;
  contactCount: number;
  positiveCount: number;
  negativeCount: number;
}

// Canvass result categories (from Flutter enum)
export const POSITIVE_RESULTS = [
  "Supportive",
  "Strong Support",
  "Leaning",
  "Willing to Volunteer",
  "Requested Sign",
];

export const NEGATIVE_RESULTS = [
  "Opposed",
  "Strongly Opposed",
  "Do Not Contact",
  "Refused",
];

export const NEUTRAL_RESULTS = [
  "Undecided",
  "Needs Info",
  "Callback Requested",
];

export function isPositiveResult(result: string | null): boolean {
  return result !== null && POSITIVE_RESULTS.includes(result);
}

export function isNegativeResult(result: string | null): boolean {
  return result !== null && NEGATIVE_RESULTS.includes(result);
}

export function isNeutralResult(result: string | null): boolean {
  return result !== null && NEUTRAL_RESULTS.includes(result);
}
