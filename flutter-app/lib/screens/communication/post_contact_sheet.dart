import 'package:flutter/material.dart';
import '../../models/voter.dart';
import '../../models/enums/canvass_result.dart';
import '../../widgets/outcome_button.dart';

class PostContactSheet extends StatefulWidget {
  final Voter voter;
  final Function(CanvassResult result, String? notes) onResultSelected;

  const PostContactSheet({
    super.key,
    required this.voter,
    required this.onResultSelected,
  });

  @override
  State<PostContactSheet> createState() => _PostContactSheetState();
}

class _PostContactSheetState extends State<PostContactSheet> {
  CanvassResult? _selectedResult;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedResult != null) {
      widget.onResultSelected(_selectedResult!, _notesController.text);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Contact Result',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'How did the conversation with ${widget.voter.firstName} go?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),

            // Positive outcomes
            _buildSection('Positive', Colors.green, [
              CanvassResult.supportive,
              CanvassResult.strongSupport,
              CanvassResult.leaning,
              CanvassResult.willingToVolunteer,
              CanvassResult.requestedSign,
            ]),

            const SizedBox(height: 16),

            // Neutral outcomes
            _buildSection('Neutral', Colors.orange, [
              CanvassResult.undecided,
              CanvassResult.needsInfo,
              CanvassResult.callbackRequested,
              CanvassResult.contacted,
            ]),

            const SizedBox(height: 16),

            // Negative outcomes
            _buildSection('Negative', Colors.red, [
              CanvassResult.opposed,
              CanvassResult.stronglyOpposed,
              CanvassResult.refused,
            ]),

            const SizedBox(height: 16),

            // Not reached outcomes
            _buildSection('Not Reached', Colors.grey, [
              CanvassResult.notHome,
              CanvassResult.noAnswer,
              CanvassResult.wrongNumber,
              CanvassResult.moved,
              CanvassResult.deceased,
              CanvassResult.doNotContact,
            ]),

            const SizedBox(height: 24),

            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this conversation...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedResult != null ? _submit : null,
                child: Text(
                  _selectedResult != null
                      ? 'Save as "${_selectedResult!.displayName}"'
                      : 'Select an outcome',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Color color, List<CanvassResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: results.map((result) {
            final isSelected = _selectedResult == result;
            return OutcomeButton(
              label: result.displayName,
              color: color,
              isSelected: isSelected,
              onPressed: () => setState(() => _selectedResult = result),
            );
          }).toList(),
        ),
      ],
    );
  }
}
