"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { CutListsTable } from "@/components/cut-lists/cut-lists-table";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";
import type { CutListWithStats } from "./page";

interface User {
  id: string;
  full_name: string | null;
  email: string;
  role: string;
}

interface CutListsClientProps {
  data: {
    cutLists: CutListWithStats[];
    users: User[];
  };
}

export function CutListsClient({ data }: CutListsClientProps) {
  const [cutLists] = useState(data.cutLists);
  const router = useRouter();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Cut Lists</h1>
          <p className="text-muted-foreground">
            Manage voter cut lists and assignments
          </p>
        </div>
        <Button onClick={() => router.push("/cut-lists/create")}>
          <Plus className="mr-2 h-4 w-4" />
          Create Cut List
        </Button>
      </div>

      <CutListsTable cutLists={cutLists} users={data.users} />
    </div>
  );
}
