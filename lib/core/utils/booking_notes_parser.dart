import 'package:flutter/foundation.dart';

/// Parsed view of the customer-entered booking notes stored in `BookingModel.diagnosticNotes`.
///
/// Notes are stored as lines like:
/// - Device: Mobile Phone
/// - Model: iPhone 13
/// - Problem: Screen Repair
/// - Details: ...
/// - Promo Code: FIRST20
/// - Original Price: ₱500.00
/// - Discount: 20%
///
/// Some fields (most commonly Details) may be multiline.
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

  /// Returns a normalized text you can copy/share.
  String toPrettyText() {
    final buf = StringBuffer();
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) continue;
      buf.writeln('${entry.key}: ${entry.value.trim()}');
    }
    return buf.toString().trim();
  }
}

/// Parses `diagnosticNotes` into key/value fields.
///
/// - Only parses the customer-entered portion (splits at `---TECHNICIAN NOTES---`).
/// - Keys are matched case-insensitively.
/// - Supports multiline values: if a line does not contain a new `Key: Value` pair,
///   it is appended to the previous key's value.
BookingNotesParsed parseBookingNotes(String? diagnosticNotes) {
  if (diagnosticNotes == null || diagnosticNotes.trim().isEmpty) {
    return const BookingNotesParsed({});
  }

  final base = diagnosticNotes.split('---TECHNICIAN NOTES---').first;
  final lines = base.split('\n');

  // We keep insertion order by building into a LinkedHashMap-like map in order.
  final Map<String, String> fields = <String, String>{};

  String? currentKey;

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) continue;

    // Match "Key: value" where key is everything up to the first colon.
    final colonIndex = line.indexOf(':');
    final looksLikeKeyValue = colonIndex > 0;

    if (looksLikeKeyValue) {
      final maybeKey = line.substring(0, colonIndex).trim();
      final maybeValue = line.substring(colonIndex + 1).trim();

      // Heuristic: treat it as a key only if the key is reasonably short.
      // This prevents URLs / time strings from being treated as keys.
      if (maybeKey.isNotEmpty && maybeKey.length <= 30) {
        // Normalize key casing: title case with exact known keys preserved.
        final normalizedKey = _normalizeKey(maybeKey);
        fields[normalizedKey] = maybeValue;
        currentKey = normalizedKey;
        continue;
      }
    }

    // Continuation line => append to previous key.
    if (currentKey != null) {
      final existing = fields[currentKey] ?? '';
      fields[currentKey] = existing.isEmpty ? line.trim() : '$existing\n${line.trim()}';
    }
  }

  return BookingNotesParsed(fields);
}

String _normalizeKey(String rawKey) {
  final key = rawKey.trim();
  // Known keys we want to keep consistent.
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

  // Fallback: capitalize first letter of each word.
  return lower
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
