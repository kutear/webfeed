import 'package:intl/intl.dart';

const rfc822DatePattern = 'EEE, dd MMM yyyy HH:mm:ss Z';

const rfc822DatePatternWithoutWeek = 'dd MMM yyyy HH:mm:ss Z';

DateTime? parseDateTime(dateString) {
  if (dateString == null) return null;
  return _parseRfc822DateTime(dateString) ?? _parseIso8601DateTime(dateString);
}

DateTime? _parseRfc822DateTime(String dateString) {
  try {
    var pattern = rfc822DatePatternWithoutWeek;
    if (dateString.length > 4 && dateString[3] == ',') {
      pattern = rfc822DatePattern;
    }

    final num? length = dateString.length.clamp(0, pattern.length);
    final trimmedPattern = pattern.substring(0, length as int?); //Some feeds use a shortened RFC 822 date, e.g. 'Tue, 04 Aug 2020'
    final format = DateFormat(trimmedPattern, 'en_US');
    final dateTime = format.parse(dateString, true);
    // how to handle zone
    // ref https://www.w3.org/Protocols/rfc822/#z28
    final patternArray = dateString.split(' ');
    final zone =
        patternArray.length != 0 ? patternArray[patternArray.length - 1] : null;
    final fixedDateTime = dateTime.add(getZoneOffset(zone));
    return fixedDateTime.toLocal();
  } on FormatException {
    return null;
  }
}

Duration getZoneOffset(String? zone) {
  if (zone == null) return Duration();
  final re = RegExp(r'([-+])(\d\d)(\d\d)');
  Match? match = re.firstMatch(zone);
  if (match != null) {
    int parseIntOrZero(String? matched) {
      if (matched == null) return 0;
      return int.parse(matched);
    }
    final symbol = (match[1] == '+') ? -1 : 1;
    final hour = parseIntOrZero(match[2]);
    final minute = parseIntOrZero(match[3]);
    final durationInMinute = hour * 60 + minute;
    return Duration(minutes: symbol * durationInMinute);
  } else {
    final offset = {
      'UT': Duration(),
      'GMT': Duration(),
      'EST': Duration(hours: 5),
      'EDT': Duration(hours: 4),
      'CST': Duration(hours: 6),
      'CDT': Duration(hours: 5),
      'MST': Duration(hours: 7),
      'MDT': Duration(hours: 6),
      'PST': Duration(hours: 8),
      'PDT': Duration(hours: 7),
      'Z': Duration(),
      'A': Duration(hours: -1),
      'M': Duration(hours: -12),
      'N': Duration(hours: 1),
      'Y': Duration(hours: 12),
    };
    if(offset[zone] != null) {
      return offset[zone]!;
    }
  }
  return Duration();
}

DateTime? _parseIso8601DateTime(dateString) {
  try {
    return DateTime.parse(dateString);
  } on FormatException {
    return null;
  }
}
