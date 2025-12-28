"use client";

import { useState } from "react";
import { UsersTable } from "@/components/team/users-table";
import { PendingUsersCard } from "@/components/team/pending-users-card";
import { ActivityFeed } from "@/components/team/activity-feed";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import type { UserProfile, CutList, UserAssignment } from "./page";

interface TeamClientProps {
  data: {
    users: UserProfile[];
    cutLists: CutList[];
    assignments: UserAssignment[];
    activityStats: Record<string, { contacts: number; lastActive: string | null }>;
  };
}

export function TeamClient({ data }: TeamClientProps) {
  const [users, setUsers] = useState(data.users);

  const pendingUsers = users.filter((u) => u.role === "pending");
  const activeUsers = users.filter((u) => u.role !== "pending");

  const handleUserUpdate = (updatedUser: UserProfile) => {
    setUsers((prev) =>
      prev.map((u) => (u.id === updatedUser.id ? updatedUser : u))
    );
  };

  const handleUserRemove = (userId: string) => {
    setUsers((prev) => prev.filter((u) => u.id !== userId));
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Team Management</h1>
        <p className="text-muted-foreground">
          Manage users, roles, and cut list assignments
        </p>
      </div>

      {pendingUsers.length > 0 && (
        <PendingUsersCard
          users={pendingUsers}
          onApprove={handleUserUpdate}
          onReject={handleUserRemove}
        />
      )}

      <Tabs defaultValue="users" className="space-y-4">
        <TabsList>
          <TabsTrigger value="users">All Users ({activeUsers.length})</TabsTrigger>
          <TabsTrigger value="activity">Recent Activity</TabsTrigger>
        </TabsList>

        <TabsContent value="users" className="space-y-4">
          <UsersTable
            users={activeUsers}
            cutLists={data.cutLists}
            assignments={data.assignments}
            activityStats={data.activityStats}
            onUserUpdate={handleUserUpdate}
          />
        </TabsContent>

        <TabsContent value="activity">
          <ActivityFeed
            users={activeUsers}
            activityStats={data.activityStats}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
