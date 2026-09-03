/// Whether a destination is open, as far as its free-text hours can tell us.
enum OpeningStatus { open, closed, unknown }

OpeningStatus readOpeningStatus(String openingHours, {DateTime? now}) {
  if (_isAlwaysOpen(openingHours)) return OpeningStatus.open;

  final hours = _parse(openingHours);
  if (hours == null) return OpeningStatus.unknown;

  final moment = now ?? DateTime.now();
  final minutesNow = moment.hour * 60 + moment.minute;
  final (opens, closes) = hours;

  final isOpen = closes >= opens
      ? minutesNow >= opens && minutesNow < closes
      : minutesNow >= opens || minutesNow < closes;

  return isOpen ? OpeningStatus.open : OpeningStatus.closed;
}

String? openingSummary(String openingHours, {DateTime? now}) {
  if (_isAlwaysOpen(openingHours)) return 'Open 24 hours';

  final hours = _parse(openingHours);
  if (hours == null) return null;

  final (opens, closes) = hours;
  return switch (readOpeningStatus(openingHours, now: now)) {
    OpeningStatus.open => 'Open until ${_clock(closes)}',
    OpeningStatus.closed => 'Closed · opens ${_clock(opens)}',
    OpeningStatus.unknown => null,
  };
}

bool _isAlwaysOpen(String openingHours) {
  final text = openingHours.toLowerCase();
  return text.contains('24 hour') || text.contains('24/7');
}

(int opens, int closes)? _parse(String openingHours) {
  final match = RegExp(
    r'(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})',
  ).firstMatch(openingHours);
  if (match == null) return null;

  return (
    int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!),
    int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!),
  );
}

String _clock(int minutesPastMidnight) {
  final hours = (minutesPastMidnight ~/ 60).toString().padLeft(2, '0');
  final minutes = (minutesPastMidnight % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}
