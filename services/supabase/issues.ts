import { supabase } from '../../lib/supabase/client';
import { DbIssue } from '../../types/database';
import { IssueData } from '../../types/issue';

const mapDbIssue = (issue: DbIssue): IssueData => {
  const formatDate = (isoString: string) => {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toISOString().replace('T', ' ').substring(0, 16);
  };
  
  return {
    id: issue.id,
    userName: issue.user_name,
    title: issue.title,
    description: issue.description || '',
    priority: issue.priority,
    status: issue.status,
    createdAt: formatDate(issue.created_at),
  };
};

export async function getIssues(): Promise<IssueData[]> {
  const { data, error } = await supabase
    .from('issues')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching issues:', error);
    throw error;
  }
  
  return (data || []).map((row) => mapDbIssue(row as DbIssue));
}

export async function updateIssueStatus(
  issueId: string, 
  status: IssueData['status']
): Promise<IssueData> {
  const { data, error } = await supabase
    .from('issues')
    .update({ status })
    .eq('id', issueId)
    .select()
    .single();
  
  if (error) {
    console.error('Error updating issue status:', error);
    throw error;
  }
  
  return mapDbIssue(data as DbIssue);
}

export async function updateIssuePriority(
  issueId: string, 
  priority: IssueData['priority']
): Promise<IssueData> {
  const { data, error } = await supabase
    .from('issues')
    .update({ priority })
    .eq('id', issueId)
    .select()
    .single();
  
  if (error) {
    console.error('Error updating issue priority:', error);
    throw error;
  }
  
  return mapDbIssue(data as DbIssue);
}

export async function deleteIssue(issueId: string): Promise<boolean> {
  const { error } = await supabase
    .from('issues')
    .delete()
    .eq('id', issueId);
  
  if (error) {
    console.error('Error deleting issue:', error);
    throw error;
  }
  
  return true;
}
export type { IssueData };
