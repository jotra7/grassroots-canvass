import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final isApple = PlatformUtils.isApple;

    final color = isEnabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );

    // iOS uses GestureDetector with scale animation
    if (isApple) {
      return GestureDetector(
        onTap: widget.onPressed,
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: content,
        ),
      );
    }

    // Material uses InkWell
    return InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}
