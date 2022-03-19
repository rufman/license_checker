import 'dart:io';

import 'package:test/test.dart';

import 'package:license_checker/src/config.dart';

void main() {
  group('Valid Config', () {
    test('Parse minimal valid config', () {
      Config validConfig = Config.fromFile(
        File('test/lib/src/fixtures/valid_config_minimal.yaml'),
      );

      expect(validConfig.permittedLicenses, ['Apache-2.0']);
      expect(validConfig.rejectedLicenses, <String>[]);
      expect(validConfig.approvedPackages, <String, String>{});
    });
    test('Parse valid config with everything defined', () {
      Config validConfig =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));

      expect(validConfig.permittedLicenses, ['Apache-2.0']);
      expect(validConfig.rejectedLicenses, ['MIT']);
      expect(validConfig.approvedPackages, {
        'GPL': ['mlb']
      });
    });

    test('Parse valid config with no rejected licenses', () {
      Config validConfig = Config.fromFile(
        File('test/lib/src/fixtures/valid_config_no_reject.yaml'),
      );

      expect(validConfig.permittedLicenses, ['Apache-2.0']);
      expect(validConfig.rejectedLicenses, <String>[]);
      expect(validConfig.approvedPackages, {
        'GPL': ['mlb']
      });
    });
  });

  group('Invalid Config', () {
    test('Throw format exception on invalid permitted license config', () {
      expect(
        () {
          Config.fromFile(
            File('test/lib/src/fixtures/invalid_permitted_config.yaml'),
          );
        },
        throwsA(
          predicate(
            (e) =>
                e is FormatException &&
                e.message == '`permittedLicenses` is not defined as a list',
          ),
        ),
      );
    });

    test('Throw format exception when no permitted licesens are defined', () {
      expect(
        () {
          Config.fromFile(
            File('test/lib/src/fixtures/invalid_no_permitted_config.yaml'),
          );
        },
        throwsA(
          predicate(
            (e) =>
                e is FormatException &&
                e.message == '`permittedLicenses` not defined',
          ),
        ),
      );
    });
  });
}
