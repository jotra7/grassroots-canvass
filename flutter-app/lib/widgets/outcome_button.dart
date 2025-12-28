import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

class OutcomeButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const OutcomeButton({
    super.key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<OutcomeButton> createState() => _OutcomeButtonState();
}

class _OutcomeButtonState extends State<OutcomeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformUtils.isApple;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? widget.color.withOpacity(0.2)
            : widget.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isSelected ? widget.color : widget.color.withOpacity(0.3),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
          color: widget.color,
        ),
      ),
    );

    // iOS uses GestureDetector with scale animation
    if (isApple) {
      return GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
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
