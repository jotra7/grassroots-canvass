"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { Activity, TrendingUp, Users } from "lucide-react";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
  created_at: string;
}

interface ActivityFeedProps {
  users: UserProfile[];
  activityStats: Record<string, { contacts: number; lastActive: string | null }>;
}

export function ActivityFeed({ users, activityStats }: ActivityFeedProps) {
  // Create sorted list of users by activity
  const sortedUsers = users
    .map((user) => ({
      ...user,
      stats: activityStats[user.id] || { contacts: 0, lastActive: null },
    }))
    .sort((a, b) => b.stats.contacts - a.stats.contacts);

  const maxContacts = Math.max(
    ...sortedUsers.map((u) => u.stats.contacts),
    1
  );

  const totalContacts = sortedUsers.reduce(
    (sum, u) => sum + u.stats.contacts,
    0
  );

  const activeUsers = sortedUsers.filter((u) => u.stats.contacts > 0).length;

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

  const formatLastActive = (date: string | null) => {
    if (!date) return "No activity";
    const d = new Date(date);
    const now = new Date();
    const diffHours = Math.floor(
      (now.getTime() - d.getTime()) / (1000 * 60 * 60)
    );

    if (diffHours < 1) return "Just now";
    if (diffHours < 24) return `${diffHours}h ago`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays === 1) return "Yesterday";
    return `${diffDays} days ago`;
  };

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Contacts (7d)</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalContacts}</div>
            <p className="text-xs text-muted-foreground">
              From {activeUsers} active users
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Users</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {activeUsers} / {users.length}
            </div>
            <p className="text-xs text-muted-foreground">
              {Math.round((activeUsers / users.length) * 100)}% participation
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Contacts/User</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {activeUsers > 0 ? Math.round(totalContacts / activeUsers) : 0}
            </div>
            <p className="text-xs text-muted-foreground">
              Per active user in 7 days
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Leaderboard */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Activity Leaderboard (Last 7 Days)
          </CardTitle>
        </CardHeader>
        <CardContent>
          {sortedUsers.length === 0 ? (
            <div className="flex h-32 items-center justify-center text-muted-foreground">
              No users found
            </div>
          ) : (
            <div className="space-y-4">
              {sortedUsers.slice(0, 10).map((user, index) => (
                <div
                  key={user.id}
                  className="flex items-center gap-4"
                >
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-muted text-sm font-medium">
                    {index + 1}
                  </div>

                  <Avatar className="h-10 w-10">
                    <AvatarFallback>
                      {getInitials(user.full_name, user.email)}
                    </AvatarFallback>
                  </Avatar>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium truncate">
                        {user.full_name || user.email}
                      </span>
                      <Badge variant="outline" className="capitalize text-xs">
                        {user.role.replace("_", " ")}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      <Progress
                        value={(user.stats.contacts / maxContacts) * 100}
                        className="h-2 flex-1"
                      />
                      <span className="text-sm font-medium w-16 text-right">
                        {user.stats.contacts} contacts
                      </span>
                    </div>
                    <div className="text-xs text-muted-foreground mt-1">
                      Last active: {formatLastActive(user.stats.lastActive)}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
