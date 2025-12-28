import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/voter.dart';
import '../../models/enums/canvass_result.dart';
import '../../models/enums/contact_method.dart';
import '../../models/contact_entry.dart';
import '../../services/supabase_service.dart';
import '../../services/voice_note_service.dart';
import '../../providers/voter_provider.dart';
import '../../services/analytics_service.dart';
import '../../utils/adaptive_icons.dart';
import '../../utils/adaptive_colors.dart';
import '../../widgets/party_badge.dart';
import '../../widgets/info_row.dart';
import '../../widgets/action_button.dart';
import '../../widgets/quick_result_button.dart';
import '../../widgets/editable_row.dart';
import '../../widgets/voice_recorder.dart';
import '../../widgets/voice_player.dart';
import '../communication/text_templates_screen.dart';
import '../communication/call_script_screen.dart';
import '../communication/post_contact_sheet.dart';
import 'contact_history_screen.dart';

class VoterDetailScreen extends ConsumerStatefulWidget {
  final Voter voter;

  const VoterDetailScreen({super.key, required this.voter});

  @override
  ConsumerState<VoterDetailScreen> createState() => _VoterDetailScreenState();
}

class _VoterDetailScreenState extends ConsumerState<VoterDetailScreen>
    with WidgetsBindingObserver {
  late Voter _voter;
  bool _isEditMode = false;
  bool _isSaving = false;
  String? _pendingContactMethod; // Track if we're waiting for contact result
  int _contactCount = 0; // Calculated from contact_history table
  List<VoiceNote> _voiceNotes = [];
  bool _isLoadingVoiceNotes = false;

  // Edit controllers
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _cellPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _partyController;
  late TextEditingController _notesController;
  late TextEditingController _mailAddressController;
  late TextEditingController _mailCityController;
  late TextEditingController _mailStateController;
  late TextEditingController _mailZipController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voter = widget.voter;
    _initControllers();
    _loadContactCount();
    _loadVoiceNotes();
    AnalyticsService.instance.trackScreen('voter_detail');
  }

  Future<void> _loadContactCount() async {
    try {
      final entries = await SupabaseService.instance.fetchContactHistory(_voter.uniqueId);
      if (mounted) {
        setState(() {
          _contactCount = entries.length;
        });
      }
    } catch (_) {
      // Use voter's stored count as fallback
      _contactCount = _voter.contactAttempts;
    }
  }

  Future<void> _loadVoiceNotes() async {
    setState(() => _isLoadingVoiceNotes = true);
    try {
      final notes = await VoiceNoteService().fetchVoiceNotes(_voter.uniqueId);
      if (mounted) {
        setState(() {
          _voiceNotes = notes;
          _isLoadingVoiceNotes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading voice notes: $e');
      if (mounted) {
        setState(() => _isLoadingVoiceNotes = false);
      }
    }
  }

  Future<void> _onVoiceNoteRecorded(String localPath) async {
    try {
      final audioPath = await VoiceNoteService().uploadVoiceNote(
        localPath: localPath,
        voterId: _voter.uniqueId,
      );
      if (audioPath != null && mounted) {
        // Reload voice notes to get the newly saved one
        await _loadVoiceNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note saved')),
        );
      }
    } catch (e) {
      debugPrint('Error saving voice note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save voice note')),
        );
      }
    }
  }

  Future<void> _deleteVoiceNote(VoiceNote voiceNote) async {
    try {
      await VoiceNoteService().deleteVoiceNote(voiceNote.id);
      if (mounted) {
        setState(() {
          _voiceNotes.removeWhere((n) => n.id == voiceNote.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note deleted')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting voice note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete voice note')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingContactMethod != null) {
      // App returned from background after call/text - show result modal
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pendingContactMethod != null) {
          _showContactResultDialog(_pendingContactMethod!);
          _pendingContactMethod = null;
        }
      });
    }
  }

  void _initControllers() {
    _firstNameController = TextEditingController(text: _voter.firstName);
    _middleNameController = TextEditingController(text: _voter.middleName);
    _lastNameController = TextEditingController(text: _voter.lastName);
    _phoneController = TextEditingController(text: _voter.phone);
    _cellPhoneController = TextEditingController(text: _voter.cellPhone);
    _addressController = TextEditingController(text: _voter.residenceAddress);
    _partyController = TextEditingController(text: _voter.partyDescription);
    _notesController = TextEditingController(text: _voter.canvassNotes);
    _mailAddressController = TextEditingController(text: _voter.mailAddress);
    _mailCityController = TextEditingController(text: _voter.mailCity);
    _mailStateController = TextEditingController(text: _voter.mailState);
    _mailZipController = TextEditingController(text: _voter.mailZip);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cellPhoneController.dispose();
    _addressController.dispose();
    _partyController.dispose();
    _notesController.dispose();
    _mailAddressController.dispose();
    _mailCityController.dispose();
    _mailStateController.dispose();
    _mailZipController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) {
        // Cancel edit - restore original values
        _initControllers();
      }
      _isEditMode = !_isEditMode;
    });
    AnalyticsService.instance.trackAction(_isEditMode ? 'edit_mode_enabled' : 'edit_mode_cancelled');
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final updatedVoter = _voter.copyWith(
      firstName: _firstNameController.text,
      middleName: _middleNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      cellPhone: _cellPhoneController.text,
      residenceAddress: _addressController.text,
      partyDescription: _partyController.text,
      canvassNotes: _notesController.text,
      mailAddress: _mailAddressController.text,
      mailCity: _mailCityController.text,
      mailState: _mailStateController.text,
      mailZip: _mailZipController.text,
    );

    final success = await ref.read(voterProvider.notifier).updateVoter(updatedVoter);

    setState(() => _isSaving = false);

    if (success) {
      setState(() {
        _voter = updatedVoter;
        _isEditMode = false;
      });
      AnalyticsService.instance.trackAction('voter_info_saved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save changes')),
        );
      }
    }
  }

  Future<void> _makeCall() async {
    if (!_voter.hasPhoneNumber) return;

    final uri = Uri.parse('tel:${_voter.primaryPhone}');
    if (await canLaunchUrl(uri)) {
      _pendingContactMethod = 'Phone Call';
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      AnalyticsService.instance.trackContact('phone_call', _voter.canvassResult);
    }
  }

  Future<void> _sendText() async {
    if (!_voter.hasPhoneNumber) return;

    // Send directly to SMS app with pending result tracking
    final uri = Uri(scheme: 'sms', path: _voter.primaryPhone);
    if (await canLaunchUrl(uri)) {
      _pendingContactMethod = 'Text Message';
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      AnalyticsService.instance.trackContact('text_message', _voter.canvassResult);
    }
  }

  Future<void> _showTextTemplates() async {
    final result = await Navigator.push<bool>(
      context,
      platformPageRoute(
        context: context,
        builder: (_) => TextTemplatesScreen(voter: _voter),
      ),
    );

    // If SMS was launched from templates, set pending contact method
    if (result == true) {
      _pendingContactMethod = 'Text Message';
    }
  }

  void _showContactResultDialog(String contactMethodString) {
    final method = _parseContactMethod(contactMethodString);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('$contactMethodString Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How did the $contactMethodString with ${_voter.displayName} go?'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _resultButton(context, 'Supportive', Colors.green, CanvassResult.supportive, method: method),
                _resultButton(context, 'Undecided', Colors.orange, CanvassResult.undecided, method: method),
                _resultButton(context, 'Opposed', Colors.red, CanvassResult.opposed, method: method),
                _resultButton(context, 'No Answer', Colors.grey, CanvassResult.noAnswer, method: method),
                _resultButton(context, 'Left Voicemail', Colors.blue, CanvassResult.leftVoicemail, method: method),
                _resultButton(context, 'Wrong Number', Colors.purple, CanvassResult.wrongNumber, method: method),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _resultButton(BuildContext context, String label, Color color, CanvassResult result, {ContactMethod? method}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        Navigator.pop(context);
        _quickResult(result, method: method);
      },
      child: Text(label),
    );
  }

  Future<void> _openMaps() async {
    final address = Uri.encodeComponent(_voter.fullAddress);
    final uri = Uri.parse('https://maps.apple.com/?address=$address');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      AnalyticsService.instance.trackAction('open_maps');
    }
  }

  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: _voter.fullAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied')),
    );
    AnalyticsService.instance.trackAction('copy_address');
  }

  void _showCallScript() {
    Navigator.push(
      context,
      platformPageRoute(
        context: context,
        builder: (_) => const CallScriptScreen(),
      ),
    );
  }

  Future<void> _viewContactHistory() async {
    await Navigator.push(
      context,
      platformPageRoute(
        context: context,
        builder: (_) => ContactHistoryScreen(voter: _voter),
      ),
    );
    // Reload count in case entries were added/removed
    _loadContactCount();
  }

  void _showPostContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PostContactSheet(
        voter: _voter,
        onResultSelected: _handleCanvassResult,
      ),
    );
  }

  Future<void> _handleCanvassResult(CanvassResult result, String? notes, {ContactMethod? method}) async {
    final updatedVoter = _voter.copyWith(
      canvassResult: result,
      lastContactAttempt: DateTime.now(),
      canvassNotes: notes ?? _voter.canvassNotes,
    );

    final success = await ref.read(voterProvider.notifier).updateVoter(updatedVoter);

    if (success) {
      setState(() => _voter = updatedVoter);
      AnalyticsService.instance.trackCanvassResult(result.displayName, _voter.uniqueId);

      // Save to contact history (use uniqueId, not visitorId which is often null)
      final contactMethod = method ?? ContactMethod.door;
      final entry = ContactEntry(
        id: '',
        visitorId: _voter.uniqueId,
        method: contactMethod,
        result: result,
        notes: notes,
        contactedAt: DateTime.now(),
        contactedBy: null,
      );
      try {
        await SupabaseService.instance.addContactEntry(entry);
        // Reload count from contact_history table
        _loadContactCount();
      } catch (e) {
        debugPrint('Error saving contact history: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as ${result.displayName}')),
        );
      }
    }
  }

  Future<void> _quickResult(CanvassResult result, {ContactMethod? method}) async {
    await _handleCanvassResult(result, null, method: method);
  }

  ContactMethod _parseContactMethod(String? methodString) {
    switch (methodString) {
      case 'Phone Call':
        return ContactMethod.call;
      case 'Text Message':
        return ContactMethod.text;
      default:
        return ContactMethod.door;
    }
  }

  Color _getStatusColor() {
    switch (_voter.canvassResult) {
      case CanvassResult.supportive:
      case CanvassResult.strongSupport:
        return Colors.green;
      case CanvassResult.undecided:
      case CanvassResult.leaning:
        return Colors.orange;
      case CanvassResult.opposed:
      case CanvassResult.stronglyOpposed:
        return Colors.red;
      case CanvassResult.contacted:
        return Colors.blue;
      case CanvassResult.notContacted:
        return Colors.grey;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(_voter.displayName),
        trailingActions: [
          if (_isEditMode) ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              PlatformIconButton(
                icon: Icon(AdaptiveIcons.check),
                onPressed: _saveChanges,
                material: (_, __) => MaterialIconButtonData(tooltip: 'Save'),
              ),
            PlatformIconButton(
              icon: Icon(AdaptiveIcons.close),
              onPressed: _toggleEditMode,
              material: (_, __) => MaterialIconButtonData(tooltip: 'Cancel'),
            ),
          ] else
            PlatformIconButton(
              icon: Icon(AdaptiveIcons.edit),
              onPressed: _toggleEditMode,
              material: (_, __) => MaterialIconButtonData(tooltip: 'Edit'),
            ),
        ],
      ),
      body: Material(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header with prominent votes display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatusColor().withAlpha(25),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _voter.canvassResult.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                      const Spacer(),
                      if (_voter.partyDescription.isNotEmpty)
                        PartyBadge(party: _voter.partyDescription),
                      if (_voter.livesElsewhere) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Absentee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_voter.isMailVoter) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Mail Voter',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Quick result buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Result',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: QuickResultButton(
                          label: 'Support',
                          color: Colors.green,
                          onPressed: () => _quickResult(CanvassResult.supportive),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickResultButton(
                          label: 'Undecided',
                          color: Colors.orange,
                          onPressed: () => _quickResult(CanvassResult.undecided),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: QuickResultButton(
                          label: 'Opposed',
                          color: Colors.red,
                          onPressed: () => _quickResult(CanvassResult.opposed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showPostContactSheet,
                      child: const Text('More Options...'),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      onPressed: _voter.hasPhoneNumber ? _makeCall : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.message,
                      label: 'Text',
                      onPressed: _voter.hasPhoneNumber ? _showTextTemplates : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.map,
                      label: 'Navigate',
                      onPressed: _openMaps,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.description,
                      label: 'Script',
                      onPressed: _showCallScript,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Voter information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditMode) ...[
                    EditableRow(label: 'First Name', controller: _firstNameController),
                    EditableRow(label: 'Middle Name', controller: _middleNameController),
                    EditableRow(label: 'Last Name', controller: _lastNameController),
                    EditableRow(
                      label: 'Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    EditableRow(
                      label: 'Cell',
                      controller: _cellPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ] else ...[
                    InfoRow(label: 'Name', value: _voter.displayName),
                    InfoRow(
                      label: 'Phone',
                      value: _voter.phone.isNotEmpty ? _voter.phone : 'Not available',
                      onTap: _voter.phone.isNotEmpty ? _makeCall : null,
                    ),
                    InfoRow(
                      label: 'Cell',
                      value: _voter.cellPhone.isNotEmpty ? _voter.cellPhone : 'Not available',
                      onTap: _voter.cellPhone.isNotEmpty ? _makeCall : null,
                    ),
                  ],
                ],
              ),
            ),

            const Divider(),

            // Address section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Address',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (!_isEditMode)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: _copyAddress,
                          tooltip: 'Copy address',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isEditMode) ...[
                    EditableRow(label: 'Residence Address', controller: _addressController),
                    const SizedBox(height: 16),
                    Text(
                      'Mailing Address',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    EditableRow(label: 'Street', controller: _mailAddressController),
                    EditableRow(label: 'City', controller: _mailCityController),
                    EditableRow(label: 'State', controller: _mailStateController),
                    EditableRow(label: 'ZIP', controller: _mailZipController),
                  ] else ...[
                    InfoRow(label: 'Street', value: '${_voter.streetNum} ${_voter.streetDir} ${_voter.streetName}'),
                    InfoRow(label: 'City/ZIP', value: '${_voter.city} ${_voter.zip}'),
                    if (_voter.livesElsewhere) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final colors = AdaptiveColors.of(context);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.warningLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.warning),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.home_work, size: 16, color: colors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  'Lives Elsewhere (Absentee Owner)',
                                  style: TextStyle(
                                    color: colors.warning,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    if (_voter.hasMailingAddress) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Mailing Address',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _voter.fullMailingAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const Divider(),

            // Voter information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voter Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_voter.visitorId.isNotEmpty)
                    InfoRow(label: 'Voter ID', value: _voter.visitorId),
                  InfoRow(label: 'Party', value: _voter.partyDescription),
                  InfoRow(label: 'Age', value: _voter.voterAge.toString()),
                  InfoRow(label: 'Gender', value: _voter.gender),
                  if (_voter.isMailVoter)
                    InfoRow(
                      label: 'Mail Voter',
                      value: 'Yes - Early/Absentee Voter',
                      valueColor: Colors.green,
                    ),
                ],
              ),
            ),

            const Divider(),

            // Contact history
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Contact History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _viewContactHistory,
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Attempts',
                    value: _contactCount.toString(),
                  ),
                  if (_voter.lastContactAttempt != null)
                    InfoRow(
                      label: 'Last Contact',
                      value: _formatDate(_voter.lastContactAttempt!),
                    ),
                  if (_voter.lastContactMethod != null)
                    InfoRow(
                      label: 'Method',
                      value: _voter.lastContactMethod!.displayName,
                    ),
                ],
              ),
            ),

            const Divider(),

            // Notes section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditMode)
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Add notes about this voter...',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    Text(
                      _voter.canvassNotes.isNotEmpty ? _voter.canvassNotes : 'No notes',
                      style: TextStyle(
                        color: _voter.canvassNotes.isEmpty
                            ? Theme.of(context).colorScheme.outline
                            : null,
                      ),
                    ),
                ],
              ),
            ),

            const Divider(),

            // Voice Notes section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Voice Notes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      if (_voiceNotes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_voiceNotes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Voice recorder
                  VoiceRecorder(
                    onRecordingComplete: _onVoiceNoteRecorded,
                  ),
                  const SizedBox(height: 12),
                  // Voice notes list
                  if (_isLoadingVoiceNotes)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_voiceNotes.isEmpty)
                    Text(
                      'No voice notes yet. Tap the mic to record.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _voiceNotes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final note = _voiceNotes[index];
                        return VoicePlayer(
                          voiceNote: note,
                          onDelete: () => _deleteVoiceNote(note),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
