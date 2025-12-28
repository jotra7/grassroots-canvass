"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Check, X, UserPlus, AlertCircle } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  created_at: string;
}

interface PendingUsersCardProps {
  users: UserProfile[];
  onApprove: (user: UserProfile) => void;
  onReject: (userId: string) => void;
}

export function PendingUsersCard({
  users,
  onApprove,
  onReject,
}: PendingUsersCardProps) {
  const [selectedRoles, setSelectedRoles] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState<Record<string, boolean>>({});

  const handleApprove = async (user: UserProfile) => {
    const role = selectedRoles[user.id] || "canvasser";
    setLoading((prev) => ({ ...prev, [user.id]: true }));

    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("user_profiles")
        .update({ role })
        .eq("id", user.id);

      if (error) throw error;

      onApprove({ ...user, role });
    } catch (error) {
      console.error("Failed to approve user:", error);
    } finally {
      setLoading((prev) => ({ ...prev, [user.id]: false }));
    }
  };

  const handleReject = async (userId: string) => {
    setLoading((prev) => ({ ...prev, [userId]: true }));

    try {
      const supabase = createClient();
      // Delete the user profile (they can re-register)
      const { error } = await supabase
        .from("user_profiles")
        .delete()
        .eq("id", userId);

      if (error) throw error;

      onReject(userId);
    } catch (error) {
      console.error("Failed to reject user:", error);
    } finally {
      setLoading((prev) => ({ ...prev, [userId]: false }));
    }
  };

  if (users.length === 0) return null;

  return (
    <Card className="border-primary/50 bg-primary/5">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <AlertCircle className="h-5 w-5 text-primary" />
          Pending Approvals
          <Badge variant="default" className="ml-2">
            {users.length}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {users.map((user) => (
            <div
              key={user.id}
              className="flex items-center justify-between rounded-lg border bg-background p-4"
            >
              <div className="flex items-center gap-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted">
                  <UserPlus className="h-5 w-5" />
                </div>
                <div>
                  <div className="font-medium">
                    {user.full_name || "No name provided"}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {user.email}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    Registered {new Date(user.created_at).toLocaleDateString()}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <Select
                  value={selectedRoles[user.id] || "canvasser"}
                  onValueChange={(value) =>
                    setSelectedRoles((prev) => ({ ...prev, [user.id]: value }))
                  }
                >
                  <SelectTrigger className="w-[140px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="canvasser">Canvasser</SelectItem>
                    <SelectItem value="team_lead">Team Lead</SelectItem>
                    <SelectItem value="admin">Admin</SelectItem>
                  </SelectContent>
                </Select>

                <Button
                  size="sm"
                  onClick={() => handleApprove(user)}
                  disabled={loading[user.id]}
                >
                  <Check className="mr-1 h-4 w-4" />
                  Approve
                </Button>

                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleReject(user.id)}
                  disabled={loading[user.id]}
                >
                  <X className="mr-1 h-4 w-4" />
                  Reject
                </Button>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
