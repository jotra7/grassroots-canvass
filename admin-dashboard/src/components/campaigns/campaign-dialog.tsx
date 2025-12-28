"use client";

import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Settings, Palette, MapPin } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import type { CampaignWithStats } from "@/types/campaigns";

interface CampaignDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  campaign: CampaignWithStats | null;
  onSave: (campaign: CampaignWithStats) => void;
}

export function CampaignDialog({
  open,
  onOpenChange,
  campaign,
  onSave,
}: CampaignDialogProps) {
  const [loading, setLoading] = useState(false);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [organizationName, setOrganizationName] = useState("");
  const [candidateName, setCandidateName] = useState("");
  const [electionDate, setElectionDate] = useState("");
  const [district, setDistrict] = useState("");
  const [defaultLatitude, setDefaultLatitude] = useState("33.4484");
  const [defaultLongitude, setDefaultLongitude] = useState("-112.0740");
  const [defaultZoom, setDefaultZoom] = useState("12");
  const [primaryColor, setPrimaryColor] = useState("#2563eb");
  const [secondaryColor, setSecondaryColor] = useState("#16a34a");

  useEffect(() => {
    if (campaign) {
      setName(campaign.name);
      setDescription(campaign.description || "");
      setOrganizationName(campaign.organization_name || "");
      setCandidateName(campaign.candidate_name || "");
      setElectionDate(campaign.election_date || "");
      setDistrict(campaign.district || "");
      setDefaultLatitude(campaign.default_latitude?.toString() || "33.4484");
      setDefaultLongitude(campaign.default_longitude?.toString() || "-112.0740");
      setDefaultZoom(campaign.default_zoom?.toString() || "12");
      setPrimaryColor(campaign.primary_color || "#2563eb");
      setSecondaryColor(campaign.secondary_color || "#16a34a");
    } else {
      // Reset form for new campaign
      setName("");
      setDescription("");
      setOrganizationName("");
      setCandidateName("");
      setElectionDate("");
      setDistrict("");
      setDefaultLatitude("33.4484");
      setDefaultLongitude("-112.0740");
      setDefaultZoom("12");
      setPrimaryColor("#2563eb");
      setSecondaryColor("#16a34a");
    }
  }, [campaign, open]);

  const handleSubmit = async () => {
    if (!name.trim()) return;

    setLoading(true);

    try {
      const supabase = createClient();

      const campaignData = {
        name: name.trim(),
        description: description.trim() || null,
        organization_name: organizationName.trim() || null,
        candidate_name: candidateName.trim() || null,
        election_date: electionDate || null,
        district: district.trim() || null,
        default_latitude: parseFloat(defaultLatitude) || 33.4484,
        default_longitude: parseFloat(defaultLongitude) || -112.0740,
        default_zoom: parseInt(defaultZoom) || 12,
        primary_color: primaryColor,
        secondary_color: secondaryColor,
      };

      let savedCampaign: CampaignWithStats;

      if (campaign) {
        // Update existing campaign
        const { data, error } = await supabase
          .from("campaigns")
          .update(campaignData)
          .eq("id", campaign.id)
          .select()
          .single();

        if (error) throw error;

        savedCampaign = {
          ...data,
          totalContacts: campaign.totalContacts,
          positiveResponses: campaign.positiveResponses,
          cutListCount: campaign.cutListCount,
          voterCount: campaign.voterCount,
          memberCount: campaign.memberCount,
        };
      } else {
        // Create new campaign
        const { data: userData } = await supabase.auth.getUser();
        const userId = userData.user?.id;

        const { data, error } = await supabase
          .from("campaigns")
          .insert({
            ...campaignData,
            created_by: userId,
            is_active: true,
          })
          .select()
          .single();

        if (error) throw error;

        // Add creator as campaign admin
        if (userId) {
          await supabase.from("campaign_members").insert({
            campaign_id: data.id,
            user_id: userId,
            role: "admin",
            invited_by: userId,
          });
        }

        savedCampaign = {
          ...data,
          totalContacts: 0,
          positiveResponses: 0,
          cutListCount: 0,
          voterCount: 0,
          memberCount: 1,
        };
      }

      onSave(savedCampaign);
    } catch (error) {
      console.error("Failed to save campaign:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>
            {campaign ? "Edit Campaign" : "Create Campaign"}
          </DialogTitle>
          <DialogDescription>
            {campaign
              ? "Update campaign settings and branding"
              : "Set up a new campaign for your canvassing team"}
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="details" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="details">
              <Settings className="mr-2 h-4 w-4" />
              Details
            </TabsTrigger>
            <TabsTrigger value="branding">
              <Palette className="mr-2 h-4 w-4" />
              Branding
            </TabsTrigger>
            <TabsTrigger value="map">
              <MapPin className="mr-2 h-4 w-4" />
              Map
            </TabsTrigger>
          </TabsList>

          <TabsContent value="details" className="space-y-4 mt-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Campaign Name *</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g., City Council 2025"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Campaign objectives and notes..."
                rows={3}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="organizationName">Organization</Label>
                <Input
                  id="organizationName"
                  value={organizationName}
                  onChange={(e) => setOrganizationName(e.target.value)}
                  placeholder="e.g., Friends of Jane Doe"
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="candidateName">Candidate Name</Label>
                <Input
                  id="candidateName"
                  value={candidateName}
                  onChange={(e) => setCandidateName(e.target.value)}
                  placeholder="e.g., Jane Doe"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="electionDate">Election Date</Label>
                <Input
                  id="electionDate"
                  type="date"
                  value={electionDate}
                  onChange={(e) => setElectionDate(e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="district">District/Area</Label>
                <Input
                  id="district"
                  value={district}
                  onChange={(e) => setDistrict(e.target.value)}
                  placeholder="e.g., District 5"
                />
              </div>
            </div>
          </TabsContent>

          <TabsContent value="branding" className="space-y-4 mt-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="primaryColor">Primary Color</Label>
                <div className="flex gap-2">
                  <Input
                    id="primaryColor"
                    type="color"
                    value={primaryColor}
                    onChange={(e) => setPrimaryColor(e.target.value)}
                    className="w-12 h-10 p-1 cursor-pointer"
                  />
                  <Input
                    value={primaryColor}
                    onChange={(e) => setPrimaryColor(e.target.value)}
                    placeholder="#2563eb"
                    className="flex-1"
                  />
                </div>
                <p className="text-sm text-muted-foreground">
                  Main brand color for buttons and accents
                </p>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="secondaryColor">Secondary Color</Label>
                <div className="flex gap-2">
                  <Input
                    id="secondaryColor"
                    type="color"
                    value={secondaryColor}
                    onChange={(e) => setSecondaryColor(e.target.value)}
                    className="w-12 h-10 p-1 cursor-pointer"
                  />
                  <Input
                    value={secondaryColor}
                    onChange={(e) => setSecondaryColor(e.target.value)}
                    placeholder="#16a34a"
                    className="flex-1"
                  />
                </div>
                <p className="text-sm text-muted-foreground">
                  Secondary color for highlights
                </p>
              </div>
            </div>

            <div className="rounded-lg border p-4">
              <Label className="mb-2 block">Preview</Label>
              <div className="flex gap-2">
                <div
                  className="h-10 w-24 rounded flex items-center justify-center text-white text-sm"
                  style={{ backgroundColor: primaryColor }}
                >
                  Primary
                </div>
                <div
                  className="h-10 w-24 rounded flex items-center justify-center text-white text-sm"
                  style={{ backgroundColor: secondaryColor }}
                >
                  Secondary
                </div>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="map" className="space-y-4 mt-4">
            <p className="text-sm text-muted-foreground">
              Set the default map center for this campaign. This is where the map
              will be centered when users first open the app.
            </p>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="defaultLatitude">Default Latitude</Label>
                <Input
                  id="defaultLatitude"
                  type="number"
                  step="0.0001"
                  value={defaultLatitude}
                  onChange={(e) => setDefaultLatitude(e.target.value)}
                  placeholder="33.4484"
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="defaultLongitude">Default Longitude</Label>
                <Input
                  id="defaultLongitude"
                  type="number"
                  step="0.0001"
                  value={defaultLongitude}
                  onChange={(e) => setDefaultLongitude(e.target.value)}
                  placeholder="-112.0740"
                />
              </div>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="defaultZoom">Default Zoom Level</Label>
              <Input
                id="defaultZoom"
                type="number"
                min="1"
                max="20"
                value={defaultZoom}
                onChange={(e) => setDefaultZoom(e.target.value)}
                placeholder="12"
              />
              <p className="text-sm text-muted-foreground">
                Zoom level from 1 (world) to 20 (buildings). 12 is good for city-level view.
              </p>
            </div>

            <div className="rounded-lg border bg-muted/50 p-4">
              <p className="text-sm">
                <strong>Tip:</strong> You can find coordinates by right-clicking on Google Maps
                and selecting the coordinates.
              </p>
            </div>
          </TabsContent>
        </Tabs>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleSubmit}
            disabled={loading || !name.trim()}
          >
            {loading ? "Saving..." : campaign ? "Save Changes" : "Create Campaign"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
