# Grassroots Canvass

Open-source voter canvassing platform for grassroots campaigns and independent candidates.

**No coding required.** Deploy for free using cloud services.

---

## Why Grassroots Canvass?

Most canvassing tools are expensive ($500-5000/month) or locked to party infrastructure. This platform is:

- **Free** - Runs entirely on free tiers (Supabase, Vercel, Mapbox)
- **Open Source** - AGPL-3.0 license, yours to modify and improve
- **Independent** - Not tied to any party or vendor
- **Full-Featured** - Everything you need for a modern campaign

---

## Features

### Mobile App (iOS, Android, Web)
- Offline-first with automatic sync
- Walking route optimization
- Interactive map with party-colored markers
- Contact tracking (calls, texts, door knocks)
- 28 canvass disposition options
- Voice notes for detailed feedback
- PDF walk sheet exports

### Admin Dashboard (Web)
- Campaign analytics and reporting
- Team management with role-based access
- Voter data import/export (CSV)
- Territory management with map-based drawing
- SMS and call script templates

---

## Quick Start (No Coding!)

**Time: ~1 hour | Cost: $0**

1. **Create Supabase project** - [supabase.com](https://supabase.com) (free)
2. **Run the database setup** - Copy/paste one SQL file
3. **Deploy to Vercel** - [vercel.com](https://vercel.com) (free)
4. **Import your voter data** - Upload a CSV
5. **Invite your team** - They sign up, you approve

**[Full Quick Start Guide](docs/QUICK_START.md)**

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick Start](docs/QUICK_START.md) | Get running in under an hour |
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | Complete setup instructions |
| [Supabase Setup](docs/SUPABASE_SETUP.md) | Database configuration |
| [Voter Data Guide](docs/VOTER_DATA_GUIDE.md) | Importing and managing voters |
| [Team Management](docs/TEAM_MANAGEMENT_GUIDE.md) | Setting up your canvass team |
| [Mobile Build Guide](docs/MOBILE_BUILD_GUIDE.md) | App store publishing |
| [FAQ](docs/FAQ.md) | Common questions answered |

---

## Cost Breakdown

| Service | Free Tier Limits | When You'd Pay |
|---------|------------------|----------------|
| Supabase | 500MB database, 50K users | Large campaigns |
| Vercel | 100GB bandwidth | Heavy traffic |
| Mapbox | 50K map loads/month | Very active teams |

**For most campaigns: completely free.**

App store publishing (optional):
- Apple App Store: $99/year
- Google Play: $25 one-time

---

## Tech Stack

For developers who want to contribute or customize:

- **Mobile App**: Flutter, Dart, Riverpod, Drift (SQLite)
- **Admin Dashboard**: Next.js 15, TypeScript, TanStack Query, shadcn/ui
- **Backend**: Supabase (PostgreSQL, Auth, Row-Level Security)
- **Maps**: flutter_map, Leaflet, Mapbox tiles

---

## Project Structure

```
grassroots-canvass/
├── flutter-app/           # Mobile app (iOS/Android/Web)
│   ├── lib/               # Dart source code
│   ├── ios/               # iOS project files
│   ├── android/           # Android project files
│   └── supabase/          # Database migrations
├── admin-dashboard/       # Web admin dashboard
│   └── src/               # Next.js source code
└── docs/                  # Documentation
```

---

## User Roles

| Role | Access |
|------|--------|
| **Admin** | Full access - manage everything |
| **Team Lead** | Manage territories and view team stats |
| **Canvasser** | View assigned areas, record contacts |
| **Pending** | New signups awaiting approval |

---

## Security

- **Authentication**: Email/password with Supabase Auth
- **Authorization**: Row-Level Security policies
- **Data Isolation**: Users only see what they're assigned
- **Encryption**: All data over HTTPS

---

## Contributing

Contributions are welcome! Areas where help is needed:

- Bug fixes and testing
- Documentation improvements
- Translations
- New features

Please open an issue to discuss before submitting large PRs.

---

## License

**AGPL-3.0** - This ensures the platform remains free and open for grassroots campaigns.

- You can use it for any campaign (commercial or non-profit)
- You can modify it for your needs
- If you distribute modifications, they must also be open source
- SaaS deployments must share source code

This protects independent candidates from having their tool co-opted by well-funded interests.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/jotra7/grassroots-canvass/issues)
- **Questions**: [GitHub Discussions](https://github.com/jotra7/grassroots-canvass/discussions)
- **Documentation**: [/docs folder](docs/)

---

*Built for people-powered campaigns.*
