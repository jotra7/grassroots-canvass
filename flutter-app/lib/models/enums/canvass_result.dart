enum CanvassResult {
  notContacted('Not Contacted'),
  contacted('Contacted'),
  notHome('Not Home'),
  refused('Refused'),
  moved('Moved'),
  deceased('Deceased'),
  wrongAddress('Wrong Address'),
  supportive('Supportive'),
  strongSupport('Strong Support'),
  leaning('Leaning'),
  willingToVolunteer('Willing to Volunteer'),
  requestedSign('Requested Sign'),
  undecided('Undecided'),
  needsInfo('Needs Info'),
  callbackRequested('Callback Requested'),
  opposed('Opposed'),
  stronglyOpposed('Strongly Opposed'),
  doNotContact('Do Not Contact'),
  // Call outcomes
  leftVoicemail('Left Voicemail'),
  noAnswer('No Answer'),
  busy('Busy'),
  wrongNumber('Wrong Number'),
  disconnected('Disconnected'),
  // Text outcomes
  textSent('Text Sent'),
  textReplied('Text Replied');

  final String displayName;
  const CanvassResult(this.displayName);

  /// Returns true if this is a positive/supportive result
  bool get isPositive {
    return this == CanvassResult.supportive ||
        this == CanvassResult.strongSupport ||
        this == CanvassResult.leaning ||
        this == CanvassResult.willingToVolunteer ||
        this == CanvassResult.requestedSign;
  }

  /// Alias for isPositive
  bool get isSupportive => isPositive;

  /// Returns true if this is a negative/opposed result
  bool get isNegative {
    return this == CanvassResult.opposed ||
        this == CanvassResult.stronglyOpposed ||
        this == CanvassResult.doNotContact ||
        this == CanvassResult.refused;
  }

  /// Returns true if this is a neutral/undecided result
  bool get isNeutral {
    return this == CanvassResult.undecided ||
        this == CanvassResult.needsInfo ||
        this == CanvassResult.callbackRequested;
  }

  static CanvassResult fromString(String value) {
    return CanvassResult.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => CanvassResult.notContacted,
    );
  }
}
