import 'package:intl/intl.dart';

/// "Good morning" / "Good afternoon" / "Good evening".
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String firstName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
}

/// "MON" / "OCT" style uppercase abbreviations.
String weekdayShort(DateTime d) => DateFormat('EEE').format(d).toUpperCase();
String monthShort(DateTime d) => DateFormat('MMM').format(d).toUpperCase();
String dayNum(DateTime d, {bool pad = false}) =>
    pad ? d.day.toString().padLeft(2, '0') : d.day.toString();

String hhmm(DateTime d) => DateFormat('HH:mm').format(d);

/// "Mon 12 · 18:00"
String slotLabel(DateTime d) => '${DateFormat('EEE d').format(d)} · ${hhmm(d)}';

/// "2h ago", "Yesterday", "Oct 3".
String relativeTime(DateTime t, {DateTime? now}) {
  now ??= DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && now.day == t.day) return '${diff.inHours}h ago';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final days = today.difference(day).inDays;
  if (days == 1) return 'Yesterday';
  return DateFormat('MMM d').format(t);
}

/// Trims "HH:mm:ss" to "HH:mm".
String trimTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

/// "18–20" from "18:00:00" / "20:00:00"; keeps minutes when non-zero.
String compactRange(String start, String end) {
  String part(String t) {
    final s = trimTime(t);
    final hh = int.tryParse(s.substring(0, 2)) ?? 0;
    final mm = s.length >= 5 ? s.substring(3, 5) : '00';
    return mm == '00' ? '$hh' : '$hh:$mm';
  }

  return '${part(start)}–${part(end)}';
}
