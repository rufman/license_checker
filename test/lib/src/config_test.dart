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
  final Map<String, String> expectedCopyrightNotice;

  _ConfigSuccessTest({
    required this.fileName,
    required this.expectedPermittedLicenses,
    required this.expectedRejectedLicenses,
    required this.expectedApprovedPackages,
    required this.expectedCopyrightNotice,
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
        expectedCopyrightNotice: {},
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config with everything defined',
        fileName: 'valid_config',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: ['MIT'],
        expectedApprovedPackages: {
          'GPL-1.0': ['mlb'],
        },
        expectedCopyrightNotice: {},
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config with no rejected licenses',
        fileName: 'valid_config_no_reject',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: <String>[],
        expectedApprovedPackages: {
          'GPL': ['mlb'],
        },
        expectedCopyrightNotice: {},
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config and ignore non string licenses',
        fileName: 'valid_config_string',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: ['MIT'],
        expectedApprovedPackages: {
          'GPL': ['mlb'],
        },
        expectedCopyrightNotice: {},
      ),
      _ConfigSuccessTest(
        testDescription: 'Parse valid config with copyright notice overrides',
        fileName: 'valid_config_copyright',
        expectedPermittedLicenses: ['Apache-2.0'],
        expectedRejectedLicenses: ['MIT'],
        expectedApprovedPackages: {
          'GPL-1.0': ['mlb'],
        },
        expectedCopyrightNotice: {'mlb': '2000 MLB.'},
      ),
    ];
    for (_ConfigSuccessTest t in configSuccessTests) {
      test(t.testDescription, () {
        Config validConfig =
            Config.fromFile(File('test/lib/src/fixtures/${t.fileName}.yaml'));

        expect(validConfig.permittedLicenses, t.expectedPermittedLicenses);
        expect(validConfig.rejectedLicenses, t.expectedRejectedLicenses);
        expect(validConfig.approvedPackages, t.expectedApprovedPackages);
        expect(validConfig.copyrightNotice, t.expectedCopyrightNotice);
      });
    }
  });

  group('Invalid Config', () {
    List<_ConfigErrorTest> configErrorTests = [
      _ConfigErrorTest(
        testDescription:
            'throw format exception on invalid permitted license config',
        fileName: 'invalid_permitted_config',
        expectedErrorMessage: '`permittedLicenses` is not defined as a list',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when no permitted licesens are defined',
        fileName: 'invalid_no_permitted_config',
        expectedErrorMessage: '`permittedLicenses` not defined',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when no rejected licesens are not properly defined',
        fileName: 'invalid_rejected_config',
        expectedErrorMessage: '`rejectedLicenses` is not defined as a list',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when approved package is not defined as a map',
        fileName: 'invalid_approved_package_config',
        expectedErrorMessage: '`approvedPackages` not defined as a map',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when approved package is not defined as a map with string keys',
        fileName: 'invalid_approved_package_string_config',
        expectedErrorMessage:
            '`approvedPackages` must be keyed by a string license name',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when approved package is not defined as a map of lists',
        fileName: 'invalid_approved_package_list_config',
        expectedErrorMessage:
            '`approvedPackages` value must specified as a list',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when copyright notice is not defined as a map',
        fileName: 'invalid_copyright_list_config',
        expectedErrorMessage: '`copyrightNotice` not defined as a map',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when copyright notice is not defined with string keys',
        fileName: 'invalid_copyright_string_key_config',
        expectedErrorMessage: '`copyrightNotice` must be keyed by a string',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when copyright notice is not defined with string values',
        fileName: 'invalid_copyright_string_value_config',
        expectedErrorMessage: '`copyrightNotice` value must be a string',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when package license override is not defined as a map',
        fileName: 'invalid_license_override_list_config',
        expectedErrorMessage: '`packageLicenseOverride` not defined as a map',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when package license override is not defined with string keys',
        fileName: 'invalid_license_override_string_key_config',
        expectedErrorMessage:
            '`packageLicenseOverride` must be keyed by a string',
      ),
      _ConfigErrorTest(
        testDescription:
            'throw format exception when package license override is not defined with string values',
        fileName: 'invalid_license_override_string_value_config',
        expectedErrorMessage: '`packageLicenseOverride` value must be a string',
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
