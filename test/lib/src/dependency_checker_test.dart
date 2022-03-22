import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/dependency_checker.dart';

void main() {
  Config config =
      Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));

  Package package =
      Package('Dodgers', Uri(scheme: 'file', path: '/home/mlb/teams/'));
  test('Set package name from Package', () {
    DependencyChecker dc = DependencyChecker(config: config, package: package);

    expect(dc.name, 'Dodgers');
  });
}
