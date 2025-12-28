import 'package:flutter/material.dart';

class ScriptSection {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final List<String> tips;

  String get tip => tips.isNotEmpty ? tips.first : '';

  const ScriptSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    required this.tips,
  });

  String formattedContent(String voterName) {
    return content.replaceAll('{name}', voterName);
  }
}

class CallScript {
  static List<ScriptSection> get allSections => sections;

  // Generic call script templates
  // These should be customized per campaign via the admin dashboard
  static const List<ScriptSection> sections = [
    ScriptSection(
      id: '1',
      title: 'Opening',
      icon: Icons.waving_hand,
      color: Color(0xFF2196F3), // blue
      content: '''
"Hi, is this {name}?"

[If YES]: "Great! My name is [YOUR NAME], and I'm a volunteer with [CAMPAIGN NAME]. We're reaching out to voters about the upcoming election. Do you have a quick moment?"

[If NO]: "Oh, sorry about that! Is {name} available?"

[If not a good time]: "No problem! When would be a better time to call back?"
''',
      tips: [
        "Be friendly and upbeat — you're a neighbor, not a telemarketer",
        "Speak clearly and don't rush",
        "If they seem busy, offer to call back rather than pushing",
      ],
    ),
    ScriptSection(
      id: '2',
      title: 'Introduction',
      icon: Icons.people,
      color: Color(0xFF9C27B0), // purple
      content: '''
"I'm calling on behalf of [CANDIDATE NAME] — they're running for [POSITION] in [DISTRICT/AREA]."

[Brief candidate background]:
"They're running because they believe [KEY MOTIVATION]. They want to make a difference on issues that matter to our community."

[If they ask for more info]: "I'd be happy to share more about their platform. What issues matter most to you?"
''',
      tips: [
        "Keep it conversational — you're introducing a neighbor, not reading a resume",
        "Focus on one or two key points about the candidate",
        "Let the voter guide the conversation based on their interests",
      ],
    ),
    ScriptSection(
      id: '3',
      title: 'Key Issues',
      icon: Icons.list_alt,
      color: Color(0xFFFF9800), // orange
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
      tips: [
        "Don't rush through all the issues — pause and see which one they react to",
        "If they care about one issue, go deeper on that one",
        "Listen more than you talk",
      ],
    ),
    ScriptSection(
      id: '4',
      title: 'The Ask',
      icon: Icons.thumb_up,
      color: Color(0xFF4CAF50), // green
      content: '''
"So I'm calling to ask: can [CANDIDATE NAME] count on your vote in the upcoming election?"

[If YES]: "That's great! Thank you. Can we also count on you to spread the word to neighbors? And would you be open to a yard sign?"

[If MAYBE/UNDECIDED]: "Totally understand. Is there anything specific you'd want to know more about before deciding?"

[If NO]: "I appreciate your honesty. Mind if I ask what issues matter most to you?"

[If they don't know about the election]: "That's okay! Many people don't know about local elections. Here's how you can vote: [VOTING INFO]"
''',
      tips: [
        "A soft yes is still a yes — mark them as supportive",
        "Undecideds are worth following up with later",
        "Even if they say no, stay friendly — they might know someone who's a yes",
      ],
    ),
    ScriptSection(
      id: '5',
      title: 'Handle Objections',
      icon: Icons.chat_bubble,
      color: Color(0xFFF44336), // red
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
      tips: [
        "Stay calm and don't argue — just offer the information",
        "If they're hostile, thank them for their time and move on",
        "Most objections come from lack of information, not opposition",
      ],
    ),
    ScriptSection(
      id: '6',
      title: 'Closing',
      icon: Icons.check_circle,
      color: Color(0xFF009688), // teal
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
      tips: [
        "Always end on a positive note, even if they said no",
        "Mention the website — it's easy to remember",
        "Log the call result right away so you don't forget",
      ],
    ),
  ];
}
