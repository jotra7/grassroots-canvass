enum ContactMethod {
  call('call', 'Phone Call'),
  text('text', 'Text Message'),
  door('door', 'Door Knock');

  final String value;
  final String displayName;
  const ContactMethod(this.value, this.displayName);

  static ContactMethod? fromString(String? value) {
    if (value == null) return null;
    return ContactMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContactMethod.door,
    );
  }
}
