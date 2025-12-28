import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/voter.dart';
import '../models/enums/canvass_result.dart';
import '../utils/platform_utils.dart';
import '../utils/adaptive_icons.dart';
import 'party_badge.dart';

class VoterRow extends StatefulWidget {
  final Voter voter;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const VoterRow({
    super.key,
    required this.voter,
    this.isSelected = false,
    this.isSelectMode = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<VoterRow> createState() => _VoterRowState();
}

class _VoterRowState extends State<VoterRow> {
  bool _isPressed = false;

  Color _getStatusColor() {
    switch (widget.voter.canvassResult) {
      case CanvassResult.supportive:
        return Colors.green;
      case CanvassResult.undecided:
        return Colors.orange;
      case CanvassResult.opposed:
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
    final isApple = PlatformUtils.isApple;

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Select checkbox (in select mode)
          if (widget.isSelectMode) ...[
            if (isApple)
              CupertinoCheckbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onTap(),
              )
            else
              Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onTap(),
              ),
            const SizedBox(width: 8),
          ],

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.voter.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.voter.fullAddress,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (widget.voter.partyDescription.isNotEmpty)
                      PartyBadge(party: widget.voter.partyDescription),
                    if (widget.voter.livesElsewhere)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AdaptiveIcons.home, size: 12, color: Colors.orange),
                            const SizedBox(width: 2),
                            const Text(
                              'Absentee',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.voter.isMailVoter)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Mail Voter',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Phone icon & attempts
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.voter.hasPhoneNumber)
                Icon(
                  AdaptiveIcons.phone,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              if (widget.voter.contactAttempts > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.voter.contactAttempts}x',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),
          Icon(
            AdaptiveIcons.chevronRight,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );

    // iOS uses GestureDetector with scale animation
    if (isApple) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? CupertinoColors.systemGrey5.resolveFrom(context)
                    : CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 0.5,
                ),
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    // Material uses Card with InkWell
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: widget.isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
