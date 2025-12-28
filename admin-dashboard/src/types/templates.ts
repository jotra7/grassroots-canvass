// Template categories
export type TemplateCategory = 'introduction' | 'follow_up' | 'reminder' | 'thank_you';

export const CATEGORY_LABELS: Record<TemplateCategory, string> = {
  introduction: 'Introduction',
  follow_up: 'Follow-up',
  reminder: 'Reminder',
  thank_you: 'Thank You',
};

export const CATEGORY_COLORS: Record<TemplateCategory, string> = {
  introduction: 'bg-blue-500',
  follow_up: 'bg-purple-500',
  reminder: 'bg-orange-500',
  thank_you: 'bg-green-500',
};

// Candidate type
export interface Candidate {
  id: string;
  name: string;
  district: string;
  position: string;
  organization: string | null;
  website: string | null;
  is_active: boolean;
  created_at: string;
}

// Text template type
export interface TextTemplate {
  id: string;
  campaign_id: string | null;
  candidate_id: string | null;
  district: string;
  position: string | null;
  category: TemplateCategory;
  name: string;
  message: string;
  icon_name: string;
  is_active: boolean;
  display_order: number;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

// Template with joined candidate data
export interface TextTemplateWithCandidate extends TextTemplate {
  candidate: Candidate | null;
}

// Template with assignment counts (for table display)
export interface TextTemplateWithCounts extends TextTemplate {
  candidate: Candidate | null;
  user_count: number;
  cut_list_count: number;
}

// Assignment types
export interface TemplateUserAssignment {
  id: string;
  template_id: string;
  user_id: string;
  assigned_by: string | null;
  assigned_at: string;
}

export interface TemplateCutListAssignment {
  id: string;
  template_id: string;
  cut_list_id: string;
  assigned_by: string | null;
  assigned_at: string;
}

// Call script section types
export type CallScriptSection = 'greeting' | 'introduction' | 'issues' | 'ask' | 'objections' | 'closing';

export const SCRIPT_SECTION_LABELS: Record<CallScriptSection, string> = {
  greeting: 'Opening/Greeting',
  introduction: 'Introduction',
  issues: 'Key Issues',
  ask: 'The Ask',
  objections: 'Handle Objections',
  closing: 'Closing',
};

export const SCRIPT_SECTION_COLORS: Record<CallScriptSection, string> = {
  greeting: 'bg-blue-500',
  introduction: 'bg-purple-500',
  issues: 'bg-orange-500',
  ask: 'bg-green-500',
  objections: 'bg-red-500',
  closing: 'bg-teal-500',
};

// Call script type
export interface CallScript {
  id: string;
  campaign_id: string | null;
  name: string;
  section: CallScriptSection;
  content: string;
  display_order: number;
  is_active: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

// Icon options for template dialog
export const TEMPLATE_ICONS = [
  { name: 'waving_hand', label: 'Waving Hand' },
  { name: 'home', label: 'Home' },
  { name: 'help_outline', label: 'Help' },
  { name: 'check_circle', label: 'Check Circle' },
  { name: 'phone_callback', label: 'Phone Callback' },
  { name: 'refresh', label: 'Refresh' },
  { name: 'question_answer', label: 'Q&A' },
  { name: 'mail', label: 'Mail' },
  { name: 'calendar_today', label: 'Calendar' },
  { name: 'bolt', label: 'Bolt' },
  { name: 'warning', label: 'Warning' },
  { name: 'favorite', label: 'Heart' },
  { name: 'thumb_up', label: 'Thumbs Up' },
  { name: 'verified', label: 'Verified' },
  { name: 'star', label: 'Star' },
  { name: 'signpost', label: 'Sign' },
  { name: 'message', label: 'Message' },
] as const;
