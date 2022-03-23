import 'dart:io';

import 'package:pana/pana.dart';
import 'package:test/test.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/package_checker.dart';

void main() {
  Config _config =
      Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));

  test('should properly create a PackageChecker with all proper attributes',
      () async {
    Pubspec _pubspec = Pubspec.parseYaml(
      await File('test/lib/src/fixtures/dodgers/pubspec.yaml').readAsString(),
    );
    PackageChecker pc = await PackageChecker.fromDirectory(
      directory: Directory('test/lib/src/fixtures/dodgers'),
      config: _config,
    );
    expect(
      pc.packages.map((p) => p.name),
      containsAll(['padres', 'as', 'angeles', 'mlb']),
    );
    expect(pc.config, _config);
    expect(pc.pubspec.name, _pubspec.name);
  });

  test('should load package checker from the current directory', () async {
    PackageChecker pc =
        await PackageChecker.fromCurrentDirectory(config: _config);
    expect(pc.pubspec.name, 'license_checker');
    expect(pc.config, _config);
  });

  test('should throw an exception when no pubspec.yaml is found', () {
    expect(
      () async {
        await PackageChecker.fromDirectory(
          directory: Directory('test/lib/src/fixtures/padres'),
          config: _config,
        );
      },
      throwsA(
        predicate(
          (e) =>
              e is FileSystemException &&
              e.message
                  .contains('pubspec.yaml file not found in current directory'),
        ),
      ),
    );
  });

  test('should throw an exception when no package_config.json is found', () {
    expect(
      () async {
        await PackageChecker.fromDirectory(
          directory: Directory('test/lib/src/fixtures/angeles'),
          config: _config,
        );
      },
      throwsA(
        predicate(
          (e) =>
              e is FileSystemException &&
              e.message.contains('No package_config.json found'),
        ),
      ),
    );
  });
}
