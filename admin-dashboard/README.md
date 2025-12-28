# Grassroots Canvass - Admin Dashboard

Admin dashboard for managing grassroots voter canvassing campaigns. Built with Next.js and shares the same Supabase backend as the Flutter mobile app.

## Tech Stack

- **Framework**: Next.js 15 (App Router) with TypeScript
- **UI**: shadcn/ui + Tailwind CSS + Lucide icons
- **State**: TanStack Query (server state)
- **Charts**: Recharts
- **Tables**: TanStack Table
- **Forms**: React Hook Form + Zod
- **Maps**: Leaflet + react-leaflet with Mapbox tiles
- **Files**: PapaParse (CSV)

## Features

- **Dashboard Overview**: Key metrics, contact trends, canvass results breakdown
- **Voter Management**: Search, filter, view/edit voters, contact history
- **Cut List Management**: Create and edit cut lists with map-based polygon drawing
- **Team Management**: User approval, role management, activity tracking
- **Template Management**: Configure SMS and call script templates
- **Data Import/Export**: CSV import wizard with field mapping
- **Dark Mode**: System/light/dark theme support

## Development

```bash
# Install dependencies
npm install

# Run development server (http://localhost:3000)
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Environment Variables

Create a `.env.local` file with:

```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_PUBLIC_MAPBOX_TOKEN=your_mapbox_token
```

## Deployment

The app can be deployed using a standalone Next.js build with PM2 and nginx.

```bash
# Build production bundle
npm run build

# Copy static assets to standalone
cp -r public .next/standalone/public
cp -r .next/static .next/standalone/.next/static

# Deploy to server
rsync -avz .next/standalone/ user@yourserver:/var/www/grassroots-canvass-admin/

# On server: start with PM2
pm2 start server.js --name grassroots-canvass-admin
```

## Project Structure

```
src/
├── app/
│   ├── (auth)/login/          # Login page
│   ├── (dashboard)/           # Protected dashboard routes
│   │   ├── page.tsx           # Overview/home
│   │   ├── voters/            # Voter list and detail pages
│   │   ├── cut-lists/         # Cut list management
│   │   ├── team/              # Team/user management
│   │   ├── templates/         # SMS and call templates
│   │   └── settings/          # App settings
│   └── api/                   # API routes
├── components/
│   ├── ui/                    # shadcn components
│   ├── dashboard/             # Dashboard shell components
│   ├── analytics/             # Chart components
│   ├── voters/                # Voter-related components
│   ├── cut-lists/             # Cut list components
│   └── team/                  # Team management components
├── lib/
│   ├── supabase/              # Supabase client setup
│   └── utils/                 # Utility functions
└── types/                     # TypeScript types
```

## Related Projects

- **Grassroots Canvass Mobile**: Flutter app for canvassers (iOS/Android/Web)
- **Supabase Backend**: Shared PostgreSQL database and authentication

## License

AGPL-3.0 - See LICENSE file
