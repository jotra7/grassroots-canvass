# Deployment Guide for Non-Technical Users

This guide walks you through deploying Grassroots Canvass from scratch. No coding experience required.

**Total Cost: $0/month** (using free tiers)
**Time Required: 1-2 hours**

---

## Table of Contents

1. [Overview](#overview)
2. [What You'll Need](#what-youll-need)
3. [Step 1: Set Up Supabase (Database)](#step-1-set-up-supabase-database)
4. [Step 2: Deploy the Admin Dashboard](#step-2-deploy-the-admin-dashboard)
5. [Step 3: Deploy the Mobile App](#step-3-deploy-the-mobile-app)
6. [Step 4: First-Time Setup](#step-4-first-time-setup)
7. [Importing Your Voter Data](#importing-your-voter-data)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Grassroots Canvass has three parts:

| Component | What It Does | Where It Runs |
|-----------|--------------|---------------|
| **Supabase** | Stores all your data (voters, users, results) | Cloud (free tier) |
| **Admin Dashboard** | Web interface for campaign managers | Vercel (free tier) |
| **Mobile App** | App for canvassers in the field | iOS/Android/Web |

All three use **free tiers** - you won't pay anything unless you exceed generous limits (thousands of users).

---

## What You'll Need

Before starting, gather these:

1. **Email address** - For creating accounts
2. **Voter data** - CSV file with voter names, addresses, phone numbers
3. **Mapbox account** - Free, for maps (optional but recommended)

**Accounts you'll create:**
- [Supabase](https://supabase.com) - Database (free)
- [Vercel](https://vercel.com) - Hosts the admin dashboard (free)
- [Mapbox](https://mapbox.com) - Maps (free tier: 50,000 map loads/month)
- [GitHub](https://github.com) - Stores the code (free)

---

## Step 1: Set Up Supabase (Database)

Supabase is where all your data lives. It's free for up to 500MB of data and 50,000 monthly active users.

### 1.1 Create a Supabase Account

1. Go to [supabase.com](https://supabase.com)
2. Click **Start your project** (green button)
3. Sign up with GitHub, Google, or email
4. Verify your email if required

### 1.2 Create a New Project

1. Click **New Project**
2. Fill in the details:
   - **Name**: `grassroots-canvass` (or your campaign name)
   - **Database Password**: Create a strong password and **save it somewhere safe**
   - **Region**: Choose the closest to your location
3. Click **Create new project**
4. Wait 2-3 minutes for setup to complete

### 1.3 Set Up the Database Tables

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New query**
3. Open this file in a new browser tab: [Initial Schema SQL](../flutter-app/supabase/migrations/00000000000000_initial_schema.sql)
4. Copy the ENTIRE contents of that file
5. Paste it into the SQL Editor
6. Click **Run** (or press Ctrl+Enter / Cmd+Enter)
7. You should see "Success. No rows returned" - this is correct!

### 1.4 Get Your API Keys

1. In Supabase, go to **Settings** (gear icon) → **API**
2. You'll see two important values:
   - **Project URL**: Looks like `https://abcdefgh.supabase.co`
   - **anon/public key**: A long string starting with `eyJ...`
3. **Copy both of these** - you'll need them in the next steps

### 1.5 Enable Email Authentication

1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled (it should be by default)
3. Optionally, go to **Authentication** → **Settings** and:
   - Disable "Confirm email" if you want users to log in immediately
   - Or keep it enabled for more security

---

## Step 2: Deploy the Admin Dashboard

The admin dashboard lets you manage voters, teams, territories, and view analytics.

### 2.1 Fork the Repository

1. Go to [github.com/jotra7/grassroots-canvass](https://github.com/jotra7/grassroots-canvass)
2. Click the **Fork** button (top right)
3. If prompted, select your GitHub account
4. Wait for the fork to complete

### 2.2 Deploy to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Click **Sign Up** and sign in with your GitHub account
3. Click **Add New...** → **Project**
4. Find `grassroots-canvass` in your repositories and click **Import**
5. Configure the project:
   - **Root Directory**: Click **Edit** and type `admin-dashboard`
   - **Framework Preset**: Should auto-detect as Next.js
6. Expand **Environment Variables** and add these three:

   | Name | Value |
   |------|-------|
   | `NEXT_PUBLIC_SUPABASE_URL` | Your Supabase Project URL |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Your Supabase anon key |
   | `NEXT_PUBLIC_MAPBOX_TOKEN` | Your Mapbox token (see below) |

7. Click **Deploy**
8. Wait 2-3 minutes for deployment
9. You'll get a URL like `grassroots-canvass.vercel.app` - this is your admin dashboard!

### 2.3 Get a Mapbox Token (for maps)

1. Go to [mapbox.com](https://mapbox.com)
2. Click **Sign up** and create a free account
3. After signing in, go to your **Account** page
4. Find **Default public token** and copy it
5. Go back to Vercel → Your project → **Settings** → **Environment Variables**
6. Add `NEXT_PUBLIC_MAPBOX_TOKEN` with your Mapbox token
7. Go to **Deployments** and click the three dots → **Redeploy**

---

## Step 3: Deploy the Mobile App

You have three options for the mobile app:

### Option A: Web App Only (Easiest - Recommended to Start)

The Flutter app can run as a web app. This is the fastest way to get started.

1. In Vercel, go to your project settings
2. You'll deploy the Flutter web build separately (instructions coming)

For now, **use the Admin Dashboard** - it has most features you need to get started.

### Option B: Build Mobile Apps (Requires Developer Accounts)

To publish to app stores, you need:
- **Apple Developer Account**: $99/year for iOS
- **Google Play Developer Account**: $25 one-time for Android

This requires technical setup. See [MOBILE_BUILD_GUIDE.md](./MOBILE_BUILD_GUIDE.md) for details.

### Option C: Use Codemagic (No-Code Mobile Builds)

[Codemagic](https://codemagic.io) can build your apps without installing anything:

1. Sign up at [codemagic.io](https://codemagic.io) with GitHub
2. Add your forked repository
3. Configure the Flutter build
4. Codemagic builds the apps for you

Free tier includes 500 build minutes/month.

---

## Step 4: First-Time Setup

### 4.1 Create Your Admin Account

1. Go to your admin dashboard URL (from Vercel)
2. Click **Sign Up**
3. Enter your email and password
4. Check your email for a confirmation link (if email confirmation is enabled)

### 4.2 Make Yourself an Admin

Since you're the first user, you need to manually set yourself as admin:

1. Go to Supabase → **Table Editor**
2. Click on the `user_profiles` table
3. Find your row (your email should be visible)
4. Click on the `role` cell and change it from `pending` to `admin`
5. Click **Save**

### 4.3 Refresh Your Dashboard

Go back to your admin dashboard and refresh the page. You should now have full admin access!

---

## Importing Your Voter Data

### Prepare Your CSV File

Your voter CSV should have these columns (column names must match exactly):

**Required columns:**
- `first_name` - Voter's first name
- `last_name` - Voter's last name

**Recommended columns:**
- `address` - Full street address
- `city` - City name
- `state` - State abbreviation (e.g., "AZ")
- `zip` - ZIP code
- `phone` - Phone number (any format)
- `email` - Email address
- `party` - Party affiliation (e.g., "DEM", "REP", "IND")
- `latitude` - GPS latitude (for map display)
- `longitude` - GPS longitude (for map display)

**Example CSV:**
```csv
first_name,last_name,address,city,state,zip,phone,party
John,Smith,123 Main St,Phoenix,AZ,85001,602-555-1234,DEM
Jane,Doe,456 Oak Ave,Phoenix,AZ,85002,602-555-5678,REP
```

### Import Through the Admin Dashboard

1. Log into your admin dashboard
2. Go to **Data** in the sidebar
3. Click **Import Voters**
4. Select your CSV file
5. Map your columns to the expected fields
6. Click **Import**

### Getting GPS Coordinates

If your voter data doesn't have latitude/longitude, you can geocode addresses:

**Free options:**
- [Geocodio](https://geocod.io) - 2,500 free lookups/day
- [Census Geocoder](https://geocoding.geo.census.gov/geocoder/) - Unlimited, US addresses only

---

## Troubleshooting

### "Invalid login credentials"
- Make sure you confirmed your email (check spam folder)
- Try resetting your password

### "Permission denied" errors
- Check that your role is set to `admin` in the `user_profiles` table
- Make sure you're logged in

### Maps not showing
- Verify your Mapbox token is correct in Vercel environment variables
- Redeploy after adding the token

### Voters not appearing
- Check that your CSV import completed successfully
- Verify voters exist in Supabase → Table Editor → `voters`

### Dashboard won't load
- Check browser console for errors (Right-click → Inspect → Console)
- Verify all environment variables are set in Vercel
- Try redeploying

---

## Getting Help

- **GitHub Issues**: [Report bugs or ask questions](https://github.com/jotra7/grassroots-canvass/issues)
- **Documentation**: Check other guides in the `/docs` folder

---

## Next Steps

Once you're set up:

1. **Import your voter data** - Upload your voter list
2. **Create cut lists** - Draw territories on the map for canvassers
3. **Invite your team** - They can sign up and you approve them
4. **Create templates** - Set up SMS and call script templates
5. **Start canvassing!** - Your team can log contacts and results
