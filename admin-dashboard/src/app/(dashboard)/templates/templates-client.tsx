"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  Plus,
  Search,
  MessageSquareText,
  Users as UsersIcon,
  ChevronDown,
  Phone,
} from "lucide-react";
import { TemplatesTable } from "@/components/templates/templates-table";
import { TemplateDialog } from "@/components/templates/template-dialog";
import { CallScriptsTable } from "@/components/templates/call-scripts-table";
import { CallScriptDialog } from "@/components/templates/call-script-dialog";
import { CandidatesTable } from "@/components/candidates/candidates-table";
import { CandidateDialog } from "@/components/candidates/candidate-dialog";
import type { Candidate, TextTemplateWithCounts, CallScript } from "@/types/templates";
import { CATEGORY_LABELS } from "@/types/templates";

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

interface TemplatesClientProps {
  data: {
    templates: TextTemplateWithCounts[];
    candidates: Candidate[];
    users: UserProfile[];
    cutLists: CutList[];
    callScripts: CallScript[];
  };
}

export function TemplatesClient({ data }: TemplatesClientProps) {
  const [templates, setTemplates] = useState(data.templates);
  const [candidates, setCandidates] = useState(data.candidates);
  const [callScripts, setCallScripts] = useState(data.callScripts);
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const [candidateFilter, setCandidateFilter] = useState<string>("all");
  const [templateDialogOpen, setTemplateDialogOpen] = useState(false);
  const [candidateDialogOpen, setCandidateDialogOpen] = useState(false);
  const [callScriptDialogOpen, setCallScriptDialogOpen] = useState(false);
  const [candidatesOpen, setCandidatesOpen] = useState(false);
  const [callScriptsOpen, setCallScriptsOpen] = useState(false);

  const handleRefresh = () => {
    window.location.reload();
  };

  // Filter templates
  const filteredTemplates = templates.filter((template) => {
    const matchesSearch =
      template.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      template.message.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesCategory =
      categoryFilter === "all" || template.category === categoryFilter;

    const matchesCandidate =
      candidateFilter === "all" ||
      (candidateFilter === "none" && !template.candidate_id) ||
      template.candidate_id === candidateFilter;

    return matchesSearch && matchesCategory && matchesCandidate;
  });

  // Get unique districts for potential filtering
  const districts = [...new Set(templates.map((t) => t.district))];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Templates</h1>
          <p className="text-muted-foreground">
            Manage text templates for canvassers
          </p>
        </div>
        <Button onClick={() => setTemplateDialogOpen(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Add Template
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Templates</CardTitle>
            <MessageSquareText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{templates.length}</div>
            <p className="text-xs text-muted-foreground">
              {templates.filter((t) => t.is_active).length} active
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Candidates</CardTitle>
            <UsersIcon className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{candidates.length}</div>
            <p className="text-xs text-muted-foreground">
              {candidates.filter((c) => c.is_active).length} active
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Districts</CardTitle>
            <MessageSquareText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{districts.length}</div>
            <p className="text-xs text-muted-foreground">
              with templates
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Categories</CardTitle>
            <MessageSquareText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">4</div>
            <p className="text-xs text-muted-foreground">
              Introduction, Follow-up, Reminder, Thank You
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Candidates Section (Collapsible) */}
      <Collapsible open={candidatesOpen} onOpenChange={setCandidatesOpen}>
        <Card>
          <CollapsibleTrigger asChild>
            <CardHeader className="cursor-pointer hover:bg-muted/50">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <UsersIcon className="h-5 w-5" />
                  <CardTitle>Candidates</CardTitle>
                  <span className="text-sm text-muted-foreground">
                    ({candidates.length})
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={(e) => {
                      e.stopPropagation();
                      setCandidateDialogOpen(true);
                    }}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Add Candidate
                  </Button>
                  <ChevronDown
                    className={`h-4 w-4 transition-transform ${
                      candidatesOpen ? "rotate-180" : ""
                    }`}
                  />
                </div>
              </div>
            </CardHeader>
          </CollapsibleTrigger>
          <CollapsibleContent>
            <CardContent className="pt-0">
              <CandidatesTable
                candidates={candidates}
                onRefresh={handleRefresh}
              />
            </CardContent>
          </CollapsibleContent>
        </Card>
      </Collapsible>

      {/* Call Scripts Section (Collapsible) */}
      <Collapsible open={callScriptsOpen} onOpenChange={setCallScriptsOpen}>
        <Card>
          <CollapsibleTrigger asChild>
            <CardHeader className="cursor-pointer hover:bg-muted/50">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Phone className="h-5 w-5" />
                  <CardTitle>Call Scripts</CardTitle>
                  <span className="text-sm text-muted-foreground">
                    ({callScripts.length})
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={(e) => {
                      e.stopPropagation();
                      setCallScriptDialogOpen(true);
                    }}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Add Script
                  </Button>
                  <ChevronDown
                    className={`h-4 w-4 transition-transform ${
                      callScriptsOpen ? "rotate-180" : ""
                    }`}
                  />
                </div>
              </div>
            </CardHeader>
          </CollapsibleTrigger>
          <CollapsibleContent>
            <CardContent className="pt-0">
              <CallScriptsTable
                scripts={callScripts}
                onRefresh={handleRefresh}
              />
            </CardContent>
          </CollapsibleContent>
        </Card>
      </Collapsible>

      {/* Templates Section */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Text Templates</CardTitle>
            <div className="flex items-center gap-2">
              <div className="relative">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search templates..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-8 w-[200px]"
                />
              </div>
              <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                <SelectTrigger className="w-[150px]">
                  <SelectValue placeholder="Category" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Categories</SelectItem>
                  {Object.entries(CATEGORY_LABELS).map(([key, label]) => (
                    <SelectItem key={key} value={key}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={candidateFilter} onValueChange={setCandidateFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Candidate" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Candidates</SelectItem>
                  <SelectItem value="none">No Candidate</SelectItem>
                  {candidates
                    .filter((c) => c.is_active)
                    .map((candidate) => (
                      <SelectItem key={candidate.id} value={candidate.id}>
                        {candidate.name}
                      </SelectItem>
                    ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <TemplatesTable
            templates={filteredTemplates}
            candidates={candidates}
            users={data.users}
            cutLists={data.cutLists}
            onRefresh={handleRefresh}
          />
        </CardContent>
      </Card>

      {/* Dialogs */}
      <TemplateDialog
        open={templateDialogOpen}
        onOpenChange={setTemplateDialogOpen}
        template={null}
        candidates={candidates}
        onSaved={handleRefresh}
      />

      <CandidateDialog
        open={candidateDialogOpen}
        onOpenChange={setCandidateDialogOpen}
        candidate={null}
        onSaved={handleRefresh}
      />

      <CallScriptDialog
        open={callScriptDialogOpen}
        onOpenChange={setCallScriptDialogOpen}
        script={null}
        onSaved={handleRefresh}
      />
    </div>
  );
}
