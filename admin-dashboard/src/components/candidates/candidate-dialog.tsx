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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { createClient } from "@/lib/supabase/client";
import type { Candidate } from "@/types/templates";

// Common political positions - can be customized per campaign
const POSITIONS = [
  { value: "council", label: "Council" },
  { value: "board", label: "Board" },
  { value: "president", label: "President" },
  { value: "vice_president", label: "Vice President" },
  { value: "mayor", label: "Mayor" },
  { value: "city_council", label: "City Council" },
  { value: "state_rep", label: "State Representative" },
  { value: "state_senator", label: "State Senator" },
  { value: "commissioner", label: "Commissioner" },
  { value: "supervisor", label: "Supervisor" },
  { value: "school_board", label: "School Board" },
  { value: "other", label: "Other" },
];

interface CandidateDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  candidate: Candidate | null;
  onSaved: () => void;
}

export function CandidateDialog({
  open,
  onOpenChange,
  candidate,
  onSaved,
}: CandidateDialogProps) {
  const [name, setName] = useState("");
  const [district, setDistrict] = useState("");
  const [position, setPosition] = useState("");
  const [organization, setOrganization] = useState("");
  const [website, setWebsite] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (candidate) {
      setName(candidate.name);
      setDistrict(candidate.district);
      setPosition(candidate.position);
      setOrganization(candidate.organization || "");
      setWebsite(candidate.website || "");
      setIsActive(candidate.is_active);
    } else {
      setName("");
      setDistrict("");
      setPosition("");
      setOrganization("");
      setWebsite("");
      setIsActive(true);
    }
  }, [candidate, open]);

  const handleSave = async () => {
    if (!name || !district || !position) return;

    setLoading(true);
    try {
      const supabase = createClient();

      const data = {
        name,
        district,
        position,
        organization: organization || null,
        website: website || null,
        is_active: isActive,
      };

      if (candidate) {
        await supabase
          .from("candidates")
          .update(data)
          .eq("id", candidate.id);
      } else {
        await supabase.from("candidates").insert(data);
      }

      onSaved();
      onOpenChange(false);
    } catch (error) {
      console.error("Failed to save candidate:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>
            {candidate ? "Edit Candidate" : "Add Candidate"}
          </DialogTitle>
          <DialogDescription>
            {candidate
              ? "Update the candidate details"
              : "Add a new candidate for the campaign"}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label htmlFor="name">Name *</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Jane Smith"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="district">District/Area *</Label>
              <Input
                id="district"
                value={district}
                onChange={(e) => setDistrict(e.target.value)}
                placeholder="e.g., District 5, Ward 3, At Large"
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="position">Position *</Label>
              <Select value={position} onValueChange={setPosition}>
                <SelectTrigger>
                  <SelectValue placeholder="Select position" />
                </SelectTrigger>
                <SelectContent>
                  {POSITIONS.map((p) => (
                    <SelectItem key={p.value} value={p.value}>
                      {p.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="organization">Organization</Label>
              <Input
                id="organization"
                value={organization}
                onChange={(e) => setOrganization(e.target.value)}
                placeholder="e.g., district"
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="website">Website</Label>
              <Input
                id="website"
                value={website}
                onChange={(e) => setWebsite(e.target.value)}
                placeholder="e.g., www.example.com"
              />
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <Switch
              id="is-active"
              checked={isActive}
              onCheckedChange={setIsActive}
            />
            <Label htmlFor="is-active">Active</Label>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            disabled={loading || !name || !district || !position}
          >
            {loading ? "Saving..." : candidate ? "Save Changes" : "Add Candidate"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
