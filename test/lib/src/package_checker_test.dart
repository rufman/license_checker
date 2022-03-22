import 'dart:io';

import 'package:pana/pana.dart';
import 'package:test/test.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/package_checker.dart';

void main() async {
  Config _config =
      Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
  Pubspec _pubspec = Pubspec.parseYaml(
    await File('test/lib/src/fixtures/dodgers/pubspec.yaml').readAsString(),
  );

  PackageChecker pc = await PackageChecker.fromDirectory(
    directory: Directory('test/lib/src/fixtures/dodgers'),
    config: _config,
  );

  test('should properly create a PackageChecker with all proper attributes',
      () {
    expect(
      pc.packages.map((p) => p.name),
      containsAll(['padres', 'as', 'angeles']),
    );
    expect(pc.config, _config);
    expect(pc.pubspec.name, _pubspec.name);
  });
}
