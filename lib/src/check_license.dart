import 'dart:io';

import 'package:license_checker/src/dependency_checker.dart';
import 'package:license_checker/src/package_checker.dart';

/// Type defintion for the function that formats the display of the parsed license
/// result.
typedef LicenseDisplayFunction<D> = D Function({
  required String packageName,
  required LicenseStatus licenseStatus,
  required String licenseName,
});

/// Encapsulates a generic license display along with a priority that can be used
/// for sorting.
class LicenseDisplayWithPriority<D> {
  /// The formatted license display.
  final D display;

  /// The associated license status.
  final LicenseStatus status;

  /// The priority of the liscense display based on the status.
  late final int priority;

  LicenseDisplayWithPriority._(this.display, this.status, this.priority);

  /// Constructs thedisplayed license with a priority set by status.
  factory LicenseDisplayWithPriority.withStatusPriority({
    required D display,
    required LicenseStatus licenseStatus,
  }) {
    int priority = 0;
    switch (licenseStatus) {
      case LicenseStatus.approved:
        {
          priority = 1;
          break;
        }
      case LicenseStatus.permitted:
        {
          priority = 1;
          break;
        }
      case LicenseStatus.unknown:
        {
          priority = 2;
          break;
        }
      case LicenseStatus.rejected:
        {
          priority = 5;
          break;
        }
      case LicenseStatus.needsApproval:
        {
          priority = 4;
          break;
        }
      case LicenseStatus.noLicense:
        {
          priority = 3;
          break;
        }
    }
    return LicenseDisplayWithPriority._(display, licenseStatus, priority);
  }
}

/// Checks all licenses in a the package.
///
/// Returns a list of [LicenseDisplayWithPriority] that contains all the parsed
/// licenses. If [filterApproved] is true, then this list will not contain approved
/// package.
///
/// Throws a [FileSystemException] if the necessary files are not found.
Future<List<LicenseDisplayWithPriority<D>>> checkAllPackageLicenses<D>({
  required bool showDirectDepsOnly,
  required bool filterApproved,
  required LicenseDisplayFunction<D> licenseDisplay,
  required PackageChecker packageConfig,
  bool sort = false,
}) async {
  List<LicenseDisplayWithPriority<D>> licenses = [];

  for (DependencyChecker package in packageConfig.packages) {
    if (showDirectDepsOnly) {
      // Ignore dependencies not defined in the packages pubspec.yaml
      if (!packageConfig.pubspec.dependencies.containsKey(package.name)) {
        continue;
      }
    }
    LicenseStatus status = await package.packageLicenseStatus;
    if (!filterApproved ||
        (filterApproved &&
            status != LicenseStatus.approved &&
            status != LicenseStatus.permitted)) {
      licenses.add(
        LicenseDisplayWithPriority.withStatusPriority(
          display: await checkPackageLicense(
            package: package,
            licenseDisplay: licenseDisplay,
          ),
          licenseStatus: status,
        ),
      );
    }
  }

  if (sort) {
    // Sort by priority
    licenses.sort((a, b) {
      if (a.priority < b.priority) {
        return -1;
      }
      if (a.priority > b.priority) {
        return 1;
      }
      return 0;
    });
  }

  return licenses;
}

/// Check the license of a single package.
///
/// Retruns the formatted license results.
/// Throws a [FileSystemException] if the necessary files are not found.
Future<D> checkPackageLicense<D>({
  required DependencyChecker package,
  required LicenseDisplayFunction<D> licenseDisplay,
}) async {
  return licenseDisplay(
    packageName: package.name,
    licenseStatus: await package.packageLicenseStatus,
    licenseName: await package.licenseName,
  );
}
