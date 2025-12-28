# Frequently Asked Questions

Common questions about deploying and using Grassroots Canvass.

---

## General Questions

### What is Grassroots Canvass?

An open-source voter canvassing platform designed for grassroots campaigns and independent candidates. It includes:
- A mobile app for canvassers (iOS, Android, Web)
- An admin dashboard for campaign managers
- Supabase backend for data storage

### How much does it cost to run?

**$0/month** using free tiers:
- Supabase: Free up to 500MB database, 50K monthly users
- Vercel: Free for hobby projects
- Mapbox: 50K free map loads/month

You only pay if you need mobile app store presence ($99/year Apple, $25 one-time Google).

### Do I need coding experience?

No. The deployment guide walks you through every step. You'll copy/paste some text, but no coding required.

### Can I customize the app for my campaign?

Yes! You can:
- Change colors and branding
- Modify canvass result options
- Create custom SMS/call templates
- Add your own voter data fields

---

## Technical Questions

### Where is my data stored?

In Supabase, a hosted PostgreSQL database. Your project is:
- On Supabase's cloud infrastructure
- Protected by row-level security
- Encrypted in transit (HTTPS)
- Backed up daily (on paid plans)

### Is it secure?

Yes. Security features include:
- **Authentication**: Email/password with optional 2FA
- **Authorization**: Role-based access (admin/team lead/canvasser)
- **Row-Level Security**: Users only see data they're allowed to
- **Encryption**: All data transmitted over HTTPS
- **No shared tenancy**: Your database is isolated

### Can multiple campaigns use the same deployment?

Currently, each deployment is for one campaign. Multi-campaign support is planned for a future release.

### Does it work offline?

The mobile app works offline:
- Voters are cached locally
- Canvass results saved offline
- Auto-syncs when connection returns

The admin dashboard requires internet.

### What happens if Supabase goes down?

The mobile app continues working offline. Data syncs when Supabase is back. For critical elections, consider Supabase Pro ($25/mo) for better uptime SLA.

---

## Data & Privacy

### Where do I get voter data?

- **State/County Elections Office**: Most states sell or provide voter files
- **State Party**: If affiliated, they may provide data
- **Commercial vendors**: L2, TargetSmart, etc.
- **Your own lists**: Petition signers, event attendees

### Is voter data included?

No. You must provide your own voter data. This app is just the tool for managing and canvassing with that data.

### How do I handle Do Not Contact requests?

1. Find the voter in the system
2. Set their result to "Do Not Contact"
3. They're excluded from future contact lists

### Is this GDPR/CCPA compliant?

The platform supports compliance, but you're responsible for:
- Having a privacy policy
- Honoring data deletion requests
- Only using data for stated purposes

---

## Mobile App Questions

### Do I need to publish to app stores?

No. Options:
1. **Web-only**: Access via browser (no store needed)
2. **PWA**: Users "Add to Home Screen" from browser
3. **App stores**: Publish for native experience (costs $124)

### Why does Apple require $99/year?

Apple charges for:
- Access to developer tools
- App Store distribution
- App review and security scanning

There's no free alternative for iOS App Store.

### Can I use TestFlight for free?

Yes! TestFlight lets you distribute iOS apps to up to 10,000 testers without App Store review. You still need the $99 developer account.

### How long does app review take?

- **Apple**: Usually 24-48 hours, sometimes longer
- **Google**: Usually 2-7 days for new apps

### My app got rejected. What do I do?

Common fixes:
- Add a privacy policy URL
- Make permission descriptions more specific
- Remove placeholder/test content
- Ensure demo account works

See [MOBILE_BUILD_GUIDE.md](./MOBILE_BUILD_GUIDE.md) for detailed rejection reasons.

---

## Canvassing Operations

### How many voters should be in a territory?

- **Door-to-door**: 50-100 addresses per 3-4 hour session
- **Phone banking**: 100-200 calls per session
- Consider travel time between locations

### What are the canvass result options?

Positive:
- Supportive, Strong Support, Leaning
- Willing to Volunteer, Requested Sign

Negative:
- Opposed, Strongly Opposed
- Do Not Contact, Refused

Neutral:
- Undecided, Needs Info
- Callback Requested, Left Literature

Other:
- Not Home, Wrong Number, Moved
- Deceased, Language Barrier

### Can canvassers see all voter data?

No. Canvassers only see:
- Voters in their assigned territories
- Basic contact info (name, address, phone)
- Previous canvass results

They cannot see other territories or export data.

### How do I track team performance?

The Analytics page shows:
- Contacts per person
- Results breakdown
- Territory completion rates
- Daily/weekly trends

---

## Troubleshooting

### Users can't sign up

1. Check Supabase auth is configured
2. Verify email provider settings
3. Check browser console for errors

### Voters don't appear on map

1. Verify voters have latitude/longitude
2. Check coordinates are valid numbers
3. Ensure map is centered on the right area

### Sync isn't working

1. Check internet connection
2. Verify Supabase is accessible
3. Force sync in app settings
4. Check Supabase for errors in logs

### Dashboard shows "Permission denied"

1. Verify user role in `user_profiles` table
2. Make sure role is not "pending"
3. Clear browser cache and re-login

---

## Getting Help

### Where can I report bugs?

[GitHub Issues](https://github.com/jotra7/grassroots-canvass/issues)

### Where can I request features?

[GitHub Discussions](https://github.com/jotra7/grassroots-canvass/discussions)

### Is there paid support?

Not currently. This is a community project. Consider hiring a local developer if you need hands-on help.

---

## Contributing

### Can I contribute to the project?

Yes! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### What kind of help is needed?

- Bug fixes
- Documentation improvements
- Translations
- Testing on different devices
- Feature development

### Is there a roadmap?

Planned features:
- Multi-campaign support
- Enhanced template system
- Campaign configuration UI
- Better analytics and reporting
