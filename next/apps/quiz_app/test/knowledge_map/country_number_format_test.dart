import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/country_number_format.dart';

void main() {
  test('formats missing, zero, small and large values approximately', () {
    expect(formatCountryNumber(null, russian: true), '—');
    expect(formatCountryNumber(0, russian: true), '0');
    expect(formatCountryNumber(123, russian: true), '≈ 120');
    expect(formatCountryNumber(0.00123, russian: true), '≈ 0,0012');
    expect(formatCountryNumber(1250000, russian: true), '≈ 1,3 млн');
    expect(formatCountryNumber(12345, russian: true), '≈ 12 тыс.');
    expect(formatCountryNumber(67391000, russian: true), '≈ 67 млн');
    expect(formatCountryNumber(1250000, russian: false), '≈ 1.3 million');
    expect(formatCountryNumber(999999, russian: false), '≈ 1 million');
  });
}
