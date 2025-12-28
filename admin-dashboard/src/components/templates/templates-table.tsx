"use client";

import { useState } from "react";
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
import {
  MoreHorizontal,
  Pencil,
  Trash2,
  Copy,
  Users,
  Map,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { TemplateDialog } from "./template-dialog";
import { AssignUsersDialog } from "./assign-users-dialog";
import { AssignCutListsDialog } from "./assign-cut-lists-dialog";
import type {
  Candidate,
  TextTemplateWithCounts,
  TemplateCategory,
} from "@/types/templates";
import { CATEGORY_LABELS, CATEGORY_COLORS } from "@/types/templates";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: string;
}

interface CutList {
  id: string;
  name: string;
  voter_count: number;
}

interface TemplatesTableProps {
  templates: TextTemplateWithCounts[];
  candidates: Candidate[];
  users: UserProfile[];
  cutLists: CutList[];
  onRefresh: () => void;
}

export function TemplatesTable({
  templates,
  candidates,
  users,
  cutLists,
  onRefresh,
}: TemplatesTableProps) {
  const [editTemplate, setEditTemplate] = useState<TextTemplateWithCounts | null>(null);
  const [deleteTemplate, setDeleteTemplate] = useState<TextTemplateWithCounts | null>(null);
  const [assignUsersTemplate, setAssignUsersTemplate] = useState<TextTemplateWithCounts | null>(null);
  const [assignCutListsTemplate, setAssignCutListsTemplate] = useState<TextTemplateWithCounts | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  const handleDelete = async () => {
    if (!deleteTemplate) return;

    try {
      const supabase = createClient();
      await supabase.from("text_templates").delete().eq("id", deleteTemplate.id);
      onRefresh();
    } catch (error) {
      console.error("Failed to delete template:", error);
    } finally {
      setDeleteTemplate(null);
    }
  };

  const handleDuplicate = async (template: TextTemplateWithCounts) => {
    try {
      const supabase = createClient();
      await supabase.from("text_templates").insert({
        candidate_id: template.candidate_id,
        district: template.district,
        position: template.position,
        category: template.category,
        name: `Copy of ${template.name}`,
        message: template.message,
        icon_name: template.icon_name,
        is_active: true,
        display_order: template.display_order,
      });
      onRefresh();
    } catch (error) {
      console.error("Failed to duplicate template:", error);
    }
  };

  const getCategoryBadge = (category: TemplateCategory) => {
    const color = CATEGORY_COLORS[category];
    return (
      <Badge className={`${color} text-white`}>
        {CATEGORY_LABELS[category]}
      </Badge>
    );
  };

  return (
    <>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Category</TableHead>
            <TableHead>Candidate</TableHead>
            <TableHead>District</TableHead>
            <TableHead>Message</TableHead>
            <TableHead>Assigned To</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="w-[50px]"></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {templates.length === 0 ? (
            <TableRow>
              <TableCell colSpan={8} className="text-center text-muted-foreground py-8">
                No templates found
              </TableCell>
            </TableRow>
          ) : (
            templates.map((template) => (
              <TableRow key={template.id}>
                <TableCell className="font-medium">{template.name}</TableCell>
                <TableCell>{getCategoryBadge(template.category)}</TableCell>
                <TableCell>
                  {template.candidate?.name || (
                    <span className="text-muted-foreground">—</span>
                  )}
                </TableCell>
                <TableCell>{template.district}</TableCell>
                <TableCell className="max-w-[200px]">
                  <p className="truncate text-sm text-muted-foreground">
                    {template.message}
                  </p>
                </TableCell>
                <TableCell>
                  <div className="flex gap-1">
                    {template.user_count > 0 && (
                      <Badge variant="outline" className="text-xs">
                        <Users className="h-3 w-3 mr-1" />
                        {template.user_count}
                      </Badge>
                    )}
                    {template.cut_list_count > 0 && (
                      <Badge variant="outline" className="text-xs">
                        <Map className="h-3 w-3 mr-1" />
                        {template.cut_list_count}
                      </Badge>
                    )}
                    {template.user_count === 0 && template.cut_list_count === 0 && (
                      <span className="text-muted-foreground text-sm">—</span>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant={template.is_active ? "default" : "secondary"}>
                    {template.is_active ? "Active" : "Inactive"}
                  </Badge>
                </TableCell>
                <TableCell>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon">
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem
                        onClick={() => {
                          setEditTemplate(template);
                          setDialogOpen(true);
                        }}
                      >
                        <Pencil className="mr-2 h-4 w-4" />
                        Edit
                      </DropdownMenuItem>
                      <DropdownMenuItem onClick={() => handleDuplicate(template)}>
                        <Copy className="mr-2 h-4 w-4" />
                        Duplicate
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        onClick={() => setAssignUsersTemplate(template)}
                      >
                        <Users className="mr-2 h-4 w-4" />
                        Assign to Users
                      </DropdownMenuItem>
                      <DropdownMenuItem
                        onClick={() => setAssignCutListsTemplate(template)}
                      >
                        <Map className="mr-2 h-4 w-4" />
                        Assign to Cut Lists
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        onClick={() => setDeleteTemplate(template)}
                        className="text-destructive"
                      >
                        <Trash2 className="mr-2 h-4 w-4" />
                        Delete
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      <TemplateDialog
        open={dialogOpen}
        onOpenChange={(open) => {
          setDialogOpen(open);
          if (!open) setEditTemplate(null);
        }}
        template={editTemplate}
        candidates={candidates}
        onSaved={onRefresh}
      />

      <AssignUsersDialog
        open={!!assignUsersTemplate}
        onOpenChange={(open) => !open && setAssignUsersTemplate(null)}
        template={assignUsersTemplate}
        users={users}
        onSaved={onRefresh}
      />

      <AssignCutListsDialog
        open={!!assignCutListsTemplate}
        onOpenChange={(open) => !open && setAssignCutListsTemplate(null)}
        template={assignCutListsTemplate}
        cutLists={cutLists}
        onSaved={onRefresh}
      />

      <AlertDialog
        open={!!deleteTemplate}
        onOpenChange={(open) => !open && setDeleteTemplate(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Template</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete &quot;{deleteTemplate?.name}&quot;?
              This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete}>Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
