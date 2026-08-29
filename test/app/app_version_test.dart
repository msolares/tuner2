import 'package:afinador/app/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expone la versión visible del build Web', () {
    expect(appVersion, '1.0.5');
    expect(appBuildNumber, 9);
    expect(appVersionLabel, 'v1.0.5+9');
  });
}
