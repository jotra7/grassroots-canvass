import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/voter.dart';
import '../../models/text_template.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';

class TextTemplatesScreen extends StatefulWidget {
  final Voter voter;

  const TextTemplatesScreen({super.key, required this.voter});

  @override
  State<TextTemplatesScreen> createState() => _TextTemplatesScreenState();
}

class _TextTemplatesScreenState extends State<TextTemplatesScreen> {
  String _selectedCategory = 'All';
  List<TextTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('text_templates');
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await SupabaseService.instance.fetchTextTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fall back to defaults on error
      if (mounted) {
        setState(() {
          _templates = TextTemplate.defaults;
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _categories {
    final categories = _templates.map((t) => t.category).toSet().toList();
    return ['All', ...categories];
  }

  List<TextTemplate> get _filteredTemplates {
    if (_selectedCategory == 'All') {
      return _templates;
    }
    return _templates.where((t) => t.category == _selectedCategory).toList();
  }

  String _personalizeMessage(TextTemplate template) {
    // Use the template's formatted method which handles all placeholder substitution
    return template.formatted(
      voterName: widget.voter.firstName,
      lastName: widget.voter.lastName,
      city: widget.voter.city,
    );
  }

  Future<void> _sendMessage(TextTemplate template) async {
    final phone = widget.voter.primaryPhone;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      return;
    }

    final message = _personalizeMessage(template);
    // Use proper URI construction for cross-platform SMS
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      AnalyticsService.instance.trackContact('text_message', widget.voter.canvassResult);
      AnalyticsService.instance.trackAction('template_used_${template.name.toLowerCase().replaceAll(' ', '_')}');

      // Pop back to voter detail screen so it can handle the post-contact dialog
      if (mounted) {
        Navigator.pop(context, true); // true indicates SMS was launched
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Text Templates'),
      ),
      body: Material(
        child: Column(
        children: [
          // Recipient info
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.voter.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      widget.voter.primaryPhone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  ),
                );
              }).toList(),
            ),
          ),

          // Templates list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTemplates.isEmpty
                    ? const Center(child: Text('No templates available'))
                    : ListView.builder(
                        itemCount: _filteredTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _filteredTemplates[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: InkWell(
                              onTap: () => _sendMessage(template),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          template.icon,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            template.name,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            template.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _personalizeMessage(template),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        Icons.send,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
    );
  }
}
