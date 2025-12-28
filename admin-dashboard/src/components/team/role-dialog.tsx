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
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Shield, Users, UserCheck } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  created_at: string;
}

interface RoleDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: UserProfile;
  onUpdate: (user: UserProfile) => void;
}

const roles = [
  {
    value: "canvasser",
    label: "Canvasser",
    description: "Can access assigned cut lists and record contacts",
    icon: UserCheck,
  },
  {
    value: "team_lead",
    label: "Team Lead",
    description: "Can manage team members and view all assigned cut lists",
    icon: Users,
  },
  {
    value: "admin",
    label: "Admin",
    description: "Full access to all features and settings",
    icon: Shield,
  },
];

export function RoleDialog({
  open,
  onOpenChange,
  user,
  onUpdate,
}: RoleDialogProps) {
  const [selectedRole, setSelectedRole] = useState(user.role);
  const [loading, setLoading] = useState(false);

  const handleSave = async () => {
    if (selectedRole === user.role) {
      onOpenChange(false);
      return;
    }

    setLoading(true);

    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("user_profiles")
        .update({ role: selectedRole })
        .eq("id", user.id);

      if (error) throw error;

      onUpdate({ ...user, role: selectedRole });
      onOpenChange(false);
    } catch (error) {
      console.error("Failed to update role:", error);
    } finally {
      setLoading(false);
    }
  };

  const selectedRoleInfo = roles.find((r) => r.value === selectedRole);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Change User Role</DialogTitle>
          <DialogDescription>
            Update the role for {user.full_name || user.email}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label htmlFor="role">Role</Label>
            <Select value={selectedRole} onValueChange={setSelectedRole}>
              <SelectTrigger id="role">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {roles.map((role) => (
                  <SelectItem key={role.value} value={role.value}>
                    <div className="flex items-center gap-2">
                      <role.icon className="h-4 w-4" />
                      {role.label}
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {selectedRoleInfo && (
            <div className="rounded-lg border bg-muted/50 p-3">
              <div className="flex items-center gap-2 font-medium">
                <selectedRoleInfo.icon className="h-4 w-4" />
                {selectedRoleInfo.label}
              </div>
              <p className="mt-1 text-sm text-muted-foreground">
                {selectedRoleInfo.description}
              </p>
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={loading}>
            {loading ? "Saving..." : "Save Changes"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
