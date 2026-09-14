String formatUsd(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer(value < 0 ? r'-$' : r'$');
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String formatUsdPerM2(num value) => '${formatUsd(value)} / m²';

String formatM2(num value) {
  final rounded = value.round();
  return '$rounded m²';
}

String formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String formatListings(int count) {
  if (count == 1) return '1 listing';
  return '${formatCount(count)} listings';
}

String formatSample(int count) => formatListings(count);

String formatOrdinal(int value) {
  final tens = value % 100;
  if (tens >= 11 && tens <= 13) return '${value}th';
  return switch (value % 10) {
    1 => '${value}st',
    2 => '${value}nd',
    3 => '${value}rd',
    _ => '${value}th',
  };
}

String formatTimes(num high, num low) {
  if (low <= 0) return '';
  final ratio = high / low;
  if (ratio < 1.08) return 'about the same';
  if (ratio >= 10) return '${ratio.round()}×';
  final tenths = (ratio * 10).round() / 10;
  final label = tenths == tenths.roundToDouble()
      ? tenths.round().toString()
      : tenths.toString();
  return '$label×';
}
