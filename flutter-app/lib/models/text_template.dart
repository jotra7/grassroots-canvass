import 'package:flutter/material.dart';

enum TemplateCategory {
  introduction('Introduction', Color(0xFF2196F3)), // blue
  followUp('Follow-up', Color(0xFF9C27B0)),        // purple
  reminder('Reminder', Color(0xFFFF9800)),          // orange
  thankYou('Thank You', Color(0xFF4CAF50));         // green

  final String displayName;
  final Color color;
  const TemplateCategory(this.displayName, this.color);

  static TemplateCategory fromString(String value) {
    switch (value) {
      case 'introduction':
        return TemplateCategory.introduction;
      case 'follow_up':
        return TemplateCategory.followUp;
      case 'reminder':
        return TemplateCategory.reminder;
      case 'thank_you':
        return TemplateCategory.thankYou;
      default:
        return TemplateCategory.introduction;
    }
  }
}

class TextTemplate {
  final String id;
  final TemplateCategory _category;
  final String name;
  final String message;
  final IconData icon;
  final String iconName;
  final String district;
  final String? position;
  final String? candidateName;

  String get category => _category.displayName;
  TemplateCategory get templateCategory => _category;

  const TextTemplate({
    required this.id,
    required TemplateCategory category,
    required this.name,
    required this.message,
    required this.icon,
    this.iconName = 'message',
    this.district = '',
    this.position,
    this.candidateName,
  }) : _category = category;

  /// Factory constructor for creating from Supabase JSON
  factory TextTemplate.fromJson(Map<String, dynamic> json) {
    final iconName = json['icon_name'] as String? ?? 'message';
    final candidateData = json['candidate'] as Map<String, dynamic>?;

    return TextTemplate(
      id: json['id'] as String,
      category: TemplateCategory.fromString(json['category'] as String),
      name: json['name'] as String,
      message: json['message'] as String,
      icon: _iconFromName(iconName),
      iconName: iconName,
      district: json['district'] as String? ?? '',
      position: json['position'] as String?,
      candidateName: candidateData?['name'] as String?,
    );
  }

  /// Format message with voter data placeholders replaced
  ///
  /// Available placeholders:
  /// - {name}, {firstName} - Voter's first name
  /// - {lastName} - Voter's last name
  /// - {fullName} - Voter's full name (first + last)
  /// - {city} - Voter's city
  /// - {candidate} - Candidate name from template
  String formatted({
    required String voterName,
    String? lastName,
    String? city,
    String? candidateNameOverride,
  }) {
    final candidate = candidateNameOverride ?? candidateName ?? '';
    final fullName = lastName != null ? '$voterName $lastName' : voterName;
    return message
        .replaceAll('{name}', voterName)
        .replaceAll('{firstName}', voterName)
        .replaceAll('{lastName}', lastName ?? '')
        .replaceAll('{fullName}', fullName)
        .replaceAll('{city}', city ?? '')
        .replaceAll('{candidate}', candidate);
  }

  /// Map icon name strings to Flutter IconData
  static IconData _iconFromName(String name) {
    const iconMap = {
      'waving_hand': Icons.waving_hand,
      'home': Icons.home,
      'help_outline': Icons.help_outline,
      'check_circle': Icons.check_circle,
      'phone_callback': Icons.phone_callback,
      'refresh': Icons.refresh,
      'question_answer': Icons.question_answer,
      'mail': Icons.mail,
      'calendar_today': Icons.calendar_today,
      'bolt': Icons.bolt,
      'warning': Icons.warning,
      'favorite': Icons.favorite,
      'thumb_up': Icons.thumb_up,
      'verified': Icons.verified,
      'star': Icons.star,
      'signpost': Icons.signpost,
      'message': Icons.message,
    };
    return iconMap[name] ?? Icons.message;
  }

  // Getter for all templates (defaults as fallback)
  static List<TextTemplate> get allTemplates => defaults;

  // Generic default templates (used as offline fallback)
  // These should be customized per campaign via the admin dashboard
  static const List<TextTemplate> defaults = [
    // Introduction
    TextTemplate(
      id: '1',
      category: TemplateCategory.introduction,
      name: 'First Contact',
      message: "Hi {name}, I'm a volunteer with {candidate}'s campaign. Got a minute to chat about the upcoming election?",
      icon: Icons.waving_hand,
      iconName: 'waving_hand',
    ),
    TextTemplate(
      id: '2',
      category: TemplateCategory.introduction,
      name: 'Quick Intro',
      message: "Hi {name}! Have you heard about {candidate}? We'd love to share why we think they'd be great for our community.",
      icon: Icons.help_outline,
      iconName: 'help_outline',
    ),

    // Follow-up
    TextTemplate(
      id: '3',
      category: TemplateCategory.followUp,
      name: 'After Conversation',
      message: "Great talking with you, {name}! If you have any questions about {candidate}'s platform, feel free to reach out.",
      icon: Icons.check_circle,
      iconName: 'check_circle',
    ),
    TextTemplate(
      id: '4',
      category: TemplateCategory.followUp,
      name: 'After Voicemail',
      message: "Hi {name}, I left you a voicemail about the election. Let me know if you have any questions!",
      icon: Icons.phone_callback,
      iconName: 'phone_callback',
    ),

    // Reminders
    TextTemplate(
      id: '5',
      category: TemplateCategory.reminder,
      name: 'Election Reminder',
      message: "Hi {name}! Just a friendly reminder that Election Day is coming up. Your vote matters!",
      icon: Icons.calendar_today,
      iconName: 'calendar_today',
    ),
    TextTemplate(
      id: '6',
      category: TemplateCategory.reminder,
      name: 'Election Day',
      message: "It's Election Day! If you haven't voted yet, there's still time. Every vote counts!",
      icon: Icons.bolt,
      iconName: 'bolt',
    ),

    // Thank You
    TextTemplate(
      id: '7',
      category: TemplateCategory.thankYou,
      name: 'Supportive Voter',
      message: "Thanks for your support, {name}! We really appreciate it. If you know anyone else who might be interested, please spread the word!",
      icon: Icons.favorite,
      iconName: 'favorite',
    ),
    TextTemplate(
      id: '8',
      category: TemplateCategory.thankYou,
      name: 'General Thanks',
      message: "Thanks for taking the time to chat, {name}. If you have any questions, feel free to reach out!",
      icon: Icons.thumb_up,
      iconName: 'thumb_up',
    ),
  ];
}
