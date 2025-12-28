"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Database, Terminal, Copy, Check } from "lucide-react";
import { useState } from "react";

const migrationSQL = `-- Create campaigns table
CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'archived')),
  goal_contacts INTEGER,
  goal_positive_responses INTEGER,
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link campaigns to cut lists
CREATE TABLE campaign_cut_lists (
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  cut_list_id UUID REFERENCES cut_lists(id) ON DELETE CASCADE,
  PRIMARY KEY (campaign_id, cut_list_id)
);

-- Enable RLS
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_cut_lists ENABLE ROW LEVEL SECURITY;

-- Policies for campaigns
CREATE POLICY "Admins and team leads can view campaigns"
  ON campaigns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'team_lead')
    )
  );

CREATE POLICY "Admins can manage campaigns"
  ON campaigns FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Policies for campaign_cut_lists
CREATE POLICY "Admins and team leads can view campaign cut lists"
  ON campaign_cut_lists FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'team_lead')
    )
  );

CREATE POLICY "Admins can manage campaign cut lists"
  ON campaign_cut_lists FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );`;

export function SetupInstructions() {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(migrationSQL);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Campaigns</h1>
        <p className="text-muted-foreground">
          Set up the campaigns feature to get started
        </p>
      </div>

      <Card className="border-primary/50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5 text-primary" />
            Database Setup Required
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            The campaigns feature requires additional database tables. Run the
            following SQL migration in your Supabase SQL Editor:
          </p>

          <div className="relative">
            <Button
              variant="outline"
              size="sm"
              className="absolute right-2 top-2"
              onClick={handleCopy}
            >
              {copied ? (
                <>
                  <Check className="mr-1 h-4 w-4" />
                  Copied!
                </>
              ) : (
                <>
                  <Copy className="mr-1 h-4 w-4" />
                  Copy SQL
                </>
              )}
            </Button>
            <pre className="overflow-x-auto rounded-lg bg-muted p-4 text-sm">
              <code>{migrationSQL}</code>
            </pre>
          </div>

          <div className="rounded-lg border bg-muted/50 p-4">
            <h4 className="flex items-center gap-2 font-medium mb-2">
              <Terminal className="h-4 w-4" />
              How to apply:
            </h4>
            <ol className="list-decimal list-inside space-y-1 text-sm text-muted-foreground">
              <li>Go to your Supabase dashboard</li>
              <li>Navigate to SQL Editor</li>
              <li>Paste the migration SQL above</li>
              <li>Click &quot;Run&quot; to execute</li>
              <li>Refresh this page</li>
            </ol>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
