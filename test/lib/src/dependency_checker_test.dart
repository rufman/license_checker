import 'dart:io';
import 'dart:async';

import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/dependency_checker.dart';

typedef _PropertyGetter<T> = FutureOr<T> Function(
  DependencyChecker dependencyChecker,
);
typedef _ReturnMatcher<M> = M Function();

class DependencyTest<R> {
  final _PropertyGetter<R> testProperty;
  final _ReturnMatcher<R> expectedReturnMatcher;
  final String testDescription;

  DependencyTest({
    required this.testProperty,
    required this.expectedReturnMatcher,
    required this.testDescription,
  });
}

void main() {
  group('General tests', () {
    Config config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    DependencyChecker dc = DependencyChecker(
      config: config,
      package: Package(
        'dodgers',
        Uri(
          scheme: 'file',
          path: Directory.current.absolute.path +
              '/test/lib/src/fixtures/dodgers/',
        ),
      ),
    );

    List<DependencyTest<Object?>> _validTests = [
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'dodgers',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () =>
            Directory.current.absolute.path +
            '/test/lib/src/fixtures/dodgers/LICENSE',
        testDescription: 'should get a license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'Apache-2.0',
        testDescription: 'should get the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.permitted,
        testDescription: 'should get the license status based on the config',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => '2022 Los Angeles',
        testDescription: 'should extract the copyright from the license',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.sourceLocation;
        },
        expectedReturnMatcher: () => 'https://chavez.ravine',
        testDescription: 'should return the location of the source',
      ),
    ];

    for (DependencyTest<Object?> t in _validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('No license file', () {
    Config config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    DependencyChecker dc = DependencyChecker(
      config: config,
      package: Package(
        'angeles',
        Uri(
          scheme: 'file',
          path: Directory.current.absolute.path +
              '/test/lib/src/fixtures/angeles/',
        ),
      ),
    );

    List<DependencyTest<Object?>> _validTests = [
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'angeles',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () => null,
        testDescription: 'should return that no file was found',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => noFileLicense,
        testDescription: 'should return $noFileLicense as the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.noLicense,
        testDescription: 'should return no license as the status',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => unknownCopyright,
        testDescription: 'should return $unknownCopyright',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.sourceLocation;
        },
        expectedReturnMatcher: () => 'https://www.mlb.com/angels',
        testDescription: 'should return the location of the source',
      ),
    ];

    for (DependencyTest<Object?> t in _validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('Approved Package', () {
    Config config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    DependencyChecker dc = DependencyChecker(
      config: config,
      package: Package(
        'mlb',
        Uri(
          scheme: 'file',
          path: Directory.current.absolute.path + '/test/lib/src/fixtures/mlb/',
        ),
      ),
    );

    Config configChanged = Config.fromFile(
      File('test/lib/src/fixtures/valid_config_changed_approved_pkg_lic.yaml'),
    );
    DependencyChecker dcChanged = DependencyChecker(
      config: configChanged,
      package: Package(
        'mlb',
        Uri(
          scheme: 'file',
          path: Directory.current.absolute.path + '/test/lib/src/fixtures/mlb/',
        ),
      ),
    );

    List<DependencyTest<Object?>> _validTests = [
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'mlb',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () =>
            Directory.current.absolute.path +
            '/test/lib/src/fixtures/mlb/LICENSE',
        testDescription: 'should return the license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'GPL-1.0',
        testDescription: 'should return the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.approved,
        testDescription:
            'should return that this particular package was explicitly approved',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => '1989 Free Software Foundation, Inc.',
        testDescription:
            'should return parsed copyright (the license copyright that needs to be corrected)',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.sourceLocation;
        },
        expectedReturnMatcher: () => unknownSource,
        testDescription: 'should return $unknownSource as the source location',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return dcChanged.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.needsApproval,
        testDescription:
            "should return needs approval, if a previously approved package change it's license",
      ),
    ];

    for (DependencyTest<Object?> t in _validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('Not a package with pubspec.yaml', () {
    Config config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    DependencyChecker dc = DependencyChecker(
      config: config,
      package: Package(
        'padres',
        Uri(
          scheme: 'file',
          path: Directory.current.absolute.path +
              '/test/lib/src/fixtures/padres/',
        ),
      ),
    );

    List<DependencyTest<Object?>> _validTests = [
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'padres',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () =>
            Directory.current.absolute.path +
            '/test/lib/src/fixtures/padres/LICENSE',
        testDescription: 'should return the license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'MIT',
        testDescription: 'should return the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.rejected,
        testDescription: 'should return that this license is rejected',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => unknownCopyright,
        testDescription: 'should return $unknownCopyright',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => () => d.sourceLocation,
        expectedReturnMatcher: () => throwsA(
          predicate(
            (e) =>
                e is FileSystemException &&
                e.message
                    .contains('pubspec.yaml file not found in package padres'),
          ),
        ),
        testDescription: 'should throw an exception for pubspec.yaml file',
      ),
    ];

    for (DependencyTest<Object?> t in _validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });
}
