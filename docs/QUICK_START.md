# Quick Start Guide

Get Grassroots Canvass running in under an hour.

---

## The 5-Step Setup

### Step 1: Create Supabase Project (10 min)

1. Go to [supabase.com](https://supabase.com) → Sign up (free)
2. Click **New Project** → Name it, set password, pick region
3. Wait 2 min for setup
4. Go to **SQL Editor** → **New query**
5. Paste contents of [`flutter-app/supabase/migrations/00000000000000_initial_schema.sql`](../flutter-app/supabase/migrations/00000000000000_initial_schema.sql)
6. Click **Run**
7. Go to **Settings** → **API** → Copy your **Project URL** and **anon key**

### Step 2: Deploy Admin Dashboard (10 min)

1. Fork this repo on GitHub
2. Go to [vercel.com](https://vercel.com) → Sign in with GitHub
3. Click **Add New** → **Project** → Select your fork
4. Set **Root Directory** to `admin-dashboard`
5. Add environment variables:
   ```
   NEXT_PUBLIC_SUPABASE_URL = your-project-url
   NEXT_PUBLIC_SUPABASE_ANON_KEY = your-anon-key
   NEXT_PUBLIC_MAPBOX_TOKEN = (get from mapbox.com, free)
   ```
6. Click **Deploy**

### Step 3: Create Admin Account (5 min)

1. Go to your Vercel URL
2. Click **Sign Up** → Create account
3. In Supabase → **Table Editor** → `user_profiles`
4. Change your `role` from `pending` to `admin`
5. Refresh your dashboard

### Step 4: Import Voters (15 min)

1. Prepare CSV with columns: `first_name`, `last_name`, `address`, `city`, `state`, `zip`, `phone`, `party`
2. Add `latitude`, `longitude` columns (geocode addresses if needed)
3. In dashboard → **Data** → **Import Voters**
4. Upload and map columns

### Step 5: Create Territory & Invite Team (10 min)

1. Go to **Cut Lists** → **Create New**
2. Draw a polygon on the map
3. Share your app URL with volunteers
4. Approve them in **Team** section
5. Assign them to territories

**Done!** Your team can now canvass.

---

## What's Next?

- [Full Deployment Guide](./DEPLOYMENT_GUIDE.md) - Detailed setup instructions
- [Voter Data Guide](./VOTER_DATA_GUIDE.md) - Importing and managing voters
- [Team Management Guide](./TEAM_MANAGEMENT_GUIDE.md) - Organizing your volunteers
- [Mobile Build Guide](./MOBILE_BUILD_GUIDE.md) - Publishing to app stores

---

## Costs

| Service | Free Tier | Paid (if needed) |
|---------|-----------|------------------|
| Supabase | 500MB, 50K users | $25/mo Pro |
| Vercel | 100GB bandwidth | $20/mo Pro |
| Mapbox | 50K map loads/mo | ~$0.50/1K after |
| Apple Developer | N/A | $99/year |
| Google Play | N/A | $25 one-time |

**Web-only deployment: $0/month**
**With mobile apps: $124 first year**
