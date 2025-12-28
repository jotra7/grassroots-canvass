enum FilterOption {
  all('All'),
  positive('Positive'),
  negative('Negative'),
  neutral('Neutral'),
  contacted('Contacted'),
  uncontacted('Uncontacted'),
  attempted('Attempted'),
  unattempted('Unattempted'),
  livesAtProperty('Lives at Property');

  final String displayName;
  const FilterOption(this.displayName);
}
