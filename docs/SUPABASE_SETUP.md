# Supabase Setup Guide

Complete guide to setting up Supabase for Grassroots Canvass. This covers account creation, database setup, authentication, and security configuration.

**Time Required**: 30-45 minutes
**Cost**: Free (Supabase free tier)

---

## Table of Contents

1. [Create Your Supabase Account](#1-create-your-supabase-account)
2. [Create a New Project](#2-create-a-new-project)
3. [Run the Database Schema](#3-run-the-database-schema)
4. [Configure Authentication](#4-configure-authentication)
5. [Get Your API Keys](#5-get-your-api-keys)
6. [Configure Storage (for Voice Notes)](#6-configure-storage-for-voice-notes)
7. [Set Up Email Templates](#7-set-up-email-templates)
8. [Understanding Your Database](#8-understanding-your-database)
9. [Backup and Maintenance](#9-backup-and-maintenance)

---

## 1. Create Your Supabase Account

1. Go to [supabase.com](https://supabase.com)
2. Click **Start your project**
3. Sign up using:
   - **GitHub** (recommended - easiest)
   - **Google**
   - **Email/Password**
4. If using email, check your inbox and verify your email address

---

## 2. Create a New Project

1. After signing in, click **New Project**
2. If you have multiple organizations, select one (or use the default)
3. Fill in the project details:

   | Field | What to Enter |
   |-------|---------------|
   | **Name** | `grassroots-canvass` (or your campaign name) |
   | **Database Password** | Create a strong password (save this!) |
   | **Region** | Choose closest to your users |

4. Click **Create new project**
5. Wait 2-3 minutes while Supabase provisions your database

**Important**: Save your database password somewhere secure. You'll need it to connect directly to the database later.

---

## 3. Run the Database Schema

The schema creates all the tables, security policies, and functions needed for the app.

### 3.1 Open the SQL Editor

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New query** (top right)

### 3.2 Get the Schema SQL

1. Open this file: [00000000000000_initial_schema.sql](../flutter-app/supabase/migrations/00000000000000_initial_schema.sql)
2. Click the **Raw** button to see the plain text
3. Select all and copy (Ctrl+A, Ctrl+C or Cmd+A, Cmd+C)

### 3.3 Run the Schema

1. Paste the SQL into the Supabase SQL Editor
2. Click **Run** (or press Ctrl+Enter / Cmd+Enter)
3. Wait for it to complete

**Expected result**: "Success. No rows returned"

If you see errors:
- Make sure you copied the entire file
- Try running it again (some errors resolve on retry)
- Check that you're in a fresh project with no existing tables

### 3.4 Verify the Tables

1. Go to **Table Editor** in the left sidebar
2. You should see these tables:
   - `user_profiles`
   - `voters`
   - `cut_lists`
   - `cut_list_voters`
   - `cut_list_assignments`
   - `contact_history`
   - `candidates`
   - `text_templates`
   - `template_user_assignments`
   - `template_cut_list_assignments`

---

## 4. Configure Authentication

### 4.1 Email Settings

1. Go to **Authentication** → **Providers**
2. Confirm **Email** is enabled (should be by default)
3. Click on **Email** to expand settings

Recommended settings for campaigns:
- **Confirm email**: OFF (for quick volunteer onboarding)
- **Secure email change**: ON
- **Secure password change**: ON

### 4.2 Password Requirements

1. Go to **Authentication** → **Settings**
2. Under **Password Requirements**:
   - Minimum password length: 8 (or higher)

### 4.3 Rate Limiting (Prevent Abuse)

Default limits are fine, but verify:
- Rate limit for signup: 10 per hour (per IP)
- Rate limit for token requests: 30 per hour

---

## 5. Get Your API Keys

You need two values to connect your apps to Supabase.

1. Go to **Settings** (gear icon) → **API**
2. Find and copy:

   | Value | Where to Find It | Looks Like |
   |-------|------------------|------------|
   | **Project URL** | Under "Project URL" | `https://abcdefgh.supabase.co` |
   | **anon/public key** | Under "Project API keys" | `eyJhbGciOiJIUzI1NiIs...` (long string) |

**Save these somewhere safe** - you'll need them for:
- Admin dashboard (Vercel environment variables)
- Flutter app configuration

**Security note**: The `anon` key is safe to use in client apps. It's not a secret. The `service_role` key IS secret - never expose it publicly.

---

## 6. Configure Storage (for Voice Notes)

The app supports recording voice notes during canvassing. These need storage.

### 6.1 Create a Storage Bucket

1. Go to **Storage** in the left sidebar
2. Click **New bucket**
3. Configure:
   - **Name**: `voice-notes`
   - **Public bucket**: OFF (keep private)
   - **Allowed MIME types**: `audio/*`
   - **File size limit**: 10MB

4. Click **Create bucket**

### 6.2 Set Bucket Policies

1. Click on the `voice-notes` bucket
2. Go to **Policies** tab
3. Click **New Policy**
4. Choose **Create a policy from scratch**
5. Add these policies:

**Allow users to upload their own recordings:**
```sql
-- Policy name: Users can upload voice notes
CREATE POLICY "Users can upload voice notes"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'voice-notes');
```

**Allow users to read voice notes:**
```sql
-- Policy name: Users can read voice notes
CREATE POLICY "Users can read voice notes"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'voice-notes');
```

---

## 7. Set Up Email Templates

Customize the emails users receive when signing up or resetting passwords.

1. Go to **Authentication** → **Email Templates**
2. Edit each template as needed:

### Confirm Signup (if enabled)
```
Subject: Confirm your Grassroots Canvass account

Hi,

Click the link below to confirm your account:

{{ .ConfirmationURL }}

Welcome to the team!
```

### Reset Password
```
Subject: Reset your Grassroots Canvass password

Hi,

Click the link below to reset your password:

{{ .ConfirmationURL }}

If you didn't request this, you can ignore this email.
```

### Magic Link (if you enable passwordless login)
```
Subject: Your Grassroots Canvass login link

Hi,

Click below to log in:

{{ .ConfirmationURL }}

This link expires in 1 hour.
```

---

## 8. Understanding Your Database

### Tables Overview

| Table | Purpose |
|-------|---------|
| `user_profiles` | Campaign team members (canvassers, team leads, admins) |
| `voters` | Voter records with contact info and canvass results |
| `cut_lists` | Geographic territories drawn on the map |
| `cut_list_voters` | Links voters to cut lists |
| `cut_list_assignments` | Assigns team members to cut lists |
| `contact_history` | Log of all calls, texts, and door knocks |
| `candidates` | Candidates your campaign is supporting |
| `text_templates` | SMS message templates |
| `template_*_assignments` | Links templates to users/cut lists |

### User Roles

The `role` column in `user_profiles`:

| Role | Access Level |
|------|--------------|
| `pending` | Just signed up, waiting for approval |
| `canvasser` | Can view assigned cut lists, record results |
| `team_lead` | Can view team stats, manage cut lists |
| `admin` | Full access to everything |

### Row Level Security (RLS)

RLS policies control what each user can see:
- **Canvassers** only see voters in their assigned cut lists
- **Team leads** see all voters in cut lists they manage
- **Admins** see everything

This is automatically enforced - you don't need to do anything.

---

## 9. Backup and Maintenance

### Automatic Backups (Pro Plan)

Free tier doesn't include automatic backups. Options:

1. **Upgrade to Pro ($25/month)** - Daily backups, point-in-time recovery
2. **Manual exports** - Periodically export your data

### Manual Data Export

1. Go to **Table Editor**
2. Select a table (e.g., `voters`)
3. Click the **Export** button (download icon)
4. Choose CSV or JSON format

### Database Size Limits

Free tier: **500 MB** database size

To check your usage:
1. Go to **Settings** → **Usage**
2. View "Database size"

If approaching limit:
- Delete old contact history records
- Remove unused voters
- Or upgrade to Pro plan

### Monitoring

1. Go to **Settings** → **Usage** to see:
   - Database size
   - API requests
   - Auth users
   - Storage usage

---

## Troubleshooting

### "Permission denied" errors

1. Check RLS policies are enabled:
   - Go to **Table Editor** → Select table → **RLS** toggle should be ON
2. Verify the user's role in `user_profiles`

### "Invalid API key" errors

1. Verify you're using the correct Project URL
2. Verify you're using the `anon` key (not `service_role`)
3. Check for extra spaces when copying

### "Database error" on signup

1. Check that the schema ran successfully
2. Verify the `user_profiles` table exists
3. Check the trigger on auth.users is working

### Users can't see any voters

1. Check user is approved (role is not `pending`)
2. Check user is assigned to a cut list
3. Check cut list has voters assigned

---

## Next Steps

Once Supabase is set up:

1. **Deploy the admin dashboard** - See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
2. **Import voter data** - See [VOTER_DATA_GUIDE.md](./VOTER_DATA_GUIDE.md)
3. **Set up your team** - See [TEAM_MANAGEMENT_GUIDE.md](./TEAM_MANAGEMENT_GUIDE.md)
