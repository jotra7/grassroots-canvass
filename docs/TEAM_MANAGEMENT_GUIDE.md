# Team Management Guide

How to set up and manage your canvassing team in Grassroots Canvass.

---

## Table of Contents

1. [User Roles Explained](#user-roles-explained)
2. [Inviting Team Members](#inviting-team-members)
3. [Approving New Users](#approving-new-users)
4. [Assigning Territories](#assigning-territories)
5. [Monitoring Team Activity](#monitoring-team-activity)
6. [Managing Permissions](#managing-permissions)
7. [Best Practices](#best-practices)

---

## User Roles Explained

### Role Hierarchy

| Role | Access Level | Typical User |
|------|--------------|--------------|
| **Admin** | Full access to everything | Campaign manager, IT lead |
| **Team Lead** | Manage territories and view team stats | Field director, regional coordinator |
| **Canvasser** | View assigned areas, record contacts | Volunteers, field staff |
| **Pending** | No access (awaiting approval) | New signups |

### Role Capabilities

| Capability | Admin | Team Lead | Canvasser |
|------------|-------|-----------|-----------|
| View all voters | Yes | Yes | Only assigned |
| Record canvass results | Yes | Yes | Yes |
| Create cut lists | Yes | Yes | No |
| Assign users to cut lists | Yes | Yes | No |
| Approve new users | Yes | No | No |
| Change user roles | Yes | No | No |
| View analytics | Yes | Yes (limited) | No |
| Manage templates | Yes | Yes | No |
| Import/export data | Yes | No | No |
| Delete voters | Yes | No | No |

---

## Inviting Team Members

### Method 1: Share Signup Link

The simplest approach - share a link and approve signups:

1. Share your app URL with volunteers
2. They click "Sign Up" and create an account
3. They land on a "Pending Approval" screen
4. You approve them in the admin dashboard

**Pros**: Easy, no coordination needed
**Cons**: Requires you to approve each person

### Method 2: Signup Event

For volunteer orientations or training sessions:

1. Have everyone sign up at the same time
2. Collect their email addresses on a sign-in sheet
3. After the event, approve everyone at once
4. Assign them to territories based on their location

### Method 3: Pre-Create Accounts (Admin Only)

For campaigns with staff or vetted volunteers:

1. Go to admin dashboard → **Team**
2. Click **Add User**
3. Enter their email
4. Set their role
5. They'll receive an email to set their password

---

## Approving New Users

When someone signs up, they start as "Pending" and can't access any data.

### Approving Individual Users

1. Go to **Team** in the admin dashboard
2. You'll see a "Pending Users" section at the top
3. For each pending user:
   - Click **Approve** to make them a Canvasser
   - Click **Deny** to reject their request
4. They'll be notified (if email is configured)

### Bulk Approval

For approving many users at once:

1. Go to **Team**
2. Check the boxes next to pending users
3. Click **Approve Selected**
4. Choose the role to assign (usually Canvasser)

### Setting Roles During Approval

To approve someone directly as Team Lead or Admin:

1. Click on the pending user's name
2. In the user detail panel, change their role
3. Click **Save**

---

## Assigning Territories

### What Are Cut Lists?

"Cut lists" are geographic territories drawn on the map. Each cut list:
- Contains a specific set of voters
- Can be assigned to one or more canvassers
- Has its own progress tracking

### Creating a Cut List

1. Go to **Cut Lists** → **Create New**
2. Draw a polygon on the map:
   - Click to add points
   - Double-click to finish
3. Name the cut list (e.g., "Downtown Phoenix - Block 12")
4. Save

The system automatically assigns voters within the polygon to this cut list.

### Assigning Users to Cut Lists

1. Go to **Cut Lists**
2. Click on a cut list
3. Click **Manage Assignments**
4. Check the users you want to assign
5. Save

**Tips:**
- Assign 2-3 people to each area for backup
- Consider travel distance from where people live
- Smaller territories are easier to complete

### Self-Assignment (Optional)

If enabled, canvassers can request territories:

1. They view available cut lists on their map
2. They tap "Request Assignment"
3. A team lead approves the request

---

## Monitoring Team Activity

### Dashboard Overview

The main dashboard shows:
- Total contacts made today/this week
- Contacts by result (supportive, opposed, etc.)
- Team member activity

### Team Activity Feed

See real-time activity:

1. Go to **Team** → **Activity**
2. View recent actions:
   - Who logged contacts
   - When they were active
   - What results they recorded

### Individual Performance

To see one person's stats:

1. Go to **Team**
2. Click on their name
3. View their:
   - Total contacts
   - Contacts this week
   - Assigned territories
   - Completion rate

### Cut List Progress

Track territory completion:

1. Go to **Cut Lists**
2. View progress bars for each territory
3. Click for details:
   - Voters contacted
   - Voters remaining
   - Results breakdown

---

## Managing Permissions

### Changing User Roles

1. Go to **Team**
2. Click on the user
3. Change their role in the dropdown
4. Save

**Role changes take effect immediately** - the user will gain/lose access right away.

### Promoting to Team Lead

When promoting a canvasser to Team Lead:

1. Change their role to `team_lead`
2. Assign them cut lists to manage
3. Brief them on their new capabilities

### Removing Access

To revoke someone's access:

1. Go to **Team**
2. Click on the user
3. Change role to `pending` (soft disable)
   - Or delete the account entirely

**Note**: Deleting a user preserves their contact history (for data integrity).

### Temporary Deactivation

For volunteers who are temporarily unavailable:

1. Change their role to `pending`
2. Unassign their territories
3. When they return, restore their role

---

## Best Practices

### Onboarding Volunteers

1. **Hold a training session** - Show them how to use the app
2. **Provide written instructions** - Quick reference guide
3. **Start with a small territory** - Let them practice
4. **Check in after first session** - Address any confusion
5. **Pair new volunteers** - With experienced canvassers

### Territory Management

1. **Right-size territories** - 50-100 doors per session
2. **Consider geography** - Natural boundaries (streets, parks)
3. **Account for walk time** - Don't spread people too thin
4. **Rotate territories** - Fresh eyes catch people who were missed

### Quality Control

1. **Review results regularly** - Look for patterns
2. **Spot-check contact history** - Verify legitimacy
3. **Follow up on issues** - If results seem off, investigate
4. **Provide feedback** - Help people improve

### Communication

1. **Set expectations** - How many contacts per session?
2. **Create a group chat** - WhatsApp, Signal, or Slack
3. **Share progress updates** - Celebrate milestones
4. **Address problems quickly** - Don't let issues fester

### Data Security

1. **Limit admin access** - Only 2-3 people need full access
2. **Use team leads** - Delegate territory management
3. **Don't share exports** - Keep data in the system
4. **Monitor unusual activity** - Large exports, odd hours

---

## Troubleshooting

### User Can't Log In

1. Verify they confirmed their email (if required)
2. Have them reset their password
3. Check their role isn't `pending`

### User Can't See Voters

1. Verify their role is `canvasser` or above
2. Check they're assigned to at least one cut list
3. Verify the cut list has voters

### User Sees Wrong Territory

1. Check their cut list assignments
2. Verify cut list boundaries are correct
3. Have them log out and back in

### Accidental Role Change

1. Go to **Team**
2. Change their role back
3. Verify their cut list assignments are intact

### User Activity Not Showing

1. Check they synced their app
2. Verify internet connectivity
3. Have them force-sync in app settings

---

## Next Steps

1. **Import voter data** - See [VOTER_DATA_GUIDE.md](./VOTER_DATA_GUIDE.md)
2. **Create territories** - Draw cut lists on the map
3. **Train your team** - Walk through the app
4. **Start canvassing** - Get out in the field!
