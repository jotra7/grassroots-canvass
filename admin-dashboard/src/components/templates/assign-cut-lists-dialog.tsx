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
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Badge } from "@/components/ui/badge";
import { Search, Map } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import type { TextTemplate } from "@/types/templates";

interface CutList {
  id: string;
  name: string;
  voter_count: number;
}

interface AssignCutListsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  template: TextTemplate | null;
  cutLists: CutList[];
  onSaved: () => void;
}

export function AssignCutListsDialog({
  open,
  onOpenChange,
  template,
  cutLists,
  onSaved,
}: AssignCutListsDialogProps) {
  const [selectedCutLists, setSelectedCutLists] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(false);
  const [initialAssignments, setInitialAssignments] = useState<string[]>([]);

  useEffect(() => {
    if (open && template) {
      loadCurrentAssignments();
    }
  }, [open, template?.id]);

  const loadCurrentAssignments = async () => {
    if (!template) return;

    const supabase = createClient();
    const { data } = await supabase
      .from("text_template_cut_list_assignments")
      .select("cut_list_id")
      .eq("template_id", template.id);

    const cutListIds = data?.map((d) => d.cut_list_id) || [];
    setInitialAssignments(cutListIds);
    setSelectedCutLists(new Set(cutListIds));
  };

  const filteredCutLists = cutLists.filter((list) =>
    list.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const toggleCutList = (cutListId: string) => {
    setSelectedCutLists((prev) => {
      const next = new Set(prev);
      if (next.has(cutListId)) {
        next.delete(cutListId);
      } else {
        next.add(cutListId);
      }
      return next;
    });
  };

  const handleSave = async () => {
    if (!template) return;
    setLoading(true);

    try {
      const supabase = createClient();

      const toAdd = [...selectedCutLists].filter(
        (id) => !initialAssignments.includes(id)
      );
      const toRemove = initialAssignments.filter(
        (id) => !selectedCutLists.has(id)
      );

      if (toRemove.length > 0) {
        await supabase
          .from("text_template_cut_list_assignments")
          .delete()
          .eq("template_id", template.id)
          .in("cut_list_id", toRemove);
      }

      if (toAdd.length > 0) {
        await supabase.from("text_template_cut_list_assignments").insert(
          toAdd.map((cut_list_id) => ({
            cut_list_id,
            template_id: template.id,
          }))
        );
      }

      onSaved();
      onOpenChange(false);
    } catch (error) {
      console.error("Failed to update assignments:", error);
    } finally {
      setLoading(false);
    }
  };

  const hasChanges = () => {
    if (selectedCutLists.size !== initialAssignments.length) return true;
    return [...selectedCutLists].some((id) => !initialAssignments.includes(id));
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Map className="h-5 w-5" />
            Assign Cut Lists to Template
          </DialogTitle>
          <DialogDescription>
            Select cut lists that will have access to the &quot;{template?.name}&quot; template
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="relative">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search cut lists..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-8"
            />
          </div>

          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <span>{selectedCutLists.size} cut lists selected</span>
            <div className="flex gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() =>
                  setSelectedCutLists(new Set(cutLists.map((c) => c.id)))
                }
              >
                Select All
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedCutLists(new Set())}
              >
                Clear
              </Button>
            </div>
          </div>

          <ScrollArea className="h-[300px] rounded-md border p-4">
            {filteredCutLists.length === 0 ? (
              <div className="flex h-full items-center justify-center text-muted-foreground">
                No cut lists found
              </div>
            ) : (
              <div className="space-y-2">
                {filteredCutLists.map((list) => (
                  <div
                    key={list.id}
                    className="flex items-center space-x-3 rounded-lg border p-3 hover:bg-muted/50"
                  >
                    <Checkbox
                      id={list.id}
                      checked={selectedCutLists.has(list.id)}
                      onCheckedChange={() => toggleCutList(list.id)}
                    />
                    <Label
                      htmlFor={list.id}
                      className="flex flex-1 cursor-pointer items-center justify-between"
                    >
                      <span className="font-medium">{list.name}</span>
                      <Badge variant="secondary">
                        {list.voter_count.toLocaleString()} voters
                      </Badge>
                    </Label>
                  </div>
                ))}
              </div>
            )}
          </ScrollArea>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={loading || !hasChanges()}>
            {loading ? "Saving..." : "Save Assignments"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
