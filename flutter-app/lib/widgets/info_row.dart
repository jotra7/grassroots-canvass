import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import '../utils/adaptive_icons.dart';

class InfoRow extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.valueColor,
  });

  @override
  State<InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<InfoRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformUtils.isApple;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              widget.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.valueColor ?? (widget.onTap != null
                        ? Theme.of(context).colorScheme.primary
                        : null),
                    fontWeight: widget.valueColor != null ? FontWeight.w600 : null,
                  ),
            ),
          ),
          if (widget.onTap != null)
            Icon(
              AdaptiveIcons.chevronRight,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
        ],
      ),
    );

    if (widget.onTap != null) {
      // iOS uses GestureDetector with opacity feedback
      if (isApple) {
        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: content,
          ),
        );
      }

      // Material uses InkWell
      return InkWell(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }
}
