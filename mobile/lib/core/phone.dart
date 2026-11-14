String nationalDigits(String mobileNumber) {
  final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

String formatIndianMobile(String mobileNumber) {
  final national = nationalDigits(mobileNumber);
  if (national.length != 10) {
    return mobileNumber;
  }
  return '+91 ${national.substring(0, 5)} ${national.substring(5)}';
}

String maskIndianMobile(String mobileNumber) {
  final national = nationalDigits(mobileNumber);
  final visible = national.length >= 5 ? national.substring(0, 5) : national;
  return '+91 $visible •••••';
}

const _titles = {
  'mr',
  'mrs',
  'ms',
  'miss',
  'dr',
  'shri',
  'smt',
  'master',
  'baby',
};

/// The name without a leading title. `Mr Suneel Kumar` becomes `Suneel Kumar`.
String nameWithoutTitle(String fullName) {
  final words = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  final kept = words.toList();
  while (kept.length > 1 &&
      _titles.contains(kept.first.toLowerCase().replaceAll('.', ''))) {
    kept.removeAt(0);
  }
  return kept.join(' ');
}

/// The first name to greet someone by. `Mr Suneel Kumar` becomes `Suneel`.
String givenName(String fullName) {
  final name = nameWithoutTitle(fullName);
  return name.isEmpty ? '' : name.split(' ').first;
}
