import 'package:flutter/material.dart';

enum ScriptSectionType {
  greeting('Opening/Greeting', Color(0xFF2196F3)),     // blue
  introduction('Introduction', Color(0xFF9C27B0)),     // purple
  issues('Key Issues', Color(0xFFFF9800)),              // orange
  ask('The Ask', Color(0xFF4CAF50)),                    // green
  objections('Handle Objections', Color(0xFFF44336)),   // red
  closing('Closing', Color(0xFF009688));                // teal

  final String displayName;
  final Color color;
  const ScriptSectionType(this.displayName, this.color);

  static ScriptSectionType fromString(String value) {
    switch (value) {
      case 'greeting':
        return ScriptSectionType.greeting;
      case 'introduction':
        return ScriptSectionType.introduction;
      case 'issues':
        return ScriptSectionType.issues;
      case 'ask':
        return ScriptSectionType.ask;
      case 'objections':
        return ScriptSectionType.objections;
      case 'closing':
        return ScriptSectionType.closing;
      default:
        return ScriptSectionType.greeting;
    }
  }

  IconData get icon {
    switch (this) {
      case ScriptSectionType.greeting:
        return Icons.waving_hand;
      case ScriptSectionType.introduction:
        return Icons.people;
      case ScriptSectionType.issues:
        return Icons.list_alt;
      case ScriptSectionType.ask:
        return Icons.thumb_up;
      case ScriptSectionType.objections:
        return Icons.chat_bubble;
      case ScriptSectionType.closing:
        return Icons.check_circle;
    }
  }
}

class ScriptSection {
  final String id;
  final String name;
  final ScriptSectionType sectionType;
  final String content;
  final List<String> tips;
  final int displayOrder;
  final bool isActive;

  String get title => name.isNotEmpty ? name : sectionType.displayName;
  IconData get icon => sectionType.icon;
  Color get color => sectionType.color;
  String get tip => tips.isNotEmpty ? tips.first : '';

  const ScriptSection({
    required this.id,
    required this.name,
    required this.sectionType,
    required this.content,
    this.tips = const [],
    this.displayOrder = 0,
    this.isActive = true,
  });

  /// Factory constructor for creating from Supabase JSON
  factory ScriptSection.fromJson(Map<String, dynamic> json) {
    return ScriptSection(
      id: json['id'] as String,
      name: json['name'] as String,
      sectionType: ScriptSectionType.fromString(json['section'] as String),
      content: json['content'] as String,
      tips: const [], // Tips are embedded in content for now
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Format content with voter name placeholder replaced
  String formattedContent(String voterName) {
    return content
        .replaceAll('{name}', voterName)
        .replaceAll('{firstName}', voterName)
        .replaceAll('{fullName}', voterName);
  }
}

class CallScript {
  static List<ScriptSection> get allSections => defaults;

  // Generic default call script templates (used as offline fallback)
  // These should be customized per campaign via the admin dashboard
  static const List<ScriptSection> defaults = [
    ScriptSection(
      id: '1',
      name: 'Opening',
      sectionType: ScriptSectionType.greeting,
      tips: [
        "Be friendly and upbeat — you're a neighbor, not a telemarketer",
        "Speak clearly and don't rush",
        "If they seem busy, offer to call back rather than pushing",
      ],
      content: '''
"Hi, is this {name}?"

[If YES]: "Great! My name is [YOUR NAME], and I'm a volunteer with [CAMPAIGN NAME]. We're reaching out to voters about the upcoming election. Do you have a quick moment?"

[If NO]: "Oh, sorry about that! Is {name} available?"

[If not a good time]: "No problem! When would be a better time to call back?"
''',
    ),
    ScriptSection(
      id: '2',
      name: 'Introduction',
      sectionType: ScriptSectionType.introduction,
      tips: [
        "Keep it conversational — you're introducing a neighbor, not reading a resume",
        "Focus on one or two key points about the candidate",
        "Let the voter guide the conversation based on their interests",
      ],
      content: '''
"I'm calling on behalf of [CANDIDATE NAME] — they're running for [POSITION] in [DISTRICT/AREA]."

[Brief candidate background]:
"They're running because they believe [KEY MOTIVATION]. They want to make a difference on issues that matter to our community."

[If they ask for more info]: "I'd be happy to share more about their platform. What issues matter most to you?"
''',
    ),
    ScriptSection(
      id: '3',
      name: 'Key Issues',
      sectionType: ScriptSectionType.issues,
      tips: [
        "Don't rush through all the issues — pause and see which one they react to",
        "If they care about one issue, go deeper on that one",
        "Listen more than you talk",
      ],
      content: '''
"[CANDIDATE NAME] is focused on a few key issues:"

**1. [ISSUE 1]**
"[Brief explanation of the issue and candidate's position]"

**2. [ISSUE 2]**
"[Brief explanation of the issue and candidate's position]"

**3. [ISSUE 3]**
"[Brief explanation of the issue and candidate's position]"

[Gauge interest]: "Does any of that resonate with you?"
''',
    ),
    ScriptSection(
      id: '4',
      name: 'The Ask',
      sectionType: ScriptSectionType.ask,
      tips: [
        "A soft yes is still a yes — mark them as supportive",
        "Undecideds are worth following up with later",
        "Even if they say no, stay friendly — they might know someone who's a yes",
      ],
      content: '''
"So I'm calling to ask: can [CANDIDATE NAME] count on your vote in the upcoming election?"

[If YES]: "That's great! Thank you. Can we also count on you to spread the word to neighbors? And would you be open to a yard sign?"

[If MAYBE/UNDECIDED]: "Totally understand. Is there anything specific you'd want to know more about before deciding?"

[If NO]: "I appreciate your honesty. Mind if I ask what issues matter most to you?"

[If they don't know about the election]: "That's okay! Many people don't know about local elections. Here's how you can vote: [VOTING INFO]"
''',
    ),
    ScriptSection(
      id: '5',
      name: 'Handle Objections',
      sectionType: ScriptSectionType.objections,
      tips: [
        "Stay calm and don't argue — just offer the information",
        "If they're hostile, thank them for their time and move on",
        "Most objections come from lack of information, not opposition",
      ],
      content: '''
**"I don't vote in local elections"**
"You're not alone — local elections often have low turnout. That's actually why every vote matters so much. Your vote has more impact in local races than almost any other election."

**"I've never heard of this candidate"**
"That's fair — [CANDIDATE NAME] is running a grassroots campaign. They're a member of our community who decided to run because they care about [KEY ISSUE]."

**"I'm happy with the way things are"**
"Glad to hear things are working well for you. [CANDIDATE NAME] wants to keep what's working while improving [SPECIFIC AREA]."

**"I don't trust politicians"**
"That's a common feeling. [CANDIDATE NAME] isn't a career politician — they're a community member who got involved because they care about making things better."
''',
    ),
    ScriptSection(
      id: '6',
      name: 'Closing',
      sectionType: ScriptSectionType.closing,
      tips: [
        "Always end on a positive note, even if they said no",
        "Mention the website — it's easy to remember",
        "Log the call result right away so you don't forget",
      ],
      content: '''
**[If supportive]:**
"Thank you so much! Just to confirm — Election Day is [DATE]. You can vote [VOTING METHODS]. We'll send a reminder closer to the date. Thanks again for your time!"

**[If undecided]:**
"Thanks for hearing me out. If you have questions later, you can check out [WEBSITE]. Have a great day!"

**[If not supportive]:**
"I appreciate you taking the time to talk. Have a good one!"

**[If not home / voicemail]:**
"Hi {name}, this is [YOUR NAME] calling on behalf of [CANDIDATE NAME], candidate for [POSITION]. We'd love to chat about the upcoming election. Feel free to check out [WEBSITE], or I'll try you again soon. Thanks!"
''',
    ),
  ];
}
