import 'dart:io';

import 'package:pana/pana.dart';
import 'package:test/test.dart';

import 'package:mockito/mockito.dart';

import 'package:license_checker/src/checker.dart';
import 'package:license_checker/src/config.dart';
import 'package:license_checker/src/package_checker.dart';
import 'package:license_checker/src/dependency_checker.dart';

// class MockedPackage extends Mock implements Package {
//   @override
//   final Package package;

//   MockedDependencyChecker(this.package);
// }

class MockedDependencyChecker extends Mock implements DependencyChecker {
  @override
  final String name;

  final LicenseStatus _status;
  final File? _licenseFile;

  @override
  Future<LicenseStatus> get packageLicenseStatus {
    return Future.value(_status);
  }

  @override
  Future<String> get licenseName => Future.value('swag');

  @override
  Future<String> get copyright => Future.value('1958 Los Angeles');

  @override
  String get sourceLocation => 'Chavez Ravine';

  @override
  File? get licenseFile => _licenseFile;

  MockedDependencyChecker(this.name, this._status) : _licenseFile = null;

  MockedDependencyChecker.withLicenseFile(
    this.name,
    this._status,
    this._licenseFile,
  );
}

class MockedPackageChecker extends Mock implements PackageChecker {
  @override
  final List<DependencyChecker> packages;

  @override
  final Pubspec pubspec = Pubspec({
    'name': 'MLB',
    'dependencies': {'Dodgers': '1.0.0', 'Giants': '1.0.0'}
  });

  MockedPackageChecker(this.packages);
}

void main() {
  group('Check License', () {
    String licenseDisplay({
      required String packageName,
      required LicenseStatus licenseStatus,
      required String licenseName,
    }) {
      return '$packageName $licenseName ${licenseStatus.toString()}';
    }

    test('should check the license and return the display for one package',
        () async {
      DependencyChecker package =
          MockedDependencyChecker('Dodgers', LicenseStatus.approved);

      expect(
        await checkPackageLicense(
          package: package,
          licenseDisplay: licenseDisplay,
        ),
        'Dodgers swag LicenseStatus.approved',
      );
    });

    test('should check the license of all dependencies of a package', () async {
      PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
      ]);
      List<LicenseDisplayWithPriority<String>> result =
          await checkAllPackageLicenses(
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
      );

      expect(result.map((e) => e.display.toString()), [
        'Dodgers swag LicenseStatus.approved',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.approved,
        LicenseStatus.rejected,
      ]);
    });

    test('should check the license of direct dependencies of a package',
        () async {
      PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Kings', LicenseStatus.approved),
      ]);
      List<LicenseDisplayWithPriority<String>> result =
          await checkAllPackageLicenses(
        packageConfig: packageConfig,
        showDirectDepsOnly: true,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
      );

      expect(result.map((e) => e.display.toString()), [
        'Dodgers swag LicenseStatus.approved',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.approved,
        LicenseStatus.rejected,
      ]);
    });

    test(
        'should check the license of all dependencies of a package and filter out approved and permitted license',
        () async {
      PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Angles', LicenseStatus.unknown),
        MockedDependencyChecker('As', LicenseStatus.permitted),
        MockedDependencyChecker('Padres', LicenseStatus.needsApproval),
        MockedDependencyChecker('Rockies', LicenseStatus.noLicense),
      ]);
      List<LicenseDisplayWithPriority<String>> result =
          await checkAllPackageLicenses(
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: true,
        licenseDisplay: licenseDisplay,
      );

      expect(result.map((e) => e.display.toString()), [
        'Giants swag LicenseStatus.rejected',
        'Angles swag LicenseStatus.unknown',
        'Padres swag LicenseStatus.needsApproval',
        'Rockies swag LicenseStatus.noLicense',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.rejected,
        LicenseStatus.unknown,
        LicenseStatus.needsApproval,
        LicenseStatus.noLicense,
      ]);
    });

    test(
        'should check the license of all dependencies and sort them correctly by status priority',
        () async {
      PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Angles', LicenseStatus.unknown),
        MockedDependencyChecker('As', LicenseStatus.permitted),
        MockedDependencyChecker('Padres', LicenseStatus.needsApproval),
        MockedDependencyChecker('Rockies', LicenseStatus.noLicense),
      ]);
      List<LicenseDisplayWithPriority<String>> result =
          await checkAllPackageLicenses(
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
        sort: true,
      );

      expect(result.map((e) => e.display.toString()), [
        'Dodgers swag LicenseStatus.approved',
        'As swag LicenseStatus.permitted',
        'Angles swag LicenseStatus.unknown',
        'Rockies swag LicenseStatus.noLicense',
        'Padres swag LicenseStatus.needsApproval',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.approved,
        LicenseStatus.permitted,
        LicenseStatus.unknown,
        LicenseStatus.noLicense,
        LicenseStatus.needsApproval,
        LicenseStatus.rejected,
      ]);
    });
  });

  group('Generate Disclaimer', () {
    String disclaimerCLIDisplay({
      required String packageName,
      required String licenseName,
      required String copyright,
      required String sourceLocation,
    }) {
      return 'cli: $packageName $licenseName $copyright $sourceLocation';
    }

    String disclaimerFileDisplay({
      required String packageName,
      required String licenseName,
      required String copyright,
      required String sourceLocation,
      required File? licenseFile,
    }) {
      return 'file: $packageName $licenseName $copyright $sourceLocation ${licenseFile?.path}';
    }

    test('should generate the disclaimer for a single package', () async {
      Config config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      DisclaimerDisplay<String, String> result =
          await generatePackageDisclaimer<String, String>(
        config: config,
        package: MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli, 'cli: Dodgers swag 1958 Los Angeles Chavez Ravine');
      expect(
        result.file,
        'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium',
      );
    });

    test(
        'should generate the disclaimer for a single package overriding the copyright with what is defined in the config',
        () async {
      Config config = Config.fromFile(
        File('test/lib/src/fixtures/valid_config_copyright.yaml'),
      );
      DisclaimerDisplay<String, String> result =
          await generatePackageDisclaimer<String, String>(
        config: config,
        package: MockedDependencyChecker.withLicenseFile(
          'mlb',
          LicenseStatus.approved,
          File('/new/york'),
        ),
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );
      expect(result.cli, 'cli: mlb swag 2000 MLB. Chavez Ravine');
      expect(
        result.file,
        'file: mlb swag 2000 MLB. Chavez Ravine /new/york',
      );
    });

    test('should generate the disclaimer for all dependencies of a package',
        () async {
      Config config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'Kings',
          LicenseStatus.approved,
          File('/crypto/.com'),
        ),
      ]);
      DisclaimerDisplay<List<String>, List<String>> result =
          await generateDisclaimers<String, String>(
        config: config,
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli.length, equals(2));
      expect(
        result.cli[0],
        equals('cli: Dodgers swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(
        result.cli[1],
        equals('cli: Kings swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(result.file.length, equals(2));
      expect(
        result.file[0],
        equals(
            'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium'),
      );
      expect(
        result.file[1],
        equals('file: Kings swag 1958 Los Angeles Chavez Ravine /crypto/.com'),
      );
    });

    test('should generate the disclaimer for direct dependencies of a package',
        () async {
      Config config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'Kings',
          LicenseStatus.approved,
          File('/crypto/.com'),
        ),
      ]);
      DisclaimerDisplay<List<String>, List<String>> result =
          await generateDisclaimers<String, String>(
        config: config,
        packageConfig: packageConfig,
        showDirectDepsOnly: true,
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli.length, equals(1));
      expect(
        result.cli[0],
        equals('cli: Dodgers swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(result.file.length, equals(1));
      expect(
        result.file[0],
        equals(
          'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium',
        ),
      );
    });
  });
}
