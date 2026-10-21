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
