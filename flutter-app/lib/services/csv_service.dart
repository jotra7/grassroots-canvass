import 'package:intl/intl.dart';
import '../models/voter.dart';

class CSVService {
  static String exportResults(List<Voter> voters) {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(
      'Owner Name,Address,City,Zip,First Name,Last Name,Party,'
      'Phone,Cell Phone,Canvass Result,Canvass Notes,Canvass Date'
    );

    final dateFormat = DateFormat('M/d/yyyy h:mm a');

    for (final voter in voters) {
      final canvassDateStr = voter.canvassDate != null
          ? dateFormat.format(voter.canvassDate!)
          : '';

      final row = [
        _escapeCSV(voter.ownerName),
        _escapeCSV(voter.fullAddress),
        _escapeCSV(voter.city),
        _escapeCSV(voter.zip),
        _escapeCSV(voter.firstName),
        _escapeCSV(voter.lastName),
        _escapeCSV(voter.partyDescription),
        _escapeCSV(voter.phone),
        _escapeCSV(voter.cellPhone),
        _escapeCSV(voter.canvassResult.displayName),
        _escapeCSV(voter.canvassNotes),
        _escapeCSV(canvassDateStr),
      ].join(',');

      buffer.writeln(row);
    }

    return buffer.toString();
  }

  static String exportPhoneNumbers(List<Voter> voters) {
    final numbers = <String>[];
    for (final voter in voters) {
      if (voter.cellPhone.isNotEmpty) {
        numbers.add(voter.cellPhone);
      } else if (voter.phone.isNotEmpty) {
        numbers.add(voter.phone);
      }
    }
    return numbers.join('\n');
  }

  static String _escapeCSV(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
