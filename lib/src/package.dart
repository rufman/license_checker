import 'dart:io';

import 'package:pana/pana.dart';
// ignore: implementation_imports
import 'package:pana/src/license_detection/license_detector.dart'
    as pana_license_detector;
import 'package:path/path.dart';

import 'package:license_checker/src/config.dart';

/// Placeholder for when no license file is found.
const String noFileLicense = 'no-file';

/// Placeholder for when the license is not recognized,
const String unknownLicense = 'unknown-license';

/// Placeholder for when the copyright is no known.
const String unknownCopyright = 'unknown-copyright';

/// Placeholder for when the source location is not known.
const String unknownSource = 'unknown-source';

/// Regular expression to find and extract the copyright notice.
RegExp coprightRegex = RegExp(
  r'Copyright\s(\(c\)\s)*(?<date>[0-9]{4})(?<holders>.+)\n',
  caseSensitive: false,
  multiLine: false,
);

final _licenseFileNames = [
  ...textFileNameCandidates('LICENSE'),
  ...textFileNameCandidates('LICENCE'),
  ...textFileNameCandidates('COPYING'),
  ...textFileNameCandidates('UNLICENSE'),
  ...textFileNameCandidates('License'),
  ...textFileNameCandidates('Licence'),
  ...textFileNameCandidates('Copying'),
  ...textFileNameCandidates('Unlicense'),
  ...textFileNameCandidates('license'),
  ...textFileNameCandidates('licence'),
  ...textFileNameCandidates('copying'),
  ...textFileNameCandidates('unlicense'),
];

/// Status of a license according to the given config.
enum LicenseStatus {
  /// State when the license type is not detected.
  unknown,

  /// State when the package has been explicitly approved according to the config,
  approved,

  /// State when the license is permmitted according to the config,
  permitted,

  /// State when the license has been diallowed according to the config,
  rejected,

  /// State when the license associated with the package needs approval.
  needsApproval,

  /// State when no license if found.
  noLicense,
}

/// Represents a single package that is a dependency of the package we are checking.
class Package {
  /// The name of the package.
  final String name;

  /// The root uri of the package.
  final String rootUri;

  /// User config for the license checker.
  final Config config;

  Package._({
    required this.name,
    required this.rootUri,
    required this.config,
  });

  /// Constructs a package from json
  factory Package.fromJson({required Config config, required Object source}) {
    if (source is! Map) {
      throw FormatException();
    }

    String rootUri = source['rootUri'] ?? '<unknown root uri>';
    if (rootUri.startsWith('file://')) {
      if (Platform.isWindows) {
        rootUri = rootUri.substring(8);
      } else {
        rootUri = rootUri.substring(7);
      }
    }

    return Package._(
      name: source['name'] ?? '<unknown name>',
      rootUri: rootUri,
      config: config,
    );
  }

  /// Returns the license status of the package.
  Future<LicenseStatus> get packageLicenseStatus async {
    String lname = await licenseName;

    // No file found
    if (lname == noFileLicense) {
      // Check approved packages
      return _checkApprovedPackages(noFileLicense) ?? LicenseStatus.noLicense;
    }

    if (lname == unknownLicense) {
      return LicenseStatus.unknown;
    }

    // Check different cases defined in the config
    return Future.value(
      _checkLicense(
            lname,
            config.permittedLicenses,
            LicenseStatus.permitted,
          ) ??
          _checkLicense(
            lname,
            config.rejectedLicenses,
            LicenseStatus.rejected,
          ) ??
          _checkApprovedPackages(lname) ??
          LicenseStatus.needsApproval,
    );
  }

  /// Returns the license file associated with the package. Will check for various
  /// different file names.
  File? get licenseFile {
    for (String fileName in _licenseFileNames) {
      File file = File(join(rootUri, fileName));
      if (file.existsSync()) {
        return file;
      }
    }

    return null;
  }

  /// The license name associated with the package
  Future<String> get licenseName async {
    if (licenseFile == null) {
      return noFileLicense;
    }

    String content = await licenseFile!.readAsString();
    pana_license_detector.Result res =
        await pana_license_detector.detectLicense(content, 0.9);
    // Just the first match (highest probability) as the license.
    return res.matches.isNotEmpty
        ? res.matches.first.identifier
        : unknownLicense;
  }

  /// Returns the copyright notice extracted from the license file.
  Future<String> get copyright async {
    if (licenseFile == null) {
      return unknownCopyright;
    }

    String content = await licenseFile!.readAsString();
    RegExpMatch? match = coprightRegex.firstMatch(content);
    String? copyrightText = (match?.namedGroup('date') ?? '') +
        (match?.namedGroup('holders') ?? unknownCopyright);

    return copyrightText;
  }

  /// Returns the location where the source can be found
  String get sourceLocation {
    String sourceLocation = unknownSource;
    File file = File(join(rootUri, 'pubspec.yaml'));
    if (!file.existsSync()) {
      return throw FileSystemException(
        'pubspec.yaml file not found in package $name.',
      );
    }

    sourceLocation =
        Pubspec.parseYaml(file.readAsStringSync()).repositoryOrHomepage ??
            unknownSource;

    return sourceLocation;
  }

  LicenseStatus? _checkApprovedPackages(String lName) {
    List<String>? pkgs = config.approvedPackages[lName];
    if (pkgs != null && pkgs.contains(name)) {
      // Has been explicitly approved
      return LicenseStatus.approved;
    }
    return null;
  }

  LicenseStatus? _checkLicense(
    String lName,
    List<String> licenses,
    LicenseStatus status,
  ) {
    if (licenses.contains(lName)) {
      return status;
    }
    return null;
  }
}
