import 'enums/canvass_result.dart';
import 'enums/contact_method.dart';

class Voter {
  // Unique identifier
  final String uniqueId;

  // Voter Data
  final String visitorId;
  String firstName;
  final String middleName;
  String lastName;
  String ownerName;
  String phone;
  String cellPhone;
  String partyDescription;
  int voterAge;
  String gender;
  final String registrationDate;
  String residenceAddress;

  // Address
  final String streetNum;
  final String streetDir;
  final String streetName;
  final String city;
  final String zip;

  // Location
  final double latitude;
  final double longitude;

  // Canvassing Data
  CanvassResult canvassResult;
  String canvassNotes;
  DateTime? canvassDate;

  // Contact Tracking
  int contactAttempts;
  DateTime? lastContactAttempt;
  ContactMethod? lastContactMethod;
  bool voicemailLeft;

  // Mailing Address
  final String mailAddress;
  final String mailCity;
  final String mailState;
  final String mailZip;
  final bool livesElsewhere;

  // Mail Voter (early voter list)
  final bool isMailVoter;

  Voter({
    this.uniqueId = '',
    this.visitorId = '',
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.ownerName = '',
    this.phone = '',
    this.cellPhone = '',
    this.partyDescription = '',
    this.voterAge = 0,
    this.gender = '',
    this.registrationDate = '',
    this.residenceAddress = '',
    this.streetNum = '',
    this.streetDir = '',
    this.streetName = '',
    this.city = '',
    this.zip = '',
    this.latitude = 0,
    this.longitude = 0,
    this.canvassResult = CanvassResult.notContacted,
    this.canvassNotes = '',
    this.canvassDate,
    this.contactAttempts = 0,
    this.lastContactAttempt,
    this.lastContactMethod,
    this.voicemailLeft = false,
    this.mailAddress = '',
    this.mailCity = '',
    this.mailState = '',
    this.mailZip = '',
    this.livesElsewhere = false,
    this.isMailVoter = false,
  });

  // Computed properties
  String get fullAddress {
    return '$streetNum $streetDir $streetName, $city $zip'.trim();
  }

  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return ownerName;
  }

  bool get hasValidLocation => latitude != 0 && longitude != 0;

  bool get hasPhoneNumber => cellPhone.isNotEmpty || phone.isNotEmpty;

  String get primaryPhone => cellPhone.isNotEmpty ? cellPhone : phone;

  /// Returns the full mailing address if available
  String get fullMailingAddress {
    if (mailAddress.isEmpty) return '';
    final parts = [mailAddress];
    if (mailCity.isNotEmpty) parts.add(mailCity);
    if (mailState.isNotEmpty) parts.add(mailState);
    if (mailZip.isNotEmpty) parts.add(mailZip);
    return parts.join(', ');
  }

  bool get hasMailingAddress => mailAddress.isNotEmpty;

  // Factory from Supabase JSON
  factory Voter.fromSupabase(Map<String, dynamic> json) {
    return Voter(
      uniqueId: json['unique_id'] ?? json['id'] ?? '',
      ownerName: json['owner_name'] ?? '',
      streetNum: json['street_num'] ?? '',
      streetDir: json['street_dir'] ?? '',
      streetName: json['street_name'] ?? '',
      city: json['city'] ?? '',
      zip: json['zip'] ?? '',
      visitorId: json['voter_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      cellPhone: json['cell_phone'] ?? '',
      partyDescription: json['party'] ?? '',
      voterAge: json['voter_age'] ?? 0,
      gender: json['gender'] ?? '',
      registrationDate: json['registration_date'] ?? '',
      residenceAddress: json['residence_address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      canvassResult: CanvassResult.fromString(json['canvass_result'] ?? 'Not Contacted'),
      canvassNotes: json['canvass_notes'] ?? '',
      canvassDate: json['canvass_date'] != null
          ? DateTime.tryParse(json['canvass_date'])
          : null,
      contactAttempts: json['contact_attempts'] ?? 0,
      lastContactAttempt: json['last_contact_attempt'] != null
          ? DateTime.tryParse(json['last_contact_attempt'])
          : null,
      lastContactMethod: ContactMethod.fromString(json['last_contact_method']),
      voicemailLeft: json['voicemail_left'] ?? false,
      mailAddress: json['mail_address'] ?? '',
      mailCity: json['mail_city'] ?? '',
      mailState: json['mail_state'] ?? '',
      mailZip: json['mail_zip'] ?? '',
      livesElsewhere: json['lives_elsewhere'] ?? false,
      isMailVoter: json['is_mail_voter'] ?? json['is_pevl'] ?? false,
    );
  }

  /// Factory for creating a minimal Voter from cut list creation query
  /// Only includes fields needed for map display (much faster than full fromSupabase)
  factory Voter.fromMinimalJson(Map<String, dynamic> json) {
    return Voter(
      uniqueId: json['unique_id'] ?? json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      partyDescription: json['party'] ?? '',
      livesElsewhere: json['lives_elsewhere'] ?? false,
      isMailVoter: json['is_mail_voter'] ?? json['is_pevl'] ?? false,
      canvassResult: CanvassResult.fromString(json['canvass_result'] ?? 'Not Contacted'),
    );
  }

  // To JSON for editable fields
  Map<String, dynamic> toEditableJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'owner_name': ownerName,
      'phone': phone,
      'cell_phone': cellPhone,
      'party': partyDescription,
      'voter_age': voterAge,
      'gender': gender,
      'residence_address': residenceAddress,
      'mail_address': mailAddress,
      'mail_city': mailCity,
      'mail_state': mailState,
      'mail_zip': mailZip,
    };
  }

  // To JSON for canvass/contact data
  Map<String, dynamic> toCanvassJson() {
    final data = <String, dynamic>{
      'canvass_result': canvassResult.displayName,
      'canvass_date': DateTime.now().toIso8601String(),
      'contact_attempts': contactAttempts,
    };
    if (canvassNotes.isNotEmpty) {
      data['canvass_notes'] = canvassNotes;
    }
    if (lastContactAttempt != null) {
      data['last_contact_attempt'] = lastContactAttempt!.toIso8601String();
    }
    if (lastContactMethod != null) {
      data['last_contact_method'] = lastContactMethod!.displayName;
    }
    data['voicemail_left'] = voicemailLeft;
    return data;
  }

  // Copy with
  Voter copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? ownerName,
    String? phone,
    String? cellPhone,
    String? partyDescription,
    int? voterAge,
    String? gender,
    String? residenceAddress,
    CanvassResult? canvassResult,
    String? canvassNotes,
    DateTime? canvassDate,
    int? contactAttempts,
    DateTime? lastContactAttempt,
    ContactMethod? lastContactMethod,
    bool? voicemailLeft,
    String? mailAddress,
    String? mailCity,
    String? mailState,
    String? mailZip,
  }) {
    return Voter(
      uniqueId: uniqueId,
      visitorId: visitorId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      cellPhone: cellPhone ?? this.cellPhone,
      partyDescription: partyDescription ?? this.partyDescription,
      voterAge: voterAge ?? this.voterAge,
      gender: gender ?? this.gender,
      registrationDate: registrationDate,
      residenceAddress: residenceAddress ?? this.residenceAddress,
      streetNum: streetNum,
      streetDir: streetDir,
      streetName: streetName,
      city: city,
      zip: zip,
      latitude: latitude,
      longitude: longitude,
      canvassResult: canvassResult ?? this.canvassResult,
      canvassNotes: canvassNotes ?? this.canvassNotes,
      canvassDate: canvassDate ?? this.canvassDate,
      contactAttempts: contactAttempts ?? this.contactAttempts,
      lastContactAttempt: lastContactAttempt ?? this.lastContactAttempt,
      lastContactMethod: lastContactMethod ?? this.lastContactMethod,
      voicemailLeft: voicemailLeft ?? this.voicemailLeft,
      mailAddress: mailAddress ?? this.mailAddress,
      mailCity: mailCity ?? this.mailCity,
      mailState: mailState ?? this.mailState,
      mailZip: mailZip ?? this.mailZip,
      livesElsewhere: livesElsewhere,
      isMailVoter: isMailVoter,
    );
  }
}
