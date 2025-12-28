"use client";

import { useState } from "react";
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
import { Search, ClipboardList, Users } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  created_at: string;
}

interface CutList {
  id: string;
  name: string;
  voter_count: number;
}

interface AssignmentsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: UserProfile;
  cutLists: CutList[];
  currentAssignments: string[];
}

export function AssignmentsDialog({
  open,
  onOpenChange,
  user,
  cutLists,
  currentAssignments,
}: AssignmentsDialogProps) {
  const [selectedLists, setSelectedLists] = useState<Set<string>>(
    new Set(currentAssignments)
  );
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(false);

  const filteredLists = cutLists.filter((list) =>
    list.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const toggleList = (listId: string) => {
    setSelectedLists((prev) => {
      const next = new Set(prev);
      if (next.has(listId)) {
        next.delete(listId);
      } else {
        next.add(listId);
      }
      return next;
    });
  };

  const handleSave = async () => {
    setLoading(true);

    try {
      const supabase = createClient();

      // Get current assignments from DB
      const toAdd = [...selectedLists].filter(
        (id) => !currentAssignments.includes(id)
      );
      const toRemove = currentAssignments.filter((id) => !selectedLists.has(id));

      // Remove unselected assignments
      if (toRemove.length > 0) {
        const { error: deleteError } = await supabase
          .from("user_cut_list_assignments")
          .delete()
          .eq("user_id", user.id)
          .in("cut_list_id", toRemove);

        if (deleteError) throw deleteError;
      }

      // Add new assignments
      if (toAdd.length > 0) {
        const { error: insertError } = await supabase
          .from("user_cut_list_assignments")
          .insert(
            toAdd.map((cut_list_id) => ({
              user_id: user.id,
              cut_list_id,
            }))
          );

        if (insertError) throw insertError;
      }

      onOpenChange(false);
      // Trigger a page refresh to show updated assignments
      window.location.reload();
    } catch (error) {
      console.error("Failed to update assignments:", error);
    } finally {
      setLoading(false);
    }
  };

  const hasChanges = () => {
    if (selectedLists.size !== currentAssignments.length) return true;
    return [...selectedLists].some((id) => !currentAssignments.includes(id));
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ClipboardList className="h-5 w-5" />
            Manage Cut List Assignments
          </DialogTitle>
          <DialogDescription>
            Assign cut lists to {user.full_name || user.email}
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
            <span>{selectedLists.size} of {cutLists.length} selected</span>
            <div className="flex gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedLists(new Set(cutLists.map((l) => l.id)))}
              >
                Select All
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedLists(new Set())}
              >
                Clear All
              </Button>
            </div>
          </div>

          <ScrollArea className="h-[300px] rounded-md border p-4">
            {filteredLists.length === 0 ? (
              <div className="flex h-full items-center justify-center text-muted-foreground">
                No cut lists found
              </div>
            ) : (
              <div className="space-y-2">
                {filteredLists.map((list) => (
                  <div
                    key={list.id}
                    className="flex items-center space-x-3 rounded-lg border p-3 hover:bg-muted/50"
                  >
                    <Checkbox
                      id={list.id}
                      checked={selectedLists.has(list.id)}
                      onCheckedChange={() => toggleList(list.id)}
                    />
                    <Label
                      htmlFor={list.id}
                      className="flex flex-1 cursor-pointer items-center justify-between"
                    >
                      <span className="font-medium">{list.name}</span>
                      <Badge variant="outline" className="ml-2">
                        <Users className="mr-1 h-3 w-3" />
                        {list.voter_count.toLocaleString()}
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
