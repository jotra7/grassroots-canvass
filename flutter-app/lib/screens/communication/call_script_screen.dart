import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../models/call_script.dart';
import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/adaptive_icons.dart';

class CallScriptScreen extends StatefulWidget {
  const CallScriptScreen({super.key});

  @override
  State<CallScriptScreen> createState() => _CallScriptScreenState();
}

class _CallScriptScreenState extends State<CallScriptScreen> {
  int _currentSection = 0;
  List<ScriptSection> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('call_script');
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    try {
      final scripts = await SupabaseService.instance.getCallScripts();
      setState(() {
        _sections = scripts;
        _isLoading = false;
      });
    } catch (e) {
      // Fall back to defaults on error
      setState(() {
        _sections = CallScript.defaults;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PlatformScaffold(
        appBar: PlatformAppBar(
          title: const Text('Call Script'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_sections.isEmpty) {
      return PlatformScaffold(
        appBar: PlatformAppBar(
          title: const Text('Call Script'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_disabled,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No call scripts available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your campaign admin to set up scripts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final current = _sections[_currentSection];

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Call Script'),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(AdaptiveIcons.infoOutlined),
            onPressed: _showTips,
            material: (_, __) => MaterialIconButtonData(tooltip: 'Tips'),
          ),
        ],
      ),
      body: Material(
        child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentSection + 1) / _sections.length,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),

          // Section indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: current.color.withOpacity(0.1),
            child: Row(
              children: [
                for (int i = 0; i < _sections.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentSection = i),
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentSection
                              ? current.color
                              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Section content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: current.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_currentSection + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: current.color,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Step ${_currentSection + 1} of ${_sections.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Script content
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      current.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tip
                  if (current.tip.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              current.tip,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentSection > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentSection--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                const SizedBox(width: 16),
                if (_currentSection < _sections.length - 1)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _currentSection++),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                  )
                else
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call Tips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTipItem(Icons.volume_up, 'Speak clearly and at a moderate pace'),
            _buildTipItem(Icons.emoji_emotions, 'Smile while talking - it comes through!'),
            _buildTipItem(Icons.hearing, 'Listen more than you talk'),
            _buildTipItem(Icons.timer, 'Keep calls under 5 minutes'),
            _buildTipItem(Icons.note_add, 'Take notes during the call'),
            _buildTipItem(Icons.thumb_up, 'Thank them for their time'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
