"use client";

import { useState } from "react";
import {
  ColumnDef,
  SortingState,
  flexRender,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  ChevronLeft,
  ChevronRight,
  MoreHorizontal,
  ArrowUpDown,
  Edit,
  Trash2,
  Target,
  Users,
  Calendar,
  MapPin,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import type { CampaignWithStats } from "@/types/campaigns";

interface CampaignsTableProps {
  campaigns: CampaignWithStats[];
  onEdit: (campaign: CampaignWithStats) => void;
  onDelete: (campaignId: string) => void;
}

export function CampaignsTable({
  campaigns,
  onEdit,
  onDelete,
}: CampaignsTableProps) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [campaignToDelete, setCampaignToDelete] = useState<CampaignWithStats | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDeleteClick = (campaign: CampaignWithStats) => {
    setCampaignToDelete(campaign);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!campaignToDelete) return;

    setIsDeleting(true);
    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("campaigns")
        .delete()
        .eq("id", campaignToDelete.id);

      if (error) throw error;

      onDelete(campaignToDelete.id);
    } catch (error) {
      console.error("Failed to delete campaign:", error);
    } finally {
      setIsDeleting(false);
      setDeleteDialogOpen(false);
      setCampaignToDelete(null);
    }
  };

  const columns: ColumnDef<CampaignWithStats>[] = [
    {
      accessorKey: "name",
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Campaign
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const campaign = row.original;
        return (
          <div>
            <div className="font-medium">{campaign.name}</div>
            {campaign.candidate_name && (
              <div className="text-sm text-muted-foreground">
                {campaign.candidate_name}
              </div>
            )}
          </div>
        );
      },
    },
    {
      accessorKey: "is_active",
      header: "Status",
      cell: ({ row }) => {
        const isActive = row.getValue("is_active") as boolean;
        return (
          <Badge variant={isActive ? "default" : "secondary"}>
            {isActive ? "Active" : "Inactive"}
          </Badge>
        );
      },
    },
    {
      id: "info",
      header: "Info",
      cell: ({ row }) => {
        const campaign = row.original;
        return (
          <div className="space-y-1">
            {campaign.district && (
              <div className="flex items-center gap-1 text-sm">
                <MapPin className="h-3 w-3 text-muted-foreground" />
                {campaign.district}
              </div>
            )}
            {campaign.election_date && (
              <div className="flex items-center gap-1 text-sm">
                <Calendar className="h-3 w-3 text-muted-foreground" />
                {new Date(campaign.election_date).toLocaleDateString()}
              </div>
            )}
          </div>
        );
      },
    },
    {
      id: "stats",
      header: "Stats",
      cell: ({ row }) => {
        const campaign = row.original;
        return (
          <div className="space-y-1 text-sm">
            <div className="flex items-center gap-1">
              <Users className="h-3 w-3 text-muted-foreground" />
              <span>{campaign.memberCount} members</span>
            </div>
            <div className="flex items-center gap-1">
              <Target className="h-3 w-3 text-muted-foreground" />
              <span>{campaign.voterCount.toLocaleString()} voters</span>
            </div>
          </div>
        );
      },
    },
    {
      id: "contacts",
      header: "Contacts",
      cell: ({ row }) => {
        const campaign = row.original;
        return (
          <div className="text-sm">
            <div>{campaign.totalContacts.toLocaleString()} total</div>
            <div className="text-green-600">
              {campaign.positiveResponses.toLocaleString()} positive
            </div>
          </div>
        );
      },
    },
    {
      id: "branding",
      header: "Branding",
      cell: ({ row }) => {
        const campaign = row.original;
        return (
          <div className="flex gap-2">
            <div
              className="h-6 w-6 rounded border"
              style={{ backgroundColor: campaign.primary_color }}
              title="Primary color"
            />
            <div
              className="h-6 w-6 rounded border"
              style={{ backgroundColor: campaign.secondary_color }}
              title="Secondary color"
            />
          </div>
        );
      },
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const campaign = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <span className="sr-only">Open menu</span>
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Actions</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => onEdit(campaign)}>
                <Edit className="mr-2 h-4 w-4" />
                Edit Campaign
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={() => handleDeleteClick(campaign)}
                className="text-destructive"
              >
                <Trash2 className="mr-2 h-4 w-4" />
                Delete
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const table = useReactTable({
    data: campaigns,
    columns,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    state: {
      sorting,
    },
  });

  if (campaigns.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12">
          <Target className="h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium mb-2">No campaigns yet</h3>
          <p className="text-muted-foreground text-center max-w-sm">
            Create your first campaign to start organizing your canvassing efforts.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>All Campaigns</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                {table.getHeaderGroups().map((headerGroup) => (
                  <TableRow key={headerGroup.id}>
                    {headerGroup.headers.map((header) => (
                      <TableHead key={header.id}>
                        {header.isPlaceholder
                          ? null
                          : flexRender(
                              header.column.columnDef.header,
                              header.getContext()
                            )}
                      </TableHead>
                    ))}
                  </TableRow>
                ))}
              </TableHeader>
              <TableBody>
                {table.getRowModel().rows?.length ? (
                  table.getRowModel().rows.map((row) => (
                    <TableRow key={row.id}>
                      {row.getVisibleCells().map((cell) => (
                        <TableCell key={cell.id}>
                          {flexRender(
                            cell.column.columnDef.cell,
                            cell.getContext()
                          )}
                        </TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell
                      colSpan={columns.length}
                      className="h-24 text-center"
                    >
                      No campaigns found.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>

          <div className="flex items-center justify-between py-4">
            <div className="text-sm text-muted-foreground">
              {campaigns.length} campaign{campaigns.length !== 1 ? "s" : ""}
            </div>
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.previousPage()}
                disabled={!table.getCanPreviousPage()}
              >
                <ChevronLeft className="h-4 w-4" />
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.nextPage()}
                disabled={!table.getCanNextPage()}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Campaign</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete &quot;{campaignToDelete?.name}&quot;?
              This will also delete all associated data including voters,
              cut lists, and contact history. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleConfirmDelete}
              disabled={isDeleting}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {isDeleting ? "Deleting..." : "Delete"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
