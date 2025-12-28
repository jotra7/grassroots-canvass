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
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Search, Users } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

interface CutList {
  id: string;
  name: string;
}

interface User {
  id: string;
  full_name: string | null;
  email: string;
  role: string;
}

interface AssignUsersDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cutList: CutList;
  users: User[];
}

export function AssignUsersDialog({
  open,
  onOpenChange,
  cutList,
  users,
}: AssignUsersDialogProps) {
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(false);
  const [initialAssignments, setInitialAssignments] = useState<string[]>([]);

  useEffect(() => {
    if (open) {
      loadCurrentAssignments();
    }
  }, [open, cutList.id]);

  const loadCurrentAssignments = async () => {
    const supabase = createClient();
    const { data } = await supabase
      .from("user_cut_list_assignments")
      .select("user_id")
      .eq("cut_list_id", cutList.id);

    const userIds = data?.map((d) => d.user_id) || [];
    setInitialAssignments(userIds);
    setSelectedUsers(new Set(userIds));
  };

  const filteredUsers = users.filter(
    (user) =>
      (user.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const toggleUser = (userId: string) => {
    setSelectedUsers((prev) => {
      const next = new Set(prev);
      if (next.has(userId)) {
        next.delete(userId);
      } else {
        next.add(userId);
      }
      return next;
    });
  };

  const getInitials = (name: string | null, email: string) => {
    if (name) {
      return name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .toUpperCase()
        .slice(0, 2);
    }
    return email.slice(0, 2).toUpperCase();
  };

  const handleSave = async () => {
    setLoading(true);

    try {
      const supabase = createClient();

      const toAdd = [...selectedUsers].filter(
        (id) => !initialAssignments.includes(id)
      );
      const toRemove = initialAssignments.filter(
        (id) => !selectedUsers.has(id)
      );

      // Remove unselected assignments
      if (toRemove.length > 0) {
        await supabase
          .from("user_cut_list_assignments")
          .delete()
          .eq("cut_list_id", cutList.id)
          .in("user_id", toRemove);
      }

      // Add new assignments
      if (toAdd.length > 0) {
        await supabase.from("user_cut_list_assignments").insert(
          toAdd.map((user_id) => ({
            user_id,
            cut_list_id: cutList.id,
          }))
        );
      }

      onOpenChange(false);
      window.location.reload();
    } catch (error) {
      console.error("Failed to update assignments:", error);
    } finally {
      setLoading(false);
    }
  };

  const hasChanges = () => {
    if (selectedUsers.size !== initialAssignments.length) return true;
    return [...selectedUsers].some((id) => !initialAssignments.includes(id));
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Assign Users to Cut List
          </DialogTitle>
          <DialogDescription>
            Select users to assign to &quot;{cutList.name}&quot;
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="relative">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search users..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-8"
            />
          </div>

          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <span>{selectedUsers.size} users selected</span>
            <div className="flex gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedUsers(new Set(users.map((u) => u.id)))}
              >
                Select All
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedUsers(new Set())}
              >
                Clear
              </Button>
            </div>
          </div>

          <ScrollArea className="h-[300px] rounded-md border p-4">
            {filteredUsers.length === 0 ? (
              <div className="flex h-full items-center justify-center text-muted-foreground">
                No users found
              </div>
            ) : (
              <div className="space-y-2">
                {filteredUsers.map((user) => (
                  <div
                    key={user.id}
                    className="flex items-center space-x-3 rounded-lg border p-3 hover:bg-muted/50"
                  >
                    <Checkbox
                      id={user.id}
                      checked={selectedUsers.has(user.id)}
                      onCheckedChange={() => toggleUser(user.id)}
                    />
                    <Label
                      htmlFor={user.id}
                      className="flex flex-1 cursor-pointer items-center gap-3"
                    >
                      <Avatar className="h-8 w-8">
                        <AvatarFallback className="text-xs">
                          {getInitials(user.full_name, user.email)}
                        </AvatarFallback>
                      </Avatar>
                      <div className="flex-1">
                        <div className="font-medium">
                          {user.full_name || user.email}
                        </div>
                        {user.full_name && (
                          <div className="text-xs text-muted-foreground">
                            {user.email}
                          </div>
                        )}
                      </div>
                      <Badge variant="outline" className="capitalize text-xs">
                        {user.role.replace("_", " ")}
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
