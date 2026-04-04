import 'package:flutter/foundation.dart';
@immutable
class BookingNotesParsed {
  final Map<String, String> fields;
  const BookingNotesParsed(this.fields);
  String? get device => fields['Device'];
  String? get model => fields['Model'];
  String? get problem => fields['Problem'];
  String? get details => fields['Details'];
  String? get technician => fields['Technician'];
  String? get promoCode => fields['Promo Code'];
  String? get originalPrice => fields['Original Price'];
  String? get discount => fields['Discount'];
  String? get priority => fields['Priority'];
  String toPrettyText() {
    final buf = StringBuffer();
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) continue;
      buf.writeln('${entry.key}: ${entry.value.trim()}');
    }
    return buf.toString().trim();
  }
}
BookingNotesParsed parseBookingNotes(String? diagnosticNotes) {
  if (diagnosticNotes == null || diagnosticNotes.trim().isEmpty) {
    return const BookingNotesParsed({});
  }
  final base = diagnosticNotes.split('---TECHNICIAN NOTES---').first;
  final lines = base.split('\n');
  final Map<String, String> fields = <String, String>{};
  String? currentKey;
  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) continue;
    final colonIndex = line.indexOf(':');
    final looksLikeKeyValue = colonIndex > 0;
    if (looksLikeKeyValue) {
      final maybeKey = line.substring(0, colonIndex).trim();
      final maybeValue = line.substring(colonIndex + 1).trim();
      if (maybeKey.isNotEmpty && maybeKey.length <= 30) {
        final normalizedKey = _normalizeKey(maybeKey);
        fields[normalizedKey] = maybeValue;
        currentKey = normalizedKey;
        continue;
      }
    }
    if (currentKey != null) {
      final existing = fields[currentKey] ?? '';
      fields[currentKey] = existing.isEmpty ? line.trim() : '$existing\n${line.trim()}';
    }
  }
  return BookingNotesParsed(fields);
}
String _normalizeKey(String rawKey) {
  final key = rawKey.trim();
  const known = <String, String>{
    'device': 'Device',
    'model': 'Model',
    'problem': 'Problem',
    'details': 'Details',
    'technician': 'Technician',
    'promo code': 'Promo Code',
    'original price': 'Original Price',
    'discount': 'Discount',
    'priority': 'Priority',
  };
  final lower = key.toLowerCase();
  if (known.containsKey(lower)) return known[lower]!;
  return lower
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}