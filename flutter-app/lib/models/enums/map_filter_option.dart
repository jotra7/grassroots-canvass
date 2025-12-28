enum MapFilterOption {
  notContacted('Not Contacted'),
  contacted('Contacted'),
  supportive('Supportive'),
  opposed('Opposed'),
  democrats('Democrats'),
  republicans('Republicans'),
  independents('Independents/Other'),
  livesAtProperty('Lives at Property'),
  absenteeOwners('Absentee Owners Only'),
  mailVoters('Mail/Early Voters'),
  nearby('Nearby (100 shown)'),
  all('All (may be slow)');

  final String displayName;
  const MapFilterOption(this.displayName);
}
