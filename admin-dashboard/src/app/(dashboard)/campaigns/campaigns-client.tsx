"use client";

import { useState } from "react";
import { CampaignsTable } from "@/components/campaigns/campaigns-table";
import { CampaignDialog } from "@/components/campaigns/campaign-dialog";
import { SetupInstructions } from "@/components/campaigns/setup-instructions";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";
import type { CampaignWithStats } from "@/types/campaigns";

interface CampaignsClientProps {
  data: {
    campaigns: CampaignWithStats[];
    tableExists: boolean;
  };
}

export function CampaignsClient({ data }: CampaignsClientProps) {
  const [campaigns, setCampaigns] = useState(data.campaigns);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingCampaign, setEditingCampaign] = useState<CampaignWithStats | null>(null);

  if (!data.tableExists) {
    return <SetupInstructions />;
  }

  const handleCreate = () => {
    setEditingCampaign(null);
    setDialogOpen(true);
  };

  const handleEdit = (campaign: CampaignWithStats) => {
    setEditingCampaign(campaign);
    setDialogOpen(true);
  };

  const handleSave = (campaign: CampaignWithStats) => {
    if (editingCampaign) {
      setCampaigns((prev) =>
        prev.map((c) => (c.id === campaign.id ? campaign : c))
      );
    } else {
      setCampaigns((prev) => [campaign, ...prev]);
    }
    setDialogOpen(false);
    setEditingCampaign(null);
  };

  const handleDelete = (campaignId: string) => {
    setCampaigns((prev) => prev.filter((c) => c.id !== campaignId));
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Campaigns</h1>
          <p className="text-muted-foreground">
            Manage campaigns and their settings
          </p>
        </div>
        <Button onClick={handleCreate}>
          <Plus className="mr-2 h-4 w-4" />
          New Campaign
        </Button>
      </div>

      <CampaignsTable
        campaigns={campaigns}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />

      <CampaignDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        campaign={editingCampaign}
        onSave={handleSave}
      />
    </div>
  );
}
