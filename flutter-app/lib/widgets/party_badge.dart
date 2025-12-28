import 'package:flutter/material.dart';

class PartyBadge extends StatelessWidget {
  final String party;

  const PartyBadge({super.key, required this.party});

  String get _abbreviation {
    switch (party) {
      case 'Democratic':
        return 'DEM';
      case 'Republican':
        return 'REP';
      case 'Libertarian':
        return 'LIB';
      case 'Green':
        return 'GRN';
      case 'Registered Independent':
        return 'IND';
      case 'Non-Partisan':
        return 'NP';
      case 'Liberal':
        return 'LIB';
      case 'Other':
        return 'OTH';
      default:
        return '?';
    }
  }

  Color get _color {
    switch (party) {
      case 'Democratic':
        return Colors.blue;
      case 'Republican':
        return Colors.red;
      case 'Libertarian':
        return Colors.amber.shade700;
      case 'Green':
        return Colors.green;
      case 'Registered Independent':
        return Colors.purple;
      case 'Non-Partisan':
        return Colors.teal;
      case 'Liberal':
        return Colors.lightBlue;
      case 'Other':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _abbreviation,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}
