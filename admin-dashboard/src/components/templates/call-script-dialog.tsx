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
import { Card, CardContent } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";
import type { CallScript, CallScriptSection } from "@/types/templates";
import { SCRIPT_SECTION_LABELS } from "@/types/templates";

interface CallScriptDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  script: CallScript | null;
  onSaved: () => void;
}

export function CallScriptDialog({
  open,
  onOpenChange,
  script,
  onSaved,
}: CallScriptDialogProps) {
  const [name, setName] = useState("");
  const [section, setSection] = useState<CallScriptSection>("greeting");
  const [content, setContent] = useState("");
  const [displayOrder, setDisplayOrder] = useState(0);
  const [isActive, setIsActive] = useState(true);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (script) {
      setName(script.name);
      setSection(script.section);
      setContent(script.content);
      setDisplayOrder(script.display_order);
      setIsActive(script.is_active);
    } else {
      setName("");
      setSection("greeting");
      setContent("");
      setDisplayOrder(0);
      setIsActive(true);
    }
  }, [script, open]);

  const handleSave = async () => {
    if (!name || !section || !content) return;

    setLoading(true);
    try {
      const supabase = createClient();

      const data = {
        name,
        section,
        content,
        display_order: displayOrder,
        is_active: isActive,
        updated_at: new Date().toISOString(),
      };

      if (script) {
        await supabase
          .from("call_scripts")
          .update(data)
          .eq("id", script.id);
      } else {
        await supabase.from("call_scripts").insert(data);
      }

      onSaved();
      onOpenChange(false);
    } catch (error) {
      console.error("Failed to save call script:", error);
    } finally {
      setLoading(false);
    }
  };

  // Preview content with sample voter name
  const previewContent = () => {
    return content
      .replace(/\{name\}/g, "John")
      .replace(/\{firstName\}/g, "John")
      .replace(/\{lastName\}/g, "Smith")
      .replace(/\{fullName\}/g, "John Smith");
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {script ? "Edit Call Script" : "Add Call Script"}
          </DialogTitle>
          <DialogDescription>
            {script
              ? "Update the call script section"
              : "Create a new call script section for canvassers"}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="grid gap-2">
            <Label htmlFor="name">Section Name *</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Opening Script"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="section">Section Type *</Label>
              <Select
                value={section}
                onValueChange={(v) => setSection(v as CallScriptSection)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(SCRIPT_SECTION_LABELS).map(([key, label]) => (
                    <SelectItem key={key} value={key}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="order">Display Order</Label>
              <Input
                id="order"
                type="number"
                value={displayOrder}
                onChange={(e) => setDisplayOrder(parseInt(e.target.value) || 0)}
              />
            </div>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="content">Script Content *</Label>
            <Textarea
              id="content"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder={`"Hi, is this {name}?"

[If YES]: "Great! My name is [YOUR NAME]..."

[If NO]: "Oh, sorry about that!"`}
              rows={10}
              className="font-mono text-sm"
            />
          </div>

          <Card className="bg-muted/50">
            <CardContent className="pt-4">
              <Label className="text-xs font-medium">Available Variables</Label>
              <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1.5 text-sm">
                <div className="flex items-center gap-2">
                  <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{name}"}</code>
                  <span className="text-muted-foreground">Voter first name</span>
                </div>
                <div className="flex items-center gap-2">
                  <code className="bg-background px-1.5 py-0.5 rounded text-xs">{"{fullName}"}</code>
                  <span className="text-muted-foreground">Full name</span>
                </div>
              </div>
              <p className="mt-2 text-xs text-muted-foreground">
                Use [BRACKETS] for instructions and **asterisks** for emphasis.
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-4">
              <Label className="text-xs text-muted-foreground">Preview</Label>
              <pre className="mt-2 text-sm whitespace-pre-wrap font-sans">
                {previewContent() || "Enter content above to see preview"}
              </pre>
            </CardContent>
          </Card>

          <div className="flex items-center space-x-2">
            <Switch
              id="is-active"
              checked={isActive}
              onCheckedChange={setIsActive}
            />
            <Label htmlFor="is-active">Active</Label>
          </div>
        </div>

        <DialogFooter className="mt-4">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            disabled={loading || !name || !section || !content}
          >
            {loading ? "Saving..." : script ? "Save Changes" : "Add Script"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
