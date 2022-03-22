import 'dart:io';

import 'package:test/test.dart';

import 'package:license_checker/src/config.dart';

class _ConfigErrorTest {
  final String testDescription;
  final String fileName;
  final String expectedErrorMessage;

  _ConfigErrorTest({
    required this.fileName,
    required this.expectedErrorMessage,
    required this.testDescription,
  });
}

class _ConfigSuccessTest {
  final String testDescription;
  final String fileName;
  final List<String> expectedPermittedLicenses;
  final List<String> expectedRejectedLicenses;
  final Map<String, List<String>> expectedApprovedPackages;

  _ConfigSuccessTest({
    required this.fileName,
    required this.expectedPermittedLicenses,
    required this.expectedRejectedLicenses,
    required this.expectedApprovedPackages,
    required this.testDescription,
  });
}

void main() {
  test('No config file found', () {
    const file = 'not_here';
    expect(
      () => Config.fromFile(File(file)),
      throwsA(
        predicate(
          (e) =>
              e is FileSystemException &&
              e.message.contains('$file file not found in current directory.'),
        ),
      ),
    );
  });

  group('Valid Config', () {
    List<_ConfigSuccessTest> configSuccessTests = [
      _ConfigSuccessTest(
        testDescription: 'Parse minimal valid config',
        fileName: 'valid_config_minimal',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: <String>[],
        expectedApprovedPackages: <String, List<String>>{},
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config with everything defined',
        fileName: 'valid_config',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: ['MIT'],
        expectedApprovedPackages: {
          'GPL-1.0': ['mlb'],
        },
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config with no rejected licenses',
        fileName: 'valid_config_no_reject',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: <String>[],
        expectedApprovedPackages: {
          'GPL': ['mlb'],
        },
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config and ignore non string licenses',
        fileName: 'valid_config_string',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: ['MIT'],
        expectedApprovedPackages: {
          'GPL': ['mlb'],
        },
      ),
    ];
    for (_ConfigSuccessTest t in configSuccessTests) {
      test(t.testDescription, () {
        Config validConfig =
            Config.fromFile(File('test/lib/src/fixtures/${t.fileName}.yaml'));

        expect(validConfig.permittedLicenses, t.expectedPermittedLicenses);
        expect(validConfig.rejectedLicenses, t.expectedRejectedLicenses);
        expect(validConfig.approvedPackages, t.expectedApprovedPackages);
      });
    }
  });

  group('Invalid Config', () {
    List<_ConfigErrorTest> configErrorTests = [
      _ConfigErrorTest(
        testDescription:
            'Throw format exception on invalid permitted license config',
        fileName: 'invalid_permitted_config',
        expectedErrorMessage: '`permittedLicenses` is not defined as a list',
      ),
      _ConfigErrorTest(
        testDescription:
            'Throw format exception when no permitted licesens are defined',
        fileName: 'invalid_no_permitted_config',
        expectedErrorMessage: '`permittedLicenses` not defined',
      ),
      _ConfigErrorTest(
        testDescription:
            'Throw format exception when no rejected licesens are not properly defined',
        fileName: 'invalid_rejected_config',
        expectedErrorMessage: '`rejectedLicenses` is not defined as a list',
      ),
      _ConfigErrorTest(
        testDescription:
            'Throw format exception when approved package is not defined as a map',
        fileName: 'invalid_approved_package_config',
        expectedErrorMessage: '`approvedPackages` not defined as a map',
      ),
      _ConfigErrorTest(
        testDescription:
            'Throw format exception when approved package is not defined as a map with string keys',
        fileName: 'invalid_approved_package_string_config',
        expectedErrorMessage:
            '`approvedPackages` must be keyed by a string license name',
      ),
      _ConfigErrorTest(
        testDescription:
            'Throw format exception when approved package is not defined as a map of lists',
        fileName: 'invalid_approved_package_list_config',
        expectedErrorMessage: '`approvedPackages` must specified as a list',
      ),
    ];

    for (_ConfigErrorTest t in configErrorTests) {
      test(t.testDescription, () {
        expect(
          () {
            Config.fromFile(
              File('test/lib/src/fixtures/${t.fileName}.yaml'),
            );
          },
          throwsA(
            predicate(
              (e) =>
                  e is FormatException && e.message == t.expectedErrorMessage,
            ),
          ),
        );
      });
    }
  });
}
