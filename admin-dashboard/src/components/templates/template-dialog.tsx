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
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";
import type { Candidate, TextTemplate, TemplateCategory } from "@/types/templates";
import { CATEGORY_LABELS, TEMPLATE_ICONS } from "@/types/templates";

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

interface TemplateDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  template: TextTemplate | null;
  candidates: Candidate[];
  onSaved: () => void;
}

export function TemplateDialog({
  open,
  onOpenChange,
  template,
  candidates,
  onSaved,
}: TemplateDialogProps) {
  const [name, setName] = useState("");
  const [candidateId, setCandidateId] = useState<string>("");
  const [district, setDistrict] = useState("");
  const [position, setPosition] = useState("");
  const [category, setCategory] = useState<TemplateCategory>("introduction");
  const [message, setMessage] = useState("");
  const [iconName, setIconName] = useState("message");
  const [isActive, setIsActive] = useState(true);
  const [displayOrder, setDisplayOrder] = useState(0);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (template) {
      setName(template.name);
      setCandidateId(template.candidate_id || "");
      setDistrict(template.district);
      setPosition(template.position || "");
      setCategory(template.category);
      setMessage(template.message);
      setIconName(template.icon_name);
      setIsActive(template.is_active);
      setDisplayOrder(template.display_order);
    } else {
      setName("");
      setCandidateId("");
      setDistrict("");
      setPosition("");
      setCategory("introduction");
      setMessage("");
      setIconName("message");
      setIsActive(true);
      setDisplayOrder(0);
    }
  }, [template, open]);

  // Auto-fill district/position when candidate is selected
  useEffect(() => {
    if (candidateId) {
      const candidate = candidates.find((c) => c.id === candidateId);
      if (candidate) {
        setDistrict(candidate.district);
        setPosition(candidate.position);
      }
    }
  }, [candidateId, candidates]);

  const handleSave = async () => {
    if (!name || !district || !category || !message) return;

    setLoading(true);
    try {
      const supabase = createClient();

      const data = {
        name,
        candidate_id: candidateId || null,
        district,
        position: position || null,
        category,
        message,
        icon_name: iconName,
        is_active: isActive,
        display_order: displayOrder,
        updated_at: new Date().toISOString(),
      };

      if (template) {
        await supabase
          .from("text_templates")
          .update(data)
          .eq("id", template.id);
      } else {
        await supabase.from("text_templates").insert(data);
      }

      onSaved();
      onOpenChange(false);
    } catch (error) {
      console.error("Failed to save template:", error);
    } finally {
      setLoading(false);
    }
  };

  // Preview message with placeholders replaced
  const previewMessage = () => {
    const candidate = candidates.find((c) => c.id === candidateId);
    return message
      .replace(/\{name\}/g, "John")
      .replace(/\{firstName\}/g, "John")
      .replace(/\{lastName\}/g, "Smith")
      .replace(/\{fullName\}/g, "John Smith")
      .replace(/\{city\}/g, "Phoenix")
      .replace(/\{candidate\}/g, candidate?.name || "[Candidate]");
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {template ? "Edit Template" : "Add Template"}
          </DialogTitle>
          <DialogDescription>
            {template
              ? "Update the text template"
              : "Create a new text template for canvassers"}
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="details" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="details">Details</TabsTrigger>
            <TabsTrigger value="message">Message</TabsTrigger>
          </TabsList>

          <TabsContent value="details" className="space-y-4 mt-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Template Name *</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g., First Contact"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="candidate">Candidate</Label>
              <Select
                value={candidateId || "none"}
                onValueChange={(v) => setCandidateId(v === "none" ? "" : v)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a candidate" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">No candidate</SelectItem>
                  {candidates
                    .filter((c) => c.is_active)
                    .map((candidate) => (
                      <SelectItem key={candidate.id} value={candidate.id}>
                        {candidate.name} ({candidate.district})
                      </SelectItem>
                    ))}
                </SelectContent>
              </Select>
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
                <Label htmlFor="position">Position</Label>
                <Select
                  value={position || "none"}
                  onValueChange={(v) => setPosition(v === "none" ? "" : v)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select position" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">No position</SelectItem>
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
                <Label htmlFor="category">Category *</Label>
                <Select
                  value={category}
                  onValueChange={(v) => setCategory(v as TemplateCategory)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(CATEGORY_LABELS).map(([key, label]) => (
                      <SelectItem key={key} value={key}>
                        {label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="icon">Icon</Label>
                <Select value={iconName} onValueChange={setIconName}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {TEMPLATE_ICONS.map((icon) => (
                      <SelectItem key={icon.name} value={icon.name}>
                        {icon.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="order">Display Order</Label>
                <Input
                  id="order"
                  type="number"
                  value={displayOrder}
                  onChange={(e) => setDisplayOrder(parseInt(e.target.value) || 0)}
                />
              </div>
              <div className="flex items-center space-x-2 pt-6">
                <Switch
                  id="is-active"
                  checked={isActive}
                  onCheckedChange={setIsActive}
                />
                <Label htmlFor="is-active">Active</Label>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="message" className="space-y-4 mt-4">
            <div className="grid gap-2">
              <Label htmlFor="message">Message *</Label>
              <Textarea
                id="message"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Hi {name}, ..."
                rows={6}
              />
            </div>

            <Card className="bg-muted/50">
              <CardContent className="pt-4">
                <Label className="text-xs font-medium">Available Variables</Label>
                <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1.5 text-sm">
                  <div className="flex items-center gap-2">
                    <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{name}"}</code>
                    <span className="text-muted-foreground">First name</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{firstName}"}</code>
                    <span className="text-muted-foreground">First name</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{lastName}"}</code>
                    <span className="text-muted-foreground">Last name</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{fullName}"}</code>
                    <span className="text-muted-foreground">Full name</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{city}"}</code>
                    <span className="text-muted-foreground">City</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{candidate}"}</code>
                    <span className="text-muted-foreground">Candidate name</span>
                  </div>
                </div>
                <p className="mt-2 text-xs text-muted-foreground">
                  Variables are automatically replaced when the canvasser sends the message.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-4">
                <Label className="text-xs text-muted-foreground">Preview</Label>
                <p className="mt-2 text-sm whitespace-pre-wrap">
                  {previewMessage() || "Enter a message above to see preview"}
                </p>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        <DialogFooter className="mt-4">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            disabled={loading || !name || !district || !category || !message}
          >
            {loading ? "Saving..." : template ? "Save Changes" : "Add Template"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
