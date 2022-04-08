// Ensure that we have run the generate script, so versions are properly set

import 'dart:io';

import 'package:path/path.dart' show joinAll;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

import 'package:license_checker/version.g.dart';

void main() {
  test('versions should agree', () async {
    YamlMap pubspec = loadYaml(
      await File(joinAll([Directory.current.path, 'pubspec.yaml']))
          .readAsString(),
    );

    expect(pubspec['version'], equals(licenseCheckerVersion));
  });
}
