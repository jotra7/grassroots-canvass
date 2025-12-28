# Voter Data Guide

How to prepare, import, and manage voter data in Grassroots Canvass.

---

## Table of Contents

1. [Getting Voter Data](#getting-voter-data)
2. [Preparing Your CSV File](#preparing-your-csv-file)
3. [Adding GPS Coordinates](#adding-gps-coordinates)
4. [Importing Into the System](#importing-into-the-system)
5. [Managing Voter Data](#managing-voter-data)
6. [Data Privacy Considerations](#data-privacy-considerations)

---

## Getting Voter Data

### Sources of Voter Data

| Source | Cost | Data Quality | Notes |
|--------|------|--------------|-------|
| **State/County Elections Office** | $0-50 | Official | Most states provide voter rolls |
| **State Party** | Usually free | Good | If affiliated with a party |
| **L2 Political** | $$ | Excellent | Commercial voter file vendor |
| **TargetSmart** | $$$ | Excellent | Enhanced data with modeling |
| **Your Own Signups** | Free | Varies | Petition signers, event attendees |

### Requesting from Your State

Most states provide voter files to candidates. Search for:
> "[Your State] voter file request"

Common requirements:
- Must be a registered candidate or campaign
- May need to sign a use agreement
- Fee varies ($0 to several hundred dollars)
- Usually delivered as CSV or fixed-width text file

### What Data You'll Get

Typical voter file includes:
- Full name
- Registered address
- Mailing address (if different)
- Party affiliation
- Voting history (which elections they voted in)
- Date of birth or age
- Registration date

Usually does NOT include:
- Phone numbers (you may need to append these)
- Email addresses

---

## Preparing Your CSV File

### Required CSV Format

Your CSV must have these column headers (exact match required):

**Required columns:**
| Column Name | Description | Example |
|-------------|-------------|---------|
| `first_name` | First name | `John` |
| `last_name` | Last name | `Smith` |

**Recommended columns:**
| Column Name | Description | Example |
|-------------|-------------|---------|
| `address` | Street address | `123 Main St` |
| `city` | City | `Phoenix` |
| `state` | State abbreviation | `AZ` |
| `zip` | ZIP code | `85001` |
| `phone` | Phone number | `602-555-1234` |
| `email` | Email address | `john@example.com` |
| `party` | Party affiliation | `DEM`, `REP`, `IND`, `LBT`, `GRN` |
| `latitude` | GPS latitude | `33.4484` |
| `longitude` | GPS longitude | `-112.0740` |

**Optional columns:**
| Column Name | Description | Example |
|-------------|-------------|---------|
| `middle_name` | Middle name or initial | `Robert` |
| `suffix` | Name suffix | `Jr.`, `III` |
| `unit` | Apartment/unit number | `Apt 4B` |
| `birth_year` | Year of birth | `1985` |
| `registration_date` | When they registered | `2020-03-15` |
| `precinct` | Voting precinct | `Phoenix 42` |
| `congressional_district` | CD number | `9` |
| `legislative_district` | State leg district | `24` |

### Example CSV

```csv
first_name,last_name,address,city,state,zip,phone,party,latitude,longitude
John,Smith,123 Main St,Phoenix,AZ,85001,602-555-1234,DEM,33.4484,-112.0740
Jane,Doe,456 Oak Ave,Phoenix,AZ,85002,602-555-5678,REP,33.4495,-112.0751
Bob,Johnson,789 Pine Rd,Phoenix,AZ,85003,,IND,33.4506,-112.0762
```

### Cleaning Your Data

Before importing, clean your data:

1. **Remove duplicates** - Same person listed twice
2. **Standardize party codes** - Use consistent abbreviations
3. **Format phone numbers** - Any format works, but be consistent
4. **Fix encoding issues** - Save as UTF-8 to handle special characters
5. **Remove extra columns** - Delete columns you don't need

**Using Excel/Google Sheets:**
1. Open your voter file
2. Delete unneeded columns
3. Rename columns to match the required names
4. Save as CSV (UTF-8 encoding)

---

## Adding GPS Coordinates

Maps require latitude/longitude for each voter. If your data doesn't have coordinates, you need to geocode it.

### Free Geocoding Options

#### Option 1: Census Geocoder (Best for US addresses)

The US Census provides free, unlimited geocoding:

1. Go to [geocoding.geo.census.gov/geocoder/](https://geocoding.geo.census.gov/geocoder/)
2. Click **Address Batch**
3. Format your CSV with these columns:
   - Unique ID
   - Street Address
   - City
   - State
   - ZIP
4. Upload (max 10,000 addresses per batch)
5. Download results with lat/long

**Limitations:**
- US addresses only
- Max 10,000 per batch (split larger files)
- Some addresses may not match

#### Option 2: Geocodio (Easy, 2,500 free/day)

1. Go to [geocod.io](https://www.geocod.io)
2. Create a free account
3. Upload your CSV
4. Map your columns
5. Download results with coordinates

**Pricing:**
- Free: 2,500 lookups/day
- Paid: $0.50 per 1,000 after that

#### Option 3: Google Sheets Add-on

1. In Google Sheets, go to **Extensions** → **Add-ons** → **Get add-ons**
2. Search for "Geocode by Awesome Table"
3. Install it
4. Select your address columns
5. Run the geocoder

**Limitations:**
- Slow for large datasets
- Uses Google Maps quota

### Geocoding Tips

1. **Combine address fields** first:
   ```
   =A2 & ", " & B2 & ", " & C2 & " " & D2
   ```
   Result: `123 Main St, Phoenix, AZ 85001`

2. **Handle failures** - Some addresses won't geocode:
   - PO Boxes (no physical location)
   - New construction
   - Typos in address
   - Rural routes

3. **Verify a sample** - Spot-check 10-20 results on a map to ensure accuracy

---

## Importing Into the System

### Using the Admin Dashboard

1. Log into your admin dashboard
2. Go to **Data** in the sidebar
3. Click **Import Voters**
4. Select your CSV file
5. Map your columns to the system fields:
   - Match each column header to the corresponding field
   - Skip columns you don't want to import
6. Click **Preview** to verify
7. Click **Import**

### Import Options

| Option | Description |
|--------|-------------|
| **Add new voters** | Only imports voters not already in system |
| **Update existing** | Updates voters that match on name + address |
| **Replace all** | Deletes all voters and imports fresh |

### Direct Database Import (Advanced)

For large datasets (100K+ voters), direct import is faster:

1. Go to Supabase → **Table Editor** → `voters`
2. Click **Insert** → **Import data from CSV**
3. Upload your CSV
4. Map columns
5. Import

**Note**: This bypasses some validation. Verify data after import.

---

## Managing Voter Data

### Viewing Voters

In the admin dashboard:
- **Voters** page shows all voters with filters
- Click a voter to see full details
- Use search to find specific people

### Filtering Options

| Filter | Description |
|--------|-------------|
| Party | Filter by party affiliation |
| Canvass Result | See contacted/not contacted/supportive/opposed |
| Cut List | See voters in specific territory |
| Contact Attempts | Filter by # of contact attempts |

### Updating Voter Data

**Individual edits:**
1. Go to Voters → Click on a voter
2. Edit any field
3. Save changes

**Bulk updates:**
1. Export current data
2. Make changes in spreadsheet
3. Re-import with "Update existing" option

### Exporting Data

1. Go to **Data** → **Export**
2. Choose what to export:
   - All voters
   - Filtered subset
   - With contact history
3. Select format (CSV or Excel)
4. Download

---

## Data Privacy Considerations

### Legal Requirements

Voter data is regulated. Common requirements:

| Requirement | Description |
|-------------|-------------|
| **Use restrictions** | Only for campaign/political purposes |
| **No commercial use** | Can't sell or use for marketing |
| **Must protect data** | Reasonable security measures |
| **Honor opt-outs** | Remove people who request it |

### Best Practices

1. **Limit access** - Only give data access to people who need it
2. **Use role-based permissions** - Canvassers only see their territory
3. **Don't export unnecessarily** - Keep data in the system when possible
4. **Delete when done** - After the campaign, clean up data you don't need
5. **Train your team** - Everyone should understand data privacy

### Handling Do Not Contact Requests

When someone asks to be removed:

1. Find them in the Voters list
2. Set their Canvass Result to "Do Not Contact"
3. They'll be excluded from call/text lists
4. Optionally delete their phone/email

### GDPR/CCPA Compliance

If you have voters in CA (CCPA) or EU (GDPR):

- Provide a way for people to request their data
- Delete data upon request
- Don't share data with third parties without consent
- Document your data practices in a privacy policy

---

## Troubleshooting

### Import Fails

| Error | Solution |
|-------|----------|
| "Invalid CSV format" | Save as CSV UTF-8, not Excel format |
| "Missing required columns" | Ensure `first_name` and `last_name` exist |
| "Duplicate header" | Each column name must be unique |
| "Too many rows" | Split file into smaller batches |

### Voters Not Appearing on Map

1. Check they have valid latitude/longitude
2. Verify coordinates are in the right format (decimal degrees)
3. Check they're within the visible map area
4. Verify they're assigned to a cut list

### Duplicate Voters

1. Export all voters
2. Use Excel/Sheets to find duplicates (name + address match)
3. Delete duplicates manually or via re-import

### Wrong Coordinates

If voters appear in wrong locations:
1. Verify address data is correct
2. Re-geocode affected addresses
3. Update latitude/longitude fields

---

## Next Steps

1. **Create cut lists** - Draw territories on the map
2. **Assign territories** - Give canvassers their areas
3. **Start canvassing** - Begin making contacts
